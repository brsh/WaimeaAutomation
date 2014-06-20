# ======================================================================
# PURPOSE: Destroy specified Waimea peering relationship
#
# ======================================================================
#!/bin/sh
function QUIT {
	COLOR "The script will now exit." $yellow
	exit
}

function COLOR {
	local default_msg=" "
	message=${1:-$default_msg}   # Defaults to default message.
	color=${2:-$white}           # Defaults to white, if not specified.

	echo -e "$color$message"
	tput sgr0
}

black='\E[30m'
red='\E[31m'
green='\E[32m'
yellow='\E[33m'
blue='\E[34m'
magenta='\E[35m'
cyan='\E[36m'
white='\E[37m'

IP01="192.168.185.21"
IP02="192.168.185.22"

DomainName="$1"
if [[ -z "$DomainName" ]]
then
	COLOR "Please enter the domain name:" $cyan
	read DomainName
fi

COLOR
COLOR "...Testing for the domain..." $yellow

Type="c"
Domain02=$(wm-domain -H $IP02 --check-name $DomainName -t $Type 2> /dev/null)

if [[ -z "$Domain02" ]]
then
	#must be a K domain
	Type="k"
	Domain02=$(wm-domain -H $IP02 --check-name $DomainName -t k 2> /dev/null)
fi

Domain01=$(wm-domain -H $IP01 --check-name $DomainName -t $Type 2> /dev/null)

if [[ -z "$Domain01" ]]
then
	COLOR "$DomainName does not exist on 01" $red
	QUIT
else
	COLOR "Found $DomainName as $Domain01 on 01" $green
fi
if [[ -z "$Domain02" ]]
then
	COLOR "$DomainName does not exist on 02" $red
	QUIT
else
	COLOR "Found $DomainName as $Domain02 on 02" $green
fi

COLOR
COLOR "...Testing for peer relationship..." $yellow
Peer02=$(wm-peer --list-peers -H $IP02 2> /dev/null | grep $Domain02 2> /dev/null | grep $Domain01 2> /dev/null)
Peer01=$(wm-peer --list-peers -H $IP01 2> /dev/null | grep $Domain02 2> /dev/null | grep $Domain01 2> /dev/null)

if [[ -z "$Peer02" ]]
then
	COLOR "Peer relationship does not exist on 02" $red
	QUIT
else
	COLOR "Found peer relationship on 02" $green
fi

if [[ -z "$Peer01" ]]
then
	COLOR "Peer relationship does not exist on 01" $red
	QUIT
else
	COLOR "Found peer relationship on 01" $green
fi

COLOR
COLOR "This will delete all peering for $DomainName." $yellow
COLOR
echo -e "$red    ** Are you certain? $yellow (you must type YES to proceed)"
echo -n "    "
read confirm
COLOR

if [[ "$confirm" == "YES" ]]
then
	COLOR "Proceeding..." $yellow
else
	COLOR "User aborted!" $red
	QUIT
fi

#destroy the peering
wm-peer -H $IP02 --cancel-peer $Domain02 $Domain01
wm-peer -H $IP01 --cancel-peer $Domain01 $Domain02

