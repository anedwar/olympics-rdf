#!/bin/bash
mydir=`dirname $0`                # scriptdir
mydir=$(cd -P -- $mydir && pwd -P)  # absolutify path
echo Working from $mydir

host=$1
remote_data_path=$2

if [ "$remote_data_path" = "" ]
then
	echo "[$0] host remote_data_dir"
	echo "runs the Wallscope benchmark against AnzoGraph. This requires that enable_sparql_protocl=true in the settings file."
	echo "creates an output directory to store results."
	echo ""
	echo "host: ip address or host name to connect to"
	echo "remote_data_dir: path to the olympics.ttl file on the remote host"
	exit 1
fi

data_dir="$mydir/data"
query_dir="$mydir/queries"
output_dir="$mydir/output"

#runs the query against anzograph via sparql port 7070 using curl
#arg1: host
#arg2: query path

function execute_query {
	if [ "$1" = "" ]
	then
		echo "host argument must be supplied to execute_query"
		return
	fi

	if [ "$2" = "" ]
	then
		echo "query argument must be supplied to execute_query"
		return
	fi
	query_name=$(echo -n $2 | awk -F"/" {'print $NF'})
	curl http://$1:7070/sparql/ -H "Accept: application/sparql-results+csv" --data-urlencode query@$2 -w "$query_name, %{time_total}\n" --output "$output_dir/$query_name" -s
}

#runs the query against anzograph via sparql port 7070 using curl
#arg1: host
#arg2: query string

function execute_query_string {
	if [ "$1" = "" ]
	then
		echo "host argument must be supplied to execute_query"
		return
	fi

	if [ "$2" = "" ]
	then
		echo "query argument must be supplied to execute_query"
		return
	fi
	curl http://$1:7070/sparql/ -H "Accept: application/sparql-results+csv" --data-urlencode "query=$2" -w "%{time_total}\n" -s
}

mkdir -p $output_dir
#loading data
echo -n "load,"
execute_query_string $host "load <dir:$remote_data_path>"
for query in $(ls $query_dir/*.rq)
do
	execute_query $host $query
done
echo -n "cleanup,"
execute_query_string $host "delete {?s ?p ?o } where {?s ?p ?o}"
