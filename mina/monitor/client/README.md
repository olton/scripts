# Mina Monitor Client Install

The script is designed to quickly install Mina Monitor Client

### Using

#### Windows

>You must launch script in a PowerShell

```shell
& $([scriptblock]::Create((New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/olton/scripts/master/mina/monitor/client/install.ps1')))
```

#### Options

By default, the script takes files from branch `master` and saves these into folder `mina-monitor-client`.
You can set a branch or tag where the script will take files and where these files will be saved.

```shell
& $([scriptblock]::Create((New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/olton/scripts/master/mina/monitor/client/install.ps1'))) -target targetFolderName -branch branchName
```

#### Linux
```shell
curl -s https://raw.githubusercontent.com/olton/scripts/master/mina/monitor/client/install.sh | bash
```

#### Options

By default, the script takes files from branch `master` and saves these into folder `~/mina-monitor-client`.
You can set a branch or tag where the script will take files and where these files will be saved.
To  set branch use first argument for script and for target folder second.

```shell
curl -s https://raw.githubusercontent.com/olton/scripts/master/mina/monitor/client/install.sh | bash -s -- branchName targetFolderName
```

> If you need to set a target folder, you must define a branch.
