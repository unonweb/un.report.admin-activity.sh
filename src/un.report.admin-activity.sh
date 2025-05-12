#!/bin/bash

# Ensure the script is run as root
if [ "${EUID}" -ne 0 ]; then
	echo "This script must be run as root. Exiting."
	exit 1
fi

# BOILERPLATE
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE}")"
SCRIPT_DIR=$(dirname -- "$(readlink -f "${BASH_SOURCE}")")
SCRIPT_NAME=$(basename -- "$(readlink -f "${BASH_SOURCE}")")

ESC=$(printf "\e")
BOLD="${ESC}[1m"
RESET="${ESC}[0m"
RED="${ESC}[31m"
GREEN="${ESC}[32m"
BLUE="${ESC}[34m"
UNDERLINE="${ESC}[4m"

# FUNCTIONS
source "${SCRIPT_DIR}/lib/readFileToMap.sh"

# CONSTANTS
CONFIG_PATH="${SCRIPT_DIR}/config.ini"
declare -A CONFIG

# read config from file
readFileToMap CONFIG ${CONFIG_PATH}

function main() {

	local mailDest=${CONFIG[EMAIL]}
	local mailSubj=${CONFIG[SUBJECT]}
	local timeFrame=${CONFIG[TIME_FRAME]}
	local report=
	local sudoUse=()
	local rootLogins=()
	local sshLogins=()

	# Collect data
	mapfile -t sudoUse < <(journalctl --quiet --since "${timeFrame}" --identifier sudo --grep "COMMAND=")
	mapfile -t rootLogins < <(journalctl --quiet --since "${timeFrame}" _UID=0 --grep "session opened for user root")
	mapfile -t sshLogins < <(journalctl --quiet --since "${timeFrame}" --unit sshd)
	TOTAL=$((${#sudoUse[@]} + ${#rootLogins[@]} + ${#sshLogins[@]})) # sum up the lengths of the arrays

	if [[ ${TOTAL} -eq 0 ]]; then
		echo -e "No sudo usage, no root logins, no sshd logins detected since ${timeFrame}."
		exit
	fi

	# create a report
	report=
	report+="REPORT\n"
	report+="------\n"
	report+="SINCE: ${timeFrame}\n"
	report+="HOST: $(hostname)\n"
	report+="DATE: $(date)\n"
	report+="\n"
	report+="SUDO USAGE\n"
	report+="----------\n"
	for item in "${sudoUse[@]}"; do
		report+="${item}\n"
	done
	report+="\n"
	report+="ROOT LOGINS\n"
	report+="-----------\n"
	for item in "${rootLogins[@]}"; do
		report+="${item}\n"
	done
	report+="\n"
	report+="SSH LOGINS\n"
	report+="-----------\n"
	for item in "${sshLogins[@]}"; do
		report+="${item}\n"
	done

	# send report
	echo -e ${report} | mail -s "${mailSubj}" "${mailDest}"
}
