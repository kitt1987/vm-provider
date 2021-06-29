#!/usr/bin/env bash

hostname=$1
ipPrefix=${2:-10.38.}

DNSConf=/etc/dnsmasq.d/vm

ExistedRescord=$(grep -w ${hostname} ${DNSConf})

mac1=08
mac2=00
mac3=28

if [ "${ExistedRescord}" != "" ]; then
	mac=$(echo ${ExistedRescord} | cut -d "=" -f 2 | awk -F ',' '{ print $1 }')
	ip=$(echo ${ExistedRescord} | cut -d "=" -f 2 | awk -F ',' '{ print $3 }')
	NextMac4=$(echo ${mac} | awk -F ':' '{ print $4 }')
	NextMac5=$(echo ${mac} | awk -F ':' '{ print $5 }')
	NextMac6=$(echo ${mac} | awk -F ':' '{ print $6 }')
	echo ${mac1}${mac2}${mac3}${NextMac4}${NextMac5}${NextMac6} ${ip}
	exit 0
fi

NextMac4=00
NextMac5=00
NextMac6=01
NextIP3=1
NextIP4=1

LastRecord=$(tail -1 ${DNSConf})
if [ "${LastRecord}" != "" ]; then
	LastMac=$(echo ${LastRecord} | cut -d "=" -f 2 | awk -F ',' '{ print $1 }')
	LastIP=$(echo ${LastRecord} | cut -d "=" -f 2 | awk -F ',' '{ print $3 }')
	
	if [ "${LastMac}" != "" ]; then
		NextMac4=$((16#$(echo ${LastMac} | awk -F ':' '{ print $4 }')))
		NextMac5=$((16#$(echo ${LastMac} | awk -F ':' '{ print $5 }')))
		NextMac6=$((16#$(echo ${LastMac} | awk -F ':' '{ print $6 }')))
		NextMac6=$((${NextMac6} + 1))
		if [ ${NextMac6} -ge 16 ]; then
			NextMac6=0
			NextMac5=$((${NextMac5} + 1))
			if [ ${NextMac5} -ge 16 ]; then
				NextMac5=0
				NextMac4=$((${NextMac4} + 1))
				if [ ${NextMac4} -ge 16 ]; then
					>&2 echo "More more MAC can be allocated after ${LastMac}"
					exit 2
				fi
			fi
		fi

		NextMac4=$(printf "%02x\n" ${NextMac4})
		NextMac5=$(printf "%02x\n" ${NextMac5})
		NextMac6=$(printf "%02x\n" ${NextMac6})
	fi
	
	if [ "${LastIP}" != "" ]; then
		NextIP3=$(($(echo ${LastIP} | awk -F '.' '{ print $3 }')))
		NextIP4=$(($(echo ${LastIP} | awk -F '.' '{ print $4 }')))
		NextIP4=$((${NextIP4} + 1))
		if [ ${NextIP4} -gt 255 ]; then
			NextIP4=0
			NextIP3=$((${NextIP3} + 1))
			if [ ${NextIP3} -gt 255 ]; then
				>&2 echo "More more IP can be allocated after ${LastIP}"
				exit 2
			fi
		fi
	fi
fi

ip=${ipPrefix}${NextIP3}.${NextIP4}

echo "dhcp-host=${mac1}:${mac2}:${mac3}:${NextMac4}:${NextMac5}:${NextMac6},${hostname},${ip},infinite" >> ${DNSConf}

systemctl restart dnsmasq

echo ${mac1}${mac2}${mac3}${NextMac4}${NextMac5}${NextMac6} ${ip}
