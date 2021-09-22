#!/bin/ash

# Space separated list of hosts that script needs to Ping to check their availability 
HOSTS="192.168.0.1 example.com 3.3.4.4"
# Space separated list of URLs that script needs to query with wget to check their availability 
URLS="http://192.168.0.5:8080/owncloud http://example.com http://notexist5.com https://google.com https://shmugl.au"

# Number of ping attempts
COUNT=6
# API URL of the Telegram bot used for notification
TELEGRAM_API="https://api.telegram.org/botXXXXXXXXXX:AAAAAAAAA-BBBBBBBBBBBBBBBBBBBBBBBBB"
# CHAT_ID of the Telegram chat, where the telegram bot will post messages
TELEGRAM_CHAT_ID=-511111111

# Directory where scripts holds temporaty files 
MONITORING_DIR="/tmp/.monitoring"

if ! [ -d "$MONITORING_DIR" ]; then
  mkdir $MONITORING_DIR
fi

notify() {
  wget -O /dev/null -o /dev/null "$TELEGRAM_API/sendMessage?chat_id=$TELEGRAM_CHAT_ID&text=$1"
}

format_msg() {
  echo "Host : $1 is $2 at $(date)" 
}

begins_with() { 
  case $2 in "$1"*) true;; *) false;; esac; 
}


test_http() {
  httpStatusString=$(wget --server-response --spider --quiet "$1" 2>&1 | awk 'NR==1{print $2}')
  if [ "$httpStatusString" = "200" ] || [ "$httpStatusString" = "301" ] ; then
    echo 1
  else
    echo 0
  fi
}

test_ping() {
  count=$(ping -c $COUNT $1 | grep 'received' | awk -F',' '{ print $2 }' | awk '{ print $1 }')
  if [ "$count" = "0" ]; then
    echo 0
  else
    echo 1
  fi

}

#Combine hosts we need to ping and urls we need to query in one list
ITEMS="$HOSTS $URLS"


for item in $ITEMS
do
  # Calculate temporary file name based on MD5 
  MD5=`echo $item | md5sum | awk '{ print $1 }'`
  FAIL_FILE=$MONITORING_DIR/$MD5.fail
  
  # If item in the list starts with "http" than we need to check it as http URL
  # Otherwise we need ping it
  if begins_with http "$item"; then
    testResult="$(test_http $item)"
  else
    testResult="$(test_ping $item)"
  fi

  if [ "$testResult" = "1" ] ; then
    state="Online"
    echo "$(format_msg $item $state)"
    if [ -f "$FAIL_FILE" ] ; then
      notify "$(format_msg $item $state)"
    fi
    rm -f $FAIL_FILE
  else
    state="Offline"
    echo "$(format_msg $item $state)"
    if ! [ -f "$FAIL_FILE" ] ; then
      notify "$(format_msg $item $state)"
    fi
    echo $item > $FAIL_FILE
  fi 
done

exit 0
