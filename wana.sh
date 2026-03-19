#!/bin/bash

# initializing variables
TIME_A=""
TIME_B=""
IP=""
URI=""
COMMAND=""
FILE=""

# convert argument time format to Unix seconds
get_timestamp() {
  if [[ "$(uname)" == "Darwin" ]]; then
    date -j -f "%Y-%m-%d %H:%M:%S" "$1" "+%s"
  else
    date -d "$1" "+%s"
  fi
}

# clean the log time from brackets and other unwanted chars
clean_log_date() {
  echo "$1" | sed 's/\[//g; s/\]//g; s/\// /g; s/:/ /'
}

# convert clean log time format to Unix seconds
get_log_timestamp() {
  local clean_time=$(clean_log_date "$1")
  
  if [[ "$(uname)" == "Darwin" ]]; then
    date -j -f "%d %b %Y %H %M %S %z" "$clean_time" "+%s"
  else
    date -d "$clean_time" "+%s"
  fi
}


# parsing arguments
while [[ $# -gt 0 ]]; do
	case "$1" in
		-a|-b|-ip|-uri)
			if [[ -z "$2" || "$2" == -* ]]; then
				echo "Argument for $1 is missing or invalid."
				exit 1
			fi
	
			case "$1" in
				-a) TIME_A=$(get_timestamp "$2") ;;
				-b) TIME_B=$(get_timestamp "$2") ;;
				-ip) IP="$2" ;;
				-uri) URI="$2" ;;
			esac

			shift 2 ;;

		list-ip|list-hosts|list-uri|hist-ip|hist-load)
			COMMAND="$1"
			shift ;;

		*.log|.gz)
			FILE="$1"
			shift ;;

		*)
			echo "Invalid option: $1"
			exit 1 ;;
	esac
done

# applying filters
{
	while read -r line; do
		if [[ -n "$TIME_A" ]]; then
			RAW_LOG_TIME=$(echo "$line" | awk '{print $4 " " $5}')
			LOG_TIME_SECS=$(get_log_timestamp "$RAW_LOG_TIME")

			if [[ "$TIME_A" -gt "$LOG_TIME_SECS" ]]; then
				continue
			fi

		fi

		if [[ -n "$TIME_B" ]]; then
			RAW_LOG_TIME=$(echo "$line" | awk '{print $4 " " $5}')
			LOG_TIME_SECS=$(get_log_timestamp "$RAW_LOG_TIME")

			if [[ "$TIME_B" -lt "$LOG_TIME_SECS" ]]; then
				continue
			fi

		fi
		
		echo "$line"
	done < "$FILE"


# executing commands 
} | case "$COMMAND" in
	"")
		awk '{print $0}' ;;
	list-ip) 
		awk '{print $1}' ;;
	list-hosts)
		awk '{print $11}' ;;
	list-uri)
		awk '{print $7}' ;;
	hist-ip)
		awk '{print $1}' | sort | uniq -c | sort -nr  |head -n 15 | \
		awk  '{ printf "%-39s  (%d): ", $2, $1; for(i=0; i<$1; i++) printf "#"; printf "\n" }' ;;
	hist-load)
		awk '{split($4, t, ":");
			print substr(t[1], 2) ":" t[2] ":00";
		}' | sort | uniq -c | \
		awk 'BEGIN {
			split("Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec", months);
			for (i=1; i<=12; i++) m[months[i]] = sprintf("%02d", i)
		}
		{
			split($2, d, "/");
			new_date = d[1] "-" m[d[2]] "-" d[3];
			printf "%-19s (%2d): ", new_date, $1;
			for(i=0; i<$1; i++) printf "#"; printf "\n";
		}' ;;
esac

