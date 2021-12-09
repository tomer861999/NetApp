#! /bin/bash

# Gets IP as argument for bash script 
ip=$1

# Applies terraform configuration that creates infrastructure:
# 1 ec2 server with latest ami OS, m5ad.xlarge size (4 cpu, 16 ram, 150gb disk)
# security group: my-sg: outbound: all traffic to all ips
#                        inbound: all traffic from specific ip
# private vpc and private subnet for ec2 to reside in,
# internet gateway to enable internet access, adding rule to default route table in subnet
terraform apply -var="ip=$ip" -auto-approve

# Saves ec2 public ip as variable
host=$(terraform output server_ip)

# Changes host in inventory to match ec2 public ip
echo "[ec2]
$host ansible_ssh_private_key_file=~/.ssh/id_rsa ansible_user=ec2-user" | tr -d '"' > hosts

# Runs ansible playbook to set up docker containers on ec2 according to docker compose file,
# nginx container to redirect requests for hello_world app container, and postgresql db container
# Servers key for ssh is generated via terraform based on ssh-keygen local public key
ansible-playbook docker_setup.yaml 
