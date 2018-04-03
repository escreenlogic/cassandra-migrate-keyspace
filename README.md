# Migrating from one Cassandra cluster to another

[Apache Cassandra](https://cassandra.apache.org/) is a free and open-source distributed NoSQL database management system designed to handle large amounts of data across many commodity servers, providing high availability with no single point of failure.

There is some documentation out their about how to migrate from one cluster to another:


* [Restoring a snapshot into a new cluster](http://docs.datastax.com/en/cassandra/2.1/cassandra/operations/ops_snapshot_restore_new_cluster.html)


Here are some scripts to help you do that quite easily. These scrips work if you're restoring on the same cluster or to another cluster, or even to a cluster with same or different topology:


Create export
-------------

* Export of keyspace schema structure with  [`DESC keyspace`](http://docs.datastax.com/en/cql/3.1/cql/cql_reference/describe_r.html)
* [Create a snapshot](http://docs.datastax.com/en/cassandra/2.1/cassandra/operations/ops_backup_takes_snapshot_t.html)
* Create a tar file with all the data
* [Remove the snapshot](http://docs.datastax.com/en/cassandra/2.1/cassandra/tools/toolsClearSnapShot.html)

The export script `export.sh` does all of those steps. Run the following command to export the data:

```bash
$ ./export.sh -k <keyspace name> [-h <host>]

``` 

You can get a list of your keyspace with `describe keyspaces`

Transfer the tar file to one of the node of the new cluster.

Import data
-------------

* "Copy" the old keyspace settings
* Drop the old keyspace
* Create the keyspace schema using the old keyspace settings
* Import data into table with [sstableloader](https://www.datastax.com/dev/blog/bulk-loading)

That what the `import.sh` script is doing from the previous generated tar file. Run the following command to import the data:

```bash
$ ./import.sh -f <keypsace backup tar file> [-h <host>]

```

