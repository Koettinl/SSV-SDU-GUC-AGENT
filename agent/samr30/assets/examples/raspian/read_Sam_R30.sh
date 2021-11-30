#!/bin/bash

# Autor: LKO
# part of SDU GUC testing system
# this programm reads the input on specified pins to verify the updates installed on the sam r30

# variables
FILEPATH="/home/pi/SSV-SDU-GUC-AGENT/agent/samr30/assets/examples/raspian"
LOGFILE="logfile_samr30_fw-update.txt"

# time and date for the logfile
logString="$(date +"%Y-%m-%d %H:%M:%S")"
# variables to see what firmware is used
fwLedRed="fwLedRed"
fwLedGreen="fwLedGreen"
currentFw="none"
previousFw="none"
# used pins on the Raspberry Pi 
pin23=0
pin24=0

# routine to verify if update process was succsesfull
# combination of pin is read out 
# pin 23=1 and pin 24=0 --> fwLedGreen is installed
# pin 23=0 and pin 24=1 --> fwLedRed is installed

pin23=$(gpioget 0 23)
pin24=$(gpioget 0 24)
# echo $pin23
# echo $pin24

# read pins and specify firmware
if [[ $pin23 -eq 1 && $pin24 -eq 0 ]]
then echo fwLedGreen is installed!
    previousFw=currentFw
    currentFw=fwLedGreen

elif [[ $pin23 -eq 0 && $pin24 -eq 1 ]]
then echo fwLedRed is installed!
    previousFw=currentFw
    currentFw=fwLedRed
# no firmware, write text into Logfile
else logString+="	1 No Firmware detected[Pin Err], starting with fwLedGreen!" 
    echo $logString #>> $FILEPATH/$LOGFILE
    currentFw="none"
fi

# decide wich update should be installed or if an error occured
if [ $currentFw != $fwLedGreen -a $previousFw != $currentFw -o $currentFw = "none" ]
then logString+="	1 Set update to fwLedGreen"
# write into Logfile
    echo $logString >> $FILEPATH/$LOGFILE
    echo 1
    # call function to update firmware fwLedGreen
    $FILEPATH/3-set-current-version.sh fwLedGreen
    
elif [ $currentFw != $fwLedRed -a $previousFw != $currentFw ]
then logString+="	2 Set update to fwLedRed" 
    echo $logString >> $FILEPATH/$LOGFILE
    echo 2
    $FILEPATH/3-set-current-version.sh fwLedRed

else logstring+="	3 Error occured, current firmware update is Current firmware, try again"
    echo $logstring >> $FILEPATH/$LOGFILE
    echo 3
fi