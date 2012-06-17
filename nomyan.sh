#!/bin/bash
#################################
### Please enter your API keys in
### a file with
### APIKEYS="<key> [key]*"
### in follow files or options
### 
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
	-k	Specify the API keys (overrides API keyfiles)
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

[[ -z $APIKEYS ]] && logger "No API keys specified." && logger "Please create API keyfiles or use -k option" && usage
NOTIFYURL="https://nma.usk.bz/publicapi/notify"
CURL="`which curl`"
[[ -z $CURL ]] && logger "curl not installed" && exit 1

#check for right number of arguments
[[ ! $# -eq 3 ]] && logger "Wrong number of arguments." && usage

for d in $APIKEYS; do
	NOTIFY="`curl -s --data-ascii "apikey=$d" --data-ascii "application=$1" --data-ascii "event=$2" --data-asci "description=$3" $NOTIFYURL -o- | sed 's/.*success code="\([0-9]*\)".*/\1/'`"
	case $NOTIFY in
		200)
		logger "Notification submitted."
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
done
exit 0
