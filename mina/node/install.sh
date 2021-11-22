#!/usr/bin/env bash

set -Eeuo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT

# SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
# SCRIPT_NAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_NAME="install.sh"

# Default values
INSTALL_UFW=false
NODE_VERSION=0
MINA_USER=umina
MINA_USER_PASS=""
MINA_VERSION=1.2.0-fe51f1e
MINA_KEY=keys
MINA_KEY_PASS=""
NET_TARGET=mainnet
SSH_PORT=22

usage() {
	cat <<- EOF
		Usage: $SCRIPT_NAME [OPTIONS]...

		This script is intended to simple install a Mina node.

		Available options:

		-h, --help      Print this help and exit
		--no-color      Disable color output
		--ufw           Install UFW (Uncomplicated Firewall), default true.
										Use false to disable this action.
		--node          Install NodeJS
		--net           Use mainnet or devnet values to set net type, default mainnet
		--key           Directory for the Mina keys
		--key-pass      Password for Mina Private key
		--user          Define a user name for Mina owner, default umina
		--user-pass     Define a Mina user password
		--ssh-port      Define a ssh port, default 22

	EOF
  exit
}

cleanup() {
  trap - SIGINT SIGTERM ERR EXIT
  # script cleanup here
}

setup_colors() {
  if [[ -t 2 ]] && [[ -z "${NO_COLOR-}" ]] && [[ "${TERM-}" != "dumb" ]]; then
    NOFORMAT='\033[0m' RED='\033[0;31m' GREEN='\033[0;32m' ORANGE='\033[0;33m' BLUE='\033[0;34m' PURPLE='\033[0;35m' CYAN='\033[0;36m' YELLOW='\033[1;33m'
  else
    NOFORMAT='' RED='' GREEN='' ORANGE='' BLUE='' PURPLE='' CYAN='' YELLOW=''
  fi
}

msg() {
  echo >&2 -e "${1-}"
}

die() {
  local msg=$1
  local code=${2-1} # default exit status 1
  msg "$msg"
  exit "$code"
}

parse_params() {
  while :; do
    case "${1-}" in
    -h | --help) usage ;;
    --no-color) NO_COLOR=1 ;;
    --ufw) INSTALL_UFW=true ;;
    --node)
      NODE_VERSION="${2-}"
      shift
      ;;
    --user)
      MINA_USER="${2-}"
      shift
      ;;
    --user-pass)
      MINA_USER_PASS="${2-}"
      shift
      ;;
    --net)
      NET_TARGET="${2-}"
      shift
      ;;
    --key)
      MINA_KEY="${2-}"
      shift
      ;;
    --key_pass)
      MINA_KEYS_PASS="${2-}"
      shift
      ;;
    --ssh-port)
      MINA_KEYS_PASS="${2-}"
      shift
      ;;
#    -f | --flag) flag=1 ;; # example flag
#    -p | --param) # example named parameter
#      param="${2-}"
#      shift
#      ;;
    -?*) die "Unknown option: $1" ;;
    *) break ;;
    esac
    shift
  done

  args=("$@")

  # check required params and arguments
#  [[ -z "${param-}" ]] && die "Missing required parameter: param"
#  [[ ${#args[@]} -eq 0 ]] && die "Missing script arguments"

  return 0
}

welcome() {
  msg "$GREEN Welcome to Mina Installer!$NOFORMAT"
  msg "$GREEN Copyright 2021 by Serhii Pimenov <serhii@pimenov.com.ua>$NOFORMAT"
  read -p " If you are ready, press [Enter] key to start or Ctrl+C to stop..."
}

install_pre_requirements() {
  msg "$CYAN Preparing OS...$NOFORMAT"
  sudo apt-get -y update -qq
  sudo apt-get -y upgrade -qq
  sudo apt --fix-broken install
  sudo apt-get install -y apt-transport-https ca-certificates gnupg
  sudo apt-get install -y curl htop mc net-tools unzip

  IFS="."
  read -a OS_VERSION <<< $(lbs_release -d | sed -nre 's/^[^0-9]*(([0-9]+\.)*[0-9]+).*/\1/p')
  if [ $OS_VERSION[0] -gt 18 ]; then
	  msg "$CYAN Installing required libs...$NOFORMAT"
    cd
    mkdir -p mina_required_libs
    cd mina_required_libs
    wget http://mirrors.kernel.org/ubuntu/pool/main/libf/libffi/libffi6_3.2.1-8_amd64.deb
    wget http://mirrors.edge.kernel.org/ubuntu/pool/universe/j/jemalloc/libjemalloc1_3.6.0-11_amd64.deb
    wget http://mirrors.edge.kernel.org/ubuntu/pool/main/p/procps/libprocps6_3.3.12-3ubuntu1_amd64.deb
    sudo dpkg -i *.deb
    cd
    rm -rf mina_required_libs
  fi
}

install_nodejs() {
  msg "$CYAN Installing NodeJS...$NOFORMAT"
  if [[ "$NODE_VERSION" -ne "0" ]]; then
    if ! which node > /dev/null; then
        #install node & npm - see https://github.com/nodesource/distributions#deb
        curl -fsSL https://deb.nodesource.com/gpgkey/nodesource.gpg.key | sudo apt-key add -
        VERSION=("node_${NODE_VERSION}.x")
        DISTRO="$(lsb_release -s -c)"
        echo "deb https://deb.nodesource.com/$VERSION $DISTRO main" | sudo tee /etc/apt/sources.list.d/nodesource.list
        echo "deb-src https://deb.nodesource.com/$VERSION $DISTRO main" | sudo tee -a /etc/apt/sources.list.d/nodesource.list
        sudo apt-get update
        sudo apt-get install -y nodejs
    fi
  fi
}

install_ufw() {
  msg "$CYAN Installing UFW...$NOFORMAT"
  if $INSTALL_UFW; then
    if ! which node > /dev/null; then
      sudo apt-get -y install ufw
      sudo ufw default deny incoming
      sudo ufw default allow outgoing
      sudo ufw allow $SSH_PORT
      sudo ufw allow 8302/tcp
      sudo ufw allow 8303/tcp
      sudo ufw allow 8000/tcp
      sudo ufw disable
      sudo ufw enable
      sudo ufw status
    fi
  fi
}

create_user() {
  msg "$CYAN Create user for Mina...$NOFORMAT"
  if ! id $MINA_USER &>/dev/null; then
    msg "$CYAN Adding user...$NOFORMAT"
    adduser --disabled-password --gecos "" $MINA_USER
    usermod -aG sudo $MINA_USER
#    usermod -aG system-journal $MINA_USER

    if [ -Z "$MINA_USER_PASS" ]; then
      msg "$CYAN Set user password...$NOFORMAT"
      echo $MINA_USER_PASS | passwd $MINA_USER --stdin
    fi
  fi

  mkdir -p /home/${MINA_USER}/.ssh
  chown ${MINA_USER}:${MINA_USER} /home/${MINA_USER}/.ssh
  cp /root/.ssh/authorized_keys /home/${MINA_USER}/.ssh/authorized_keys
  chown ${MINA_USER}:${MINA_USER} /home/${MINA_USER}/.ssh/authorized_keys
  chmod 600 /home/${MINA_USER}/.ssh/authorized_keys

  sudo systemctl restart sshd

  msg "$CYAN User was created successful.$NOFORMAT"
}

install_mina() {
  msg "$CYAN Installing Mina...$NOFORMAT"

  echo "deb [trusted=yes] http://packages.o1test.net stretch stable" | sudo tee /etc/apt/sources.list.d/mina.list
  sudo apt-get update
  sudo apt-get install -y mina-$NET_TARGET=$MINA_VERSION

  installed_mina_version=($("mina version"))

  msg "$GREEN We installed Mina version ${installed_mina_version[1]}.$NOFORMAT"

  su - -c "systemctl --user daemon-reload" $MINA_USER
  su - -c "systemctl --user enable mina" $MINA_USER

  sudo loginctl enable-linger $MINA_USER

  msg "$CYAN Mina was installed successful.$NOFORMAT"
}

install_mina_env(){
  msg "$CYAN Create Mina environment...$NOFORMAT"

  mkdir -p /home/${MINA_USER}/$MINA_KEY
  chown ${MINA_USER}:${MINA_USER} /home/${MINA_USER}/${MINA_KEY}
  chmod 700 /home/${MINA_USER}/${MINA_KEY}
  touch /home/${MINA_USER}/.mina-env
  chown ${MINA_USER}:${MINA_USER} /home/${MINA_USER}/.mina-env

  mina_env_file="/home/${MINA_USER}/.mina-env"

  cat <<- EOF > $mina_env_file
		UPTIME_PRIVKEY_PASS="your_password"
		CODA_PRIVKEY_PASS="your_password"
		LOG_LEVEL=Info
		FILE_LOG_LEVEL=Debug
		EXTRA_FLAGS=" --block-producer-key /home/${MINA_USER}/${MINA_KEY}/my-wallet --uptime-submitter-key /home/${MINA_USER}/${MINA_KEY}/my-wallet --uptime-url http://34.134.227.208/v1/submit --limited-graphql-port 3095 "
	EOF

	if $MINA_KEY_PASS; then
	    sed -i 's/your_password/${MINA_KEYS_PASS}/g' $mina_env_file
	fi

  msg "$GREEN The Mina environment created successful!$NOFORMAT"
  msg "$YELLOW Now, you must set the password in file .mina-env for your keys if you not defined it with command argument --key-pass.$NOFORMAT"
  msg "$YELLOW Then, run command below to start Mina Node and init others requirements and stop it with Ctrl+C after successful runs:$NOFORMAT"
  msg "$PURPLE mina daemon --peer-list-url https://storage.googleapis.com/mina-seed-lists/mainnet_seeds.txt $NOFORMAT"
  msg "$YELLOW After, you will stop standalone process, you can run service with a command below:$NOFORMAT"
  msg "$PURPLE systemctl --user start mina $NOFORMAT"
}

parse_params "$@"
setup_colors

welcome
install_pre_requirements
install_ufw
install_nodejs
create_user
install_mina
install_mina_env

cleanup
# End of script