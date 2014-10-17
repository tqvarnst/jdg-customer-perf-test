package com.jboss.datagrid.perftest.libraryclient;

import org.apache.log4j.Logger;
import org.infinispan.Cache;
import org.infinispan.commons.api.AsyncCache;
import org.infinispan.context.Flag;

import static com.jboss.datagrid.perftest.libraryclient.Constants.ClusterMode;

import java.util.HashMap;
import java.util.Map;
import java.util.Objects;

/**
 * Created by tqvarnst on 15/10/14.
 */
public class Writer implements Runnable {


    static Logger log = Logger.getLogger(Writer.class.getName());

    private Cache<Object,Object> cache;

    private long waitTimeBetweenIteration;
    private long numberOfEntries;
    private int objectSize;
    private boolean async=false;
    private boolean writeBulk=false;
    private int bulkSize;

    public Writer(ClusterMode clusterMode, long waitTimeBetweenIterations, long numberOfEntries, int objectSize, boolean async) {
        log.info("Initiating Writer in " + (async?"asynchronous":"synchronous") + " write mode");
        this.waitTimeBetweenIteration = waitTimeBetweenIterations;
        this.numberOfEntries = numberOfEntries;
        this.objectSize = objectSize;
        this.async = async;
        this.cache = EmbeddedCacheContainer.getCacheManager(clusterMode).getCache(Constants.CACHE_NAME).getAdvancedCache().withFlags(Flag.SKIP_LOCKING,Flag.IGNORE_RETURN_VALUES,Flag.FORCE_SYNCHRONOUS);
    }

    /**
     * Constructor for Bulk writer
     * @param clusterMode
     * @param waitTimeBetweenIterations
     * @param numberOfEntries
     * @param objectSize
     * @param writeBulk
     * @param bulkSize
     */
    public Writer(ClusterMode clusterMode, long waitTimeBetweenIterations, long numberOfEntries, int objectSize, boolean writeBulk, int bulkSize) {
        log.info("Initiating Writer in Bulk mode");
        this.waitTimeBetweenIteration = waitTimeBetweenIterations;
        this.numberOfEntries = numberOfEntries;
        this.objectSize = objectSize;
        this.writeBulk = writeBulk;
        this.bulkSize=bulkSize;
        this.cache = EmbeddedCacheContainer.getCacheManager(clusterMode).getCache(Constants.CACHE_NAME).getAdvancedCache().withFlags(Flag.SKIP_LOCKING,Flag.IGNORE_RETURN_VALUES,Flag.FORCE_SYNCHRONOUS);
    }

    @Override
    public void run() {

        while(true) {
            try {
                Thread.sleep(this.waitTimeBetweenIteration);
            } catch (InterruptedException e) {}

            if (!writeBulk) {
                writeObjects();
            } else {
                writeObjectsInBulk();
            }
        }
    }

    protected void writeObjects() {
        log.info("Writing " + numberOfEntries +  " objects to cache " + (async?"using async api":"using sync api"));
        final long start = System.currentTimeMillis();
        for (long i = 1; i <= numberOfEntries + 1; i++) {
            final byte[] record = new byte[objectSize];

            if (!async) {
                cache.put(i, record);
            } else {
                ((AsyncCache<Object,Object>)cache).putAsync(i,record);
            }
        }
        log.info("Added " + numberOfEntries + " to the cache in " + (System.currentTimeMillis()-start) + " ms");
    }

    protected void writeObjectsInBulk() {
        log.info("Writing " + numberOfEntries +  " objects to cache in bulks of " + bulkSize);
        final long start = System.currentTimeMillis();
        Map bulk = new HashMap<Object,Object>(bulkSize);


        for (long i = 1; i <= numberOfEntries + 1; i++) {
            bulk.put(i,new byte[objectSize]);
            if(i>0 && i%bulkSize==0) {
                log.info("Writing " + bulk.size() + " object in bulk");
                cache.putAll(bulk);
                bulk.clear();
            }
        }
        log.info("Added " + numberOfEntries + " to the cache in " + (System.currentTimeMillis()-start) + " ms");
    }


    public static void main(final String[] args) {
        log.info("Starting the writer....");
        switch (args.length) {
            case 6 :
                Writer w1 = new Writer(ClusterMode.valueOf(args[0]),Long.parseLong(args[1]),Long.parseLong(args[2]),Integer.parseInt(args[3]),Boolean.parseBoolean(args[4]),Integer.parseInt(args[5]));
                Thread t1 = new Thread(w1);
                t1.start();
                break;
            case 5 :
                Writer w2 = new Writer(ClusterMode.valueOf(args[0]),Long.parseLong(args[1]),Long.parseLong(args[2]),Integer.parseInt(args[3]),Boolean.parseBoolean(args[4]));
                Thread t2 = new Thread(w2);
                t2.start();
                break;
            default:
                System.out.println("Usage: Writer <cluster-mode> <wait time between iterations> <number of entries> <object size>");
                System.exit(99);
        }
    }
}
