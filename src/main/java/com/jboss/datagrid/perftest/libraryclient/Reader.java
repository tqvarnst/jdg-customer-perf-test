package com.jboss.datagrid.perftest.libraryclient;

import org.apache.log4j.Logger;
import org.infinispan.Cache;
import org.infinispan.context.Flag;

import static com.jboss.datagrid.perftest.libraryclient.Constants.ClusterMode;


public class Reader {

    static Logger log = Logger.getLogger(Reader.class.getName());

    private Cache<Object,Object> cache;

    public Reader(ClusterMode clusterMode, long waitTimeBetweenIterations, long numberOfEntries, boolean readEntries) {
        long count = 0;
        cache = EmbeddedCacheContainer.getCacheManager(clusterMode)
                .getCache(Constants.CACHE_NAME)
                .getAdvancedCache()
                .withFlags(Flag.CACHE_MODE_LOCAL,
                        Flag.SKIP_LOCKING);
        while(true) {
            count=0;
            try {
                Thread.sleep(waitTimeBetweenIterations);
            } catch (InterruptedException e) {}

            if(readEntries) {
                long startTime = System.currentTimeMillis();
                for (long i = 0; i <= numberOfEntries; i++) {
                    if (cache.get(i) != null) {
                        count++;
                     }
                }
                log.info("Reading " + count + " objects from the cache took " + (System.currentTimeMillis() - startTime) + " ms");
            }
        }
    }

    public static void main(final String[] args) {
        log.info("Starting the reader....");
        switch (args.length) {
            case 4 :
                new Reader(ClusterMode.valueOf(args[0]),Long.parseLong(args[1]),Long.parseLong(args[2]),Boolean.parseBoolean(args[3]));
                break;
            default:
                System.out.println("Usage: Reader <cluster-mode> <wait time between iterations> <number of entries> <read entries>");
                System.exit(99);
        }
    }
}
