#!/bin/bash

usage() { echo "Usage: $0 -f <tar_file> -k <keyspace> [-h <host>]" 1>&2; exit 1; }

host=localhost

while getopts ":f:k:h:" o; do
    case "${o}" in
        f)
            tar_file=${OPTARG}
            ;;
        k)
            keyspace=${OPTARG}
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

if [ -z "${tar_file}" ] || [ -z "${keyspace}" ]; then
    usage
fi

bkp_name="bkp-$$"
data_dir=$(basename "${tar_file}" ".tar.gz")

mkdir -p "${bkp_name}"

tar -xvzf "${tar_file}" -C "${bkp_name}"

# update sql file with keyspace settings from host system
keyspace_sql=$(cqlsh "${host}" -e "desc \"${keyspace}\";" | grep "CREATE KEYSPACE")
sed -i "s/CREATE KEYSPACE .*/${keyspace_sql}/" "${bkp_name}/${data_dir}.sql"

# make sure the keyspace name are correct
sed -i "s/CREATE TABLE [A-Za-z]\{1,\}./CREATE TABLE ${keyspace}./" "${bkp_name}/${data_dir}.sql"

# if we are changing keyspaces, rename the data directory
if [[ ! -d "${bkp_name}/${keyspace}" ]]; then
    mv "${bkp_name}/${data_dir}" "${bkp_name}/${keyspace}"
fi

echo "Drop keyspace ${keyspace}"
cqlsh "${host}" --request-timeout="60" -e "drop keyspace \"${keyspace}\";"

echo "Create empty keyspace: ${keyspace}"
cat "${bkp_name}/${data_dir}.sql" | cqlsh "${host}"

for dir in "${bkp_name}/${keyspace}/"*; do
    sstableloader -d "${host}" "${dir}"
done