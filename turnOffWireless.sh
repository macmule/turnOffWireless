#!/bin/sh
####################################################################################################
#
# More information: https://macmule.com/2011/09/09/how-to-turn-off-wireless-card/
#
# GitRepo: https://github.com/macmule/turnOffWireless/
#
# License: https://macmule.com/license/
#
####################################################################################################
#
####################################################################################################
#
# DEFINE VARIABLES 
#
####################################################################################################

# HARDCODED VALUES SET HERE
# Set to y to clear DNS for macs running Tiger
clearTiger="n"

# CHECK TO SEE IF A VALUE WAS PASSED IN PARAMETER 4 AND, IF SO, ASSIGN
if [ "$4" != "" ] &amp;&amp; [ "$clearTiger" == "" ];then
clearTiger=$4
fi

####################################################################################################
#
# SCRIPT CONTENTS - DO NOT MODIFY BELOW THIS LINE
#
####################################################################################################

# Gets OS Version
OS=`/usr/bin/defaults read /System/Library/CoreServices/SystemVersion ProductVersion | awk '{print substr($1,1,4)}'`

# Checks networksetup to see if an Airport Card is installed
checkHasAnAirportCard=`networksetup -listallhardwareports | grep -i "Hardware Port: Air" | cut -c 16-`

# Checks to see if their is a service created for Airport, &amp; if so gets the name
checkWireless=$(networksetup -listallhardwareports | egrep "Hardware Port: (Air|Wi-)" | cut -c 16-)

# Checks to see if Airport is installed
if [ -z "$checkWireless" ]; then
	# If no Wireless is installed
	echo "No Wireless Card exiting..."
	exit 0

else

	# Checks to see if Wireless has a service created for it.
	if [ -z "$checkWireless" ]; then

	# If Aiport is installed, but does not have a service create a service &amp; enable
	echo "Wireless installed, but not configured as a service..."

	# Creates Aiport service
	networksetup -createnetworkservice "$checkWireless" "$checkWireless"
	echo "Wireless service created..."

	#Enable Wireless
	networksetup -setnetworkserviceenabled "$checkWireless" on
	echo "Enabled Wireless service..."

fi

#Loops through the list of network services
for i in $(networksetup -listallnetworkservices | tail +2 );
do
	#Checks to see if there is a service called *Airport* or *Wireless if so enables it.
	if [[ "$i" =~ '*A' || "$i" =~ '*W' ]]; then

		#Removes the * prefix
		disabledServices=`( echo $i | cut -c 2- )`

		#Enables the disabled netwoprk services
		/usr/sbin/networksetup -setnetworkserviceenabled "$disabledServices" on
		
		#Echo's the name of any services enabled
		echo "Wireless now enabled..."
	
	fi

done

# Re-checks the service name for Wireless as it should now be enabled
checkWirelessIsAService=$(networksetup -listallnetworkservices | egrep -i "(Air|Wi-)")

#Checks power state of Wireless
if [[ "$OS" "10.5" ]]; then
	
	# If OS is 10.6.x run the following to check Wireless power...
	airportPower=`/usr/sbin/networksetup -getairportpower "$checkWireless" | cut -c 26-`
else

	# If OS is 10.5.x run the following to check Wireless power...
	airportPower=`/usr/sbin/networksetup -getairportpower | cut -c 16-`

fi

if [[ "$airportPower" == "Off" ]]; then
	
	#Checks to see if Wireless is off &amp; if so.. exits.
	echo "Wireless already powered off.. exiting..."
	exit 0
	
else
	#Checks to see if Wireless is on
	echo "Wireless is powered on..."
	
	# If machine is running Tiger, clear search domains if specified for $clearTiger variable
	if [[ "$OS" &lt; "10.5" ]]; then
		if [[ "$clearTiger" == "y" ]]; then
			
			echo "Clearing DNS Servers for OS $OS..."
			/System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Support/networksetup -setdnsservers "$checkWireless" "empty"
			
			echo "Clearing search domains for OS $OS..."
			/System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Support/networksetup -setsearchdomains "$checkWireless" "empty"
		
		else

			echo "Not Clearing DNS as OS is $OS..."

		fi

	else

		# If machine is not running 10.5 or higher clear dns &amp; search domains as these will be picked up by DHCP
		echo "Clearing DNS Servers for OS $OS..."
		/usr/sbin/networksetup -setdnsservers "$checkWireless" "empty"
		echo "Clearing search domains for OS $OS..."
		/usr/sbin/networksetup -setsearchdomains "$checkWireless" "empty"

	fi

	if [[ "$OS" == "10.4" ]]; then
	
		# If OS is 10.4.x run the following to turn off Wireless...
		echo "Turning off the Wireless for OS $OS..."
		/System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Support/networksetup -setairportpower off
		exit 0
		
		elif [[ "$OS" == "10.5" ]]; then
		
			# If OS is 10.5.x run the following to turn off Wireless...
			echo "Turning off the Wireless for OS $OS..."
			/usr/sbin/networksetup -setairportpower off
			exit 0
			
		elif [[ "$OS" == "10.6" ]]; then
		
			# If OS is 10.6.x run the following to turn off Wireless...
			echo "Turning off the Wireless for OS $OS..."
			/usr/sbin/networksetup -setairportpower "$checkWireless" off
			exit 0
		
		else
		
			# If OS is 10.7.x or greater then run the following to turn off Wireless...
			checkWireless=$(networksetup -listallhardwareports | egrep "Hardware Port: (Air|Wi-)" | cut -c 16-)
			# First we need to get the Wi-Fi device's name
			wifiDevice=`/usr/sbin/networksetup -listallhardwareports | awk '/^Hardware Port: Wi-Fi/,/^Ethernet Address/' | head -2 | tail -1 | cut -c 9-`
			echo "Turning off the Wireless for OS $OS..."
			/usr/sbin/networksetup -setairportpower "$wifiDevice" off
			exit 0
		fi
	fi
fi
