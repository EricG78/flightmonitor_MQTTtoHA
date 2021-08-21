#!/bin/bash

#Copyright © 2021 Eric Georgeaux (eric.geprgeaux at gmail.com)

# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), 
# to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 
# copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, 
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


######################################
# Start of the configuration section #
######################################
# Connection to MQTT broker
mqtt_broker_ip="192.168.0.1"
#mqtt_broker_port=1883
#user="user"
#pwd="pwd"

# Topics for the JSON messages
mqtt_topic_prefix="flightmonitor"
fr24feed_subtopic="fr24feed"
dump1090_subtopic="dump1090"
piaware_subtopic="piaware"

# Delay between messages (in seconds)
update_rate=60

# Discovery prefix for Home Assistant (defualt is homeassistant. See https://www.home-assistant.io/docs/mqtt/discovery/
discovery_prefix="homeassistant"
# In case several computers with 1090MHz receiver sent their data to the same instance of Home Assistant
unique_id_suffix="_RasPi"

####################################
# End of the configuration section #
####################################

# Arguments for mosquitto_pub calls
mosquittoArgs="`[ ! -z $mqtt_broker_ip ] && echo "-h $mqtt_broker_ip" || echo "-h localhost"` `[ ! -z $user ] && echo "-u $user -P $pwd"` `[ ! -z $port ] && echo "-p $port" || echo "-p 1883"`"

# Publish Home assistant MQTT discovery messages for FR24feed
fr24feedHADiscovery() {
	local topiclist=()
	local msglist=()
	# Status fr24feed
	local unique_id="fr24feed_problem$unique_id_suffix"
	topiclist+=("$discovery_prefix/binary_sensor/$unique_id/config")
	msglist+=("{\"name\":\"FR24feed status\",\"unique_id\":\"$unique_id\",\"device_class\":\"problem\",\"~\":\"$mqtt_topic_prefix/$fr24feed_subtopic\",\"availability_topic\":\"~/status\",\"state_topic\":\"~\",\"value_template\":\"{{value_json.problem}}\"}")
	# Connectivity to FR24
	unique_id="fr24feed_connect$unique_id_suffix"
	topiclist+=("$discovery_prefix/binary_sensor/$unique_id/config")
	msglist+=("{\"name\":\"Connection to FR24\",\"unique_id\":\"$unique_id\",\"device_class\":\"connectivity\",\"~\":\"$mqtt_topic_prefix/$fr24feed_subtopic\",\"availability_topic\":\"~/status\",\"state_topic\":\"~\",\"value_template\":\"{{value_json.connection}}\"}")
	# Status MLAT
	local unique_id="fr24feed_pbMLAT$unique_id_suffix"
	topiclist+=("$discovery_prefix/binary_sensor/$unique_id/config")
	msglist+=("{\"name\":\"FR24feed MLAT status\",\"unique_id\":\"$unique_id\",\"device_class\":\"problem\",\"~\":\"$mqtt_topic_prefix/$fr24feed_subtopic\",\"availability_topic\":\"~/status\",\"state_topic\":\"~\",\"value_template\":\"{{value_json.mlat_problem}}\"}")
	# Aircraft tracked
	local unique_id="fr24feed_actracked$unique_id_suffix"
	topiclist+=("$discovery_prefix/sensor/$unique_id/config")
	msglist+=("{\"name\":\"Aircraft Tracked\",\"unique_id\":\"$unique_id\",\"icon\":\"mdi:airplane\",\"unit_of_measurement\":\"aircraft(s)\",\"~\":\"$mqtt_topic_prefix/$fr24feed_subtopic\",\"availability_topic\":\"~/status\",\"state_topic\":\"~\",\"value_template\":\"{{value_json.numACtracked}}\"}")
	# Aircraft uploaded
	local unique_id="fr24feed_acuploaded$unique_id_suffix"
	topiclist+=("$discovery_prefix/sensor/$unique_id/config")
	msglist+=("{\"name\":\"Aircraft Uploaded\",\"unique_id\":\"$unique_id\",\"icon\":\"mdi:airplane\",\"unit_of_measurement\":\"aircraft(s)\",\"~\":\"$mqtt_topic_prefix/$fr24feed_subtopic\",\"availability_topic\":\"~/status\",\"state_topic\":\"~\",\"value_template\":\"{{value_json.numACuploaded}}\"}")
	# Last transmission to FR24
	local unique_id="fr24feed_lasttx$unique_id_suffix"
	topiclist+=("$discovery_prefix/sensor/$unique_id/config")
	msglist+=("{\"name\":\"Last transmission to FR24\",\"unique_id\":\"$unique_id\",\"icon\":\"mdi:clock\",\"unit_of_measurement\":\"s\",\"~\":\"$mqtt_topic_prefix/$fr24feed_subtopic\",\"availability_topic\":\"~/status\",\"state_topic\":\"~\",\"value_template\":\"{{value_json.lastACsent}}\"}")
	for index in ${!topiclist[@]}; do
		cmd="mosquitto_pub $mosquittoArgs -r -t ${topiclist[$index]} -m '${msglist[$index]}'"
		eval "$cmd"
	done
	mosquitto_pub $mosquittoArgs -r -t $mqtt_topic_prefix/$fr24feed_subtopic/status -m "online"
}

# Publish Home assistant MQTT discovery messages for dump1090-fa
dump1090HADiscovery() {
	local topiclist=()
	local msglist=()
	# Status dump1090
	local unique_id="dump1090_problem$unique_id_suffix"
	topiclist+=("$discovery_prefix/binary_sensor/$unique_id/config")
	msglist+=("{\"name\":\"dump1090 status\",\"unique_id\":\"$unique_id\",\"device_class\":\"problem\",\"~\":\"$mqtt_topic_prefix/$dump1090_subtopic\",\"availability_topic\":\"~/status\",\"state_topic\":\"~\",\"value_template\":\"{{value_json.problem}}\"}")
	# Total aircraft
	local unique_id="dump1090_totalac$unique_id_suffix"
	topiclist+=("$discovery_prefix/sensor/$unique_id/config")
	msglist+=("{\"name\":\"Total Aircraft\",\"unique_id\":\"$unique_id\",\"icon\":\"mdi:airplane\",\"unit_of_measurement\":\"aircraft(s)\",\"~\":\"$mqtt_topic_prefix/$dump1090_subtopic\",\"availability_topic\":\"~/status\",\"state_topic\":\"~\",\"value_template\":\"{{value_json.total_aircraft}}\"}")
	# Aircraft with positions
	local unique_id="dump1090_acwithpos$unique_id_suffix"
	topiclist+=("$discovery_prefix/sensor/$unique_id/config")
	msglist+=("{\"name\":\"Aircrafts with positions\",\"unique_id\":\"$unique_id\",\"icon\":\"mdi:airplane\",\"unit_of_measurement\":\"aircraft(s)\",\"~\":\"$mqtt_topic_prefix/$dump1090_subtopic\",\"availability_topic\":\"~/status\",\"state_topic\":\"~\",\"value_template\":\"{{value_json.aircraft_with_positions}}\"}")
	for index in ${!topiclist[@]}; do
		cmd="mosquitto_pub $mosquittoArgs -r -t ${topiclist[$index]} -m '${msglist[$index]}'"
		eval "$cmd"
	done
	mosquitto_pub $mosquittoArgs -r -t $mqtt_topic_prefix/$dump1090_subtopic/status -m "online"
}

# Publish Home assistant MQTT discovery messages for piaware
piawareHADiscovery() {
	local topiclist=()
	local msglist=()
	# Status piaware
	local unique_id="piaware_problem$unique_id_suffix"
	topiclist+=("$discovery_prefix/binary_sensor/$unique_id/config")
	msglist+=("{\"name\":\"piaware status\",\"unique_id\":\"$unique_id\",\"device_class\":\"problem\",\"~\":\"$mqtt_topic_prefix/$piaware_subtopic\",\"availability_topic\":\"~/status\",\"state_topic\":\"~\",\"value_template\":\"{{value_json.piaware_problem}}\"}")
	# Status faup1090
	local unique_id="piaware_faup1090_problem$unique_id_suffix"
	topiclist+=("$discovery_prefix/binary_sensor/$unique_id/config")
	msglist+=("{\"name\":\"faup1090 status\",\"unique_id\":\"$unique_id\",\"device_class\":\"problem\",\"~\":\"$mqtt_topic_prefix/$piaware_subtopic\",\"availability_topic\":\"~/status\",\"state_topic\":\"~\",\"value_template\":\"{{value_json.faup1090_problem}}\"}")
	# Status faup978
	local unique_id="piaware_faup978_problem$unique_id_suffix"
	topiclist+=("$discovery_prefix/binary_sensor/$unique_id/config")
	msglist+=("{\"name\":\"faup978 status\",\"unique_id\":\"$unique_id\",\"device_class\":\"problem\",\"~\":\"$mqtt_topic_prefix/$piaware_subtopic\",\"availability_topic\":\"~/status\",\"state_topic\":\"~\",\"value_template\":\"{{value_json.faup978_problem}}\"}")
	# Status mlat
	local unique_id="piaware_mlat_problem$unique_id_suffix"
	topiclist+=("$discovery_prefix/binary_sensor/$unique_id/config")
	msglist+=("{\"name\":\"Piaware MLAT status\",\"unique_id\":\"$unique_id\",\"device_class\":\"problem\",\"~\":\"$mqtt_topic_prefix/$piaware_subtopic\",\"availability_topic\":\"~/status\",\"state_topic\":\"~\",\"value_template\":\"{{value_json.mlat_problem}}\"}")
	# Status dump1090
	local unique_id="piaware_dump1090_problem$unique_id_suffix"
	topiclist+=("$discovery_prefix/binary_sensor/$unique_id/config")
	msglist+=("{\"name\":\"Piaware dump1090 status\",\"unique_id\":\"$unique_id\",\"device_class\":\"problem\",\"~\":\"$mqtt_topic_prefix/$piaware_subtopic\",\"availability_topic\":\"~/status\",\"state_topic\":\"~\",\"value_template\":\"{{value_json.dump1090_problem}}\"}")
	# Status data on port 3005
	local unique_id="piaware_data3005_problem$unique_id_suffix"
	topiclist+=("$discovery_prefix/binary_sensor/$unique_id/config")
	msglist+=("{\"name\":\"Data on port 3005\",\"unique_id\":\"$unique_id\",\"device_class\":\"problem\",\"~\":\"$mqtt_topic_prefix/$piaware_subtopic\",\"availability_topic\":\"~/status\",\"state_topic\":\"~\",\"value_template\":\"{{value_json.data3005_problem}}\"}")
	# Connectivity between faup1090 and dump1090
	unique_id="piaware_faupdump_connect$unique_id_suffix"
	topiclist+=("$discovery_prefix/binary_sensor/$unique_id/config")
	msglist+=("{\"name\":\"Connection faup1090-dump1090\",\"unique_id\":\"$unique_id\",\"device_class\":\"connectivity\",\"~\":\"$mqtt_topic_prefix/$piaware_subtopic\",\"availability_topic\":\"~/status\",\"state_topic\":\"~\",\"value_template\":\"{{value_json.faup1090dump1090_connection}}\"}")
	# Connectivity between piaware and the server
	unique_id="piaware_server_connect$unique_id_suffix"
	topiclist+=("$discovery_prefix/binary_sensor/$unique_id/config")
	msglist+=("{\"name\":\"Connection to flightaware.com\",\"unique_id\":\"$unique_id\",\"device_class\":\"connectivity\",\"~\":\"$mqtt_topic_prefix/$piaware_subtopic\",\"availability_topic\":\"~/status\",\"state_topic\":\"~\",\"value_template\":\"{{value_json.piawareserver_connection}}\"}")
	for index in ${!topiclist[@]}; do
		cmd="mosquitto_pub $mosquittoArgs -r -t ${topiclist[$index]} -m '${msglist[$index]}'"
		eval "$cmd"
	done
	mosquitto_pub $mosquittoArgs -r -t $mqtt_topic_prefix/$piaware_subtopic/status -m "online"
}

# Publish Home assistant MQTT discovery messages
pubHAdiscoveryMsg() {
	if [[ ! -z $fr24feed_subtopic ]]; then
		fr24feedHADiscovery
	fi
	if [[ ! -z $dump1090_subtopic ]]; then
		dump1090HADiscovery
	fi
	if [[ ! -z $piaware_subtopic ]]; then
		piawareHADiscovery
	fi
}


# Retreive fr24feed information by parsing monitor.json
fr24feedUpdate() {
	monitor=$(curl -s http://127.0.0.1:8754/monitor.json)
	if [ -z monitor ]; then
		fr24feedProblem="ON"
		timeSinceLastACSent="n/a"
		numACTracked = 0
		numACUploaded = 0
	else
		fr24feedProblem="OFF"
		fr24feedStatus=$(echo $monitor | jq '.feed_status' | sed 's/connected/ON/i' | sed '/ON/!s/.*/OFF/')
		fr24feedMLAT=$(echo $monitor | jq '."mlat-ok"' | sed 's/yes/OFF/i' | sed '/OFF/!s/.*/ON/')
		timeSinceLastACSent=$(echo $(date '+%s') - $(echo $monitor | jq '.feed_last_ac_sent_time | tonumber') | bc)
		numACTracked=$(echo $monitor | jq '.d11_map_size')
		numACUploaded=$(echo $monitor | jq '.feed_num_ac_tracked')
	fi
	fr24feedMsg="{\"problem\":\"$fr24feedProblem\", \
	              \"connection\":$fr24feedStatus, \
	              \"mlat_problem\": $fr24feedMLAT, \
	              \"lastACsent\":$timeSinceLastACSent, \
	              \"numACtracked\":$numACTracked, \
	              \"numACuploaded\":$numACUploaded}"
}

# Extract information from aircraft.json file produced by dump1090-fa
dump1090Update() {
	if [ ! -f /run/dump1090-fa/aircraft.json ]; then
		dump1090Problem="ON"
		totalAircraft=0
		aircraftWithPositions=0
	else
		dump1090Problem="OFF"
		# Total number of aircrafts, as displayed in PiAware SkyAware page
		totalAircraft=$(cat /run/dump1090-fa/aircraft.json | jq '[.aircraft[] | select(.seen < 58)] | length')

		# Number of aircrafts with positions, as displayed in PiAware SkyAware page
		aircraftWithPositions=$(cat /run/dump1090-fa/aircraft.json | jq '[.aircraft[] | select(.seen < 58 and has("lat") and has("lon") and .seen_pos < 60)] | length')
	fi
	dump1090Msg="{\"problem\":\"$dump1090Problem\", \
	              \"total_aircraft\":$totalAircraft, \
	              \"aircraft_with_positions\":$aircraftWithPositions}"
}

# Parse the output of command piaware-status
piawareUpdate() {
	piaware=$(piaware-status)
	#echo -e "$piaware"
	lines=()
	while IFS= read -r line;do
		lines+=("$line")
	done <<< $piaware

	# piaware status
	run=`expr match "${lines[0]}" '^.*[(].*[)] is \(.*running\).*$'`
	piawareProblem=$( [[ $run =~ "not running" ]] && echo "ON" || echo "OFF")
	# faup1090 status
	run=`expr match "${lines[1]}" '^.*[(].*[)] is \(.*running\).*$'`
	faup1090Problem=$( [[ $run =~ "not running" ]] && echo "ON" || echo "OFF")
	# faup978 status
	run=`expr match "${lines[2]}" '^.*[(].*[)] is \(.*running\).*$'`
	faup978Problem=$( [[ $run =~ "not running" ]] && echo "ON" || echo "OFF")
	# mlat receiver status
	run=`expr match "${lines[3]}" '^.*[(].*[)] is \(.*running\).*$'`
	mlatProblem=$( [[ $run =~ "not running" ]] && echo "ON" || echo "OFF")
	# dump1090 status
	run=`expr match "${lines[4]}" '^.*[(].*[)] is \(.*running\).*$'`
	#echo "dump1090 run --->$run<---"
	#echo "${lines[4]}"
	dump1090Problem=$( [[ $run =~ "not running" ]] && echo "ON" || echo "OFF")

	# faup1090 connectivity
	run=`expr match "${lines[7]}" '^.* is \(.*connected\).*$'`
	faup1090Dump1090Connection=$( [[ $run =~ "not connected" ]] && echo "OFF" || echo "ON")
	# piaware connectivity
	run=`expr match "${lines[8]}" '^.* is \(.*connected\).*$'`
	piawareServerConnection=$( [[ $run =~ "not connected" ]] && echo "OFF" || echo "ON")

	# data on port 3005
	run=`expr match "${lines[10]}" '^.* is \(.*producing\).*$'`
	data3005Problem=$( [[ $run =~ "NOT producing" ]] && echo "ON" || echo "OFF")

	piawareMsg="{\"piaware_problem\":\"$piawareProblem\", \
	             \"faup1090_problem\":\"$faup1090Problem\", \
	             \"faup978_problem\":\"$faup978Problem\",
	             \"mlat_problem\":\"$mlatProblem\", \
	             \"dump1090_problem\":\"$dump1090Problem\", \
	              \"faup1090dump1090_connection\":\"$faup1090Dump1090Connection\", \
	              \"piawareserver_connection\":\"$piawareServerConnection\", \
	              \"data3005_problem\":\"$data3005Problem\"}"
}

# Called when SIGINT or EXIT signals are detected to change the status of the sensors in Home Assistant to unavailable
changeStatus() {
	if [[ ! -z $fr24feed_subtopic ]]; then
		mosquitto_pub $mosquittoArgs -r -t $mqtt_topic_prefix/$fr24feed_subtopic/status -m "offline"
	fi
	if [[ ! -z $dump1090_subtopic ]]; then
		mosquitto_pub $mosquittoArgs -r -t $mqtt_topic_prefix/$dump1090_subtopic/status -m "offline"
	fi
	if [[ ! -z $piaware_subtopic ]]; then
		mosquitto_pub $mosquittoArgs -r -t $mqtt_topic_prefix/$piaware_subtopic/status -m "offline"
	fi
	exit
}

# trap script termination to update the status to "offline"
trap changeStatus SIGINT
trap changeStatus EXIT

# Publish Home Assistant discovery messages
pubHAdiscoveryMsg

# Main loop
while true; do
	if [[ ! -z $dump1090_subtopic ]]; then
		dump1090Update
		mosquitto_pub $mosquittoArgs -t $mqtt_topic_prefix/$dump1090_subtopic -m $(echo $dump1090Msg | tr -d ' ')
	fi
	if [[ ! -z $fr24feed_subtopic ]]; then
		fr24feedUpdate
		mosquitto_pub $mosquittoArgs -t $mqtt_topic_prefix/$fr24feed_subtopic -m $(echo $fr24feedMsg | tr -d ' ')
	fi
	if [[ ! -z $piaware_subtopic ]]; then
		piawareUpdate
		mosquitto_pub $mosquittoArgs -t $mqtt_topic_prefix/$piaware_subtopic -m $(echo $piawareMsg | tr -d ' ')
	fi
	sleep $update_rate
done

