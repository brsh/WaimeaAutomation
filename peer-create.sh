# ======================================================================
# PURPOSE: Create specified Waimea peering relationship
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
	COLOR "Peer relationship does not exist on 02" $green
else
	COLOR "Found peer relationship on 02" $red
	QUIT
fi

if [[ -z "$Peer01" ]]
then
	COLOR "Peer relationship does not exist on 01" $green
else
	COLOR "Found peer relationship on 01" $red
	QUIT
fi

COLOR
COLOR "This will create peering for $DomainName." $yellow
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

COLOR "Exporting master domain chain..." $yellow
wm-domain -H $IP02 --get-chain -o $DomainName.chain.pem $Domain02 2> /dev/null

COLOR "Exporting Sub chain..." $yellow
wm-domain -H $IP01 --get-chain -o $DomainName.sub.chain.pem $Domain01 2> /dev/null

COLOR "Concat'ing chain files into a single file..." $yellow
cat $DomainName.chain* >> $DomainName.chain.pem

COLOR "Gen'ing peering request..." $yellow
wm-peer -H $IP01 --new-peering-request -o $DomainName.peering.request.bin $Domain01 $IP01 $DomainName.chain.pem 2> /dev/null

COLOR "Gen'ing peering auth" $yellow
wm-peer --auth-peering-request -H $IP02 -o $DomainName.peering.response.bin $IP02 $DomainName.peering.request.bin 2> /dev/null

COLOR "Confirming..." $yellow
wm-peer --conf-peering-response -H $IP01 $DomainName.peering.response.bin 2> /dev/null

#List
COLOR
COLOR "Listing Peers" $yellow
wm-peer --list-peers -H $IP02 2> /dev/null | grep $Domain02 2> /dev/null | grep $Domain01 --color=never 2> /dev/null
wm-peer --list-peers -H $IP01 2> /dev/null | grep $Domain02 2> /dev/null | grep $Domain01 --color=never 2> /dev/null
COLOR

#Remove temp files
rm $DomainName*.pem
rm $DomainName.peering*.bin

