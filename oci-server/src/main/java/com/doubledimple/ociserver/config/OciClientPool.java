package com.doubledimple.ociserver.config;

import com.oracle.bmc.auth.SimpleAuthenticationDetailsProvider;
import com.oracle.bmc.core.BlockstorageClient;
import com.oracle.bmc.core.ComputeClient;
import com.oracle.bmc.core.VirtualNetworkClient;
import com.oracle.bmc.identity.IdentityClient;
import com.oracle.bmc.workrequests.WorkRequestClient;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

import javax.annotation.PreDestroy;
import java.io.IOException;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Component
@Profile("optimized")
@Slf4j
public class OciClientPool {

    private final Map<String, ClientWrapper> clientPool = new ConcurrentHashMap<>();
    private final MultiUserAuthenticationDetailsProvider authenticationDetailsProvider;

    @Autowired
    public OciClientPool(@Qualifier("multiUserAuthenticationDetailsProvider") 
                         MultiUserAuthenticationDetailsProvider authenticationDetailsProvider) {
        this.authenticationDetailsProvider = authenticationDetailsProvider;
    }

    public ClientWrapper getClientWrapper(String userId, String region) throws IOException {
        String poolKey = userId + ":" + region;
        
        return clientPool.computeIfAbsent(poolKey, key -> {
            try {
                Map<String, SimpleAuthenticationDetailsProvider> providers = 
                    authenticationDetailsProvider.simpleAuthenticationDetailsProvider();
                SimpleAuthenticationDetailsProvider provider = providers.get(userId);
                
                if (provider == null) {
                    throw new IllegalArgumentException("User not found: " + userId);
                }

                ClientWrapper wrapper = new ClientWrapper();
                wrapper.setIdentityClient(IdentityClient.builder().build(provider));
                wrapper.getIdentityClient().setRegion(region);
                
                wrapper.setComputeClient(ComputeClient.builder().build(provider));
                wrapper.getComputeClient().setRegion(region);
                
                wrapper.setVirtualNetworkClient(VirtualNetworkClient.builder().build(provider));
                wrapper.getVirtualNetworkClient().setRegion(region);
                
                wrapper.setBlockstorageClient(BlockstorageClient.builder().build(provider));
                wrapper.getBlockstorageClient().setRegion(region);
                
                wrapper.setWorkRequestClient(WorkRequestClient.builder().build(provider));
                wrapper.getWorkRequestClient().setRegion(region);
                
                log.info("Created OCI client pool for user: {}, region: {}", userId, region);
                return wrapper;
            } catch (IOException e) {
                log.error("Failed to create OCI client pool for user: {}, region: {}", userId, region, e);
                throw new RuntimeException("Failed to create OCI client pool", e);
            }
        });
    }

    @PreDestroy
    public void cleanup() {
        log.info("Cleaning up OCI client pool, size: {}", clientPool.size());
        clientPool.forEach((key, wrapper) -> {
            try {
                wrapper.close();
            } catch (Exception e) {
                log.error("Error closing client wrapper for key: {}", key, e);
            }
        });
        clientPool.clear();
    }

    public static class ClientWrapper {
        private IdentityClient identityClient;
        private ComputeClient computeClient;
        private VirtualNetworkClient virtualNetworkClient;
        private BlockstorageClient blockstorageClient;
        private WorkRequestClient workRequestClient;

        public IdentityClient getIdentityClient() {
            return identityClient;
        }

        public void setIdentityClient(IdentityClient identityClient) {
            this.identityClient = identityClient;
        }

        public ComputeClient getComputeClient() {
            return computeClient;
        }

        public void setComputeClient(ComputeClient computeClient) {
            this.computeClient = computeClient;
        }

        public VirtualNetworkClient getVirtualNetworkClient() {
            return virtualNetworkClient;
        }

        public void setVirtualNetworkClient(VirtualNetworkClient virtualNetworkClient) {
            this.virtualNetworkClient = virtualNetworkClient;
        }

        public BlockstorageClient getBlockstorageClient() {
            return blockstorageClient;
        }

        public void setBlockstorageClient(BlockstorageClient blockstorageClient) {
            this.blockstorageClient = blockstorageClient;
        }

        public WorkRequestClient getWorkRequestClient() {
            return workRequestClient;
        }

        public void setWorkRequestClient(WorkRequestClient workRequestClient) {
            this.workRequestClient = workRequestClient;
        }

        public void close() {
            safeClose(identityClient);
            safeClose(computeClient);
            safeClose(virtualNetworkClient);
            safeClose(blockstorageClient);
            safeClose(workRequestClient);
        }

        private void safeClose(AutoCloseable client) {
            if (client != null) {
                try {
                    client.close();
                } catch (Exception e) {
                    log.error("Error closing client: {}", client.getClass().getSimpleName(), e);
                }
            }
        }
    }
}