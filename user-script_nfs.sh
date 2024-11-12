sudo su -

user_name="ansible-user"
user_home="/home/$user_name"
user_ssh_dir="$user_home/.ssh"
ssh_key_path="$user_ssh_dir/authorized_keys"
# Check if user already exists
if id "$user_name" &>/dev/null; then
  echo "User $user_name already exists."
  exit 1
fi

# create a user
sudo adduser --disabled-password --gecos "" "$user_name"

echo "User $user_name is created succesfully"

mkdir -p $user_ssh_dir
chmod 700 $user_ssh_dir

# install awscli
sudo apt update -y
sudo apt-get install -y awscli

aws s3cp s3://my-key/server.pub $ssh_key_path
chmod 600 $ssh_key_path
chown -R $user_name:$user_name $user_name

# add user to sudoer group
echo "ansible-user ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/ansible-user

# Navigate to home directory and log a message
cd $user_home && echo "correct till this step" >>nfs.log 2>&1
