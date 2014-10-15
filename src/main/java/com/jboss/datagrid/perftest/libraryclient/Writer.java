package com.jboss.datagrid.perftest.libraryclient;

import org.infinispan.commons.api.AsyncCache;
import org.infinispan.context.Flag;

import java.util.logging.Logger;

/**
 * Created by tqvarnst on 15/10/14.
 */
public class Writer {


    static Logger log = Logger.getLogger(Writer.class.getName());

    private AsyncCache<Object,Object> cache;

    public Writer() {
        this(Constants.DEFAULT_WAITTIME_BETWEEN_INTERATIONS_IN_MS,Constants.DEFAULT_NUMBER_OF_ENTRIES, Constants.OBJECTSIZE);
    }

    public Writer(long waitTimeBetweenIterations) {
        this(waitTimeBetweenIterations,Constants.DEFAULT_NUMBER_OF_ENTRIES, Constants.OBJECTSIZE);
    }

    public Writer(long waitTimeBetweenIterations, long numberOfEntries) {
        this(waitTimeBetweenIterations, numberOfEntries, Constants.OBJECTSIZE);
    }

    public Writer(long waitTimeBetweenIterations, long numberOfEntries, int objectSize) {
        cache = EmbeddedCacheContainer.getCache(Constants.CACHE_NAME).getAdvancedCache().withFlags(Flag.SKIP_LOCKING,Flag.IGNORE_RETURN_VALUES);
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
            case 3 :
                new Writer(Long.parseLong(args[0]),Long.parseLong(args[1]),Integer.parseInt(args[2]));
                break;
            case 2 :
                new Writer(Long.parseLong(args[0]),Long.parseLong(args[1]));
                break;
            case 1 :
                new Writer(Long.parseLong(args[0]));
                break;
            default:
                new Writer();
        }
        log.info("Writer is done!!");
    }
}
