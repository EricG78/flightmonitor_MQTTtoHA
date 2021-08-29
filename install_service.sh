#!/bin/bash


#Copyright © 2021 Eric Georgeaux (eric.georgeaux at gmail.com)

# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), 
# to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 
# copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, 
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


# Echo usage if something isn't right.
usage() {
    echo -e "Usage: sudo bash $0  [-t rate_s] [-h]\n\n\
-t rate_s: rate_s shall be a numeric value. It defines the periodicity of the publishing of MQTT status messages (default value is 60s)
-h display this help"  1>&2; exit 1;
}

# Check the script is ran with root priviledge
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

# Check if the default value is overwritten by argument -t
update_rate=60
while getopts ":t:h" o; do
	case "${o}" in
	t)
		update_rate=${OPTARG}
		if [ -n "$update_rate" ] && [ "$update_rate" -eq "$update_rate" ] 2>/dev/null; then
			echo "Update rate: $update_rate seconds"
		else
			echo "Argument after -t shall be a number (update rate in seconds)"
			usage
		fi
		;;
	h)
		usage
		;;
	:)
		echo "ERROR: Option -$OPTARG requires an argument"
		usage
		;;
	\?)
		echo "ERROR: Invalid option -$OPTARG"
		usage
		;;
	esac
done
shift $((OPTIND-1))

# Check dependancies
dl_jq=`[ -z "$(which jq)" ] && echo "jq"`
dl_bc=`[ -z "$(which bc)" ] && echo "bc"`
dl_curl=`[ -z "$(which curl)" ] && echo "curl"`
dl_mosquitto=`[ -z "$(which mosquitto_pub)" ] && echo "mosquitto-clients"`
apt_arg="$dl_jq $dl_bc $dl_curl $dl_mosquitto"

if [ ${#apt_arg} -gt 3 ]; then
        apt-get install $apt_arg
fi

scriptName="flightmonitor_MQTTtoHA"

# Find bash location
bashPath="/bin/bash"
if [ ! -f $bashPath ]; then
        bashPath=$(which bash)
        echo "bash found by which command: $bashPath"
fi
if [ -z bashPath ]; then
        echo "Error: Unable to find bash"
        exit
fi

# Check the location of the script
scriptPath="$(pwd)/$scriptName.sh"
if [ ! -f $scriptPath ]; then
        echo "Error: unable to find $scriptName.sh in the current directory."
        exit
fi

# Full command line
execCmdLine="$bashPath $scriptPath -d yes -r loop -t $update_rate"

# Find user behind sudo
user=$(who am i | awk '{print $1}')

# Create service file
tempFileName="$(cat /dev/urandom | tr -cd 'a-f0-9' | head -c 16).service"
echo -e "\
[Unit]\n\
Description=Service to send through MQTT FR24feed, dump1090 and piAware information to Home Assistant\n \
After=network.target\n\n\
[Service]\n\
Type=simple\n\
User=$user\n\
Group=$user\n\
ExecStart=$execCmdLine\n\
Restart=always\n\
RestartSec=30\n\n\
[Install]\n\
WantedBy=default.target" >> $tempFileName

# Copy to the systemd directory
cp $tempFileName /etc/systemd/system/$scriptName.service

# Delete temp file
rm $tempFileName

# Enable and start the service
systemctl daemon-reload
systemctl enable $scriptName.service
systemctl start $scriptName.service
systemctl status $scriptName.service
