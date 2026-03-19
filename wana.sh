#!/bin/bash

# initializing filter variables
TIME_A=""
TIME_B=""
IP=""
URI=""
COMMAND=""
FILE=""

# parsing arguments
while [[ $# -gt 0 ]]; do
	case "$1" in
		-a|-b|-ip|-uri)
			if [[ -z "$2" || "$2" == -* ]]; then
				echo "Argument for $1 is missing or invalid."
				exit 1
			fi
	
			case "$1" in
				-a) TIME_A="$2" ;;
				-b) TIME_B="$2" ;;
				-ip) IP="$2" ;;
				-uri) URI="$2" ;;
			esac

			shift 2
			;;

		list-ip|list-hosts|list-uri|hist-ip|hist-load)
			COMMAND="$1"
			shift
			;;

		*.log|.gz)
			FILE="$1"
			shift
			;;

		*)
			echo "Invalid option: $1"
			exit 1
			;;
	esac
done


# executing commands
case "$COMMAND" in
	list-ip) 
		awk '{print $1}' "$FILE"
		;;
	list-hosts)
		awk '{print $11}' "$FILE"
		;;
	list-uri)
		awk '{print $7}' "$FILE"
		;;
	hist-ip)
		awk '{print $1}' "$FILE" | sort | uniq -c | sort -nr  |head -n 15 | \
		awk  '{ printf "%-39s  (%d): ", $2, $1; for(i=0; i<$1; i++) printf "#"; printf "\n" }'
		;;
	hist-load)
		awk '{split($4, t, ":");
			print substr(t[1], 2) ":" t[2] ":00";
		}' "$FILE" | sort | uniq -c | \
		awk 'BEGIN {
			split("Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec", months);
			for (i=1; i<=12; i++) m[months[i]] = sprintf("%02d", i)
		}
		{
			split($2, d, "/");
			new_date = d[1] "-" m[d[2]] "-" d[3];
			printf "%-19s (%2d): ", new_date, $1;
			for(i=0; i<$1; i++) printf "#"; printf "\n";
		}'
		;;
esac

