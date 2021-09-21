#!/bin/ash

HOSTS="192.168.0.1 192.168.0.2 8.8.8.8 example.com"
COUNT=6
TELEGRAM_API="https://api.telegram.org/botXXXXXXXXXX:AAAAAAAAA-BBBBBBBBBBBBBBBBBBBBBBBBB"
CHAT_ID=-511111111
MONITORING_DIR="/tmp"

notify () {
  echo "Notification $1"
  wget -O /dev/null -o /dev/null  "$API/sendMessage?chat_id=$CHAT_ID&text=$1"
}

format_msg() {
  echo "Host : $1 is $2 at $(date)" 
}

for myHost in $HOSTS
do
  FILE=$MONITORING_DIR/$myHost.fail
  count=$(ping -c $COUNT $myHost | grep 'received' | awk -F',' '{ print $2 }' | awk '{ print $1 }')
  if [ $count -eq 0 ]; then
    # 100% failed 
    state="Offline"
    echo "$(format_msg $myHost $state)"
 
    if ! [ -f "$FILE" ] ; then
      notify "$(format_msg $myHost $state)"
    fi
    touch $FILE
  else
    state="Online"
    # host responded at least once
    echo "$(format_msg $myHost $state)"
    
    if [ -f "$FILE" ] ; then
      notify "$(format_msg $myHost $state)"
    fi
    rm -f $FILE
  fi
done
