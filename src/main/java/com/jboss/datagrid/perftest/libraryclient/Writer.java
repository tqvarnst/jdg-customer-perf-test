package com.jboss.datagrid.perftest.libraryclient;

import org.infinispan.commons.api.AsyncCache;
import org.infinispan.context.Flag;

import static com.jboss.datagrid.perftest.libraryclient.Constants.ClusterMode;

import java.util.logging.Logger;

/**
 * Created by tqvarnst on 15/10/14.
 */
public class Writer {


    static Logger log = Logger.getLogger(Writer.class.getName());

    private AsyncCache<Object,Object> cache;

    public Writer(ClusterMode clusterMode, long waitTimeBetweenIterations, long numberOfEntries, int objectSize) {
        cache = EmbeddedCacheContainer.getCacheManager(clusterMode).getCache(Constants.CACHE_NAME).getAdvancedCache().withFlags(Flag.SKIP_LOCKING,Flag.IGNORE_RETURN_VALUES);
        while(true) {
            try {
                Thread.sleep(waitTimeBetweenIterations);
            } catch (InterruptedException e) {}

            log.info("Pushing objects to cache");
            final long start = System.currentTimeMillis();
            for (long i = 1; i <= numberOfEntries + 1; i++) {
                final byte[] record = new byte[objectSize];
                cache.putAsync(i, record);
            }
            log.info("Added " + numberOfEntries + " async to the cache in " + (System.currentTimeMillis()-start) + " ms");
        }
    }


    public static void main(final String[] args) {
        log.info("Starting the writer....");
        switch (args.length) {
            case 4 :
                new Writer(ClusterMode.valueOf(args[0]),Long.parseLong(args[1]),Long.parseLong(args[2]),Integer.parseInt(args[2]));
                break;
            default:
                System.out.println("Usage: Writer <cluster-mode> <wait time between iterations> <number of entries> <object size>");
                System.exit(99);
        }
    }
}
