#################################
# Internet Failover Script v2.6 #
# by igroykt	                #
#################################

#!/bin/sh

PATH="/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin:/root/bin"

CHECK_HOST="8.8.8.8"

WAN1=""
WAN1_GW=""
SUBJECT_WAN1="Internet Failover Notify [TTK]"
PING_ERR_WAN1="Ping failed to $CHECK_HOST! Route changed to RTK."
IP_ERR_WAN1="TTK lost IP address! Route changed to RTK."
LINK_ERR_WAN1="TTK link down! Route changed to RTK."
UPLINK_WAN1="TTK is UP! Route changed to TTK."

WAN2=""
WAN2_GW=""
SUBJECT_WAN2="Internet Failover Notify [RTK]"
PING_ERR_WAN2="Ping failed to $CHECK_HOST! Route changed to TTK."
IP_ERR_WAN2="RTK lost IP address! Route changed to TTK."
LINK_ERR_WAN2="RTK link down! Route changed to TTK."

DEFAULT_GW=`netstat -r|grep default|awk '{print $2}'`

check_ping() {
        if ! ping -s1 -S $WAN1 -c4 -t4 $CHECK_HOST > /dev/null
        then
                sleep 4
                if ! ping -s1 -S $WAN1 -c4 -t4 $CHECK_HOST > /dev/null
                then
                        if [ "$DEFAULT_GW" != "$WAN2_GW" ]
                        then
                                if [ ! -f wan1_link.lost ]; then
                                        if [ ! -f wan1_ip.lost ]; then
                                                route change default $WAN2_GW
                                                php failover_notify.php $SUBJECT_WAN1 $PING_ERR_WAN1
                                        fi
                                fi
                        fi
                else
                        if ! ping -s1 -S $WAN2 -c4 -t4 $CHECK_HOST > /dev/null
                        then
                                sleep 4
                                if ! ping -s1 -S $WAN2 -c4 -t4 $CHECK_HOST > /dev/null
                                then
                                        if [ "$DEFAULT_GW" != "$WAN1_GW" ]
                                        then
                                                if [ ! -f wan2_link.lost ]; then
                                                        if [ ! -f wan2_ip.lost ]; then
                                                                route change default $WAN1_GW
                                                                php failover_notify.php $SUBJECT_WAN2 $PING_ERR_WAN2
                                                        fi
                                                fi
                                        fi
                                fi
                        fi
                fi
        fi
        if ping -s1 -S $WAN1 -c4 -t4 $CHECK_HOST > /dev/null
        then
                if [ "$DEFAULT_GW" != "$WAN1_GW" ]
                then
                        route change default $WAN1_GW
                        php failover_notify.php $SUBJECT_WAN1 $UPLINK_WAN1
                fi
        fi
}

check_ip() {
        wan1_ip=`ifconfig|grep $WAN1|wc -l`
        wan2_ip=`ifconfig|grep $WAN2|wc -l`
        if [ "$wan1_ip" -ne "1" ]; then
                if [ "$DEFAULT_GW" != "$WAN2_GW" ]; then
                        if [ ! -f wan1_ip.lost ]; then
                                touch wan1_ip.lost
                        fi
                        route change default $WAN2_GW
                        php failover_notify.php $SUBJECT_WAN1 $IP_ERR_WAN1
                fi
        else
                if [ -f wan1_ip.lost ]; then
                        rm -f wan1_ip.lost
                fi
        fi

        if [ "$wan2_ip" -ne "1" ]; then
                if [ "$DEFAULT_GW" != "$WAN1_GW" ]; then
                        if [ ! -f wan2_ip.lost ]; then
                                touch wan2_ip.lost
                        fi
                        route change default $WAN1_GW
                        php failover_notify.php $SUBJECT_WAN2 $IP_ERR_WAN2
                fi
        else
                if [ -f wan2_ip.lost ]; then
                        rm -f wan2_ip.lost
                fi
        fi
}

check_link() {
        wan1_link=`ifconfig re0|grep active|awk '{print $2}'|wc -l`
        wan2_link=`ifconfig ue0|grep active|awk '{print $2}'|wc -l`
        if [ "$wan1_link" -ne "1" ]; then
                if [ "$DEFAULT_GW" != "$WAN2_GW" ]; then
                        if [ ! -f wan1_link.lost ]; then
                                touch wan1_link.lost
                        fi
                        route change default $WAN2_GW
                        php failover_notify.php $SUBJECT_WAN1 $LINK_ERR_WAN1
                fi
        else
                if [ -f wan1_link.lost ]; then
                        rm -f wan1_link.lost
                fi
        fi
        if [ "$wan2_link" -ne "1" ]; then
                if [ "$DEFAULT_GW" != "$wAN1_GW" ]; then
                        if [ ! -f wan2_link.lost ]; then
                                touch wan2_link.lost
                        fi
                        route change default $wAN1_GW
                        php failover_notify.php $SUBJECT_WAN2 $LINK_ERR_WAN2
                fi
        else
                if [ -f wan2_link.lost ]; then
                        rm -f wan2_link.lost
                fi
        fi
}

check_link
check_ip
check_ping