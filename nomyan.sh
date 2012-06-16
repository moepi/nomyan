#!/bin/bash
#################################
### Please enter your API key in
### a file with APIKEY=<key> in
### /etc/nomyan.key
### ~/.nomyan.key
### or as option -k
#################################

filename=$(basename "$0")
basename=${filename%.*}
LOGFILE="$basename.log"
VERBOSE=0
LOGGING=1

function logger {
LOGLINE="`date +%Y-%m-%d_%H:%M:%S` [$$] $@"
[[ $LOGGING -eq 1 ]] && echo -e $LOGLINE >> $LOGFILE
[[ $VERBOSE -eq 1 ]] && echo -e $LOGLINE
}

function usage {
cat << EOF
usage: $filename application event description

This script notifies your android devices via Notify-My-Android app.

OPTIONS:
	-k	Specify the API-Key (overrides from apikey-files)
	-l	Specify logfile
	-L	Disable Logging to file
	-v	Verbose output
EOF
exit 3
}

[[ -r /etc/$basename.key ]] && . /etc/$basename.key
[[ -r ~/.$basename.key ]] && . ~/.$basename.key

while getopts "hk:vl:L" OPTION
do
	case $OPTION in
	h)
		usage
		exit 1
		;;
	k)
		APIKEY=$OPTARG
		;;
	v)
		VERBOSE=1
		;;
	L)
		LOGGING=0
		;;
	l)
		LOGFILE=$OPTARG
		;;
	?)
		usage
		exit
		;;
	esac
done

shift $((OPTIND-1))

[[ -z $APIKEY ]] && logger "No API-Key specified." && logger "Please create API keyfile or use -k option" && usage
NOTIFYURL="https://nma.usk.bz/publicapi/notify"
CURL="`which curl`"
[[ -z $CURL ]] && logger "curl not installed" && exit 1

#check for right number of arguments
[[ ! $# -eq 3 ]] && logger "Wrong number of arguments." && usage

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
