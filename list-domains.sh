#!/bin/bash
# List all K and C domains on the specified Waimea server
# Specify 01 or 02 on the command line to switch server
#     Defaults to 01

if [ "$1" == "02" ]; then
	ip="192.168.185.22"
	serv="SFO-WAIMEA-02"
elif [ "$1" == "01" ]; then
	ip="192.168.185.21"
	serv="SFO-WAIMEA-01"
else
	echo ""
	echo "Waimea List Domains"
	echo ""
	echo "Usage:"
	echo ""
	echo "       list-domains.sh ##"
	echo ""
	echo " where ## = 01 or 02"
	exit
fi

echo "Working on $serv ($ip)"

echo ""
echo "K Domains"
for i in $(wm-domain --list -t K -H $ip 2> /dev/null)
do
	echo -ne "$i\t\t"
	wm-domain --check-id $i -H $ip 2> /dev/null
done

echo ""
echo "C Domains"
for i in $(wm-domain --list -t C -H $ip 2> /dev/null)
do
	echo -ne "$i\t\t"
	wm-domain --check-id $i -H $ip 2> /dev/null
done
