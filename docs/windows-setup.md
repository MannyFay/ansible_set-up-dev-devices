# Windows Setup Guide

## Prerequisites for Windows Management

Windows machines require specific configuration to be managed by Ansible from your Hetzner server.

### 1. Enable WinRM on Windows Machines

Run this PowerShell script **as Administrator** on each Windows machine:

```powershell
# Enable WinRM service
Enable-PSRemoting -Force

# Configure WinRM for HTTP (basic auth)
winrm quickconfig -q
winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="1024"}'
winrm set winrm/config '@{MaxTimeoutms="1800000"}'
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
winrm set winrm/config/service/auth '@{Basic="true"}'

# Configure firewall
netsh advfirewall firewall add rule name="WinRM-HTTP" dir=in localport=5985 protocol=TCP action=allow

# Create local user for Ansible (if needed)
net user ansible AnsiblePassword123! /add
net localgroup administrators ansible /add
```

### 2. Configure Ansible Control Node (Hetzner Server)

Install required Python modules on your Hetzner server:

```bash
# Install pywinrm for Windows communication
pip install pywinrm[credssp]

# Install Windows Ansible collections
ansible-galaxy collection install ansible.windows
ansible-galaxy collection install community.windows
```

### 3. Inventory Configuration

Update your inventory file with Windows connection details:

```yaml
windows:
  hosts:
    windows-desktop:
      ansible_host: YOUR_WINDOWS_IP
      ansible_user: ansible
      ansible_password: "{{ vault_windows_password }}"
      ansible_connection: winrm
      ansible_winrm_transport: basic
      ansible_winrm_server_cert_validation: ignore
      ansible_winrm_port: 5985
```

### 4. Vault Configuration

Store Windows passwords securely:

```bash
# Create vault file
ansible-vault create group_vars/windows/vault.yml

# Add this content:
vault_windows_password: "AnsiblePassword123!"
```

### 5. Running the Playbook

From your Hetzner Ansible server:

```bash
# Test connection
ansible windows -i inventory/hosts.yml -m win_ping --ask-vault-pass

# Run full setup
ansible-playbook -i inventory/hosts.yml set-up-environment.yml --limit windows --ask-vault-pass

# Run specific components
ansible-playbook -i inventory/hosts.yml set-up-environment.yml --limit windows --tags chocolatey --ask-vault-pass
```

## Network Considerations

### VPN Setup (Recommended)
If your Windows machines are behind NAT/firewall, consider setting up a VPN:

1. **Tailscale** (easiest): Install on both Hetzner server and Windows machines
2. **WireGuard**: More complex but more control
3. **OpenVPN**: Traditional solution

### Port Forwarding
If using direct internet connection:
- Forward port 5985 (WinRM HTTP) to your Windows machine
- Use strong passwords and consider IP restrictions

## Security Notes

⚠️ **Important Security Considerations:**

1. **Use HTTPS in production**: The above setup uses HTTP for simplicity
2. **Strong passwords**: Change default passwords immediately
3. **Network isolation**: Keep management traffic on isolated networks
4. **Certificate validation**: Enable in production environments
5. **Firewall rules**: Restrict WinRM access to specific IPs

## Troubleshooting

### Connection Issues
```bash
# Test WinRM connectivity
ansible windows -i inventory/hosts.yml -m win_ping -vvv

# Check Windows firewall
Get-NetFirewallRule -DisplayName "*WinRM*"

# Verify WinRM listeners
winrm enumerate winrm/config/listener
```

### Authentication Problems
```bash
# Verify user exists and has admin rights
net user ansible
net localgroup administrators

# Check WinRM auth settings
winrm get winrm/config/service/auth
```

### Module Errors
```bash
# Install missing Windows collections
ansible-galaxy collection install community.windows --force

# Verify Python dependencies
pip list | grep pywinrm
```