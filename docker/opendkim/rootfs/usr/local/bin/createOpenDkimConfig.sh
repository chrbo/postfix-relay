#!/bin/bash

########################################################################################################################
# Set opendkim basics variables                                                                                        #
########################################################################################################################
POSTFIX_RELAY_DKIM_TRUSTED_HOSTS=${POSTFIX_RELAY_DKIM_TRUSTED_HOSTS:-127.0.0.1/32}

########################################################################################################################
# Validate and set default outbound relay variables                                                                    #
########################################################################################################################
if [ -z "${POSTFIX_RELAY_DEFAULT_OUTBOUND_RELAY_DKIM_DOMAIN}" ]; then
  echo "Empty environment variable POSTFIX_RELAY_DEFAULT_OUTBOUND_RELAY_DKIM_DOMAIN"
  exit 1
fi
POSTFIX_RELAY_DEFAULT_OUTBOUND_RELAY_DKIM_DOMAIN=${POSTFIX_RELAY_DEFAULT_OUTBOUND_RELAY_DKIM_DOMAIN}

if [ -z "${POSTFIX_RELAY_DEFAULT_OUTBOUND_RELAY_DKIM_SELECTOR}" ]; then
  echo "Empty environment variable POSTFIX_RELAY_DEFAULT_OUTBOUND_RELAY_DKIM_SELECTOR"
  exit 1
fi
POSTFIX_RELAY_DEFAULT_OUTBOUND_RELAY_DKIM_SELECTOR=${POSTFIX_RELAY_DEFAULT_OUTBOUND_RELAY_DKIM_SELECTOR}

if [ -z "${POSTFIX_RELAY_DEFAULT_OUTBOUND_RELAY_DKIM_KEY}" ]; then
  echo "Empty environment variable POSTFIX_RELAY_DEFAULT_OUTBOUND_RELAY_DKIM_KEY"
  exit 1
fi
POSTFIX_RELAY_DEFAULT_OUTBOUND_RELAY_DKIM_KEY=${POSTFIX_RELAY_DEFAULT_OUTBOUND_RELAY_DKIM_KEY}

if [ -z "${POSTFIX_RELAY_DEFAULT_OUTBOUND_RELAY_DKIM_FILTER}" ]; then
  echo "Empty environment variable POSTFIX_RELAY_DEFAULT_OUTBOUND_RELAY_DKIM_FILTER"
  exit 1
fi
POSTFIX_RELAY_DEFAULT_OUTBOUND_RELAY_DKIM_FILTER=${POSTFIX_RELAY_DEFAULT_OUTBOUND_RELAY_DKIM_FILTER}

########################################################################################################################
# Validate and set sender based routing variables                                                                      #
########################################################################################################################
LOOP_SUCCESS="true"

while read -r POSTFIX_RELAY_SENDER_BASED_ROUTING_LINE; do
  [[ -z "${POSTFIX_RELAY_SENDER_BASED_ROUTING_LINE}" ]] && break

  VAR_DKIM_DOMAIN="${POSTFIX_RELAY_SENDER_BASED_ROUTING_LINE}DKIM_DOMAIN"
  if [ -z "${!VAR_DKIM_DOMAIN}" ]; then
    echo "Empty environment variable ${VAR_DKIM_DOMAIN}"
    LOOP_SUCCESS="false"
    break
  fi

  VAR_DKIM_SELECTOR="${POSTFIX_RELAY_SENDER_BASED_ROUTING_LINE}DKIM_SELECTOR"
  if [ -z "${!VAR_DKIM_SELECTOR}" ]; then
    echo "Empty environment variable ${VAR_DKIM_SELECTOR}"
    LOOP_SUCCESS="false"
    break
  fi

  VAR_DKIM_KEY="${POSTFIX_RELAY_SENDER_BASED_ROUTING_LINE}DKIM_KEY"
  if [ -z "${!VAR_DKIM_KEY}" ]; then
    echo "Empty environment variable ${VAR_DKIM_KEY}"
    LOOP_SUCCESS="false"
    break
  fi

  VAR_DKIM_FILTER="${POSTFIX_RELAY_SENDER_BASED_ROUTING_LINE}DKIM_FILTER"
  if [ -z "${!VAR_DKIM_FILTER}" ]; then
    echo "Empty environment variable ${VAR_DKIM_FILTER}"
    LOOP_SUCCESS="false"
    break
  fi

done <<< $(env | grep -E '^POSTFIX_RELAY_ADDITIONAL_OUTBOUND_RELAY_[0-9]{1,7}_DKIM' | awk -F_ '{print $1"_"$2"_"$3"_"$4"_"$5"_"$6"_"}' | uniq | sort -n | tr -s "\n")

if [ "${LOOP_SUCCESS}" == "false" ]; then
  exit 1;
fi

########################################################################################################################
# Display configuration                                                                                                #
########################################################################################################################
CONFIG_OUTPUT="POSTFIX_RELAY_DKIM_TRUSTED_HOSTS:${POSTFIX_RELAY_DKIM_TRUSTED_HOSTS}"

if [ ! -z "${POSTFIX_RELAY_DEFAULT_OUTBOUND_RELAY_DKIM_DOMAIN}" ]; then
  CONFIG_OUTPUT="${CONFIG_OUTPUT}\nPOSTFIX_RELAY_DEFAULT_OUTBOUND_RELAY_DKIM_DOMAIN:${POSTFIX_RELAY_DEFAULT_OUTBOUND_RELAY_DKIM_DOMAIN}"
  CONFIG_OUTPUT="${CONFIG_OUTPUT}\nPOSTFIX_RELAY_DEFAULT_OUTBOUND_RELAY_DKIM_SELECTOR:${POSTFIX_RELAY_DEFAULT_OUTBOUND_RELAY_DKIM_SELECTOR}"
  CONFIG_OUTPUT="${CONFIG_OUTPUT}\nPOSTFIX_RELAY_DEFAULT_OUTBOUND_RELAY_DKIM_KEY:********** (masked)"
  CONFIG_OUTPUT="${CONFIG_OUTPUT}\nPOSTFIX_RELAY_DEFAULT_OUTBOUND_RELAY_DKIM_FILTER:${POSTFIX_RELAY_DEFAULT_OUTBOUND_RELAY_DKIM_FILTER}"
fi

while read -r POSTFIX_RELAY_SENDER_BASED_ROUTING_LINE; do
  [[ -z "${POSTFIX_RELAY_SENDER_BASED_ROUTING_LINE}" ]] && break

  VAR_DKIM_DOMAIN="${POSTFIX_RELAY_SENDER_BASED_ROUTING_LINE}DKIM_DOMAIN"
  VAR_DKIM_SELECTOR="${POSTFIX_RELAY_SENDER_BASED_ROUTING_LINE}DKIM_SELECTOR"
  VAR_DKIM_KEY="${POSTFIX_RELAY_SENDER_BASED_ROUTING_LINE}DKIM_KEY"
  VAR_DKIM_FILTER="${POSTFIX_RELAY_SENDER_BASED_ROUTING_LINE}DKIM_FILTER"

  CONFIG_OUTPUT="${CONFIG_OUTPUT}\n${VAR_DKIM_DOMAIN}:${!VAR_DKIM_DOMAIN}"
  CONFIG_OUTPUT="${CONFIG_OUTPUT}\n${VAR_DKIM_SELECTOR}:${!VAR_DKIM_SELECTOR}"
  CONFIG_OUTPUT="${CONFIG_OUTPUT}\n${VAR_DKIM_KEY}:********** (masked)"
  CONFIG_OUTPUT="${CONFIG_OUTPUT}\n${VAR_DKIM_FILTER}:${!VAR_DKIM_FILTER}"
done <<< $(env | grep -E '^POSTFIX_RELAY_ADDITIONAL_OUTBOUND_RELAY_[0-9]{1,7}_DKIM' | awk -F_ '{print $1"_"$2"_"$3"_"$4"_"$5"_"$6"_"}' | uniq | sort -n)

echo "Running configuration:"
echo -e "${CONFIG_OUTPUT}" | column -t -s ':' --table-columns C1,C2 --table-noheadings --table-wrap C2

########################################################################################################################
# Create configuration                                                                                                 #
########################################################################################################################
echo "${POSTFIX_RELAY_DKIM_TRUSTED_HOSTS}" > /etc/opendkim/TrustedHosts || exit 1

CONFIG_KEYTABLE=""
CONFIG_SIGNINGTABLE=""

if [ ! -z "${POSTFIX_RELAY_DEFAULT_OUTBOUND_RELAY_DKIM_DOMAIN}" ]; then
  CONFIG_KEYTABLE="${CONFIG_KEYTABLE}${POSTFIX_RELAY_DEFAULT_OUTBOUND_RELAY_DKIM_DOMAIN}.${POSTFIX_RELAY_DEFAULT_OUTBOUND_RELAY_DKIM_SELECTOR}"
  CONFIG_KEYTABLE="${CONFIG_KEYTABLE}|${POSTFIX_RELAY_DEFAULT_OUTBOUND_RELAY_DKIM_DOMAIN}:${POSTFIX_RELAY_DEFAULT_OUTBOUND_RELAY_DKIM_SELECTOR}"
  CONFIG_KEYTABLE="${CONFIG_KEYTABLE}:/etc/opendkim/${POSTFIX_RELAY_DEFAULT_OUTBOUND_RELAY_DKIM_DOMAIN}.${POSTFIX_RELAY_DEFAULT_OUTBOUND_RELAY_DKIM_SELECTOR}.private.key"
  CONFIG_SIGNINGTABLE="${CONFIG_SIGNINGTABLE}${POSTFIX_RELAY_DEFAULT_OUTBOUND_RELAY_DKIM_FILTER}"
  CONFIG_SIGNINGTABLE="${CONFIG_SIGNINGTABLE}|${POSTFIX_RELAY_DEFAULT_OUTBOUND_RELAY_DKIM_DOMAIN}.${POSTFIX_RELAY_DEFAULT_OUTBOUND_RELAY_DKIM_SELECTOR}"
  echo -e "${POSTFIX_RELAY_DEFAULT_OUTBOUND_RELAY_DKIM_KEY}" | base64 -d > /etc/opendkim/${POSTFIX_RELAY_DEFAULT_OUTBOUND_RELAY_DKIM_DOMAIN}.${POSTFIX_RELAY_DEFAULT_OUTBOUND_RELAY_DKIM_SELECTOR}.private.key
  chown opendkim:opendkim /etc/opendkim/${POSTFIX_RELAY_DEFAULT_OUTBOUND_RELAY_DKIM_DOMAIN}.${POSTFIX_RELAY_DEFAULT_OUTBOUND_RELAY_DKIM_SELECTOR}.private.key
  chmod go-rwx /etc/opendkim/${POSTFIX_RELAY_DEFAULT_OUTBOUND_RELAY_DKIM_DOMAIN}.${POSTFIX_RELAY_DEFAULT_OUTBOUND_RELAY_DKIM_SELECTOR}.private.key
fi

while read -r POSTFIX_RELAY_SENDER_BASED_ROUTING_LINE; do
  [[ -z "${POSTFIX_RELAY_SENDER_BASED_ROUTING_LINE}" ]] && break

  VAR_DKIM_DOMAIN="${POSTFIX_RELAY_SENDER_BASED_ROUTING_LINE}DKIM_DOMAIN"
  VAR_DKIM_SELECTOR="${POSTFIX_RELAY_SENDER_BASED_ROUTING_LINE}DKIM_SELECTOR"
  VAR_DKIM_KEY="${POSTFIX_RELAY_SENDER_BASED_ROUTING_LINE}DKIM_KEY"
  VAR_DKIM_FILTER="${POSTFIX_RELAY_SENDER_BASED_ROUTING_LINE}DKIM_FILTER"

  CONFIG_KEYTABLE="${CONFIG_KEYTABLE}\n${!VAR_DKIM_DOMAIN}.${!VAR_DKIM_SELECTOR}"
  CONFIG_KEYTABLE="${CONFIG_KEYTABLE}|${!VAR_DKIM_DOMAIN}:${!VAR_DKIM_SELECTOR}"
  CONFIG_KEYTABLE="${CONFIG_KEYTABLE}:/etc/opendkim/${!VAR_DKIM_DOMAIN}.${!VAR_DKIM_SELECTOR}.private.key"
  CONFIG_SIGNINGTABLE="${CONFIG_SIGNINGTABLE}\n${!VAR_DKIM_FILTER}"
  CONFIG_SIGNINGTABLE="${CONFIG_SIGNINGTABLE}|${!VAR_DKIM_DOMAIN}.${!VAR_DKIM_SELECTOR}"
  echo "${!VAR_DKIM_KEY}" | base64 -d > /etc/opendkim/${!VAR_DKIM_DOMAIN}.${!VAR_DKIM_SELECTOR}.private.key
  chown opendkim:opendkim /etc/opendkim/${!VAR_DKIM_DOMAIN}.${!VAR_DKIM_SELECTOR}.private.key
  chmod go-rwx /etc/opendkim/${!VAR_DKIM_DOMAIN}.${!VAR_DKIM_SELECTOR}.private.key
done <<< $(env | grep -E '^POSTFIX_RELAY_ADDITIONAL_OUTBOUND_RELAY_[0-9]{1,7}_DKIM' | awk -F_ '{print $1"_"$2"_"$3"_"$4"_"$5"_"$6"_"}' | uniq | sort -n)

echo -e "${CONFIG_KEYTABLE}" | column -t -s '|' --table-noheadings > /etc/opendkim/KeyTable
echo -e "${CONFIG_SIGNINGTABLE}" | column -t -s '|' --table-noheadings > /etc/opendkim/SigningTable
