#!/bin/bash

FILEPATH=/home/pi/SSV-SDU-GUC-AGENT

# call updateclient for dummy agent
#	[path to GUC | path to used agent]
$FILEPATH/guc/app/guc_sdu/guc_sdu-update.sh $FILEPATH/agent/samr30/agent_samr30_sdu-agent-samr30.sh

# call read_Sam_R30.sh to create a logfile
#	~/gpio_testing
$FILEPATH/agent/samr30/assets/examples/raspian/read_Sam_R30.sh