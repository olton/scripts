#!/usr/bin/env bash

set -Eeuo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
keys_path="keys"

usage() {
  cat <<- EOF
		Usage: $(basename "${BASH_SOURCE[0]}") [-h] [-v] [--no-color]

		This script is intended to simple update a Mina node.

		Available options:

		-h, --help                  Print this help and exit
		--no-color                  Disable color output
		--user                      Define a Mina owner
		--net                       Define a Mina network
		--mina, --mina-version      Set Mina version to update
		--archive										Use this flag to update archive node
		--sidecar										Use this flag to update sidecar

		For example:
		${SCRIPT_NAME} --help

		For example:
		${SCRIPT_NAME} 1.2.2-feee67c

		For example:
		${SCRIPT_NAME} --mina 1.2.2-feee67c --archive --sidecar

	EOF
  exit
}

MINA_VERSION=""
MINA_USER=""
MINA_NETWORK=mainnet
UPDATE_ARCHIVE=false
UPDATE_SIDECAR=false

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
    --archive) UPDATE_ARCHIVE=true ;;
    --sidecar) UPDATE_SIDECAR=true ;;
    --mina | --mina-version)
      MINA_VERSION="${2-}"
      shift
      ;;
    --net)
      MINA_NETWORK="${2-}"
      shift
      ;;
    --user)
      MINA_USER="${2-}"
      shift
      ;;
    -?*) die "Unknown option: $1" ;;
    *) break ;;
    esac
    shift
  done

  args=("$@")

  if [[ -z "${MINA_VERSION}" && ${#args[@]} -eq 0 ]]; then
		die "Missing required parameter! You must specify a Mina version with a parameters --mina or --mina-version or first positioned argument."
  fi

  if [[ -z "${MINA_VERSION}" ]]; then
  	MINA_VERSION=$args
  fi

  return 0
}

welcome() {
	msg "$GREEN Welcome to Mina Updater!${NOFORMAT}"
	msg "$GREEN Copyright 2021 by Serhii Pimenov <serhii@pimenov.com.ua>${NOFORMAT}"
	read -p " If you are ready, press [Enter] key to start or Ctrl+C to stop..."
}

stop_services() {
  echo -e -n "$CYAN Stopping Mina...$NOFORMAT"
	if [[ -z "$MINA_USER"  ]]; then
		systemctl --user stop mina
	else
		su - -c "systemctl --user stop mina" $MINA_USER
	fi

  if $UPDATE_ARCHIVE; then
  echo -e -n "$CYAN Stopping Mina Archive...$NOFORMAT"
		if [[ -z "$MINA_USER"  ]]; then
			systemctl --user stop mina-archive
		else
			su - -c "systemctl --user stop mina-archive" $MINA_USER
		fi
  fi

  if $UPDATE_SIDECAR; then
    echo -e -n "$CYAN Stopping Sidecar...$NOFORMAT"
		if [[ -z "$MINA_USER"  ]]; then
			systemctl --user stop mina-bp-stats-sidecar
		else
			su - -c "systemctl --user stop mina-bp-stats-sidecar" $MINA_USER
		fi
  fi

	return 0
}

update_services() {
  echo -e -n "$CYAN Updating Mina to ${MINA_VERSION}...$NOFORMAT"
  mina_package="mina-${MINA_NETWORK}=${MINA_VERSION}"
  echo "deb [trusted=yes] http://packages.o1test.net stretch stable" | sudo tee /etc/apt/sources.list.d/mina.list
  sudo apt-get -y update &>/dev/null
  sudo apt-get -y --allow-downgrades install $mina_package &>/dev/null

  if $UPDATE_ARCHIVE; then
		echo -e -n "$CYAN Updating Mina Archive...$NOFORMAT"
		mina_archive_package="mina-archive=${MINA_VERSION}"
		sudo apt-get -y --allow-downgrades install $mina_archive_package &>/dev/null
  fi

  if $UPDATE_SIDECAR; then
		echo -e -n "$CYAN Updating Sidecar...$NOFORMAT"
		sidecar_package="mina-bp-stats-sidecar=${MINA_VERSION}"
		sudo apt-get -y --allow-downgrades install $sidecar_package &>/dev/null
		sidecar_config=/etc/mina-sidecar.json
		sudo cat <<- EOF > $sidecar_config
		{
			"uploadURL": "https://us-central1-mina-mainnet-303900.cloudfunctions.net/block-producer-stats-ingest/?token=72941420a9595e1f4006e2f3565881b5",
			"nodeURL": "http://127.0.0.1:3095"
		}
		EOF
  fi

	return 0
}

start_services() {
  echo -e -n "$CYAN Starting Mina...$NOFORMAT"
	if [[ -z "$MINA_USER"  ]]; then
		systemctl --user daemon-reload
		systemctl --user start mina
	else
		su - -c "systemctl --user daemon-reload" $MINA_USER
		su - -c "systemctl --user start mina" $MINA_USER
	fi

  if $UPDATE_ARCHIVE; then
    echo -e -n "$CYAN Starting Mina Archive...$NOFORMAT"
		if [[ -z "$MINA_USER"  ]]; then
  		systemctl --user daemon-reload
			systemctl --user start mina-archive
		else
  		su - -c "systemctl --user daemon-reload" $MINA_USER
			su - -c "systemctl --user start mina-archive" $MINA_USER
		fi
  fi

  if $UPDATE_SIDECAR; then
    echo -e -n "$CYAN Starting Sidecar...$NOFORMAT"
		if [[ -z "$MINA_USER"  ]]; then
  		systemctl --user daemon-reload
			systemctl --user start mina-bp-stats-sidecar
		else
  		su - -c "systemctl --user daemon-reload" $MINA_USER
			su - -c "systemctl --user mina-bp-stats-sidecar" $MINA_USER
		fi
  fi

	return 0
}

parse_params "$@"
setup_colors

welcome

stop_services
update_services
start_services

cleanup