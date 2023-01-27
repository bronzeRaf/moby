#!/bin/bash


SERVER_IP="${SERVER_IP:-192.168.1.99}"
SSH_USER="${SSH_USER:-$(whoami)}"
KEY_USER="${KEY_USER:-$(whoami)}"


function preseed_staging() {
cat << EOF
STAGING SERVER (DIRECT VIRTUAL MACHINE) DIRECTIONS:
  1. Configure a static IP address directly on the VM
     su
     <enter password>
     nano /etc/network/interfaces
     [change the last line to look like this, remember to set the correct
      gateway for your router's IP address if it's not 192.168.1.1]
iface eth0 inet static
  address ${SERVER_IP}
  netmask 255.255.255.0
  gateway 192.168.1.1

  2. Reboot the VM and ensure the Debian CD is mounted

  3. Install sudo
     apt-get update && apt-get install -y -q sudo

  4. Add the user to the sudo group
     adduser ${SSH_USER} sudo

  5. Run the commands in: ${0} --help
     Example:
       ./deploy.sh -a
EOF
}

function configure_sudo () {
  echo "Configuring passwordless sudo..."
  scp -i "~/.ssh/moby.pub" "sudo/sudoers" "${SSH_USER}@${SERVER_IP}:/tmp/sudoers"
  ssh -i "~/.ssh/moby.pub" -t "${SSH_USER}@${SERVER_IP}" bash -c "'
sudo chmod 440 /tmp/sudoers
sudo chown root:root /tmp/sudoers
sudo mv /tmp/sudoers /etc
ls
  '"
  echo "done!"
}

function add_ssh_key() {
  echo "Adding SSH key..."
  cat "$HOME/.ssh/moby.pub" | ssh  -i "~/.ssh/moby.pub" -t "${SSH_USER}@${SERVER_IP}" bash -c "'
mkdir /home/${KEY_USER}/.ssh
cat >> /home/${KEY_USER}/.ssh/authorized_keys
    '"
  ssh -i "~/.ssh/moby.pub" -t "${SSH_USER}@${SERVER_IP}" bash -c "'
chmod 700 /home/${KEY_USER}/.ssh
chmod 640 /home/${KEY_USER}/.ssh/authorized_keys
sudo chown ${KEY_USER}:${KEY_USER} -R /home/${KEY_USER}/.ssh
  '"
  echo "done!"
}

function configure_secure_ssh () {
  echo "Configuring secure SSH..."
  scp -i "~/.ssh/moby.pub" "ssh/sshd_config" "${SSH_USER}@${SERVER_IP}:/tmp/sshd_config"
  ssh -i "~/.ssh/moby.pub" -t "${SSH_USER}@${SERVER_IP}" bash -c "'
sudo chown root:root /tmp/sshd_config
sudo mv /tmp/sshd_config /etc/ssh
sudo systemctl restart ssh
  '"
  echo "done!"
}

function install_docker () {
  echo "Configuring Docker..."
  ssh -i "~/.ssh/moby.pub" -t "${SSH_USER}@${SERVER_IP}" bash -c "'
sudo apt-get update && sudo apt-get install -y curl
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
rm get-docker.sh
sudo usermod -aG docker "${KEY_USER}"
  '"
  echo "done!"
}

function provision_server () {
  configure_sudo
  echo "---"
  add_ssh_key
  echo "---"
  configure_secure_ssh
  echo "---"
  install_docker
}

function help_menu () {
cat << EOF
Usage: ${0} (-h | -S | -u | -k | -s | -d | -a)

ENVIRONMENT VARIABLES:
   SERVER_IP        IP address to work on, ie. staging or production
                    Defaulting to ${SERVER_IP}

   SSH_USER         User account to ssh and scp in as
                    Defaulting to ${SSH_USER}

   KEY_USER         User account linked to the SSH key
                    Defaulting to ${KEY_USER}

OPTIONS:
   -h|--help                 Show this message
   -S|--preseed-staging      Preseed intructions for the staging server
   -u|--sudo                 Configure passwordless sudo
   -k|--ssh-key              Add SSH key
   -s|--ssh                  Configure secure SSH
   -d|--docker               Install Docker
   -a|--all                  Provision everything except preseeding

EXAMPLES:
   Configure passwordless sudo:
        $ deploy -u

   Add SSH key:
        $ deploy -k

   Configure secure SSH:
        $ deploy -s

   Install Docker:
        $ deploy -d

   Configure everything together:
        $ deploy -a
EOF
}


while [[ $# > 0 ]]
do
case "${1}" in
  -S|--preseed-staging)
  preseed_staging
  shift
  ;;
  -u|--sudo)
  configure_sudo
  shift
  ;;
  -k|--ssh-key)
  add_ssh_key
  shift
  ;;
  -s|--ssh)
  configure_secure_ssh
  shift
  ;;
  -d|--docker)
  install_docker
  shift
  ;;
  -a|--all)
  provision_server
  shift
  ;;
  -h|--help)
  help_menu
  shift
  ;;
  *)
  echo "${1} is not a valid flag, try running: ${0} --help"
  ;;
esac
shift
done
