#!/bin/bash

sudo su -

# User creation
user_name="ansible-user"
user_home="/home/$user_name"
user_ssh_dir="$user_home/.ssh"
ssh_key_path="$user_ssh_dir/authorized_keys"

# Check if the user already exists
if id "$username" &>/dev/null; then
    echo "User $username already exists."
    exit 1
fi

# Create the user
sudo adduser --disabled-password --gecos "" "$user_name"

# Inform user creation success
echo "User $user_name has been created successfully."

sleep 2

# Create .ssh directory if not exists
mkdir -p $user_ssh_dir
chmod 700 $user_ssh_dir

# Install AWS CLI
apt-get update -y
apt-get install -y awscli

# Fetch and copy SSH public key from S3
aws s3 cp s3://my-key/server.pub $ssh_key_path
chmod 600 $ssh_key_path
chown -R $user_name:$user_name $user_home

# Add user to sudoer group
echo "ansible-user ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/ansible-user

sleep 2

# Function to wait for the "Ok" button and press Enter
press_ok() {
    # Wait for the prompt to appear (adjust sleep time as needed)
    sleep 5
    # Send "Ok" followed by Enter
    echo "Ok"
    sleep 2
    echo "" # Press Enter
}

# Upgrade Ubuntu
sudo apt-get update && sudo apt-get upgrade -y && apt-get install -y expect

# Use expect to handle the interactive prompt
expect <<EOF
spawn sudo apt-get dist-upgrade
expect {
    "Which services should be restarted?" {
        send "Ok\r"
        exp_continue
    }
    eof
}
EOF

sudo apt-get install haproxy -y

# Fetch the public IP address
private_ip=$(aws ec2 describe-instances --region ap-south-1 --filters "Name=tag:Name,Values=master" --query "Reservations[*].Instances[*].PrivateIpAddress" --output text)
private_ip1=$(aws ec2 describe-instances --region ap-south-1 --filters "Name=tag:Name,Values=master1" --query "Reservations[*].Instances[*].PrivateIpAddress" --output text)
private_ip2=$(aws ec2 describe-instances --region ap-south-1 --filters "Name=tag:Name,Values=master2" --query "Reservations[*].Instances[*].PrivateIpAddress" --output text)
sleep 10
# Define HAProxy configuration content with the fetched public IP
haproxy_cfg_content=$(
    cat <<EOF
frontend fe-apiserver
   bind 0.0.0.0:6443
   mode tcp
   option tcplog
   timeout client 30s  # Adjust as needed
   log 127.0.0.1 local0  # Adjust the IP and log facility as needed
   default_backend be-apiserver

backend be-apiserver
   mode tcp
   option tcp-check
   balance roundrobin
   timeout connect 10s  # Adjust as needed
   timeout server 30s  # Adjust as needed
   default-server inter 10s downinter 5s rise 2 fall 2 slowstart 60s maxconn 250 maxqueue 256 weight 100

   server master1 ${private_ip}:6443 check
   server master2 ${private_ip1}:6443 check
   server master3 ${private_ip2}:6443 check

EOF
)

# Write the configuration content to the HAProxy config file
echo "$haproxy_cfg_content" >/etc/haproxy/haproxy.cfg

sudo systemctl restart haproxy
sudo systemctl enable haproxy
