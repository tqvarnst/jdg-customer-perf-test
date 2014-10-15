#!/bin/bash

#Make sure we are in the root dir
pushd $(dirname $0) > /dev/null

JAVA_OPS="-XX:+UseConcMarkSweepGC -XX:+UseParNewGC -Xms1g -Xmx1g -verbose:gc -XX:+PrintGCDetails -XX:+PrintGCTimeStamps -Dlog4j.configuration=log4j.xml"
#JAVA_OPS="-XX:+UseConcMarkSweepGC -XX:+UseParNewGC -Xms1g -Xmx1g"
READ_CLIENT_JAR=target/reader-jar-with-dependencies.jar
WRITE_CLIENT_JAR=target/writer-jar-with-dependencies.jar

#DEFAULT VALUES
WAIT_TIME=10000
OBJECT_COUNT=100000
OBJECT_SIZE=600
READ_ENTRIES=false

NUM_OF_READERS=1

CLUSTER_MODE=DIST_SYNC

mkdir -p pids

function start_server_logs {
    mkdir -p logs
    mpstat -P ALL 2 > logs/server.log 2>&1 &
    echo "$!" > pids/server-loger.pid
}

function start_readers {
    if [[ "$5" != "" ]]; then
        READ_ENTRIES=$5
    fi
    if [[ "$4" != "" ]]; then
        OBJECT_COUNT=$4
    fi
    if [[ "$3" != "" ]]; then
        WAIT_TIME=$3
    fi
    if [[ "$2" != "" ]]; then
        NUM_OF_READERS=$2
    fi
    if [[ "$1" != "" ]]; then
        CLUSTER_MODE=$1
    fi
    echo "Starting $NUM_OF_READERS readers"
    for i in $(seq 1 $NUM_OF_READERS)
    do
        echo "Starting reader $i"
        mkdir -p logs
        java ${JAVA_OPS} -DINSTANCE_NAME=byte-reader-${i} -jar ${READ_CLIENT_JAR} ${CLUSTER_MODE} ${WAIT_TIME} ${OBJECT_COUNT} ${READ_ENTRIES} | tee logs/reader-$i.log
        echo "$!" > pids/reader-$i.pid
    done
}

function start_writer {
    if [[ "$4" != "" ]]; then
        OBJECT_SIZE=$4
    fi
    if [[ "$3" != "" ]]; then
        OBJECT_COUNT=$3
    fi
    if [[ "$2" != "" ]]; then
        WAIT_TIME=$2
    fi
    if [[ "$1" != "" ]]; then
        CLUSTER_MODE=$1
    fi
    echo "Starting Writer with parameter CLUSTER_MODE=${CLUSTER_MODE} WAIT_TIME=${WAIT_TIME} OBJECT_COUNT=${OBJECT_COUNT} OBJECT_SIZE=${OBJECT_SIZE}"
    java ${JAVA_OPS} -DINSTANCE_NAME=byte-writer -jar ${WRITE_CLIENT_JAR} ${CLUSTER_MODE} ${WAIT_TIME} ${OBJECT_COUNT} ${OBJECT_SIZE}  | tee logs/writer.log
    echo "$!" > pids/writer.pid
}

case "$1" in
    build)
        mvn clean install -P no-settings
        mvn assembly:single -P no-settings
        mvn assembly:single -P writer,no-settings
        ;;

    start)
        shift
        case "$1" in
            reader)
                shift
                start_readers $@
                ;;
            writer)
                shift
                start_writer $@
                ;;
            server-log)
                start_server_logs
                ;;
            *)
                echo "usage: cli.sh start (reader|writer|server-log)"
                popd > /dev/null
                exit 1
        esac
        ;;
    view)
        shift
        case "$1" in
            server-log)
                cat logs/server.log | more
                ;;
            reader-log)
                shift
                cat logs/reader-$1.log | more
                ;;
            writer-log)
                cat logs/writer.log | more
                ;;
            *)
                echo "usage: cli.sh view (server-log|reader-log <num>|writer)"
                popd > /dev/null
                exit 1
        esac
        ;;
    stop-all)
        for pidfile in $(ls pids/*.pid)
        do
            echo "Killing process width pid $(cat $pidfile)"
            kill $(cat $pidfile)
            rm $pidfile
        done
        ;;
    export)
        shift
        if [[ "x$1" = "x" ]]; then
            echo "usage: cli.sh export <outputfile>"
            popd > /dev/null
            exit 1
        fi
        cat logs/server.log | grep all | awk '{ print $1,$4,$12 }' > $1
        ;;
     *)
        echo "usage: cli.sh (build|start|view|stop-all|export)"
        popd > /dev/null
        exit 1
esac

popd > /dev/null

