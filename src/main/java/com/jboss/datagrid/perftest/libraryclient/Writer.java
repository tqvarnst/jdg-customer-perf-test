package com.jboss.datagrid.perftest.libraryclient;

import org.infinispan.Cache;
import org.infinispan.commons.api.AsyncCache;
import org.infinispan.context.Flag;

import static com.jboss.datagrid.perftest.libraryclient.Constants.ClusterMode;

import java.util.Objects;
import java.util.logging.Logger;

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

    public Writer(ClusterMode clusterMode, long waitTimeBetweenIterations, long numberOfEntries, int objectSize, boolean async) {
        this.waitTimeBetweenIteration = waitTimeBetweenIterations;
        this.numberOfEntries = numberOfEntries;
        this.objectSize = objectSize;
        this.async = async;
        this.cache = EmbeddedCacheContainer.getCacheManager(clusterMode).getCache(Constants.CACHE_NAME).getAdvancedCache().withFlags(Flag.SKIP_LOCKING,Flag.IGNORE_RETURN_VALUES,Flag.FORCE_SYNCHRONOUS);
    }

    @Override
    public void run() {

        while(true) {
            try {
                Thread.sleep(this.waitTimeBetweenIteration);
            } catch (InterruptedException e) {}

            log.info("Pushing objects to cache");
            final long start = System.currentTimeMillis();
            for (long i = 1; i <= numberOfEntries + 1; i++) {
                final byte[] record = new byte[objectSize];

                if (!async) {
                    cache.put(i, record);
                } else {
                    ((AsyncCache<Object,Object>)cache).putAsync(i,record);
                }
            }
            log.info("Added " + numberOfEntries + " async to the cache in " + (System.currentTimeMillis()-start) + " ms");
        }
    }


    public static void main(final String[] args) {
        log.info("Starting the writer....");
        switch (args.length) {
            case 5 :
                Writer writer = new Writer(ClusterMode.valueOf(args[0]),Long.parseLong(args[1]),Long.parseLong(args[2]),Integer.parseInt(args[3]),Boolean.parseBoolean(args[4]));
                Thread t1 = new Thread(writer);
                t1.start();
                break;
            default:
                System.out.println("Usage: Writer <cluster-mode> <wait time between iterations> <number of entries> <object size>");
                System.exit(99);
        }
    }
}
