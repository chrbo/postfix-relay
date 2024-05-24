#!/bin/bash

set -e

function create_config() {
  ########################################################################################################################
  # Set postfix basics variables                                                                                         #
  ########################################################################################################################
  POSTFIX_RELAY_HOSTNAME=${POSTFIX_RELAY_HOSTNAME:-my.local}
  POSTFIX_RELAY_NETWORKS=${POSTFIX_RELAY_NETWORKS:-10.0.0.0/8,127.0.0.0/8,172.17.0.0/16,192.0.0.0/8}
  POSTFIX_RELAY_CUSTOM_CONFIG=${POSTFIX_RELAY_CUSTOM_CONFIG:-}

  ########################################################################################################################
  # Validate and set default outbound relay variables                                                                    #
  ########################################################################################################################
  if [ -z "${POSTFIX_RELAY_DEFAULT_OUTBOUND_RELAY_HOST}" ]; then
    echo "Empty environment variable POSTFIX_RELAY_DEFAULT_OUTBOUND_RELAY_HOST"
    exit 1
  fi
  POSTFIX_RELAY_DEFAULT_OUTBOUND_RELAY_HOST=${POSTFIX_RELAY_DEFAULT_OUTBOUND_RELAY_HOST}

  if [ -z "${POSTFIX_RELAY_DEFAULT_OUTBOUND_RELAY_USERNAME}" ]; then
    echo "Empty environment variable POSTFIX_RELAY_DEFAULT_OUTBOUND_RELAY_USERNAME"
    exit 1
  fi
  POSTFIX_RELAY_DEFAULT_OUTBOUND_RELAY_USERNAME=${POSTFIX_RELAY_DEFAULT_OUTBOUND_RELAY_USERNAME}

  if [ -z "${POSTFIX_RELAY_DEFAULT_OUTBOUND_RELAY_PASSWORD}" ]; then
    echo "Empty environment variable POSTFIX_RELAY_DEFAULT_OUTBOUND_RELAY_PASSWORD"
    exit 1
  fi
  POSTFIX_RELAY_DEFAULT_OUTBOUND_RELAY_PASSWORD=${POSTFIX_RELAY_DEFAULT_OUTBOUND_RELAY_PASSWORD}

  ########################################################################################################################
  # Validate and set inbound mail transport via TLS variables                                                            #
  ########################################################################################################################
  POSTFIX_RELAY_INBOUND_TLS=${POSTFIX_RELAY_INBOUND_TLS:-false}

  if [ "${POSTFIX_RELAY_INBOUND_TLS}" == "may" ] || [ "${POSTFIX_RELAY_INBOUND_TLS}" == "encrypt" ]; then
    POSTFIX_RELAY_INBOUND_TLS_SETTINGS=${POSTFIX_RELAY_INBOUND_TLS_SETTINGS:-smtpd_tls_loglevel=1;smtpd_tls_mandatory_protocols=!SSLv2,!SSLv3,!TLSv1;smtpd_tls_protocols=!SSLv2,!SSLv3,!TLSv1}
    POSTFIX_RELAY_INBOUND_TLS_SETTINGS="smtpd_tls_security_level=${POSTFIX_RELAY_INBOUND_TLS};${POSTFIX_RELAY_INBOUND_TLS_SETTINGS}"

    if [ -z "${POSTFIX_RELAY_INBOUND_TLS_CERTIFICATE}" ]; then
      echo "Empty environment variable POSTFIX_RELAY_INBOUND_TLS_CERTIFICATE"
      exit 1
    fi
    POSTFIX_RELAY_INBOUND_TLS_CERTIFICATE=${POSTFIX_RELAY_INBOUND_TLS_CERTIFICATE}

    if [ -z "${POSTFIX_RELAY_INBOUND_TLS_KEY}" ]; then
      echo "Empty environment variable POSTFIX_RELAY_INBOUND_TLS_KEY"
      exit 1
    fi
    POSTFIX_RELAY_INBOUND_TLS_KEY=${POSTFIX_RELAY_INBOUND_TLS_KEY}
  fi

  ########################################################################################################################
  # Set outbound mail transport via TLS variables                                                                        #
  ########################################################################################################################
  POSTFIX_RELAY_OUTBOUND_TLS=${POSTFIX_RELAY_OUTBOUND_TLS:-false}

  if [ "${POSTFIX_RELAY_OUTBOUND_TLS}" == "may" ] || [ "${POSTFIX_RELAY_OUTBOUND_TLS}" == "encrypt" ]; then
    POSTFIX_RELAY_OUTBOUND_TLS_SETTINGS=${POSTFIX_RELAY_OUTBOUND_TLS_SETTINGS:-smtp_use_tls=yes;smtp_tls_loglevel=1;smtp_tls_mandatory_protocols=!SSLv2,!SSLv3,!TLSv1;smtp_tls_protocols=!SSLv2,!SSLv3,!TLSv1}
    POSTFIX_RELAY_OUTBOUND_TLS_SETTINGS="smtp_tls_security_level=${POSTFIX_RELAY_OUTBOUND_TLS};${POSTFIX_RELAY_OUTBOUND_TLS_SETTINGS}"
  fi

  ########################################################################################################################
  # Validate and set sender based routing variables                                                                      #
  ########################################################################################################################
  LOOP_SUCCESS="true"

  while read -r POSTFIX_RELAY_SENDER_BASED_ROUTING_LINE; do
      [[ -z "${POSTFIX_RELAY_SENDER_BASED_ROUTING_LINE}" ]] && break

      VAR_SENDER="${POSTFIX_RELAY_SENDER_BASED_ROUTING_LINE}SENDER"
      if [ -z "${!VAR_SENDER}" ]; then
        echo "Empty environment variable ${VAR_SENDER}"
        LOOP_SUCCESS="false"
        break
      fi

      VAR_OUTBOUND_RELAY_HOST="${POSTFIX_RELAY_SENDER_BASED_ROUTING_LINE}HOST"
      if [ -z "${!VAR_OUTBOUND_RELAY_HOST}" ]; then
        echo "Empty environment variable ${VAR_OUTBOUND_RELAY_HOST}"
        LOOP_SUCCESS="false"
        break
      fi

      VAR_OUTBOUND_RELAY_USERNAME="${POSTFIX_RELAY_SENDER_BASED_ROUTING_LINE}USERNAME"
      if [ -z "${!VAR_OUTBOUND_RELAY_USERNAME}" ]; then
        echo "Empty environment variable ${VAR_OUTBOUND_RELAY_USERNAME}"
        LOOP_SUCCESS="false"
        break
      fi

      VAR_OUTBOUND_RELAY_PASSWORD="${POSTFIX_RELAY_SENDER_BASED_ROUTING_LINE}PASSWORD"
      if [ -z "${!VAR_OUTBOUND_RELAY_PASSWORD}" ]; then
        echo "Empty environment variable ${VAR_OUTBOUND_RELAY_PASSWORD}"
        LOOP_SUCCESS="false"
        break
      fi

  done <<< $(env | grep -E '^POSTFIX_RELAY_ADDITIONAL_OUTBOUND_RELAY_[0-9]{1,7}_DKIM' | awk -F_ '{print $1"_"$2"_"$3"_"$4"_"$5"_"$6"_"}' | uniq | sort -n)

  if [ "${LOOP_SUCCESS}" == "false" ]; then
    exit 1;
  fi

  ########################################################################################################################
  # Set DKIM variables                                                                                                   #
  ########################################################################################################################
  POSTFIX_RELAY_DKIM_MILTER_HOST=${POSTFIX_RELAY_DKIM_MILTER_HOST:-false}

  ########################################################################################################################
  # Display configuration                                                                                                #
  ########################################################################################################################
  CONFIG_OUTPUT="POSTFIX_RELAY_HOSTNAME:${POSTFIX_RELAY_HOSTNAME}"
  CONFIG_OUTPUT="${CONFIG_OUTPUT}\nPOSTFIX_RELAY_NETWORKS:${POSTFIX_RELAY_NETWORKS}"

  CONFIG_OUTPUT="${CONFIG_OUTPUT}\nPOSTFIX_RELAY_DEFAULT_OUTBOUND_RELAY_HOST:${POSTFIX_RELAY_DEFAULT_OUTBOUND_RELAY_HOST}"
  CONFIG_OUTPUT="${CONFIG_OUTPUT}\nPOSTFIX_RELAY_DEFAULT_OUTBOUND_RELAY_USERNAME:${POSTFIX_RELAY_DEFAULT_OUTBOUND_RELAY_USERNAME}"
  CONFIG_OUTPUT="${CONFIG_OUTPUT}\nPOSTFIX_RELAY_DEFAULT_OUTBOUND_RELAY_PASSWORD:********** (masked)"

  CONFIG_OUTPUT="${CONFIG_OUTPUT}\nPOSTFIX_RELAY_INBOUND_TLS:${POSTFIX_RELAY_INBOUND_TLS}"
  if [ "${POSTFIX_RELAY_INBOUND_TLS}" == "may" ] || [ "${POSTFIX_RELAY_INBOUND_TLS}" == "encrypt" ]; then
    CONFIG_OUTPUT="${CONFIG_OUTPUT}\nPOSTFIX_RELAY_INBOUND_TLS_CERTIFICATE:${POSTFIX_RELAY_INBOUND_TLS_CERTIFICATE}"
    CONFIG_OUTPUT="${CONFIG_OUTPUT}\nPOSTFIX_RELAY_INBOUND_TLS_KEY:********** (masked)"
    CONFIG_OUTPUT="${CONFIG_OUTPUT}\nPOSTFIX_RELAY_INBOUND_TLS_SETTINGS:${POSTFIX_RELAY_INBOUND_TLS_SETTINGS}"
  fi

  CONFIG_OUTPUT="${CONFIG_OUTPUT}\nPOSTFIX_RELAY_OUTBOUND_TLS:${POSTFIX_RELAY_OUTBOUND_TLS}"
  if [ "${POSTFIX_RELAY_OUTBOUND_TLS}" == "may" ] || [ "${POSTFIX_RELAY_OUTBOUND_TLS}" == "encrypt" ]; then
    CONFIG_OUTPUT="${CONFIG_OUTPUT}\nPOSTFIX_RELAY_OUTBOUND_TLS_SETTINGS:${POSTFIX_RELAY_OUTBOUND_TLS_SETTINGS}"
  fi

  while read -r POSTFIX_RELAY_SENDER_BASED_ROUTING_LINE; do
    [[ -z "${POSTFIX_RELAY_SENDER_BASED_ROUTING_LINE}" ]] && break

    VAR_SENDER="${POSTFIX_RELAY_SENDER_BASED_ROUTING_LINE}SENDER"
    VAR_OUTBOUND_RELAY_HOST="${POSTFIX_RELAY_SENDER_BASED_ROUTING_LINE}HOST"
    VAR_OUTBOUND_RELAY_USERNAME="${POSTFIX_RELAY_SENDER_BASED_ROUTING_LINE}USERNAME"
    VAR_OUTBOUND_RELAY_PASSWORD="${POSTFIX_RELAY_SENDER_BASED_ROUTING_LINE}PASSWORD"

    CONFIG_OUTPUT="${CONFIG_OUTPUT}\n${VAR_SENDER}:${!VAR_SENDER}"
    CONFIG_OUTPUT="${CONFIG_OUTPUT}\n${VAR_OUTBOUND_RELAY_HOST}:${!VAR_OUTBOUND_RELAY_HOST}"
    CONFIG_OUTPUT="${CONFIG_OUTPUT}\n${VAR_OUTBOUND_RELAY_USERNAME}:${!VAR_OUTBOUND_RELAY_USERNAME}"
    CONFIG_OUTPUT="${CONFIG_OUTPUT}\n${VAR_OUTBOUND_RELAY_PASSWORD}:********** (masked)"
  done <<< $(env | grep -E '^POSTFIX_RELAY_ADDITIONAL_OUTBOUND_RELAY_[0-9]{1,7}_DKIM' | awk -F_ '{print $1"_"$2"_"$3"_"$4"_"$5"_"$6"_"}' | uniq | sort -n)

  if [ "${POSTFIX_RELAY_DKIM_MILTER_HOST}" != "false" ]; then
    CONFIG_OUTPUT="${CONFIG_OUTPUT}\nPOSTFIX_RELAY_DKIM_MILTER_HOST:${POSTFIX_RELAY_DKIM_MILTER_HOST}"
  fi

  if [ ! -z "${POSTFIX_RELAY_CUSTOM_CONFIG}" ]; then
    CONFIG_OUTPUT="${CONFIG_OUTPUT}\nPOSTFIX_RELAY_CUSTOM_CONFIG:${POSTFIX_RELAY_CUSTOM_CONFIG}"
  fi

  echo "Running configuration:"
  echo -e "${CONFIG_OUTPUT}" | column -t -s ':' --table-columns C1,C2 --table-noheadings --table-wrap C2

  ########################################################################################################################
  # Create configuration                                                                                                 #
  ########################################################################################################################
  echo "${POSTFIX_RELAY_DEFAULT_OUTBOUND_RELAY_HOST} ${POSTFIX_RELAY_DEFAULT_OUTBOUND_RELAY_USERNAME}:${POSTFIX_RELAY_DEFAULT_OUTBOUND_RELAY_PASSWORD}" > /etc/postfix/sasl_passwd || exit 1

  while read -r POSTFIX_RELAY_SENDER_BASED_ROUTING_LINE; do
    [[ -z "${POSTFIX_RELAY_SENDER_BASED_ROUTING_LINE}" ]] && break

    VAR_SENDER="${POSTFIX_RELAY_SENDER_BASED_ROUTING_LINE}SENDER"
    VAR_OUTBOUND_RELAY_HOST="${POSTFIX_RELAY_SENDER_BASED_ROUTING_LINE}HOST"
    VAR_OUTBOUND_RELAY_USERNAME="${POSTFIX_RELAY_SENDER_BASED_ROUTING_LINE}USERNAME"
    VAR_OUTBOUND_RELAY_PASSWORD="${POSTFIX_RELAY_SENDER_BASED_ROUTING_LINE}PASSWORD"

    echo "${!VAR_OUTBOUND_RELAY_HOST} ${!VAR_OUTBOUND_RELAY_USERNAME}:${!VAR_OUTBOUND_RELAY_PASSWORD}" >> /etc/postfix/sasl_passwd || exit 1
    echo "${!VAR_SENDER} ${!VAR_OUTBOUND_RELAY_HOST}" >> /etc/postfix/relay_map || exit 1
  done <<< $(env | grep -E '^POSTFIX_RELAY_ADDITIONAL_OUTBOUND_RELAY_[0-9]{1,7}_DKIM' | awk -F_ '{print $1"_"$2"_"$3"_"$4"_"$5"_"$6"_"}' | uniq | sort -n)

  postmap /etc/postfix/sasl_passwd || exit 1

  if [ -f /etc/postfix/relay_map ]; then
    postmap /etc/postfix/relay_map || exit 1
    postconf 'sender_dependent_relayhost_maps = lmdb:/etc/postfix/relay_map' || exit 1
    postconf 'smtp_sender_dependent_authentication = yes' || exit 1
  fi

  # Set configurations
  postconf "maillog_file=/dev/stdout" || exit 1
  postconf 'smtp_sasl_auth_enable = yes' || exit 1
  postconf 'smtp_sasl_password_maps = lmdb:/etc/postfix/sasl_passwd' || exit 1
  postconf 'smtp_sasl_security_options = noanonymous' || exit 1
  postconf 'smtpd_tls_CAfile = /etc/ssl/certs/ca-certificates.crt' || exit 1
  postconf "relayhost = ${POSTFIX_RELAY_DEFAULT_OUTBOUND_RELAY_HOST}" || exit 1
  postconf "myhostname = ${POSTFIX_RELAY_HOSTNAME}" || exit 1
  postconf "mynetworks = ${POSTFIX_RELAY_NETWORKS}" || exit 1

  # http://www.postfix.org/COMPATIBILITY_README.html#smtputf8_enable
  postconf 'smtputf8_enable = no' || exit 1

  # This makes sure the message id is set. If this is set to no dkim=fail will happen.
  postconf 'always_add_missing_headers = yes' || exit 1

  if [ "${POSTFIX_RELAY_INBOUND_TLS}" == "may" ] || [ "${POSTFIX_RELAY_INBOUND_TLS}" == "encrypt" ]; then
    echo "${POSTFIX_RELAY_INBOUND_TLS_CERTIFICATE}" | base64 -d > /etc/postfix/inbound_certificate.crt
    echo "${POSTFIX_RELAY_INBOUND_TLS_KEY}" | base64 -d > /etc/postfix/inbound_certificate.key

    postconf 'smtpd_tls_cert_file=/etc/postfix/inbound_certificate.crt'
    postconf 'smtpd_tls_key_file=/etc/postfix/inbound_certificate.key'

    OLD_IFS=${IFS}
    IFS=';'
    for f in ${POSTFIX_RELAY_INBOUND_TLS_SETTINGS}; do
        f=$(echo "$f" | tr -d ' ')
        postconf "$f" || exit 1
    done
    IFS=${OLD_IFS}
  fi

  if [ "${POSTFIX_RELAY_OUTBOUND_TLS}" == "may" ] || [ "${POSTFIX_RELAY_OUTBOUND_TLS}" == "encrypt" ]; then
    OLD_IFS=${IFS}
    IFS=';'
    for f in ${POSTFIX_RELAY_OUTBOUND_TLS_SETTINGS}; do
        f=$(echo "$f" | tr -d ' ')
        postconf "$f" || exit 1
    done
    IFS=${OLD_IFS}
  fi

  if [ "${POSTFIX_RELAY_DKIM_MILTER_HOST}" != "false" ]; then
    postconf "milter_default_action=accept" || exit 1
    postconf "milter_protocol=6" || exit 1
    postconf "smtpd_milters=inet:${POSTFIX_RELAY_DKIM_MILTER_HOST}:8891" || exit 1
    postconf "non_smtpd_milters=inet:${POSTFIX_RELAY_DKIM_MILTER_HOST}:8891" || exit 1
  fi

  if [ -n "${POSTFIX_RELAY_CUSTOM_CONFIG}" ]; then
      OLD_IFS=${IFS}
      IFS=';'
      for f in ${POSTFIX_RELAY_CUSTOM_CONFIG}; do
          f=$(echo "$f" | tr -d ' ')
          postconf "$f" || exit 1
      done
      IFS=${OLD_IFS}
  fi
}

if [ "$1" = 'postfix' ]; then
  create_config
  echo "Starting the postfix service:"
  exec "$@"
fi

exec "$@"
