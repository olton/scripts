param($branch, $target)

cls
Write-Host -ForegroundColor green "Welcome to Mina Monitor Cluster installer!"
Write-Host -ForegroundColor white "Copyright 2021 by Serhii Pimenov <serhii@pimenov.com.ua>"
Write-Host

$br =  $branch
if (!$br) {
    $br = "master"
}

$trg = $target
if (!$trg) {
    $trg = "mina-monitor-cluster"
}

Write-Host "We are installing Mina Monitor Cluster from a " -NoNewLine
Write-Host -ForegroundColor yellow $br -NoNewLine
Write-Host " branch into a folder " -NoNewLine
Write-Host -ForegroundColor yellow $trg

mkdir -p $trg
cd $trg

$sourcesUrl = "https://github.com/olton/mina-monitor-cluster/tarball/$br"

Write-Host "Downloading sources from $sourcesUrl..."
Invoke-WebRequest -URI $sourcesUrl -OutFile _.tar.gz

$url = tar -tf _.tar.gz | head -n 1

Write-Host "Sources in $url"

tar --strip-components=2 -xf _.tar.gz "$url/src"
tar --strip-components=1 -xf _.tar.gz "$url/package.json" "$url/README.md" "$url/CHANGELOG.md" "$url/babel.config.json"
Move-Item -Path config.example.json -Destination config.json

Write-Host "Deleting temporary files..."

Remove-Item -Path _.tar.gz

Write-Host "Preparing files..."
((Get-Content -path package.json -Raw) -replace 'src/', '') | Set-Content -Path package.json

Write-Host "Installing dependencies..."
npm install --silent

Write-Host
Write-Host "Mina Monitor Client successfully installed."
Write-Host "Before start, you must define a nodes in the config.json."
Write-Host "When you complete a node setups, you can launch client with a command " -NoNewLine; Write-Host -ForegroundColor yellow "npm start"
Write-Host