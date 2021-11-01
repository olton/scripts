# Mina Monitor Server Install

The script is designed to quickly install Mina Monitor Server

### Using
```shell
curl -s https://raw.githubusercontent.com/olton/scripts/master/mina/monitor/server/install.sh | bash
```

### Options

By default, the script takes files from branch `master` and saves these into folder `~/mina-monitor-server`.
You can set a branch or tag where the script will take files and where these files will be saved.
To  set branch use parameter `-b branchName`, to set target - use parameter `-t targetFolderName`

```shell
curl -s https://raw.githubusercontent.com/olton/scripts/master/mina/monitor/server/install.sh | bash -s -- -b branchName -t targetFolderName
```

> If you need to set a target folder, you must define a branch.
