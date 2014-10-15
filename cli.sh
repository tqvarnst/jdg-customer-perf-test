#!/bin/bash

#Make sure we are in the root dir
pushd $(dirname $0) > /dev/null

#JAVA_OPS="-XX:+UseConcMarkSweepGC -XX:+UseParNewGC -Xms1g -Xmx1g -verbose:gc -XX:+PrintGCDetails -Djava.net.preferIPv4Stack=true -XX:+PrintGCTimeStamps -Xloggc:jdg-client-gc.log"
JAVA_OPS="-XX:+UseConcMarkSweepGC -XX:+UseParNewGC -Xms1g -Xmx1g"
READ_CLIENT_JAR=target/reader-jar-with-dependencies.jar
WRITE_CLIENT_JAR=target/writer-jar-with-dependencies.jar

WAIT_TIME=10000
OBJECT_COUNT=100000
OBJECT_SIZE=600

NUM_OF_READERS=1

mkdir -p pids

function start_server_logs {
    mkdir -p logs
    mpstat -P ALL 2 > logs/server.log 2>&1 &
    echo "$!" > pids/server-loger.pid
}

function start_readers {
    if [[ "$1" != "" ]]; then
        NUM_OF_READERS=$1
    fi
    echo "Starting $NUM_OF_READERS readers"
    for i in $(seq 1 $NUM_OF_READERS)
    do
        echo "Starting reader $i"
        mkdir -p logs
        java ${JAVA_OPS} -DINSTANCE_NAME=byte-reader-${i} -jar ${READ_CLIENT_JAR} ${WAIT_TIME} ${OBJECT_COUNT} > logs/reader-$i.log 2>&1 &
        echo "$!" > pids/reader-$i.pid
    done
}

function start_writer {
    echo "Starting writer"
    java ${JAVA_OPS} -DINSTANCE_NAME=byte-writer -jar ${WRITE_CLIENT_JAR} ${WAIT_TIME} ${OBJECT_COUNT} ${OBJECT_SIZE}  > logs/writer.log 2>&1 &
    echo "$!" > pids/writer.pid
}

case "$1" in
    build)
        mvn clean install -P no-settings
        mvn assembly:single -P no-settings
        mvn assembly:single -P writer,no-settings
        ;;

    start)
        case "$2" in
            reader)
                start_readers $3
                ;;
            writer)
                start_writer
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
        case "$2" in
            server-log)
                cat logs/server.log | more
                ;;
            reader-log)
                cat logs/reader-$3.log | more
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
        if [[ "x$2" = "x" ]]; then
            echo "usage: cli.sh export <outputfile>"
            popd > /dev/null
            exit 1
        fi
        cat logs/server.log | grep all | awk '{ print $1,$4,$12 }' > $2
        ;;
     *)
        echo "usage: cli.sh (build|start|view|stop-all|export)"
        popd > /dev/null
        exit 1
esac

popd > /dev/null

