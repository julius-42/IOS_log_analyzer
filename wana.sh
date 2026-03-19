#!/bin/bash

if [[ -z "$1" ]]; then
	echo "No file provided"
	exit 1
fi

if [[ -z "$2" ]]; then
	awk '{print $0}' ${1}
fi

if [[ "$2" == "time" ]]; then
        awk '{print $4}' ${1}
fi


if [[ "$2" == "list_ip" ]]; then
	awk '{print $1}' ${1}
fi

if [[ "$2" == "list_hosts" ]]; then
	awk '{print $11}' ${1}
fi

if [[ "$2" == "list_uri" ]]; then
	awk '{print $7}' ${1}
fi

if [[ "$2" == "hist_ip" ]]; then
	awk '{print $1}' ${1} | sort | uniq -c | sort -nr  |head -n 15 | \
	awk  '{ printf "%-39s  (%d): ", $2, $1; for(i=0; i<$1; i++) printf "#"; printf "\n" }'
fi

if [[ "$2" == "hist_load" ]]; then
	awk '{split($4, t, ":");
		print substr(t[1], 2) ":" t[2] ":00";
	}' ${1} | sort | uniq -c | \
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
fi
