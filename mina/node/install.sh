#!/usr/bin/env bash

set -Eeuo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
SCRIPT_NAME=$(basename "${BASH_SOURCE[0]}")

# Default values
INSTALL_UFW=false
INSTALL_MONITOR=false
INSTALL_ARC=false
INSTALL_SIDECAR=false
NODE_VERSION=16
MINA_USER=umina
MINA_USER_PASS=""
MINA_VERSION=""
MINA_KEY_FOLDER=keys
MINA_KEY_PASS=""
NET_TARGET=mainnet
SSH_PORT=22
MONITOR_PORT=8000
MONITOR_FOLDER="mina-monitor-server"
MONITOR_BRANCH=master
SIDECAR_VERSION=""
MINA_ARCHIVE_VERSION=""

usage() {
	cat <<- EOF
		Usage: $SCRIPT_NAME [OPTIONS]...

		This script is intended to simple install a Mina node.

		Available options:

		-h, --help             Print this help and exit
		--no-color             Disable color output
		--ufw                  Install UFW (Uncomplicated Firewall), default false. Use this flag to enable this action.
		--monitor              Install Mina Monitor, use this flag to enable action
		--archive              Install Mina Archive Node, use this flag to enable action
		--sidecar              Install Mina Sidecar, use this flag to enable action
		--node                 Install NodeJS. Default will be installed 16.x LTS. Example: --node 16.
		--net                  Use "mainnet" or "devnet" values to set net type, default "mainnet".
		--mina, --mina-version Set Mina version to be installed. Example: --mina-version "1.2.2-feee67c"
		--key-folder, --key    Set directory for the Mina keys. Default value is "keys". Example: --key mina_keys
		--key-pass             Set password for Mina Private key
		--user                 Define a user name for Mina owner, default "umina"
		--user-pass            Define a Mina user password
		--ssh-port             Define a ssh port, which will be opened in UFW, default 22
		--monitor-port         Define a Mina Monitor port, which will be opened in UFW, default 8000
		--monitor-folder       Define a folder, where Mina Monitor will be installed, default mina-monitor-server
		--monitor-branch       Define a branch, where where from Mina Monitor will be installed, default master. Example --monitor-branch dev
		--sidecar-version			 Define a sidecar version, if not define, script will use Mina version
		--archive-version			 Define a Mina Archive Node version, if not define, script will use Mina version

		For example:
		${SCRIPT_NAME} --help

		For example:
		${SCRIPT_NAME} 1.2.2-feee67c

		For example:
		${SCRIPT_NAME} --node 16 --user umina --user-pass 123 --key-pass 777 --ufw --monitor --archive

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
    --monitor) INSTALL_MONITOR=true ;;
    --archive) INSTALL_ARC=true ;;
    --sidecar) INSTALL_SIDECAR=true ;;
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
    --mina | --mina-version)
      MINA_VERSION="${2-}"
      shift
      ;;
    --key | --key-folder)
      MINA_KEY_FOLDER="${2-}"
      shift
      ;;
    --key-pass)
      MINA_KEYS_PASS="${2-}"
      shift
      ;;
    --ssh-port)
      SSH_PORT="${2-}"
      shift
      ;;
    --monitor-port)
      MONITOR_PORT="${2-}"
      shift
      ;;
    --monitor-folder)
      MONITOR_FOLDER="${2-}"
      shift
      ;;
    --monitor-branch)
      MONITOR_BRANCH="${2-}"
      shift
      ;;
    --sidecar-version)
      SIDECAR_VERSION="${2-}"
      shift
      ;;
    --archive-version)
      MINA_ARCHIVE_VERSION="${2-}"
      shift
      ;;
    -?*) die "Unknown option: $1" ;;
    *) break ;;
    esac
    shift
  done

  args=("$@")

#  check required params and arguments
#  [[ -z "${MINA_VERSION}" ]] && die "Missing required parameter: --mina-version"
#  [[ ${#args[@]} -eq 0 ]] && die "Missing script arguments"

  if [[ -z "${MINA_VERSION}" && ${#args[@]} -eq 0 ]]; then
		die "Missing required parameter! You must specify a Mina version with a parameters --mina or --mina-version or first positioned argument."
  fi

  if [[ -z "${MINA_VERSION}" ]]; then
  	MINA_VERSION=$args
  fi

  echo -e "Specified version is: ${MINA_VERSION}"

  return 0
}

welcome() {
  msg "$GREEN Welcome to Mina Installer!$NOFORMAT"
  msg "$GREEN Copyright 2021 by Serhii Pimenov <serhii@pimenov.com.ua>$NOFORMAT"
  read -p " If you are ready, press [Enter] key to start or Ctrl+C to stop..."
}

install_pre_requirements() {
  msg "$CYAN Preparing OS...$NOFORMAT"
  sudo apt-get -y update &>/dev/null
  sudo apt --fix-broken install &>/dev/null
  msg "$CYAN Installing HTTPS support...$NOFORMAT"
  sudo apt-get -y install apt-transport-https ca-certificates gnupg  &>/dev/null
  msg "$CYAN Installing utils...$NOFORMAT"
  sudo apt-get -y install curl unzip mc htop net-tools &>/dev/null

  OLD_IFS=IFS
  IFS="."
  read -a OS_VERSION <<< $(lsb_release -d | sed -nre 's/^[^0-9]*(([0-9]+\.)*[0-9]+).*/\1/p')
  if  (( $OS_VERSION > 18 )); then
	  msg "$CYAN Installing required libs...$NOFORMAT"
    cd
    mkdir -p mina_required_libs
    cd mina_required_libs
    wget http://mirrors.kernel.org/ubuntu/pool/main/libf/libffi/libffi6_3.2.1-8_amd64.deb
    wget http://mirrors.edge.kernel.org/ubuntu/pool/universe/j/jemalloc/libjemalloc1_3.6.0-11_amd64.deb
    wget http://mirrors.edge.kernel.org/ubuntu/pool/main/p/procps/libprocps6_3.3.12-3ubuntu1_amd64.deb
    sudo dpkg -i *.deb &>/dev/null
    cd
    rm -rf mina_required_libs
  fi
  IFS=OLD_IFS
}

install_ufw() {
  msg "$CYAN Installing UFW...$NOFORMAT"

	if ! which node > /dev/null; then
		sudo apt-get -y install ufw &>/dev/null
	fi

	sudo ufw default deny incoming
	sudo ufw default allow outgoing
	sudo ufw allow $SSH_PORT
	sudo ufw allow 8302/tcp
	sudo ufw allow 8303/tcp
	sudo ufw allow $MONITOR_PORT
	sudo ufw disable
	sudo ufw enable
	sudo ufw status
}

install_nodejs() {
  msg "$CYAN Installing NodeJS...$NOFORMAT"
	if ! which node > /dev/null; then
		#install node & npm - see https://github.com/nodesource/distributions#deb
		curl -fsSL https://deb.nodesource.com/gpgkey/nodesource.gpg.key | sudo apt-key add -
		VERSION=("node_${NODE_VERSION}.x")
		DISTRO="$(lsb_release -s -c)"
		echo "deb https://deb.nodesource.com/$VERSION $DISTRO main" | sudo tee /etc/apt/sources.list.d/nodesource.list
		echo "deb-src https://deb.nodesource.com/$VERSION $DISTRO main" | sudo tee -a /etc/apt/sources.list.d/nodesource.list
		sudo apt-get -y update &>/dev/null
		sudo apt-get -y install nodejs &>/dev/null
	fi
}

install_monitor() {
	msg "$CYAN Installing Mina Monitor...$NOFORMAT"

	msg "$CYAN Checking NodeJS...$NOFORMAT"
	if ! which node > /dev/null; then
		install_nodejs
	fi

	MONITOR_TARGET_FOLDER=/home/${MINA_USER}/${MONITOR_FOLDER}
	MONITOR_SOURCE=https://raw.githubusercontent.com/olton/scripts/${MONITOR_BRANCH}/mina/monitor/server
	curl -s ${MONITOR_SOURCE}/install.sh | bash -s -- -t $MONITOR_TARGET_FOLDER
}

create_user() {
  msg "$CYAN Create user for Mina...$NOFORMAT"
  if ! id $MINA_USER &>/dev/null; then
    msg "$CYAN Adding user...$NOFORMAT"
    adduser --disabled-password --gecos "" $MINA_USER
    usermod -aG sudo $MINA_USER

    if [[ ! -z "$MINA_USER_PASS" ]]; then
      msg "$CYAN Set user password...$NOFORMAT"
      echo -e "${MINA_USER_PASS}\n${MINA_USER_PASS}" | passwd $MINA_USER
    fi
  fi

  mkdir -p /home/${MINA_USER}/.ssh
  chown ${MINA_USER}:${MINA_USER} /home/${MINA_USER}/.ssh

  authorized_keys_file=/root/.ssh/authorized_keys
  if [[ -f "$authorized_keys_file" ]]; then
		cp $authorized_keys_file /home/${MINA_USER}/.ssh/authorized_keys
		chown ${MINA_USER}:${MINA_USER} /home/${MINA_USER}/.ssh/authorized_keys
		chmod 600 /home/${MINA_USER}/.ssh/authorized_keys
  fi
}

install_mina() {
  msg "$CYAN Installing Mina...$NOFORMAT"

	mina_package="mina-${NET_TARGET}=${MINA_VERSION}"

  msg "$YELLOW We will install Mina $NOFORMAT ${mina_package}"

  echo "deb [trusted=yes] http://packages.o1test.net stretch stable" | sudo tee /etc/apt/sources.list.d/mina.list
  sudo apt-get -y update &>/dev/null
  sudo apt-get -y --allow-downgrades install $mina_package &>/dev/null

	if $INSTALL_ARC; then
		archive_ver=$MINA_VERSION
		if [[ ! -z "$MINA_ARCHIVE_VERSION" ]]; then
			archive_ver=$MINA_ARCHIVE_VERSION
		fi

		mina_archive_package="mina-archive=${archive_ver}"
		msg "$YELLOW We will install Mina Archive $NOFORMAT ${mina_archive_package}"
		sudo apt-get -y --allow-downgrades install $mina_archive_package &>/dev/null
	fi

  if true; then
		mina_keygen_package="mina-generate-keypair=${MINA_VERSION}"
		msg "$YELLOW We will install Mina Key Generator $NOFORMAT ${mina_keygen_package}"
		sudo apt-get -y --allow-downgrades install $mina_keygen_package &>/dev/null
  fi

  OLD_IFS=IFS; IFS=" "; read -a mina_version <<< "$(mina version)"; IFS=OLD_IFS

  msg "$GREEN We installed Mina version ${mina_version[1]}.$NOFORMAT"

  msg "$CYAN Installing Mina Service...$NOFORMAT"
  su - -c "systemctl --user daemon-reload" $MINA_USER
  su - -c "systemctl --user enable mina" $MINA_USER

  msg "$CYAN Enabling linger for ${MINA_USER}...$NOFORMAT"
  sudo loginctl enable-linger $MINA_USER
}

install_mina_env(){
  msg "$CYAN Create Mina environment...$NOFORMAT"

	if [[ ! -d "/home/${MINA_USER}/$MINA_KEY_FOLDER" ]]; then
		mkdir -p /home/${MINA_USER}/$MINA_KEY_FOLDER
		chown ${MINA_USER}:${MINA_USER} /home/${MINA_USER}/${MINA_KEY_FOLDER}
		chmod 700 /home/${MINA_USER}/${MINA_KEY_FOLDER}
  fi

  if [[ ! -f "/home/${MINA_USER}/.mina-env" ]]; then
  	touch /home/${MINA_USER}/.mina-env
	  chown ${MINA_USER}:${MINA_USER} /home/${MINA_USER}/.mina-env
  fi

  mina_env_file="/home/${MINA_USER}/.mina-env"
	if [[ -f "$mina_en_file" ]]; then
		cat <<- EOF > $mina_env_file
			UPTIME_PRIVKEY_PASS="your_password"
			CODA_PRIVKEY_PASS="your_password"
			LOG_LEVEL=Info
			FILE_LOG_LEVEL=Debug
			EXTRA_FLAGS=" --block-producer-key /home/${MINA_USER}/${MINA_KEY_FOLDER}/my-wallet --uptime-submitter-key /home/${MINA_USER}/${MINA_KEY_FOLDER}/my-wallet --uptime-url http://34.134.227.208/v1/submit --limited-graphql-port 3095 "
		EOF

		if [[ ! -z "$MINA_KEY_PASS" ]]; then
				sed -i "s/your_password/${MINA_KEYS_PASS}/g" $mina_env_file
		fi
	fi

  msg "$GREEN Setup complete!$NOFORMAT"
  msg "$YELLOW Now, you must set the password in file .mina-env for your keys if you not defined it with command argument --key-pass.$NOFORMAT"
  msg "$YELLOW Then, run command below to start Mina Node and init others requirements and stop it with Ctrl+C after successful runs:$NOFORMAT"
  msg " mina daemon --peer-list-url https://storage.googleapis.com/mina-seed-lists/mainnet_seeds.txt"
  msg "$YELLOW After, you will stop standalone process, you can run service with a command below:$NOFORMAT"
  msg " systemctl --user start mina"
}

install_sidecar() {
	echo -e -n "$CYAN Installing sidecar...$NOFORMAT"

	sidecar_ver=$MINA_VERSION
	if [[ ! -z "$SIDECAR_VERSION" ]]; then
  	sidecar_ver=$SIDECAR_VERSION
  fi

	sidecar_package="mina-bp-stats-sidecar=${sidecar_ver}"
	msg "$YELLOW We will install Mina Sidecar $NOFORMAT ${sidecar_package}"
	sudo apt-get -y --allow-downgrades install $sidecar_package &>/dev/null

	sidecar_config=/etc/mina-sidecar.json

	cat <<- EOF > $sidecar_config
	{
    "uploadURL": "https://us-central1-mina-mainnet-303900.cloudfunctions.net/block-producer-stats-ingest/?token=72941420a9595e1f4006e2f3565881b5",
    "nodeURL": "http://127.0.0.1:3095"
  }
	EOF
}

# --- Setup ---

parse_params "$@"
setup_colors
exit
# --- Start process ---

welcome

install_pre_requirements

if $INSTALL_UFW; then
	install_ufw
fi

create_user

install_mina
install_mina_env

if [[ "$NODE_VERSION" -ne "0" ]]; then
	install_nodejs
fi

if $INSTALL_MONITOR; then
	install_monitor
fi

if $INSTALL_SIDECAR; then
	install_sidecar
fi

cleanup
# --- End of script ---