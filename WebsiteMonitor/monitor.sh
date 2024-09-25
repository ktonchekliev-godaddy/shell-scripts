#!/bin/bash

R='\033[0;31m'
G='\033[0;32m'
B='\033[0;34m'
Y='\033[0;33m'
LB='\033[1;34m'
NC='\033[0m'

function spacer { echo '--------------------------' ; }

function getPHPVersion {
    phpVersion=$(php -v  | grep -Eo '[7-9]\.[0-9].[0-9][0-9]' | uniq)
    if [[ -n $(grep '8.1' <<< $phpVersion) ]]; then
        echo -e "PHP Version: ${G}$phpVersion${NC}"
    else
        echo -e "PHP Version: ${Y}$phpVersion${NC}"
    fi
}

function getInstanceType {
    instanceType=$(ec2metadata | grep 'instance-type' | awk '{print $2}')
    echo -e "Instance type: ${G}$instanceType${NC}"
}

function getGenVersion {
    releaseNumber=$(lsb_release -sr 2>/dev/null | cut -d '.' -f1)
    case $releaseNumber in

        24)
        echo -e "Instance gen: ${G}Gen4${NC}"
        ;;

        20)
        echo -e "Instance gen: ${Y}Gen3${NC}"
        ;;

    esac
}

function getActiveWebsite {
    activeWebsite=$(grep "$(date '+%d/%b/%Y')" /mnt/log/gateway2/access.log | grep '" 200' | grep '/pagely/status/' | grep -v 'pressdns\.com' | awk '{print $6}' | sort | uniq -c | sort -nr | head -1 | awk '{print $2}' )
    
    if [[ -z $activeWebsite ]]; then
        activeWebsite=$(grep "$(date '+%d/%b/%Y')" /mnt/log/gateway2/access.log | grep '" 200' | grep '/pagely/status/' | awk '{print $6}' | sort | uniq -c | sort -nr | head -1 | awk '{print $2}' )
    fi

    if [[ -z $activeWebsite ]]; then
        activeWebsite=$(grep "$(date '+%d/%b/%Y')" /mnt/log/gateway2/access.log | grep '" 200' | awk '{print $6}' | sort | uniq -c | sort -nr | head -1 | awk '{print $2}')
    fi

    echo $activeWebsite
}

function verifyWebsite  {
    website=$1
    datetime=$(date '+%d/%b/%Y:%H:%M')
    curlResponse=$(curl -X GET -sI -A 'Gen4-Uplift-Monitor' "https://$website/pagely/status/" | head -1 | grep -oE '[0-9][0-9][0-9]')
    if [[ $curlResponse != 200 ]]; then
        curlResponse=$(curl -X GET -sI -A 'Gen4-Uplift-Monitor' "https://$website/?pagely_status=true" | head -1 | grep -oE '[0-9][0-9][0-9]')
    fi

    if [[ $curlResponse != 200 ]]; then
        echo -e "${R}Failure!${NC} Response: $curlResponse"
        exit 1
    fi

    if [[ -z $(grep "$datetime" /mnt/log/gateway2/access.log | grep 'Gen4-Uplift-Monitor' | grep '" 200') ]]; then
        echo -e "${R}Failure!${NC} Couldn't find any requests from the current server"
        exit 1
    fi
    
    echo -e "${G}Success!${NC} Everything is looking good"
}

echo ""
getPHPVersion
spacer
getInstanceType
spacer
getGenVersion
spacer

targetWebsite=$(getActiveWebsite)
echo -e "Found website: ${B}$targetWebsite${NC}. Verifying if it is accessible from the current server..."
verifyWebsite $targetWebsite
spacer
echo -e "Preview url: ${Y}https://$targetWebsite/pagely/status/${NC}"
echo ""

