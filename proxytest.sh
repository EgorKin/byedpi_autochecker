#!/bin/sh

# Copyright © 2025 Dex9999(4pda.to) aka Dex aka EgorKin(GitHub, etc.)


#===================================================================================================
# Please take a look at this part and change values/paths to desired (if default is not OK for you)
sites_filename=proxytest_sites.txt
cmds_filename=proxytest_cmds.txt

curl_path=/data/patch/bin/curl
ciadpi=/data/patch/bin/ciadpi
PIDFILE=/var/run/byedpi.pid
base_cmd="--daemon --pidfile $PIDFILE -i 127.0.0.1 -p 999"
#===================================================================================================



good_answers=0
requests=0
cmds=0
totalcmds=0

# calc total cmds if input file
while IFS= read -r cmd || [ -n "$cmd" ];
do
	totalcmds=$(( $totalcmds + 1 ))
done < $cmds_filename


while IFS= read -r cmd || [ -n "$cmd" ];
do
	cmds=$(( $cmds + 1 ))

	if [ ! -f "$PIDFILE" ] || ! kill -0 $(cat "$PIDFILE"); then
	  echo ''
	else
	  echo 'Stopping ByeDPI service...'
	  # kill ciadpi process with previous cmd
	  kill -15 $(cat "$PIDFILE") && rm -f "$PIDFILE"
	  sleep 1
    fi
	
	if [ -f $PIDFILE ] && kill -0 $(cat $PIDFILE); then
      echo 'ERROR: Service ByeDPI is STILL running!' >&2
      return 1
	else
	  echo "($cmds/$totalcmds) Check ByeDPI with $cmd"
	  # and run ciadpi process with new cmd
	  $($ciadpi $base_cmd $cmd)
	  sleep 1
    fi
	

	good_answers=0
	requests=0
	#total_time=0
	
	while IFS= read -r url || [ -n "$url" ];
	do
	  url="https://$url"
	  # -X GET  - это GET запрос
	  # а без него - HEAD
	  # -k так как проблемы с проверкой SSL сертификатов на роутере
	  urlstatus=$($curl_path -I -L -X GET -k --max-time 2 -H 'Cache-Control: no-cache' -o /dev/null --silent --head --write-out '%{http_code}' -x socks5://127.0.0.1:999 "$url")
      
	  DATENOW=`date +%Y%m%d-%H%M%S%N`
	  requests=$(( $requests + 1 ))

	  if [ "$urlstatus" = "000" ] || [ "$urlstatus" = "" ]
	  then
	  	echo -e "$DATENOW FAIL $urlstatus returned from \033[0;31m$url\033[0m"
		continue
	  fi
	  
      good_answers=$(( $good_answers + 1 ))
	  #total_time=$(( $total_time + $time ))
      echo -e "$DATENOW OK $urlstatus returned from \033[0;32m$url\033[0m"
	  
	done < $sites_filename
	
	echo "Answers for $cmd: $good_answers / $requests"
	echo ""
	set -- "$@" "$good_answers"
done < $cmds_filename


# print results for every cmd: >=90% green, >= 75 yellow
goodcmd=$(( $requests * 9 / 10 ))
finecmd=$(( $requests * 3 / 4 ))

# отсутствие в sh нормальных массивов (или скорее всего моих недознаний в shell) приводит к такому коду
# а тут всего лишь сортировка результатов от менее успешных к более успешным
i=0
while [ $i -le $requests ];
do
	curr=0
	echo "Success $i of $requests requests with options:"
	while IFS= read -r cmd || [ -n "$cmd" ];
	do
		curr=$(( $curr + 1 ))
		t=0
		for k in "$@"
		do
			t=$(( $t + 1 ))
			arr=$k
			if [ "$t" = "$curr" ]
			then
				break
			fi
		done


		if [ "$arr" -eq "$i" ]
		then
			if [ "$i" -ge "$finecmd" ]
			then
				if [ "$i" -ge "$goodcmd" ]
				then
					echo -e "\033[0;32m$cmd\033[0m"
				else
					# success >= 75%
					echo -e "\033[0;33m$cmd\033[0m"
				fi
			else
				echo "$cmd"
			fi
		fi


#		if [ "$1" -ge "$finecmd" ]
#		then
#			if [ "$1" -ge "$goodcmd" ]
#			then
#				echo "OK $1 of $requests requests with options:"
#				echo -e "\033[0;32m$cmd\033[0m"
#			else
#				# success >= 75%
#				echo "OK $1 of $requests requests with options:"
#				echo -e "\033[0;33m$cmd\033[0m"
#		else
#			echo "OK $1 of $requests requests with options:"
#			echo "$cmd"
#			fi
#		fi
#		echo ""
#		shift
	done < $cmds_filename
	i=$(( $i + 1 ))
	echo ""
done


# return back to original ciadpi settings
if [ ! -f $PIDFILE ] || ! kill -0 $(cat "$PIDFILE"); then
	  echo ''
	else
	  echo 'Stopping ByeDPI service...'
	  # kill ciadpi process with last cmd
	  kill -15 $(cat "$PIDFILE") && rm -f "$PIDFILE"
	  sleep 1
    fi
	
# run ciadpi with default settings
if [ -f $PIDFILE ] && kill -0 $(cat $PIDFILE); then
      echo 'WARNING: Service ByeDPI is STILL running with last test cmd!'
      return 1
	else
	  if [ -f /data/patch/etc/rc.d/S90tpws ]; then
	    echo "Return back to original ByeDPI service..."
	    # and run ciadpi process with default cmd
	    /data/patch/etc/rc.d/S90tpws start
	    sleep 1
	  fi
    fi
