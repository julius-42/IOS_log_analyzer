#!/bin/bash
#
# wana.sh
# Riešenie IOS, 1. Uloha, 25.3.2026
# Autor: Julius Kundrat FIT


# initializing variables
TIME_A=""
TIME_B=""
IP=""
URI=""
COMMAND=""
FILES=""

# convert argument timestamp format to Unix epoch
arg_ts_to_epoch() {
	# date-time formatting for MacOS
  	if [[ "$(uname)" == "Darwin" ]]; then
    	date -j -f "%Y-%m-%d %H:%M:%S" "$1" "+%s"
	# date-time formatting for GNU Linux
  	else
    	date -d "$1" "+%s"
  fi
}

# clean the log timestamp from brackets and other unwanted chars
clean_ts() {
  echo "$1" | sed 's/\[//g; s/ .*//; s/\// /g; s/:/ /' 
}

# convert clean log timestamp format to Unix epoch
log_ts_to_epoch() {
  	clean_time=$(clean_ts "$1")
  
  	# MacOS
	if [[ "$(uname)" == "Darwin" ]]; then
    	date -j -f "%d %b %Y %H:%M:%S" "$clean_time" "+%s"
	# GNU Linux
  	else
    	date -d "$clean_time" "+%s"
  	fi
}


# parsing arguments
while [ $# -gt 0 ]; do
	case "$1" in
		# parses all filters
		-a)
			if [ -z "$2" || "$2" == -* ]; then
				echo "Argument for $1 is missing or invalid."
				exit 1
			fi
			TIME_A=$(arg_ts_to_epoch "$2")
			shift 2 ;;
		-b)
			if [ -z "$2" || "$2" == -* ]; then
				echo "Argument for $1 is missing or invalid."
				exit 1
			fi
			TIME_B=$(arg_ts_to_epoch "$2")
			shift 2 ;;
		-ip)
			if [ -z "$2" || "$2" == -* ]; then
				echo "Argument for $1 is missing or invalid."
				exit 1
			fi
			IP="$2"
			shift 2 ;;
		-uri)
			if [ -z "$2" || "$2" == -* ]; then
				echo "Argument for $1 is missing or invalid."
				exit 1
			fi
			URI="$2"
			shift 2 ;;

		# parses command
		list-ip|list-hosts|list-uri|hist-ip|hist-load)
			COMMAND="$1"
			shift ;;

		# parses log files
		*.log|*.gz)
			FILES="$FILES $1"
			shift ;;

		# checks for invalid arguments
		*)
			echo "Invalid option: $1"
			exit 1 ;;
	esac
done


# applying filters
{
	for FILE in $FILES; do
		case "$FILE" in
            *.gz) CAT="gzip -dc" ;;
            *)    CAT="cat" ;;
        esac

		$CAT "$FILE" | while read -r line; do
			# apply -a [DATETIME] filter
			if [ -n "$TIME_A" ]; then
				RAW_LOG_TIME=$(echo "$line" | awk '{print $4 " " $5}')
				LOG_TIME_SECS=$(log_ts_to_epoch "$RAW_LOG_TIME")

				if [ "$TIME_A" -gt "$LOG_TIME_SECS" ]; then
					continue
				fi
			fi

			# apply -b [DATETIME] filter
			if [ -n "$TIME_B" ]; then
				RAW_LOG_TIME=$(echo "$line" | awk '{print $4 " " $5}')
				LOG_TIME_SECS=$(log_ts_to_epoch "$RAW_LOG_TIME")

				if [[ "$TIME_B" -lt "$LOG_TIME_SECS" ]]; then
					continue
				fi
			fi

			# apply -ip [IPADDR] filter
			if [ -n "$IP" ]; then
				CURRENT_IP=$(echo "$line" | awk '{print $1}')

				if [ "$IP" != "$CURRENT_IP" ]; then
					continue
				fi
			fi

			# apply -uri [URI] filter
			if [ -n "$URI" ]; then
				CURRENT_URI=$(echo "$line" | awk '{print $7}')

				if [ "$URI" != "$CURRENT_URI" ]; then
					continue
				fi
			fi
			
			echo "$line"
		done
	done


# executing commands 
} | case "$COMMAND" in
	"")
		awk '{print $0}' ;; # prints the whole log file
	list-ip) 
		awk '{print $1}' ;; # prints the 2nd column - IP
	list-hosts)
		awk '{print $1}' | sort -u | while read -r ip; do
			name=$(host "$ip")
			if [ "$name" == *")" ]; then 
				echo "$ip"
			else
				echo "$name" | sed 's/.* //; s/\(.*\)\./\1/'
			fi
		done ;;
	list-uri)
		awk '{print $7}' ;; # prints the 8th column - URI
	hist-ip)
		# sorts the IP column, counts unique occurrences, reverses the logs
		awk '{print $1}' | sort | uniq -c | sort -nr  | \
		# prints N '#' for each log, N = number of occurrences
		awk  '{ printf "%s  (%d): ", $2, $1; for(i=0; i<$1; i++) printf "#"; printf "\n" }' ;;
	hist-load)
		# converts minutes to '00', sorts the timedate column, counts unique occurences
		awk '{split($4, t, ":");
			split(substr(t[1], 2), date, "/");
			print date[3] "/" date[2] "/" date[1] " " t[2] ":00";
		}' | sort | uniq -c | \

		# creates a histogram for each hour with YYYY-MM-DD HH:00 format
		awk 'BEGIN {
			# creates a dictionary for all months Aaa : xx
			split("Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec", months);
			for (i=1; i<=12; i++){ 
				m[months[i]] = sprintf("%02d", i)
			} 
		}
		{
			split($2, td, "/");
			new_td = td[1] "-" m[td[2]] "-" td[3] " " $3;

			# creates a bar of $1 "#"
			bar = sprintf("%*s", $1, "");
			gsub(" ", "#", bar)

			# prints the final histogram line
			printf "%s (%d): %s", new_td, $1, bar;
			printf "\n";
		}' ;;
esac

