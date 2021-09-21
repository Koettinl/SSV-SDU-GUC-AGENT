#!/bin/bash

DIRPATH=/home/pi/sdu_guc_ssv/key_material

export SDU_SERVER_URL=https://ssvdev-sdu0.ssv-service.de

export SDU_SERVER_CA=$DIRPATH/ssv-server-pki.crt.pem
export SDU_SERVER_CLIENT_CRT=$DIRPATH/000002112000001.crt.pem
export SDU_SERVER_CLIENT_KEY=$DIRPATH/000002112000001.key.pem
export SDU_MAINTENANCE_CA=$DIRPATH/maintenance-ca.crt.pem

echo guc_sdu update environment succsesfull!!!