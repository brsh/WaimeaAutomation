# ======================================================================
# PURPOSE: Create specified Waimea peering relationship
#
# ======================================================================
#!/bin/sh
function QUIT {
	COLOR
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

function show_help {
	COLOR
	COLOR "Create Peering relationships between Waimea Domains" ${white}
	COLOR
	COLOR "Syntax: "
	COLOR "   ${0##*/} [-m 01|02] [-s 02|01] mDN " ${cyan}
	COLOR
	COLOR "Where: "
	COLOR "   -m    Device to be Master (default is 02)  [optional]" ${cyan}
	COLOR "   -s    Device to be Slave (default is OPPOSITE of Master)  [optional]" ${cyan}
	COLOR "   mDN   The master domain name to be peered" ${cyan}
	COLOR
	COLOR "Examples:"
	COLOR
	COLOR "   Peer C_DCINEMA on 01 to C_DCINEMA on 02" ${white}
	COLOR "      ${0##*/} -m 01 C_DCINEMA" ${cyan}
	COLOR
	COLOR "   Peer C_DCINEMA on 02 to C_DCINEMA_DEV on 02" ${white}
	COLOR "      ${0##*/} -m 02 -s 02 C_DCINEMA " ${cyan}
	COLOR
	QUIT
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

WhichMaster=${IP02}
WhichSlave=${IP01}
SetMaster=1
SetSlave=1

OPTIND=1
while getopts ":hm:s:" opt; do
	case "$opt" in
		h | \?) show_help
		;;
		s)
			SetSlave=9
			if [[ ${OPTARG} == "01" ]]; then
				WhichSlave=${IP01}
			elif [[ ${OPTARG} == "02" ]]; then
				WhichSlave=${IP02}
			else
				COLOR
				COLOR "Please enter 01 or 02 for the slave (-s) option" ${red}
				show_help
			fi
		;;
		m)
			SetMaster=9
			if [[ ${OPTARG} == "01" ]]; then
				WhichMaster=${IP01}
			elif [[ ${OPTARG} == "02" ]]; then
				WhichMaster=${IP02}
			else
				COLOR
				COLOR "Please enter 01 or 02 for the master (-m) option" ${red}
				show_help
			fi
		;;
	esac
done

shift "$((OPTIND-1))"

DomainName="$1"

if [[ -z "${DomainName}" ]]; then
	COLOR
	COLOR "Please supply a Domain name to peer" ${red}
	show_help
fi

if ((SetMaster == 9 && SetSlave == 1)) ; then
	#The Master was set, but Slave was not
	#Set Slave to the opposite of Master
	if [[ "${WhichMaster}" == "${IP01}" ]]; then
		WhichSlave="${IP02}"
	else
		WhichSlave="${IP01}"
	fi
fi

if ((SetSlave == 9 && SetMaster == 1)) ; then
	#The Slave was set, but Master was not
	#Set Master to the opposite of Slave
	if [[ "${WhichSlave}" == "${IP01}" ]]; then
		WhichMaster="${IP02}"
	else
		WhichMaster="${IP01}"
	fi
fi

COLOR "Using the following settings:" $yellow
COLOR "Master     =  ${WhichMaster}" $green
COLOR "Slave      =  ${WhichSlave}" $green
COLOR "DomainName =  ${DomainName}" $green


COLOR
COLOR "...Testing for the domain..." $yellow

Type="c"
Domain02=$(wm-domain -H ${WhichMaster} --check-name ${DomainName} -t ${Type} 2> /dev/null)

if [[ -z "$Domain02" ]]; then
	#must be a K domain
	Type="k"
	Domain02=$(wm-domain -H ${WhichMaster} --check-name ${DomainName} -t k 2> /dev/null)
fi

Domain01=$(wm-domain -H ${WhichSlave} --check-name ${DomainName} -t ${Type} 2> /dev/null)

if [[ -z "$Domain01" ]]; then
	COLOR "${DomainName} does not exist on ${WhichMaster}" $red
	QUIT
else
	COLOR "Found ${DomainName} as ${Domain01} on ${WhichMaster}" $green
fi
if [[ -z "$Domain02" ]]; then
	COLOR "${DomainName} does not exist on ${WhichSlave}" $red
	QUIT
else
	COLOR "Found ${DomainName} as ${Domain02} on ${WhichSlave}" $green
fi

COLOR
COLOR "...Testing for peer relationship..." $yellow
Peer02=$(wm-peer --list-peers -H ${WhichSlave} 2> /dev/null | grep $Domain02 2> /dev/null | grep $Domain01 2> /dev/null)
Peer01=$(wm-peer --list-peers -H ${WhichMaster} 2> /dev/null | grep $Domain02 2> /dev/null | grep $Domain01 2> /dev/null)

if [[ -z "$Peer02" ]]; then
	COLOR "Peer relationship does not exist on ${WhichSlave}" $green
else
	COLOR "Found peer relationship on ${WhichSlave}" $red
	QUIT
fi

if [[ -z "$Peer01" ]]; then
	COLOR "Peer relationship does not exist on ${WhichMaster}" $green
else
	COLOR "Found peer relationship on ${WhichMaster}" $red
	QUIT
fi

COLOR
COLOR "This will create peering for ${DomainName} on ${WhichMaster} to ${WhichSlave}." $yellow
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
wm-domain -H ${WhichMaster} --get-chain -o ${DomainName}.chain.pem $Domain02 2> /dev/null

COLOR "Exporting Sub chain..." $yellow
wm-domain -H ${WhichSlave} --get-chain -o ${DomainName}.sub.chain.pem $Domain01 2> /dev/null

COLOR "Concat'ing chain files into a single file..." $yellow
cat ${DomainName}.chain* >> ${DomainName}.chain.pem

COLOR "Gen'ing peering request..." $yellow
wm-peer -H ${WhichSlave} --new-peering-request -o ${DomainName}.peering.request.bin $Domain01 ${WhichSlave} ${DomainName}.chain.pem 2> /dev/null

COLOR "Gen'ing peering auth" $yellow
wm-peer --auth-peering-request -H ${WhichMaster} -o ${DomainName}.peering.response.bin ${WhichMaster} ${DomainName}.peering.request.bin 2> /dev/null

COLOR "Confirming..." $yellow
wm-peer --conf-peering-response -H ${WhichSlave} ${DomainName}.peering.response.bin 2> /dev/null

#List
COLOR
COLOR "Listing Peers" $yellow
wm-peer --list-peers -H ${WhichMaster} 2> /dev/null | grep $Domain02 2> /dev/null | grep $Domain01 --color=never 2> /dev/null
wm-peer --list-peers -H ${WhichSlave} 2> /dev/null | grep $Domain02 2> /dev/null | grep $Domain01 --color=never 2> /dev/null
COLOR

#Remove temp files
rm $DomainName*.pem
rm $DomainName.peering*.bin

