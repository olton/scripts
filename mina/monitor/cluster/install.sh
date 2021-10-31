#!/bin/bash

YELLOW="\033[33m"
GREEN="\033[32m"

echo -e "$GREEN Welcome to Mina Monitor Cluster installer!\033[0m"
echo -e "$GREEN Copyright 2021 by Serhii Pimenov <serhii@pimenov.com.ua>\033[0m"

TARGET="mina-monitor-cluster"
BRANCH="master"

while getopts ":t:b:" opt
do
  case $opt in
    t) TARGET=$OPTARG;;
    b) BRANCH=$OPTARG;;
  esac
done

echo -e "$GREEN We are installing Mina Monitor Client from branch $BRANCH into ~/$TARGET \033[0m"
echo -e "$YELLOW Installing Mina Monitor Cluster...\033[0m"
echo -e "$YELLOW Creating a target directory...\033[0m"

cd ~
mkdir -p ${TARGET}
cd ${TARGET}

echo -e "$YELLOW Downloading a required tarball...\033[0m"

curl -L https://github.com/olton/mina-monitor-cluster/tarball/${BRANCH} >> _.tar.gz

echo -e "$YELLOW Extracting files...\033[0m"

url=$(tar -tf _.tar.gz | head -n 1)
tar --strip-components=2 -xf _.tar.gz ${url}src
tar --strip-components=1 -xf _.tar.gz ${url}package.json ${url}README.md ${url}CHANGELOG.md ${url}babel.config.json

echo -e "$YELLOW Deleting temporary files...\033[0m"

rm _.tar.gz

echo -e "$YELLOW Preparing package.json file...\033[0m"
sed -i 's/src\///g' 'package.json'

echo -e "$YELLOW Installing dependencies...\033[0m"

npm install --silent

echo -e "$YELLOW Creating config file...\033[0m"
mv config.example.json config.json
#node start --no-start

echo ""
echo -e "$GREEN Mina Monitor Client successfully installed...\033[0m"
echo "Before start, you must define a nodes in the config.json."
echo "When you complete a node setups, you can launch client with a command npm start"
echo ""
