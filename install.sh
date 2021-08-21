#!/bin/bash

# Check the script is ran with root priviledge
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

scriptName="flightmonitor_MQTTtoHA"

# Find bash location
bashPath="/bin/bash"
if [[ ! -f $bashPath ]]; then
        bashPath=$(which bash)
        echo "bash found by which command: $bashPath"
fi
if [[ -z bashPath ]]; then
        echo "Error: Unable to find bash"
        exit
fi

# Check the location of the script
scriptPath="$(pwd)/$scriptName.sh"
if [[ ! -f $scriptPath ]]; then
        echo "Error: unable to find $scriptName.sh in the current directory."
        exit
fi

# Full command line
execCmdLine="$bashPath $scriptPath"

# Find user behind sudo
user=$(who am i | awk '{print $1}')

# Create service file
tempFileName="$(cat /dev/urandom | tr -cd 'a-f0-9' | head -c 16).service"
echo -e "\
[Unit]\n \
Description=Service to send through MQTT FR24feed, dump1090 and piAware information to Home Assistant\n \
After=network.target\n\n \
[Service]\n \
Type=simple\n \
User=$user\n \
ExecStart=$execCmdLine\n \
Restart=always\n \
RestartSec=30\n\n \
[Install]\n \
WantedBy=user.target" >> $tempFileName

# Copy to the systemd directory
cp $tempFileName /etc/systemd/system/$scriptName.service

# Delete temp file
rm $tempFileName

# Enable and start the service
systemctl daemon-reload
systemctl enable $scriptName.service
systemctl start $scriptName.service
systemctl status $scriptName.service
