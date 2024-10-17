#!/bin/sh

# Configuration
HOSTS="192.168.0.1 example.com 3.3.4.4"
URLS="http://192.168.0.5:8080/owncloud http://example.com http://notexist5.com https://google.com https://shmugl.au"
COUNT=6
TELEGRAM_API="https://api.telegram.org/botXXXXXXXXXX:AAAAAAAAA-BBBBBBBBBBBBBBBBBBBBBBBBB"
TELEGRAM_CHAT_ID=-511111111
MONITORING_DIR="/tmp/.monitoring"

# Ensure monitoring directory exists
mkdir -p "$MONITORING_DIR"

# Helper functions
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
    [ "$httpStatusString" = "200" ] || [ "$httpStatusString" = "301" ]
}

test_ping() {
    count=$(ping -c $COUNT "$1" | grep 'received' | awk -F',' '{ print $2 }' | awk '{ print $1 }')
    [ "$count" != "0" ]
}

handle_status() {
    local item=$1
    local FAIL_FILE=$2
    local state=$3
    
    echo "$(format_msg "$item" "$state")"
    if [ "$state" = "Online" ]; then
        [ -f "$FAIL_FILE" ] && notify "$(format_msg "$item" "$state")"
        rm -f "$FAIL_FILE"
    else
        [ ! -f "$FAIL_FILE" ] && notify "$(format_msg "$item" "$state")"
        echo "$item" > "$FAIL_FILE"
    fi
}

check_item() {
    local item=$1
    local MD5=$(echo "$item" | md5sum | awk '{ print $1 }')
    local FAIL_FILE="$MONITORING_DIR/$MD5.fail"
    
    if begins_with http "$item"; then
        test_http "$item"
    else
        test_ping "$item"
    fi

    if [ $? -eq 0 ]; then
        handle_status "$item" "$FAIL_FILE" "Online"
    else
        handle_status "$item" "$FAIL_FILE" "Offline"
    fi
}

check_system_logs() {
    local COMMAND=${1:-"dmesg --since '15 minutes ago'"}
    
    eval "$COMMAND" | while read -r line; do
        if echo "$line" | grep -qiE "ERROR|WARNING"; then
            notify "System Error: $line"
        fi
    done
}

# Main execution
for item in $HOSTS $URLS; do
    check_item "$item"
done

check_system_logs

exit 0
