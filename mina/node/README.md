# Install the Mina node

The script is designed to quickly install the Mina node on Ubuntu 18.x, 20.x, ...
This script will install:
- [x] UFW
- [x] NodeJS
- [x] Mina Monitor
- [x] Mina
- [x] Mina environment
- [x] Required folders and files
- [x] Mina Service

> Now in develop...

```shell
wget https://raw.githubusercontent.com/olton/scripts/install-mina/mina/node/install.sh -v -N -O install-mina.sh
chmod 755 ./install-mina.sh
./install-mina.sh --help
```

### Usage:
```shell
install.sh [OPTIONS]...

This script is intended to simple install a Mina node.

Available options:

-h, --help             Print this help and exit
--no-color             Disable color output
--ufw                  Install UFW (Uncomplicated Firewall), default false. Use this flag to enable this action.
--monitor              Install Mina Monitor, use this flag to enable action
--archive              Install Mina Archive Node, use this flag to enable action
--node                 Install NodeJS. Example: --node 16.
--net                  Use mainnet or devnet values to set net type, default mainnet. Example: --net devnet.
--mina-version         Set Mina version to be installed, default 1.2.0-fe51f1e. Example: --mina-version 1.2.0-fe51f1e
--key-folder, --key    Set directory for the Mina keys. Default value is "keys". Example: --key-folder mina_keys
--key-pass             Set password for Mina Private key
--user                 Define a user name for Mina owner, default "umina"
--user-pass            Define a Mina user password
--ssh-port             Define a ssh port, default 22
--monitor-port         Define a ssh port, default 8000
--monitor-folder       Define a folder, where Mina Monitor will be installed, default mina-monitor-server. Example --monitor-folder mina-monitor

For example:
install.sh --help

For example:
install.sh --node 16 --user umina --user-pass 123 --key-pass 777 --ufw --monitor --archive
```