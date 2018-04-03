#!/bin/bash

usage() { echo "Usage: $0 -f <tar_file> [-h <host>]" 1>&2; exit 1; }

host=localhost

while getopts ":f:h:" o; do
    case "${o}" in
        f)
            tar_file=${OPTARG}
            ;;
        h)
            host=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [ -z "${tar_file}" ]; then
    usage
fi

bkp_name="bkp-$$"
keyspace=$(basename "${tar_file}" ".tar.gz")

mkdir -p "${bkp_name}"

tar -xvzf "${tar_file}" -C "${bkp_name}"

# update sql file with keyspace settings from host system
keyspace_sql=$(cqlsh "${host}" -e "desc \"${keyspace}\";" | grep "CREATE KEYSPACE")
sed -i "s/CREATE KEYSPACE .*/${keyspace_sql}/" "${bkp_name}/${keyspace}.sql"

echo "Drop keyspace ${keyspace}"
cqlsh --request-timeout="60" -e "drop keyspace \"${keyspace}\";"

echo "Create empty keyspace: ${keyspace}"
cat "${bkp_name}/${keyspace}.sql" | cqlsh

for dir in "${bkp_name}/${keyspace}/"*; do
    sstableloader -d "${host}" "${dir}"
done