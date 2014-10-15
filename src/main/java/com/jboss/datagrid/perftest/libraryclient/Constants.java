package com.jboss.datagrid.perftest.libraryclient;

/**
 * Created by tqvarnst on 15/10/14.
 */
public class Constants {

    /**
     *
     */
    public static final long ONE_SECOND_IN_MS = 1000;

    /**
     *
     */
    public static final long DEFAULT_WAITTIME_BETWEEN_INTERATIONS_IN_MS = 60 * ONE_SECOND_IN_MS;

    /**
     * Not used
     */
    public static final boolean DEFAULT_USE_TRANSACTION=false;

    /**
     *
     */
    public static final long DEFAULT_NUMBER_OF_ENTRIES=60000;

    /**
     *
     */
    public static final String CACHE_NAME = "mytestcache";

    /**
     *
     */
    public static final int OBJECTSIZE = 600;


    /**
     * This flag indicated weather the reader should actually read the entries. Reading allot of entries will consume cpu cycles
     */
    public static final boolean DEFAULT_READ_ENTRIES=false;

    /**
     *
     */
    public static final ClusterMode DEFAULT_CLUSTER_MODE =ClusterMode.REPL_SYNC;


    public enum ClusterMode {
        DIST_SYNC, DIST_ASYNC, REPL_SYNC, REPL_ASYNC;

        public String getConfig() {
            switch (this) {
                case DIST_ASYNC:
                    return "infinispan-distribution_async.xml";
                case DIST_SYNC:
                    return "infinispan-distribution_sync.xml";
                case REPL_ASYNC:
                    return "infinispan-replication_async.xml";
                case REPL_SYNC:
                    return "infinispan-replication_sync.xml";
                default:
                    throw new RuntimeException("Unknown Cluster mode");
            }
        }

    }


}
