> Now in develop...

# Install the Mina node

The script is designed to quickly install the Mina node on **Ubuntu 18.x, 20.x, ...**. 

#### This script will do:

- [x] Install UFW (Uncomplicated Firewall) and setup it
- [x] Create user for Mina (you can specify name and password)
- [x] Install Mina (you can specify version and network)
- [x] Install Mina Archive Node 
- [x] Install Mina Key Generator
- [x] Install Mina Sidecar
- [x] Install NodeJS specified version
- [x] Install Mina Monitor
- [x] Setup Mina environment (create `.mina-env` file with content, set key password, if it specified)
- [x] Create required folders and files (excluding Mina wallet keys)
- [x] Setup Mina Service (on behalf of the created user)

> Now in develop...

### Usage:

#### Get script
```shell
wget https://raw.githubusercontent.com/olton/scripts/install-mina/mina/node/install.sh -v -N -O install-mina.sh
chmod 755 ./install-mina.sh
./install-mina.sh --help
```

#### Man script
```
install.sh [OPTIONS]...

This script is intended to simple install a Mina node.

Available options:

-h, --help             Print this help and exit
--no-color             Disable color output
--ufw                  Install UFW (Uncomplicated Firewall). Use this flag to enable this action.
--monitor              Install Mina Monitor, use this flag to enable action
--archive              Install Mina Archive Node, use this flag to enable action
--sidecar              Install Mina Sidecar, use this flag to enable action
--node                 Install NodeJS. Default - 16. Example: --node 17.
--net                  Use mainnet or devnet values to set net type, default mainnet. Example: --net devnet.
--mina, --mina-version Set Mina version to be installed. Example: --mina-version 1.2.0-fe51f1e
--key-folder, --key    Set directory for the Mina keys. Default value is "keys". Example: --key-folder mina_keys
--key-pass             Set password for Mina Private key
--user                 Define a user name for Mina owner, default "umina"
--user-pass            Define a Mina user password
--ssh-port             Define a ssh port, default 22
--monitor-port         Define a ssh port, default 8000
--monitor-folder       Define a folder, where Mina Monitor will be installed, default mina-monitor-server.
--monitor-branch       Define a branch, where where from Mina Monitor will be installed, default master.
--sidecar-version      Define a sidecar version, if not define, script will use Mina version
--archive-version      Define a Mina Archive Node version, if not define, script will use Mina version
```

Example, run from `root`:
```shell
./install.sh --help
```

Example, run from sudoers user:
```shell
sudo ./install.sh --help
```

Example, run from sudoers user:
```shell
sudo ./install.sh 1.2.2-feee67c
```

Example, run with arguments:
```shell
sudo ./install.sh \ 
  --mina 1.2.2-feee67c \
  --net mainnet \ 
  --user umina \ 
  --user-pass 123 \
  --key-folder keys \ 
  --key-pass 777 \ 
  --ufw \ 
  --monitor \ 
  --archive \
  --sidecar 
```