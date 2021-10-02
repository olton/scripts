# Mina Monitor Cluster Install

The script is designed to quickly install Mina Monitor Cluster

### Using
```shell
curl -s https://raw.githubusercontent.com/olton/scripts/master/mina/monitor/cluster/install.sh | bash
```

### Options

By default, the script takes files from branch `master` and saves these into folder `~/mina-monitor-client`.
You can set a branch or tag where the script will take files and where these files will be saved.
To  set branch use first argument for script and for target folder second.

```shell
curl -s https://raw.githubusercontent.com/olton/scripts/master/mina/monitor/cluster/install.sh | bash -s -- websocket mina-monitor-cluster
```

> If you need to set a target folder, you must define a branch.
