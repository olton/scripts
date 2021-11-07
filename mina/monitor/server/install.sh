#!/bin/bash

YELLOW="\033[33m"
GREEN="\033[32m"

echo -e "$GREEN Welcome to Mina Monitor Server installer!\033[0m"
echo -e "$GREEN Copyright 2021 by Serhii Pimenov <serhii@pimenov.com.ua>\033[0m"

TARGET="mina-monitor-server"
BRANCH="master"
SERVICE_TARGET_SYSTEM = "/etc/systemd/system/"
SERVICE_TARGET_USER = "/usr/lib/systemd/user"
SERVICE_TARGET = "user"

while getopts ":t:b:" opt
do
  case $opt in
    t) TARGET=$OPTARG;;
    b) BRANCH=$OPTARG;;
    s) SERVICE_TARGET=$OPTARG;;
  esac
done

echo -e "$GREEN We are installing Mina Monitor Server from branch $BRANCH into ~/$TARGET \033[0m"
echo -e "$YELLOW Installing Mina Monitor Server...\033[0m"

echo -e "$YELLOW Creating a target directory...\033[0m"

cd ~
mkdir -p ${TARGET}
cd ${TARGET}

echo -e "$YELLOW Downloading a required tarball...\033[0m"

curl -L https://github.com/olton/mina-node-monitor/tarball/${BRANCH} >> _.tar.gz

echo -e "$YELLOW Extracting files...\033[0m"

url=$(tar -tf _.tar.gz | head -n 1)
tar --strip-components=2 -xf _.tar.gz ${url}server

echo -e "$YELLOW Deleting temporary files...\033[0m"

rm _.tar.gz

echo -e "$YELLOW Installing dependencies...\033[0m"
npm install

echo -e "$YELLOW Creating config file...\033[0m"
node index --init

echo -e "$YELLOW Install Monitor as service...\033[0m"
sed -i "s/\/home\/user\//\/${HOME}\//g" 'minamon.service'
sed -i "s/mina-monitor/${TARGET}/g" 'minamon.service'

if ["$SERVICE_TARGET" == 'user']; then
  cp "minamon.serivce" "$SERVICE_TARGET_USER"
else
  cp "minamon.serivce" "$SERVICE_TARGET_SYSTEM"
fi

echo -e "$GREEN Mina Monitor Server Service successfully installed.\033[0m"

echo ""
echo -e "$GREEN Mina Monitor Server successfully installed.\033[0m"
echo ""

