#!/usr/bin/env bash

# check if needed commands are available
# cd
if ! command -v cd &> /dev/null
then
  echo "cd seems to be unavailable"
fi

# dirname
if ! command -v dirname &> /dev/null
then
  echo "dirname seems to be unavailable"
fi

# pwd
if ! command -v pwd &> /dev/null
then
  echo "pwd seems to be unavailable"
fi

# xargs
if ! command -v xargs &> /dev/null
then
  echo "xargs seems to be unavailable"
fi

# grep
if ! command -v grep &> /dev/null
then
  echo "grep seems to be unavailable"
fi

# read
if ! command -v read &> /dev/null
then
  echo "read seems to be unavailable"
fi

# tail
if ! command -v tail &> /dev/null
then
  echo "tail seems to be unavailable"
fi

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]:-$0}"; )" &> /dev/null && pwd 2> /dev/null; )";

ENVIRONMENT_FILE=
ARGUMENT_PARSING_SUCCEEDED=true

if [ -z "${POSTFIX_RELAY_TEST_ASK_FOR_ADDITIONAL}" ]; then
  POSTFIX_RELAY_TEST_ASK_FOR_ADDITIONAL=true
fi

for (( i=1; i<=$#; i++ ))
do
	arg=${@:$i:1}
	val=${@:$i+1:1}

	case $arg in
	-h|--help)
		echo "Show help text here"
		exit 0
		;;
	-e)
		ENVIRONMENT_FILE=$val
		((i++))
		;;
	--env-file=*)
		ENVIRONMENT_FILE=${arg#*=}
		;;
	*)
		echo "Unknown argument number $i: '$arg'"
		ARGUMENT_PARSING_SUCCEEDED=false
		;;
	esac
done

if [ "${ARGUMENT_PARSING_SUCCEEDED}" != "true" ]; then
  exit 1;
fi

if [ ! -z "${ENVIRONMENT_FILE}" ]; then
  if [ -f ${ENVIRONMENT_FILE} ]; then
    export $(grep -v '^#' ${ENVIRONMENT_FILE} | xargs -0)
  else
    echo "Environment file not found"
    exit 1
  fi
else
  if [ -f ${SCRIPT_DIR}/../.env ]; then
    export $(grep -v '^#' ${SCRIPT_DIR}/../.env | xargs -0)
  fi
fi

if [ -z "${POSTFIX_RELAY_TEST_POSTFIX_HOST}" ]; then
  read -p "Enter a valid email address for POSTFIX_RELAY_TEST_POSTFIX_HOST: " POSTFIX_RELAY_TEST_POSTFIX_HOST
fi

if [ -z "${POSTFIX_RELAY_TEST_POSTFIX_PORT}" ]; then
  read -p "Enter a valid email address for POSTFIX_RELAY_TEST_POSTFIX_PORT: " POSTFIX_RELAY_TEST_POSTFIX_PORT
fi

LOOP_SUCCESS=true

while read -r POSTFIX_RELAY_TEST_LINE; do
  [[ -z "${POSTFIX_RELAY_TEST_LINE}" ]] && break

  VAR_SENDER="${POSTFIX_RELAY_TEST_LINE}SENDER"
  if [ -z "${!VAR_SENDER}" ]; then
    echo "Empty environment variable ${VAR_SENDER}"
    LOOP_SUCCESS="false"
    break
  fi

  VAR_RECIPIENT="${POSTFIX_RELAY_TEST_LINE}RECIPIENT"
  if [ -z "${!VAR_RECIPIENT}" ]; then
    echo "Empty environment variable ${VAR_RECIPIENT}"
    LOOP_SUCCESS="false"
    break
  fi
done <<< "$(env | grep -E 'POSTFIX_RELAY_TEST_[0-9]{1,7}_' | awk -F_ '{print $1"_"$2"_"$3"_"$4"_"}' | uniq | sort -n)"

if [ "${LOOP_SUCCESS}" == "false" ]; then
  exit 1;
fi

if [ -z "${POSTFIX_RELAY_TEST_0_SENDER}" ]; then
  read -p "Enter a valid email address for POSTFIX_RELAY_TEST_0_SENDER: " POSTFIX_RELAY_TEST_0_SENDER
fi

if [ -z "${POSTFIX_RELAY_TEST_0_RECIPIENT}" ]; then
  read -p "Enter a valid email address for POSTFIX_RELAY_TEST_0_RECIPIENT: " POSTFIX_RELAY_TEST_0_RECIPIENT
fi

POSTFIX_RELAY_TEST_CURRENT=$(env | grep -E 'POSTFIX_RELAY_TEST_[0-9]{1,7}_' | awk -F_ '{print $4}' | uniq | sort -n | tail -n 1)
POSTFIX_RELAY_TEST_NEXT=$((POSTFIX_RELAY_TEST_CURRENT+1))

if [ "${POSTFIX_RELAY_TEST_ASK_FOR_ADDITIONAL}" == "true" ]; then
  read -p "Enter yes or no to add additional sender and recipient: " POSTFIX_RELAY_TEST_ADD

  if [ "${POSTFIX_RELAY_TEST_ADD}" == "yes" ]; then
    read -p "Enter a valid email address for POSTFIX_RELAY_TEST_${POSTFIX_RELAY_TEST_NEXT}_SENDER: " POSTFIX_RELAY_TEST_${POSTFIX_RELAY_TEST_NEXT}_SENDER
    VAR=POSTFIX_RELAY_TEST_${POSTFIX_RELAY_TEST_NEXT}_SENDER
    export ${VAR}=${!VAR}

    read -p "Enter a valid email address for POSTFIX_RELAY_TEST_${POSTFIX_RELAY_TEST_NEXT}_RECIPIENT: " POSTFIX_RELAY_TEST_${POSTFIX_RELAY_TEST_NEXT}_RECIPIENT
    VAR=POSTFIX_RELAY_TEST_${POSTFIX_RELAY_TEST_NEXT}_RECIPIENT
    export ${VAR}=${!VAR}

    POSTFIX_RELAY_TEST_NEXT=$((POSTFIX_RELAY_TEST_NEXT+1))
  else
    POSTFIX_RELAY_TEST_ASK_FOR_ADDITIONAL=false
  fi
fi

if [ "${POSTFIX_RELAY_TEST_ASK_FOR_ADDITIONAL}" == "true" ]; then
  read -p "Enter yes or no to add additional sender and recipient: " POSTFIX_RELAY_TEST_ADD

  if [ "${POSTFIX_RELAY_TEST_ADD}" == "yes" ]; then
    read -p "Enter a valid email address for POSTFIX_RELAY_TEST_${POSTFIX_RELAY_TEST_NEXT}_SENDER: " POSTFIX_RELAY_TEST_${POSTFIX_RELAY_TEST_NEXT}_SENDER
    read -p "Enter a valid email address for POSTFIX_RELAY_TEST_${POSTFIX_RELAY_TEST_NEXT}_RECIPIENT: " POSTFIX_RELAY_TEST_${POSTFIX_RELAY_TEST_NEXT}_RECIPIENT
    POSTFIX_RELAY_TEST_NEXT=$((POSTFIX_RELAY_TEST_NEXT+1))
  else
    POSTFIX_RELAY_TEST_ASK_FOR_ADDITIONAL=false
  fi
fi

if [ "${POSTFIX_RELAY_TEST_ASK_FOR_ADDITIONAL}" == "true" ]; then
  read -p "Enter yes or no to add additional sender and recipient: " POSTFIX_RELAY_TEST_ADD

  if [ "${POSTFIX_RELAY_TEST_ADD}" == "yes" ]; then
    read -p "Enter a valid email address for POSTFIX_RELAY_TEST_${POSTFIX_RELAY_TEST_NEXT}_SENDER: " POSTFIX_RELAY_TEST_${POSTFIX_RELAY_TEST_NEXT}_SENDER
    read -p "Enter a valid email address for POSTFIX_RELAY_TEST_${POSTFIX_RELAY_TEST_NEXT}_RECIPIENT: " POSTFIX_RELAY_TEST_${POSTFIX_RELAY_TEST_NEXT}_RECIPIENT
    POSTFIX_RELAY_TEST_NEXT=$((POSTFIX_RELAY_TEST_NEXT+1))
  else
    POSTFIX_RELAY_TEST_ASK_FOR_ADDITIONAL=false
  fi
fi

if [ -z "${POSTFIX_RELAY_TEST_EXECUTE_PLAIN}" ]; then
  read -p "Enter yes or no for POSTFIX_RELAY_TEST_EXECUTE_PLAIN: " POSTFIX_RELAY_TEST_EXECUTE_PLAIN
fi

if [ -z "${POSTFIX_RELAY_TEST_EXECUTE_TLS}" ]; then
  read -p "Enter yes or no for POSTFIX_RELAY_TEST_EXECUTE_TLS: " POSTFIX_RELAY_TEST_EXECUTE_TLS
fi

function sendEmail () {
  sleep 0.2
  echo "EHLO localhost"
  sleep 0.2
  echo "MAIL FROM: $1"
  sleep 0.2
  echo "RCPT TO: $2"
  sleep 0.2
  echo "DATA"
  sleep 0.2
  echo "Subject: Test from $1 to $2"
  sleep 0.2
  echo "Test from $1 to $2 at $(date +%Y%m%d%H%M%S) via $3 connection"
  sleep 0.2
  echo "."
  sleep 0.2
  echo "QUIT"
}

while read -r POSTFIX_RELAY_TEST_LINE; do
  [[ -z "${POSTFIX_RELAY_TEST_LINE}" ]] && break

  VAR_SENDER="${POSTFIX_RELAY_TEST_LINE}SENDER"
  VAR_RECIPIENT="${POSTFIX_RELAY_TEST_LINE}RECIPIENT"

  if [ "${POSTFIX_RELAY_TEST_EXECUTE_PLAIN}" == "yes" ]; then
    echo "Testing non TLS connection from ${!VAR_SENDER} to ${!VAR_RECIPIENT}"
    sendEmail "${!VAR_SENDER}" "${!VAR_RECIPIENT}" "plain" | nc ${POSTFIX_RELAY_TEST_POSTFIX_HOST} ${POSTFIX_RELAY_TEST_POSTFIX_PORT} > /dev/null
  fi

  if [ "${POSTFIX_RELAY_TEST_EXECUTE_TLS}" == "yes" ]; then
    echo "Testing TLS connection from ${!VAR_SENDER} to ${!VAR_RECIPIENT}"
    sendEmail "${!VAR_SENDER}" "${!VAR_RECIPIENT}" "TLS" | openssl s_client -quiet -starttls smtp -connect ${POSTFIX_RELAY_TEST_POSTFIX_HOST}:${POSTFIX_RELAY_TEST_POSTFIX_PORT} > /dev/null
  fi

done <<< "$(env | grep -E 'POSTFIX_RELAY_TEST_[0-9]{1,7}_' | awk -F_ '{print $1"_"$2"_"$3"_"$4"_"}' | uniq | sort -n)"
