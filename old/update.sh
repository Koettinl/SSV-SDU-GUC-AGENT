#!/bin/bash

Filepath=/home/pi/sdu_guc_ssv

# call updateclient for dummy agent
#	[path to GUC | path to used agent]
$Filepath/agents/guc_sdu-update.sh $Filepath/agents/agent_dummy_sdu-agent-dummy.sh

# call read_Sam_R30.sh to create a logfile
#	~/gpio_testing
$Filepath/clients/sam-r30/read_Sam_R30.sh