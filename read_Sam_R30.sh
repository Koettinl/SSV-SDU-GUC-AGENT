#!/bin/bash

# Autor: LKO
# part of SDU GUC testing system
# this programm reads the input on specified pins to verify the updates installed on the sam r30

# variables
filePath="/home/pi/sdu_guc_ssv/clients/sam-r30"
# time and date for the logfile
logString="$(date -u)"
# variables to see what firmware i used
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
else logString+="	1 No Firmware detected, starting with fwLedGreen!" 
    echo $logString #>> $filePath/sam-r30_fwUpdate_logfile.txt 
    currentFw="none"
fi

# decide wich update should be installed or if an error occured
if [ $currentFw != $fwLedGreen -a $previousFw != $currentFw -o $currentFw = "none" ]
then logString+="	1 Set update to fwLedGreen"
# write into Logfile
    echo $logString >> $filePath/sam-r30_fwUpdate_logfile.txt
    echo 1
    # call function to update firmware fwLedGreen
    $filePath/3-set-current-version.sh fwLedGreen
    
elif [ $currentFw != $fwLedRed -a $previousFw != $currentFw ]
then logString+="	2 Set update to fwLedRed" 
    echo $logString >> $filePath/sam-r30_fwUpdate_logfile.txt
    echo 2
    $filePath/3-set-current-version.sh fwLedRed

else logstring+="	3 Error occured, current Firmware update is Current firmware, try again"
    echo $logstring >> $filePath/sam-r30_fwUpdate_logfile.txt
    echo 3
fi