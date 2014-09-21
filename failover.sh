#################################
# Internet Failover Script v2.5 #
# by igroykt	                #
#################################

#!/bin/sh

PATH="/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin:/root/bin"

TTK=""
RTK=""
TTK_GW=""
RTK_GW=""
DEFAULT_GW=`netstat -r|grep default|awk '{print $2}'`

check_ping() {
        if ! ping -s1 -S $TTK -c4 -t4 8.8.8.8 > /dev/null
        then
                sleep 4
                if ! ping -s1 -S $TTK -c4 -t4 8.8.8.8 > /dev/null
                then
                        if [ "$DEFAULT_GW" != "$RTK_GW" ]
                        then
                                route change default $RTK_GW
                                php failover_notify.php 'Internet Failover Notify [TTK]' 'Ping failed to 8.8.8.8! Route changed to RTK.'
                        fi
                else
                        if ! ping -s1 -S $RTK -c4 -t4 8.8.8.8 > /dev/null
                        then
                                sleep 4
                                if ! ping -s1 -S $TTK -c4 -t4 8.8.8.8 > /dev/null
                                then
                                        if [ "$DEFAULT_GW" != "$TTK_GW" ]
                                        then
                                                route change default $TTK_GW
                                                php failover_notify.php 'Internet Failover Notify [RTK]' 'Ping failed to 8.8.8.8! Route changed to TTK.'
                                        fi
                                fi
                        fi
                fi
        fi
}

check_ip() {
        ttk_ip=`ifconfig|grep $TTK|wc -l`
        rtk_ip=`ifconfig|grep $RTK|wc -l`
        if [ "$ttk_ip" -ne "1" ]; then
                if [ "$DEFAULT_GW" != "$RTK_GW" ]; then
                        route change default $RTK_GW
                        php failover_notify.php 'Internet Failover Notify [TTK]' 'TTK lost IP address! Route changed to RTK.'
                fi
        fi

        if [ "$rtk_ip" -ne "1" ]; then
                if [ "$DEFAULT_GW" != "$TTK_GW" ]; then
                        route change default $TTK_GW
                        php failover_notify.php 'Internet Failover Notify [RTK]' 'RTK lost IP address! Route changed to TTK!'
                fi
        fi
}

check_link() {
        ttk_link=`ifconfig re0|grep active|awk '{print $2}'|wc -l`
        rtk_link=`ifconfig ue0|grep active|awk '{print $2}'|wc -l`
        if [ "$ttk_link" -ne "1" ]; then
                if [ "$DEFAULT_GW" != "$RTK_GW" ]; then
                        route change default $RTK_GW
                        php failover_notify.php 'Internet Failover Notify [TTK]' 'TTK link down! Route changed to RTK.'
                fi
        fi
        if [ "$rtk_link" -ne "1" ]; then
                if [ "$DEFAULT_GW" != "$TTK_GW" ]; then
                        route change default $TTK_GW
                        php failover_notify.php 'Internet Failover Notify [RTK]' 'RTK link down! Route changed to TTK!'
                fi
        fi
}

check_link
check_ip
check_ping