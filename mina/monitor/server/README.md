# Mina Monitor Server Install

The script is designed to quickly install Mina Monitor Server

### Using
```shell
curl -s https://raw.githubusercontent.com/olton/scripts/master/mina/monitor/server/install.sh | bash
```

### Options

By default, the script takes files from branch `master` and saves these into folder `~/mina-monitor-server`.
You can set a branch or tag where the script will take files and where these files will be saved.
To  set branch use first argument for script and for target folder second.

```shell
curl -s https://raw.githubusercontent.com/olton/scripts/master/mina/monitor/server/install.sh | bash -s -- websocket mina-monitor
```

> If you need to set a target folder, you must define a branch.
