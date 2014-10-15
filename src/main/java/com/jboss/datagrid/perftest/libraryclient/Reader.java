package com.jboss.datagrid.perftest.libraryclient;

import org.infinispan.Cache;
import org.infinispan.context.Flag;

import java.util.logging.Logger;

/**
 * Created by tqvarnst on 15/10/14.
 */
public class Reader {


    static Logger log = Logger.getLogger(Reader.class.getName());




    private Cache<Object,Object> cache;

    public Reader() {
        this(Constants.DEFAULT_WAITTIME_BETWEEN_INTERATIONS_IN_MS,Constants.DEFAULT_NUMBER_OF_ENTRIES);
    }

    public Reader(long waitTimeBetweenIterations) {
        this(waitTimeBetweenIterations,Constants.DEFAULT_NUMBER_OF_ENTRIES);
    }

    public Reader(long waitTimeBetweenIterations, long numberOfEntries) {
        long count = 0;
        cache = EmbeddedCacheContainer.getCache(Constants.CACHE_NAME).getAdvancedCache().withFlags(Flag.CACHE_MODE_LOCAL,Flag.SKIP_LOCKING);
        while(true) {
            count=0;
            try {
                Thread.sleep(waitTimeBetweenIterations);
            } catch (InterruptedException e) {}

            /*
            long startTime = System.currentTimeMillis();
            for (long i = 0; i <= numberOfEntries; i++) {
                if (cache.get(i) != null) {
                    count++;
                }
            }
            log.info("Reading " + count + " objects from the cache took " + (System.currentTimeMillis()-startTime) + " ms");
            */
        }
    }

    public static void main(final String[] args) {
        log.info("Starting the reader....");
        switch (args.length) {
            case 2 :
                new Reader(Long.parseLong(args[0]),Long.parseLong(args[1]));
                break;
            case 1 :
                new Reader(Long.parseLong(args[0]));
                break;
            default:
                new Reader();
        }
    }
}
