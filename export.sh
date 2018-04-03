#!/bin/bash

usage() { echo "Usage: $0 -k <keyspace> [-h <host>]" 1>&2; exit 1; }

host=localhost

while getopts ":k:h:" o; do
    case "${o}" in
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

if [ -z "${keyspace}" ]; then
    usage
fi

bkp_name="bkp-$$"
data_dir="/var/lib/cassandra/data"

echo "Create snapshot named: ${bkp_name}"
nodetool snapshot "${keyspace}" -t "${bkp_name}"

echo "Preparing backup file"
for name in $(find  "${data_dir}/${keyspace}/"*"/snapshots/${bkp_name}" -type f); do
        new=$(echo "$name" | sed -e "s#${data_dir}/##g" -e "s#\([^/]\+\)/\([^-]\+\).\+/snapshots/${bkp_name}/\([^/]\+\)\$#\1/\2/\3#g")
        mkdir -p "${bkp_name}/$(dirname $new)"
        cp "$name" "${bkp_name}/$new"
done

echo "Remove snapshot named: ${bkp_name}"
nodetool clearsnapshot -t "${bkp_name}" "${keyspace}"

echo "Dump keyspace and table creation instruction"
cqlsh "${host}" -e "desc \"${keyspace}\";" > "${bkp_name}/${keyspace}.sql"

echo "Create tar file: ${keyspace}.tar.gz"
cd "${bkp_name}"
tar -czf "../${keyspace}.tar.gz" .
cd -

echo "Remove temporary files"
rm -rf "${bkp_name}"