#!/bin/bash

# path to where the Keymaterial is saved
FILEPATH=/home/pi/SSV-SDU-GUC-AGENT/guc/assets/key_material

# used Environment variables
export SDU_SERVER_URL=https://ssvdev-sdu0.ssv-service.de

export SDU_SERVER_CA=$FILEPATH/ssv-server-pki.crt.pem
export SDU_SERVER_CLIENT_CRT=$FILEPATH/000002112000001.crt.pem
export SDU_SERVER_CLIENT_KEY=$FILEPATH/000002112000001.key.pem
export SDU_MAINTENANCE_CA=$FILEPATH/maintenance-ca.crt.pem

echo guc_sdu update environment succsesfull!!!