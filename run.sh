#!/bin/bash

echo -n "Checking if zoo.cfg exists... "
if [ ! -f /opt/zookeeper/conf/zoo.cfg ]
then
	echo "No. Creating a default"
	cp /opt/zookeeper/conf-dist/zoo_sample.cfg /opt/zookeeper/conf/zoo.cfg
else
	echo "Yes"
fi

echo -n "Checking if log4j.properties exists... "
if [ ! -f /opt/zookeeper/conf/log4j.properties ]
then
	echo "No. Creating a default"
	cp /opt/zookeeper/conf-dist/log4j.properties /opt/zookeeper/conf/log4j.properties
else
	echo "Yes"
fi

if [ "x$ZOOKEEPER_QUORUM" != "x" ]
then
	echo "Starting autoconfiguration of zookeeper quorum"

	if [ "x$SERVER_ID" = "x" ]
	then
		echo "Couldn't find env SERVER_ID"
		exit 1
	fi

	# remove any existing server items
	sed -i -e '/^server\.[0-9]*=.*/d' conf/zoo.cfg

	# Note the following modified from:
	# http://iocanel.blogspot.com/2014/10/zookeeper-on-kubernetes.html

	ZOO_DATA=`sed -n -e 's/^dataDir= *\(.*\)$/\1/p' conf/zoo.cfg`
	echo "Using a data directory of $ZOO_DATA"

	echo "$SERVER_ID" > $ZOO_DATA/myid
	#Find the servers exposed in env.
	for i in `seq 1 15`;do

		HOST=`printenv ZK_SERVER_${i}_SERVICE_HOST`
		LEADER=`printenv ZK_SERVER_${i}_SERVICE_PORT_LEADER`
		ELECTION=`printenv ZK_SERVER_${i}_SERVICE_PORT_ELECTION`

		if [ "$SERVER_ID" = "$i" ];then
			echo "Adding this server to the configuration as number $SERVER_ID"
			echo "server.$i=0.0.0.0:2888:3888" >> conf/zoo.cfg
		elif [ -z "$HOST" ] || [ -z "$LEADER" ] || [ -z "$ELECTION" ] ; then
			#if a server is not fully defined stop the loop here.
			echo "Finished searching for servers"
			break
		else
			echo "Adding server $i to configuration"
			echo "server.$i=$HOST:$LEADER:$ELECTION" >> conf/zoo.cfg
		fi

	done
fi

/opt/zookeeper/bin/zkServer.sh start-foreground

