#!/bin/bash

clear

YELLOW="\033[33m"
GREEN="\033[32m"
RED="\033[31m"

echo -e "$GREEN Welcome to Mina Monitor Server installer!\033[0m"
echo -e "$GREEN Copyright 2021 by Serhii Pimenov <serhii@pimenov.com.ua>\033[0m"
read -p " If you are ready, press [Enter] key to start or Ctrl+C to stop..."

echo -ne "$YELLOW Check NodeJS:\033[0m"

if ! which node > /dev/null; then
  echo -e "$RED Error! NodeJS not installed! Please install NodeJS v14+ and try again.\033[0m"
  exit
fi

IFS="."
read -a NODE_VERSION <<< $(node -v | sed -nre 's/^[^0-9]*(([0-9]+\.)*[0-9]+).*/\1/p')

if ! [ $NODE_VERSION[0] > 13 ]; then
  echo -e "$RED Error! NodeJS version is not a valid! You must use version NodeJS >= 14.\033[0m"
  exit
fi

echo -e "$GREEN...OK... \033[0m"

TARGET="mina-monitor-server"
BRANCH="master"
SERVICE_TARGET_SYSTEM="/etc/systemd/system/"
SERVICE_TARGET_USER="/usr/lib/systemd/user"
SERVICE_TARGET="no"
SERVICE_FILE="minamon.service"

while getopts ":t:b:s:" opt
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

echo ""
echo -e "$YELLOW Installing dependencies...\033[0m"
if npm install --silent; then
  echo -e "$GREEN Dependencies installed successfully!\033[0m"
fi

echo ""
echo -e "$YELLOW Creating config file...\033[0m"
if node index --init &>/dev/null; then
  echo -e "$GREEN Config file created successfully!\033[0m"
fi

sed -i "s#/home/user/#$HOME/#g" "$SERVICE_FILE"
sed -i "s#mina-monitor#$TARGET#g" "$SERVICE_FILE"

if [ "$SERVICE_TARGET" != "no" ]; then
  echo ""
  echo -e "$YELLOW Install Monitor as service with a file $SERVICE_FILE...\033[0m"
  SERVICE_TARGET_FOLDER=$([ "$SERVICE_TARGET" == "system" ] && echo "$SERVICE_TARGET_SYSTEM" || echo "$SERVICE_TARGET_USER")
  echo -e "$YELLOW Now, we are copying service file $SERVICE_FILE to the $SERVICE_TARGET_FOLDER. This operation required sudo. \033[0m"
  read -p " Press [Enter] key to continue or Ctrl+C to stop..."

  if sudo cp "$HOME/$TARGET/$SERVICE_FILE" "$SERVICE_TARGET_FOLDER"; then
    echo -e "$GREEN Mina Monitor Server Service successfully installed.\033[0m"
  fi
fi

echo ""
echo -e "$YELLOW Deleting temporary files...\033[0m"
rm _.tar.gz

echo ""
echo -e "$GREEN Mina Monitor Server successfully installed. Enjoy!\033[0m"
echo ""

