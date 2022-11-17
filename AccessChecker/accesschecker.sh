#!/bin/bash

R='\033[0;31m'
G='\033[0;32m'
B='\033[0;34m'
Y='\033[0;33m'
LB='\033[1;34m'
NC='\033[0m'

declare -a allFiles

function generateFiles {
    tmp=1

    for entry in $(ls /mnt/log/gateway2/ | grep access)
    do
        allFiles[${#allFiles[@]}]=$entry
    done

    for file in ${allFiles[@]}
    do
        echo -e "[$tmp] $file"
        tmp=$(($tmp+1))
    done
}

function makeSelection {
    while [[ -z $selection ]]
    do
        read selection
        if [[ $selection -le 0  || $selection -gt $tmp-1 ]]
            then
            echo -e "${R}Please enter a valid choice!${NC}"
            selection=''
        fi
    done
}

function readFile {
    if [[ -z "$(echo /mnt/log/gateway2/${allFiles[$((selection-1))]} | grep gz)" ]]
    then
        accessData="$(cat /mnt/log/gateway2/${allFiles[$((selection-1))]})"
    else 
        accessData="$(zcat /mnt/log/gateway2/${allFiles[$((selection-1))]})"
    fi
}

function spacer {
    echo "------------------------------------------------"
}

function reportIPs {
    echo "$(awk '{print $1}' <<< $accessData | sort -n | uniq -c | sort -nr | head -20)"
}

function reportDomains {
    echo "$(awk '{print $6}' <<< $accessData | sort | uniq -c | sort -r | head -20)"
}

function reportRequestType {
    echo "$(awk '{print $7}' <<< $accessData | sed 's/\"//' | sort | uniq -c | sort -r | head -10)" 
}

function reportUrls {
    echo "$(awk '{print $8}' <<< $accessData | sort | uniq -c | sort -r | head -10)"
}

function reportUA {
    echo "$(cut -d '"' -f4 <<< $accessData | sort | uniq -c | sort -r | head -10)"
}

echo "Please select file:"
generateFiles
makeSelection
readFile
spacer
echo -e "${Y}Sorted by IP's:${NC}"
reportIPs
spacer
echo -e "${Y}Sorted by domains:${NC}"
reportDomains
spacer
echo -e "${Y}Sorted by HTTP Requests:${NC}"
reportRequestType
spacer
echo -e "${Y}Sorted by URL's:${NC}"
reportUrls
spacer
echo -e "${Y}Sorted by User Agents:${NC}"
reportUA