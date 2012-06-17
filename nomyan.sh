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

# a simple logger function
function logger {
LOGLINE="`date +%Y-%m-%d_%H:%M:%S` [$$] $@"
[[ $LOGGING -eq 1 ]] && echo -e $LOGLINE >> $LOGFILE
[[ $VERBOSE -eq 1 ]] && echo -e $LOGLINE
}

# some default settings
filename=$(basename "$0")
basename=${filename%.*}
LOGFILE="$basename.log"
VERBOSE=0
LOGGING=1
PRIORITY=0
NOTIFYURL="https://nma.usk.bz/publicapi/notify"
CURL="`which curl`"
[[ -z $CURL ]] && logger "curl not installed" && exit 1

function usage {
cat << EOF
usage: $filename application event description

This script notifies your android devices via Notify-My-Android app.

OPTIONS:
	-k	Specify the API keys (overrides API keyfiles)
	-l	Specify logfile
	-L	Disable Logging to file
	-p	Specify priority (-2 to 2)
	-v	Verbose output
EOF
exit 3
}

# check default pathes for keyfiles
# keyfile in homedir will override keyfile in /etc/
# keyfile specified in -k option overrides everything
[[ -r /etc/$basename.key ]] && . /etc/$basename.key
[[ -r ~/.$basename.key ]] && . ~/.$basename.key

while getopts "hk:vl:Lp:" OPTION
do
	case $OPTION in
	h)
		# print the help (usage)
		usage
		exit 1
		;;
	k)
		# set apikey from option
		APIKEY=$OPTARG
		;;
	v)
		# enable verbose logging
		VERBOSE=1
		;;
	L)
		# disable logging to file
		LOGGING=0
		;;
	l)
		# specify logfile
		LOGFILE=$OPTARG
		;;
	p)
		# set priority
		PRIORITY=$OPTARG
		;;
	?)
		# print usage on unknown command
		usage
		exit
		;;
	esac
done

# shift parsed options for easy using $1,$2 and $3
shift $((OPTIND-1))

# check if API keys are set, if not print usage
[[ -z $APIKEYS ]] && logger "No API keys specified." && logger "Please create API keyfiles or use -k option" && usage

# check for right number of arguments
[[ ! $# -eq 3 ]] && logger "Wrong number of arguments." && usage

# iterate over API keylist
for d in $APIKEYS; do
	# send notifcation
	NOTIFY="`$CURL -s --data-ascii "apikey=$d" --data-ascii "application=$1" --data-ascii "event=$2" --data-asci "description=$3" --data-ascii "priority=$PRIORITY" $NOTIFYURL -o- | sed 's/.*success code="\([0-9]*\)".*/\1/'`"
	# handle return code
	case $NOTIFY in
		200)
		logger "Notification submitted to API key $d."
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
