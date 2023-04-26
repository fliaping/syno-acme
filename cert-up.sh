#!/bin/bash

export ACME_EAB_KID=""
export ACME_EAB_HMAC_KEY=""
export DOMAIN=
export DNS=dns_dp
export DNS_SLEEP=120
export DP_Id=""
export DP_Key=""

# export SYNO_Scheme="http" # Can be set to HTTPS, defaults to HTTP
# export SYNO_Hostname="localhost" # Specify if not using on localhost
# export SYNO_Port="5000" # Port of DSM WebUI, defaults to 5000 for HTTP and 5001 for HTTPS
export SYNO_Username="DSM_Admin_Username"
export SYNO_Password="DSM_Admin_Password"
export SYNO_Certificate="acme.sh certificate" # Description text in Control Panel -> Security -> Certificates
# export SYNO_Create=1 # defaults to off, this setting is not saved.  By setting to 1 we create the certificate if it's not in DSM
export SYNO_DID=


set -e

export NO_DETECT_SH=1

# path of this script
BASE_ROOT=$(cd "$(dirname "$0")";pwd)
# base crt path
CRT_BASE_PATH="/usr/syno/etc/certificate"
PKG_CRT_BASE_PATH="/usr/local/etc/certificate"
ACME_BIN_PATH=${BASE_ROOT}/acme.sh
TEMP_PATH=${BASE_ROOT}/temp
CRT_PATH_NAME=`cat ${CRT_BASE_PATH}/_archive/DEFAULT`
CRT_PATH=${CRT_BASE_PATH}/_archive/${CRT_PATH_NAME}

installAcme () {
  echo 'begin installAcme'
  mkdir -p ${TEMP_PATH}
  cd ${TEMP_PATH}
  echo 'begin downloading acme.sh tool...'
  ACME_SH_ADDRESS='https://ghproxy.com/https://github.com/acmesh-official/acme.sh/archive/refs/heads/master.tar.gz'
  SRC_TAR_NAME=acme.sh.tar.gz
  curl -L -o ${SRC_TAR_NAME} ${ACME_SH_ADDRESS}
  SRC_NAME=`tar -tzf ${SRC_TAR_NAME} | head -1 | cut -f1 -d"/"`
  tar zxvf ${SRC_TAR_NAME}
  echo 'begin installing acme.sh tool...'
  cd ${SRC_NAME}
  ./acme.sh --install --nocron --no-profile --home ${ACME_BIN_PATH}
  echo 'done installAcme'
  rm -rf ${TEMP_PATH}
  return 0
}

generateCrt () {
  echo 'begin generateCrt'
  cd ${BASE_ROOT}
  echo 'begin updating default cert by acme.sh tool'
  ${ACME_BIN_PATH}/acme.sh --home ${ACME_BIN_PATH} --register-account --server zerossl --eab-kid "${ACME_EAB_KID}" --eab-hmac-key "${ACME_EAB_HMAC_KEY}" 
  ${ACME_BIN_PATH}/acme.sh --home ${ACME_BIN_PATH} --force --log --issue --dns ${DNS} --dnssleep ${DNS_SLEEP} -d "${DOMAIN}" -d "*.${DOMAIN}" --server zerossl
  # ${ACME_BIN_PATH}/acme.sh --home ${ACME_BIN_PATH} --installcert -d ${DOMAIN} -d *.${DOMAIN} \
  #   --certpath ${CRT_PATH}/cert.pem \
  #   --key-file ${CRT_PATH}/privkey.pem \
  #   --fullchain-file ${CRT_PATH}/fullchain.pem
  echo 'done generateCrt'
  # if [ -s "${CRT_PATH}/cert.pem" ]; then
  #   echo 'done generateCrt'
  #   return 0
  # else
  #   echo '[ERR] fail to generateCrt'
  #   exit 1;
  # fi
}

deployCrt () {
  echo 'begin deployCrt'
  ${ACME_BIN_PATH}/acme.sh --home ${ACME_BIN_PATH} --deploy -d "${DOMAIN}" -d "*.${DOMAIN}" --deploy-hook synology_dsm"
  echo 'end deployCrt'
}

# updateService () {
#   echo 'begin updateService'
#   echo 'cp cert path to des'
#   /bin/python3 ${BASE_ROOT}/crt_cp.py ${CRT_PATH_NAME}
#   echo 'done updateService'
# }

# reloadWebService () {
#   echo 'begin reloadWebService'
#   echo 'reloading new cert...'
#   /usr/syno/bin/synow3tool --gen-all && /bin/systemctl reload nginx
#   echo 'done reloadWebService'
# }

echo '------ begin updateCrt ------'
installAcme
generateCrt
deployCrt
# updateService
# reloadWebService
echo '------ end updateCrt ------'
