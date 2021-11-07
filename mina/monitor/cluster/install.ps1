param($b, $t)

cls
Write-Host -ForegroundColor green "Welcome to Mina Monitor Cluster installer!"
Write-Host -ForegroundColor white "Copyright 2021 by Serhii Pimenov <serhii@pimenov.com.ua>"
Read-Host "If you are ready, press [Enter] key to start or Ctrl+C to stop..."
Write-Host

Write-Host -ForegroundColor yellow "Check NodeJS..." -NoNewLine

$node = (node -v | Select -First 1).replace("v", "")

if (!$node) {
    Write-Host -ForegroundColor red "Error!" -NoNewLine; Write-Host " NodeJS not installed! Please install NodeJS v14+ and try again."
    exit
}

$nodeVer = $node.Split(".")

if ($nodeVer[0] -lt 14) {
    Write-Host -ForegroundColor red "Error!" -NoNewLine; Write-Host " Wrong NodeJS version! Please install NodeJS v14+ and try again."
    exit
}

Write-Host -ForegroundColor green "OK"

$br =  $b
if (!$br) {
    $br = "master"
}

$trg = $t
if (!$trg) {
    $trg = "mina-monitor-cluster"
}

Write-Host "We are installing Mina Monitor Cluster from a " -NoNewLine
Write-Host -ForegroundColor yellow $br -NoNewLine
Write-Host " branch into a folder " -NoNewLine
Write-Host -ForegroundColor yellow $trg

if (-not(Test-Path -Path $trg)) {
    mkdir -p $trg
}
cd $trg

$sourcesUrl = "https://github.com/olton/mina-monitor-cluster/tarball/$br"

Write-Host "Downloading sources from $sourcesUrl..."
Invoke-WebRequest -URI $sourcesUrl -OutFile _.tar.gz

$url = tar -tf _.tar.gz | Select -First 1

Write-Host "Sources in $url"

tar --strip-components=2 -xf _.tar.gz "$url/src"
tar --strip-components=1 -xf _.tar.gz "$url/package.json" "$url/README.md" "$url/CHANGELOG.md" "$url/babel.config.json"

if (-not(Test-Path -Path config.json)) {
    Write-Host "Creating config file..." -NoNewLine
    Move-Item -Path config.example.json -Destination config.json
    Write-Host -ForegroundColor green "OK"
}

Write-Host "Update package.json..." -NoNewLine
((Get-Content -path package.json -Raw) -replace 'src/', '') | Set-Content -Path package.json
Write-Host -ForegroundColor green "OK"

Write-Host "Installing dependencies..."
npm install --silent

Write-Host "Deleting temporary files..." -NoNewLine
Remove-Item -Path _.tar.gz
Write-Host -ForegroundColor green "OK"

Write-Host
Write-Host "Mina Monitor Cluster successfully installed."
Write-Host "Before start, you must define a nodes in the config.json."
Write-Host "When you complete a node setups, you can launch client with a command " -NoNewLine; Write-Host -ForegroundColor yellow "npm start"
Write-Host