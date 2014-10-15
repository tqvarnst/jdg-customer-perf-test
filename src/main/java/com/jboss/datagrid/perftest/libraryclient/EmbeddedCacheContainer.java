package com.jboss.datagrid.perftest.libraryclient;

import org.infinispan.Cache;
import org.infinispan.manager.DefaultCacheManager;
import org.infinispan.manager.EmbeddedCacheManager;

import static com.jboss.datagrid.perftest.libraryclient.Constants.ClusterMode;
import java.io.IOException;

/**
 * Created by tqvarnst on 15/10/14.
 */
public class EmbeddedCacheContainer {

    private static EmbeddedCacheManager cacheManager;

    public static EmbeddedCacheManager getCacheManager(ClusterMode clusterMode) {
        if(cacheManager==null) {
            try {
                cacheManager = new DefaultCacheManager(clusterMode.getConfig(), true);
            } catch (final IOException e) {
                throw new RuntimeException("Unable to configure Infinispan", e);
            }
        }
        return cacheManager;
    }
}
