#!/bin/bash

sudo su -

user_name="ansible-user"
user_home="/home/$user_name"
user_ssh_dir="$user_home/.ssh"

# Check if user already exists
if id "$user_name" &>/dev/null; then
  echo "User $user_name already exists."
  exit 1
fi

# create a user
sudo adduser --disabled-password --gecos "" "$user_name"

echo "User $user_name is created succesfully"

# add user to sudoer group
echo "ansible-user ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/ansible-user

# Switch to user from rot
su - ansible-user

# install awscli
sudo apt update -y
sudo apt-get install -y awscli

# Install ansible
sudo apt-add-repository ppa:ansible/ansible -y
sudo apt update -y
sudo apt install ansible -y

mkdir -p $user_ssh_dir
chmod 700 $user_ssh_dir

#Generate SSH key
if [ ! -f "$user_ssh_dir/id_rsa" ]; then
  ssh-keygen -t rsa -b 4096 -f $user_ssh_dir/id_rsa -N ""
fi

chown -R $user_name:$user_name $user_home

# DELETE THE EXISTING KEY
aws s3 rm s3://my-key/server.pub

aws s3 cp $user_ssh_dir/id_rsa.pub s3://my-key/server.pub

#Login to user
ssh_key_path="$user_ssh_dir/authorized_keys"

aws s3cp s3://my-key/server.pub $ssh_key_path
chmod 600 $ssh_key_path
chown -R $user_name:$user_name $user_name

cd
# Navigate to home directory and log a message
cd $user_home && echo "correct till this step" >>bastion.log 2>&1

git clone "https://github.com/Manohar-1305/ansible-playbook-k8s-installation.git"

INVENTORY_FILE="ansible-playbook-k8s-installation/inventories/inventory.ini"
LOG_FILE="ansible_script.log"
