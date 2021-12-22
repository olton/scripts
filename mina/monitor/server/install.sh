#!/bin/bash

YELLOW="\033[33m"
GREEN="\033[32m"
RED="\033[31m"
COLOR_STOP="\033[0m"

check_node() {
	echo -ne "$YELLOW Check NodeJS:\033[0m"

  if ! which node > /dev/null; then
    echo -e "$RED Error! NodeJS not installed! Please install NodeJS v14+ and try again.${COLOR_STOP}"
    exit
  fi

  node_ver="$(node -v)"
  echo -ne " You have version installed ${YELLOW}${node_ver}${COLOR_STOP}"

  if [[ $OSTYPE == 'darwin'* ]]; then
  	return
  fi

  IFS="."
  read -r -a NODE_VERSION <<< $(echo "$node_ver" | sed -nre 's/^[^0-9]*(([0-9]+\.)*[0-9]+).*/\1/p')

  if (( "${NODE_VERSION[0]}" < 14 )); then
    echo -e "\n$RED Error! NodeJS version is not a valid! To use Mina Monitor, You must install version NodeJS >= 14.${COLOR_STOP}"
    exit
  fi

  echo -e "$GREEN it's OK${COLOR_STOP}"
}

echo -e "$GREEN Welcome to Mina Monitor Server installer!${COLOR_STOP}"
echo -e "$GREEN Copyright 2021 by Serhii Pimenov <serhii@pimenov.com.ua>${COLOR_STOP}"
read -p " If you are ready, press [Enter] key to start or Ctrl+C to stop..."

check_node

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

echo -e "$YELLOW We are installing Mina Monitor Server from branch ${GREEN}${BRANCH}${COLOR_STOP} into ${GREEN}${TARGET}${COLOR_STOP}"
echo -e "$YELLOW Installing Mina Monitor Server...${COLOR_STOP}"

echo -e "$YELLOW Creating a target directory...${COLOR_STOP}"

#cd ~
mkdir -p ${TARGET}
cd ${TARGET}

echo -e "$YELLOW Downloading a required tarball...${COLOR_STOP}"

curl -L https://github.com/olton/mina-node-monitor/tarball/${BRANCH} >> _.tar.gz

echo -e "$YELLOW Extracting files...${COLOR_STOP}"

url=$(tar -tf _.tar.gz | head -n 1)
tar --strip-components=2 -xf _.tar.gz ${url}server

echo ""
echo -e "$YELLOW Installing dependencies...${COLOR_STOP}"
if npm install --silent; then
  echo -e "$GREEN Dependencies installed successfully!${COLOR_STOP}"
fi

CONFIG_FILE=config.json
if ! [ -f "$CONFIG_FILE" ]; then
  echo -e "$YELLOW Creating config file...${COLOR_STOP}"
  if node index --init &>/dev/null; then
    echo -e "$GREEN Config file created successfully!${COLOR_STOP}"
  fi
fi

sed -i "s#/home/user/#$HOME/#g" "$SERVICE_FILE"
sed -i "s#mina-monitor#$TARGET#g" "$SERVICE_FILE"

if [ "$SERVICE_TARGET" != "no" ]; then
  echo ""
  echo -e "$YELLOW Install Monitor as service with a file $SERVICE_FILE...${COLOR_STOP}"
  SERVICE_TARGET_FOLDER=$([ "$SERVICE_TARGET" == "system" ] && echo "$SERVICE_TARGET_SYSTEM" || echo "$SERVICE_TARGET_USER")
  echo -e "$YELLOW Now, we are copying service file $SERVICE_FILE to the $SERVICE_TARGET_FOLDER. This operation required sudo. ${COLOR_STOP}"
  read -p " Press [Enter] key to continue or Ctrl+C to stop..."

  if sudo cp "$HOME/$TARGET/$SERVICE_FILE" "$SERVICE_TARGET_FOLDER"; then
    echo -e "$GREEN Mina Monitor Server Service successfully installed.${COLOR_STOP}"
  fi
fi

echo ""
echo -e "$YELLOW Deleting temporary files...${COLOR_STOP}"
rm _.tar.gz

echo ""
echo -e "$GREEN Mina Monitor Server successfully installed. Enjoy!${COLOR_STOP}"
echo -e "Before start, you must define parameters in the ${YELLOW}config.json${COLOR_STOP} (if you need)."
echo -e "When you complete a config setup, you can launch server with a command ${YELLOW}npm start ${COLOR_STOP}"
echo ""

