#!/bin/bash
#################################
### Please enter your API key ###
#################################
APIKEY=""
#################################

function logger {
echo $@
}

function usage {
cat << EOF
Usage: $0 <application> <event> <description>.
This is s script for androids Notify-My-Android app.
EOF
exit 3
}

[[ -z $APIKEY ]] && logger "No API key specified."
NOTIFYURL="https://nma.usk.bz/publicapi/notify"
CURL="`which curl`"
[[ -z $CURL ]] && logger "curl not installed" && exit 1

#check for right number of arguments
[[ ! $# -eq 3 ]] && logger "wrong number of arguments" && usage

NOTIFY="`curl -s --data-ascii "apikey=$APIKEY" --data-ascii "application=$1" --data-ascii "event=$2" --data-asci "description=$3" $NOTIFYURL -o- | sed 's/.*success code="\([0-9]*\)".*/\1/'`"
case $NOTIFY in
	200)
	logger "Notification submitted."
	exit 0
	;;
	400)
	logger "The data supplied is in the wrong format, invalid length or null."
	exit 400
	;;
	401)
	logger "None of the API keys provided were valid."
	exit 401
	;;
	402)
	logger "Maximum number of API calls per hour exceeded."
	exit 402
	;;
	500)
	logger "Internal server error. Please contact our support if the problem persists."
	exit 500
	;;
esac
logger "something wen't badly wrong here!"
exit 9001
