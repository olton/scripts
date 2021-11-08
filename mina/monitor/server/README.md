# Mina Monitor Server Install

The script is designed to quickly install Mina Monitor Server

## Using

### Linux

>You must have Bash

```shell
curl -s https://raw.githubusercontent.com/olton/scripts/master/mina/monitor/server/install.sh | bash
```

### Options

By default, the script takes files from branch `master` and saves these into folder `mina-monitor-server`.
You can set a branch or tag where the script will take files and where these files will be saved.
To  set branch use parameters:
- `-b branchName` - get source from specified branch
- `-t targetFolderName` - set target folder name for Mina Monitor 
- `-s system || user` - if you want to install Monitor as service, use this parameter with values `system` or `user` to specify target services folder 

```shell
curl -s https://raw.githubusercontent.com/olton/scripts/master/mina/monitor/server/install.sh | bash -s -- -b branchName -t targetFolderName
```
