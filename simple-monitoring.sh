#!/bin/bash


SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
MONITORING_DIR=$SCRIPT_DIR/".simple-monitoring"
SETTINGS_FILE=$MONITORING_DIR/"simple-monitoring.conf"

SETTING_TEMPLATE_HOSTS="192.168.0.1 192.168.0.2 8.8.8.8 example.com"
SETTING_TEMPLATE_COUNT=6
SETTING_TEMPLATE_TELEGRAM_API="https://api.telegram.org/botXXXXXXXXXX:AAAAAAAAA-BBBBBBBBBBBBBBBBBBBBBBBBB"
SETTING_TEMPLATE_TELEGRAM_CHAT_ID=-511111111


notify () {
  echo "Notification $1"
  wget -O /dev/null -o /dev/null  "$API/sendMessage?chat_id=$CHAT_ID&text=$1"
}

format_msg() {
  echo "Host : $1 is $2 at $(date)" 
}

first_run(){
    echo "First run detected"
    echo "Creating settings folder: $MONITORING_DIR"
    mkdir $MONITORING_DIR
    
    echo "Creating settings file: $SETTINGS_FILE"
    touch $SETTINGS_FILE
    echo "HOSTS=\"$SETTING_TEMPLATE_HOSTS\"" >> $SETTINGS_FILE
    echo "COUNT=$SETTING_TEMPLATE_COUNT" >> $SETTINGS_FILE
    echo "API=\"$SETTING_TEMPLATE_TELEGRAM_API\"" >> $SETTINGS_FILE
    echo "CHAT_ID=$SETTING_TEMPLATE_TELEGRAM_CHAT_ID" >> $SETTINGS_FILE
    
    echo "Please modify $SETTINGS_FILE to create your configuration"
    exit 0
}


if ! [ -f "$SETTINGS_FILE" ] ; then
    first_run
else
    source $SETTINGS_FILE
fi

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
