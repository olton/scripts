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

echo -e "$GREEN Welcome to Mina Monitor Client installer!${COLOR_STOP}"
echo -e "$GREEN Copyright 2021 by Serhii Pimenov <serhii@pimenov.com.ua>${COLOR_STOP}"
read -p " If you are ready, press [Enter] key to start or Ctrl+C to stop..."

check_node

TARGET="mina-monitor-client"
BRANCH="master"

while getopts ":t:b:" opt
do
  case $opt in
    t) TARGET=$OPTARG;;
    b) BRANCH=$OPTARG;;
  esac
done

echo -e "$GREEN We are installing Mina Monitor Client from branch $BRANCH into ~/$TARGET ${COLOR_STOP}"
echo -e "$YELLOW Installing Mina Monitor Client...${COLOR_STOP}"
echo -e "$YELLOW Creating a target directory...${COLOR_STOP}"

#cd ~
mkdir -p ${TARGET}
cd ${TARGET}

echo -e "$YELLOW Downloading a required tarball...${COLOR_STOP}"

curl -L https://github.com/olton/mina-node-monitor/tarball/${BRANCH} >> _.tar.gz

echo -e "$YELLOW Extracting files...${COLOR_STOP}"

url=$(tar -tf _.tar.gz | head -n 1)
tar --strip-components=2 -xf _.tar.gz ${url}client

echo -e "$YELLOW Deleting temporary files...${COLOR_STOP}"

rm _.tar.gz

echo -e "$YELLOW Installing dependencies...${COLOR_STOP}"

npm install --silent

CONFIG_FILE=config.json
if ! [ -f "$CONFIG_FILE" ]; then
  echo -e "$YELLOW Creating config file...${COLOR_STOP}"
  mv config.example.json config.json
  # node start --no-start // TODO
fi

echo ""
echo -e "$GREEN Mina Monitor Client successfully installed...${COLOR_STOP}"
echo -e "Before start, you must define a node in the ${YELLOW}config.json${COLOR_STOP}."
echo -e "When you complete a config setup, you can launch client with a command ${YELLOW}npm start ${COLOR_STOP}"
echo ""

