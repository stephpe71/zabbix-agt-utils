#!/usr/bin/env bash
# ==================================================================================================================================
# Script de recuperation/check des dates d'expiration licenses et certifs via API
# licences/certificate expiration check on $ip (via API /metrics/rich)
# Auteur:       Stéphane Perrot
# Date:         February 2023
# 
# DISCLAIMER: 	provided as EXAMPLE ONLY, obviously very specific to the api requested
#               intended to show it quite easy to request a value and
# 				to check in a standalone fashion (complentary to the whole package)
# 
# ==================================================================================================================================
ALERT_THRESHOLD=60
TMPFILE=/tmp/tmp$$.json
VERSION="0.9 08-02-2023"

# ==================================================================================================================================
function usage {
  echo "$PROGNAME: usage: $PRGNAME <ip-or-host<"
}
  
# ==================================================================================================================================
PROGNAME=$(basename $0)
# Main section

#[[ -z $1 ]] && usage && exit 0

ip=$1

echo
echo "## licences/certificate expiration check on $ip (via API /metrics/rich)"
curl -s -k "https://${ip}:8443/metrics/rich" > $TMPFILE

# 1) Licence get & check
echo

licence_expiry_ndays=$(cat $TMPFILE | jq  '.[] | select (.definition.name == "pulse.license.expiry") | .metric.value')
date_licence_expiry=$(date --date="now + $licence_expiry_ndays days")
echo "License expiration: $date_licence_expiry"
[[ $licence_expiry_ndays -lt $ALERT_THRESHOLD ]] && echo "# Attention : expiration de la licence dans moins de $licence_expiry_ndays jours !..."

# 2) Certificate get & check

echo
cert_expiry_ndays=$(   cat $TMPFILE| jq  '.[] | select (.definition.name == "pulse.certificates.expiry") | .metric.metrics[].value')
#echo cert_expiry_ndays=$cert_expiry_ndays
date_cert_expiry=$(   date --date="now + $cert_expiry_ndays days")
echo "Certificat(s) expiration: $date_cert_expiry"
[[ $licence_expiry_ndays -lt $ALERT_THRESHOLD ]] && echo "# Attention : expiration du certificat dans moins de $cert_expiry_ndays jours !..."

# Cleanup
rm -f $TMPFILE

echo
