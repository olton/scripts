#!/bin/bash

YELLOW="\033[33m"
GREEN="\033[32m"

echo -e "$GREEN Welcome to Mina Monitor Cluster installer!\033[0m"

if [ -n "$1" ]
then
VER=$1
else
VER="master"
fi

if [ -n "$2" ]
then
TARGET=$2
else
TARGET="mina-monitor-cluster"
fi

echo -e "$GREEN We are installing Mina Monitor Cluster ${VER} branch\033[0m"
echo -e "$GREEN into a ~/${TARGET} folder\033[0m"
echo "So, let's go..."

echo -e "$YELLOW Installing Mina Monitor Cluster...\033[0m"

echo -e "$YELLOW Creating a target directory...\033[0m"

cd ~
mkdir -p ${TARGET}
cd ${TARGET}

echo -e "$YELLOW Downloading a required tarball...\033[0m"

curl -L https://github.com/olton/mina-monitor-cluster/tarball/${VER} >> _.tar.gz

echo -e "$YELLOW Extracting files...\033[0m"

url=$(tar -tf _.tar.gz | head -n 1)
tar --strip-components=2 -xf _.tar.gz ${url}src
tar --strip-components=1 -xf _.tar.gz ${url}package.json ${url}README.md ${url}CHANGELOG.md ${url}babel.comfig.json
mv config.example.json config.json

echo -e "$YELLOW Deleting temporary files...\033[0m"

rm _.tar.gz

echo -e "$YELLOW Installing dependencies...\033[0m"

npm install

#echo -e "$YELLOW Creating config file...\033[0m"
#node start --no-start

echo ""
echo -e "$GREEN Mina Monitor Client successfully installed...\033[0m"
echo ""
