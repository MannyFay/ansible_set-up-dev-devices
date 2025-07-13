#!/usr/bin/env bash

sudo apt update && \
sudo apt full-upgrade -y && \
sudo apt autoremove -y && \
sudo apt -f install -y && \
sudo apt clean

sudo apt install software-properties-common -y
sudo apt-add-repository --yes --update ppa:ansible/ansible
sudo apt install ansible -y
