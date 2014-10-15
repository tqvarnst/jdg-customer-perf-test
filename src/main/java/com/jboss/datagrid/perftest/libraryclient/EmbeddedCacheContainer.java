package com.jboss.datagrid.perftest.libraryclient;

import org.infinispan.Cache;
import org.infinispan.manager.DefaultCacheManager;
import org.infinispan.manager.EmbeddedCacheManager;

import java.io.IOException;

/**
 * Created by tqvarnst on 15/10/14.
 */
public class EmbeddedCacheContainer {
    private static final String INFINISPAN_CONFIGURATION = "infinispan-replication.xml";

    private static EmbeddedCacheManager cacheManager;

    public static EmbeddedCacheManager getCacheManager() {
        if(cacheManager==null) {
            try {
                cacheManager = new DefaultCacheManager(INFINISPAN_CONFIGURATION, true);
            } catch (final IOException e) {
                throw new RuntimeException("Unable to configure Infinispan", e);
            }
        }
        return cacheManager;
    }

    public static <K, V> Cache<K, V> getCache(final String cacheName) {
        if (cacheName == null)
            throw new NullPointerException("Cache name cannot be null!");
        return getCacheManager().getCache(cacheName);
    }



}
