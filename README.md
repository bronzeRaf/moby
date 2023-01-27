# moby
Moby is a Docker-based CI tool to automate deployment into a staging server.

## STAGING SERVER (DIRECT VIRTUAL MACHINE) DIRECTIONS:

- Configure a static IP address directly on the VM

```
$ su
$ nano /etc/network/interfaces
```

[change the last line to look like this, remember to set the correct gateway for your router's IP address if it's not 192.168.1.1]

```
iface eth0 inet static
  address ${SERVER_IP}
  netmask 255.255.255.0
  gateway 192.168.1.1
```

- Reboot the VM and ensure the Debian CD is mounted

- Install sudo

```
$ apt-get update && apt-get install -y -q sudo
```

- Add the user to the sudo group

```
$ su -l 
$ adduser ${SSH_USER} sudo
$ logout
```

- Run the commands in: ${0} --help

For Example:

```
$ ./deploy.sh -a
```


## Option and Usage
Usage: ${0} (-h | -S | -u | -k | -s | -d | -a)

ENVIRONMENT VARIABLES:
   SERVER_IP        IP address to work on, ie. staging or production
                    Defaulting to ${SERVER_IP}

   SSH_USER         User account to ssh and scp in as
                    Defaulting to ${SSH_USER}

   KEY_USER         User account linked to the SSH key
                    Defaulting to ${KEY_USER}

OPTIONS:
```
   -h|--help                 Show this message
   -S|--preseed-staging      Preseed intructions for the staging server
   -u|--sudo                 Configure passwordless sudo
   -k|--ssh-key              Add SSH key
   -s|--ssh                  Configure secure SSH
   -d|--docker               Install Docker
   -l|--docker-pull          Pull necessary Docker images
   -a|--all                  Provision everything except preseeding
```

EXAMPLES:
```
# Configure passwordless sudo:
$ deploy -u

# Add SSH key:
$ deploy -k

# Configure secure SSH:
$ deploy -s

# Install Docker:
$ deploy -d

# Install custom Docker version:
$ deploy -d 1.8.1

# Pull necessary Docker images:
$ deploy -l

# Configure everything together:
$ deploy -a

# Configure everything together with a custom Docker version:
$ deploy -a 1.8.1
```
