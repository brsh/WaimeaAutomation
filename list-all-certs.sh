#!/bin/bash
# Dumps lists of all certs from C_DCinema to txt files for Excel parsing
# Used to verify all certs are replicating between devices.

function QUIT {
	COLOR "Done." $yellow
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

COLOR
COLOR "Dump a list of all certs in C_DCinema" $yellow
COLOR
COLOR "...Getting info from W-01..." $yellow
COLOR ".....overwriting ~/Documents/w01-dump.csv....." $cyan
COLOR ".......part 1 of 3......" $cyan
wm-cert -H 192.168.185.21 -C RhKoaKEhpFMsvkMvhVA2GTCeWBo= -l > ~/Documents/w01-dump.csv 2> /dev/null
COLOR ".......part 2 of 3......" $cyan
wm-cert -H 192.168.185.21 -C RhKoaKEhpFMsvkMvhVA2GTCeWBo= -l -t s >> ~/Documents/w01-dump.csv 2> /dev/null
COLOR ".......part 3 of 3......" $cyan
wm-cert -H 192.168.185.21 -C RhKoaKEhpFMsvkMvhVA2GTCeWBo= -l -t r >> ~/Documents/w01-dump.csv 2> /dev/null

COLOR
COLOR "...Getting info from W-02..." $yellow
COLOR ".....over-writing ~/Documents/w02-dump.csv....." $cyan
COLOR ".......part 1 of 3......" $cyan
wm-cert -H 192.168.185.22 -C Gs6Bat8ga0u11OfU1wWwmRqlTzQ= -l  > ~/Documents/w02-dump.csv 2> /dev/null
COLOR ".......part 2 of 3......" $cyan
wm-cert -H 192.168.185.22 -C Gs6Bat8ga0u11OfU1wWwmRqlTzQ= -l -t s >> ~/Documents/w02-dump.csv 2> /dev/null
COLOR ".......part 3 of 3......" $cyan
wm-cert -H 192.168.185.22 -C Gs6Bat8ga0u11OfU1wWwmRqlTzQ= -l -t r >> ~/Documents/w02-dump.csv 2> /dev/null


