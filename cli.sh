#!/bin/bash

#Make sure we are in the root dir
pushd $(dirname $0) > /dev/null

#JAVA_OPS="-XX:+UseConcMarkSweepGC -XX:+UseParNewGC -Xms1g -Xmx1g -verbose:gc -XX:+PrintGCDetails -XX:+PrintGCTimeStamps -Dlog4j.configuration=log4j.xml"
JAVA_OPS="-XX:+UseConcMarkSweepGC -XX:+UseParNewGC -Xms1g -Xmx1g -Dlog4j.configuration=log4j.xml -Dlog4j.debug=true"
READ_CLIENT_JAR=target/reader-jar-with-dependencies.jar
WRITE_CLIENT_JAR=target/writer-jar-with-dependencies.jar

#DEFAULT VALUES
WAIT_TIME=60000
OBJECT_COUNT=100000
OBJECT_SIZE=600
READ_ENTRIES=true
NUM_OF_READERS=10
BATCH_SIZE=1000

CLUSTER_MODE=REPL_ASYNC

USE_ASYNC_API=
USE_BULK=

TEST_EXECUTION_TIME=300  #Tests are run for 300sek or 5 min

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
        java ${JAVA_OPS} -DINSTANCE_NAME=byte-reader-${i} -jar ${READ_CLIENT_JAR} ${CLUSTER_MODE} ${WAIT_TIME} ${OBJECT_COUNT} ${READ_ENTRIES} > logs/reader-$i.log 2>&1 &
        echo "$!" > pids/reader-$i.pid
    done
}

function start_writer {
    if [[ "$6" != "" ]]; then
        USE_BULK=$5
        BULK_SIZE=$6
    elif [[ "$5" != "" ]]; then
        USE_ASYNC_API=$5
    fi
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
    echo "Starting Writer with parameter CLUSTER_MODE=${CLUSTER_MODE} WAIT_TIME=${WAIT_TIME} OBJECT_COUNT=${OBJECT_COUNT} OBJECT_SIZE=${OBJECT_SIZE} USE_ASYNC_API=${USE_ASYNC_API} USE_BULK=${USE_BULK} BULK_SIZE=${BULK_SIZE}"
    java ${JAVA_OPS} -DINSTANCE_NAME=byte-writer -jar ${WRITE_CLIENT_JAR} ${CLUSTER_MODE} ${WAIT_TIME} ${OBJECT_COUNT} ${OBJECT_SIZE} ${USE_ASYNC_API} ${USE_BULK} ${BULK_SIZE}> logs/writer.log 2>&1 &
    echo "$!" > pids/writer.pid
}

function stop_all_pids {

    for pidfile in $(ls pids/*.pid 2>/dev/null)
    do
        while (( "$(ps -p $(cat ${pidfile}) | grep -v PID | wc -l)" > 0 ))
        do
            echo "Killing process width pid $(cat $pidfile)"
            kill $(cat $pidfile)
            sleep 1
        done
        rm -f $pidfile
    done

}

function create_reports {
    testcase=$1
    mkdir -p results
    cat logs/server.log | grep all | awk '{ print $1,$4,$12 }' | tr " " ","  > results/cpu_load_${testcase}.csv
    cat logs/writer.log | grep "com.jboss.datagrid.perftest.libraryclient.Writer" > results/write_perf_report_${testcase}.log


    reader_log_file=results/read_perf_report_${testcase}.log

    echo "###### READ PERFORMANCE REPORT #######" > $reader_log_file

    for reader in $(ls logs/reader-*.log 2>/dev/null)
    do
        echo ">>>>>>>>>>>>>>> $reader_log_file <<<<<<<<<<<<<<<" >> $reader_log_file
        cat $reader | grep "com.jboss.datagrid.perftest.libraryclient.Reader Reading" >> $reader_log_file
        echo ">>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<" >> $reader_log_file
    done

}

function executeTests {
    testReplAsync16ReaderNodesAsyncAPI
    testReplAsync16ReaderNodesSyncAPI
    testReplSync16ReaderNodesAsyncAPI
    testReplSync16ReaderNodesSyncAPI
    testReplAsync16ReaderNodesBulkAPI
    testReplSync16ReaderNodesBulkAPI
}



function testReplAsync16ReaderNodesSyncAPI {
    stop_all_pids
    rm -rf logs/*
    start_readers REPL_ASYNC ${NUM_OF_READERS} ${WAIT_TIME} ${OBJECT_COUNT} ${READ_ENTRIES}
    start_writer REPL_ASYNC ${WAIT_TIME} ${OBJECT_COUNT} ${OBJECT_SIZE} false
    sleep 10 # Wait for servers to start
    start_server_logs
    sleep ${TEST_EXECUTION_TIME}
    stop_all_pids
    create_reports "repl_async_syncapi"
}

function testReplAsync16ReaderNodesAsyncAPI {
    stop_all_pids
    rm -rf logs/*
    start_readers REPL_ASYNC ${NUM_OF_READERS} ${WAIT_TIME} ${OBJECT_COUNT} ${READ_ENTRIES}
    start_writer REPL_ASYNC ${WAIT_TIME} ${OBJECT_COUNT} ${OBJECT_SIZE} true
    sleep 10 # Wait for servers to start
    start_server_logs
    sleep ${TEST_EXECUTION_TIME}
    stop_all_pids
    create_reports "repl_async_asyncapi"
}

function testReplSync16ReaderNodesSyncAPI {
    stop_all_pids
    rm -rf logs/*
    start_readers REPL_SYNC ${NUM_OF_READERS} ${WAIT_TIME} ${OBJECT_COUNT} ${READ_ENTRIES}
    start_writer REPL_SYNC ${WAIT_TIME} ${OBJECT_COUNT} ${OBJECT_SIZE} false
    sleep 10 # Wait for servers to start
    start_server_logs
    sleep ${TEST_EXECUTION_TIME}
    stop_all_pids
    create_reports "repl_sync_syncapi"
}

function testReplSync16ReaderNodesAsyncAPI {
    stop_all_pids
    rm -rf logs/*
    start_readers REPL_SYNC ${NUM_OF_READERS} ${WAIT_TIME} ${OBJECT_COUNT} ${READ_ENTRIES}
    start_writer REPL_SYNC ${WAIT_TIME} ${OBJECT_COUNT} ${OBJECT_SIZE} true
    sleep 10 # Wait for servers to start
    start_server_logs
    sleep ${TEST_EXECUTION_TIME}
    stop_all_pids
    create_reports "repl_sync_asyncapi"
}

function testReplAsync16ReaderNodesBulkAPI {
    stop_all_pids
    rm -rf logs/*
    start_readers REPL_ASYNC ${NUM_OF_READERS} ${WAIT_TIME} ${OBJECT_COUNT} ${READ_ENTRIES}
    start_writer REPL_ASYNC ${WAIT_TIME} ${OBJECT_COUNT} ${OBJECT_SIZE} true ${BATCH_SIZE}
    sleep 10 # Wait for servers to start
    start_server_logs
    sleep ${TEST_EXECUTION_TIME}
    stop_all_pids
    create_reports "repl_async_bulkapi"
}

function testReplSync16ReaderNodesBulkAPI {
    stop_all_pids
    rm -rf logs/*
    start_readers REPL_SYNC ${NUM_OF_READERS} ${WAIT_TIME} ${OBJECT_COUNT} ${READ_ENTRIES}
    start_writer REPL_SYNC ${WAIT_TIME} ${OBJECT_COUNT} ${OBJECT_SIZE} true ${BATCH_SIZE}
    sleep 10 # Wait for servers to start
    start_server_logs
    sleep ${TEST_EXECUTION_TIME}
    stop_all_pids
    create_reports "repl_sync_bulkapi"
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
        stop_all_pids
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
    run-tests)
        shift
        executeTests
        ;;
    run-test)
        shift
        case "$1" in
            repl-sync-sync)
                testReplSync16ReaderNodesSyncAPI
                ;;
            repl-async-sync)
                testReplAsync16ReaderNodesSyncAPI
                ;;
            repl-sync-async)
                testReplSync16ReaderNodesAsyncAPI
                ;;
            repl-async-async)
                testReplAsync16ReaderNodesAsyncAPI
                ;;
            repl-async-bulk)
                testReplAsync16ReaderNodesBulkAPI
                ;;
            repl-sync-bulk)
                testReplSync16ReaderNodesBulkAPI
                ;;
            *)
                echo "usage: cli.sh run-test (repl-async-bulk)"
                popd > /dev/null
                exit 1
        esac
        ;;

     *)
        echo "usage: cli.sh (build|start|view|stop-all|export)"
        popd > /dev/null
        exit 1
esac

popd > /dev/null

