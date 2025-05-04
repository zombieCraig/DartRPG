// Cache names
const CACHE_NAME = 'fe-runners-cache-v1';
const ASSETS_CACHE_NAME = 'fe-runners-assets-cache-v1';

// Assets that must be cached for offline use
const CORE_ASSETS = [
  './',
  './index.html',
  './offline.html',
  './main.dart.js',
  './flutter_bootstrap.js',
  './favicon.png',
  './manifest.json',
  './icons/Icon-192.png',
  './icons/Icon-512.png',
  './icons/Icon-maskable-192.png',
  './icons/Icon-maskable-512.png'
];

// Critical data files that must be cached
const CRITICAL_DATA = [
  './assets/data/fe_runners.json',
  './assets/data/custom_oracles.json',
  './assets/data/changelog.json',
  './assets/docs/overview.md',
  './assets/images/sentient_ai/a_glitch.webp',
  './assets/images/sentient_ai/broken_code.webp',
  './assets/images/sentient_ai/the_archivist.webp',
  './assets/images/sentient_ai/the_broken_doll.webp',
  './assets/images/sentient_ai/the_gambler.webp',
  './assets/images/sentient_ai/the_ghost.webp',
  './assets/images/sentient_ai/the_jester.webp',
  './assets/images/sentient_ai/the_puppeteer.webp',
  './assets/images/sentient_ai/the_swarm.webp',
  './assets/images/sentient_ai/the_virus.webp'
];

// Install event - cache core assets and critical data
self.addEventListener('install', (event) => {
  console.log('[Service Worker] Installing Service Worker...');
  event.waitUntil(
    Promise.all([
      // Cache core assets
      caches.open(CACHE_NAME).then((cache) => {
        console.log('[Service Worker] Caching core assets');
        return cache.addAll(CORE_ASSETS);
      }),
      
      // Cache critical data files
      caches.open(ASSETS_CACHE_NAME).then((cache) => {
        console.log('[Service Worker] Caching critical data files');
        return cache.addAll(CRITICAL_DATA);
      })
    ])
    .then(() => {
      console.log('[Service Worker] Installation complete');
      return self.skipWaiting();
    })
  );
});

// Activate event - clean up old caches and take control
self.addEventListener('activate', (event) => {
  console.log('[Service Worker] Activating Service Worker...');
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames.filter((cacheName) => {
          return cacheName.startsWith('fe-runners-') && 
                 cacheName !== CACHE_NAME &&
                 cacheName !== ASSETS_CACHE_NAME;
        }).map((cacheName) => {
          console.log('[Service Worker] Deleting old cache:', cacheName);
          return caches.delete(cacheName);
        })
      );
    })
    .then(() => {
      console.log('[Service Worker] Activation complete');
      return self.clients.claim();
    })
  );
});

// Helper function to determine if a request is for an asset
function isAssetRequest(url) {
  return url.includes('/assets/');
}

// Helper function to determine if a request is for a critical data file
function isCriticalDataRequest(url) {
  return CRITICAL_DATA.some(path => url.includes(path));
}

// Fetch event - serve from cache or network
self.addEventListener('fetch', (event) => {
  const url = new URL(event.request.url);
  
  // Skip cross-origin requests
  if (url.origin !== self.location.origin) {
    return;
  }
  
  // For critical data files, use cache-first strategy
  if (isCriticalDataRequest(url.pathname)) {
    console.log('[Service Worker] Fetching critical data:', url.pathname);
    event.respondWith(
      caches.match(event.request).then((cachedResponse) => {
        if (cachedResponse) {
          console.log('[Service Worker] Serving critical data from cache:', url.pathname);
          return cachedResponse;
        }
        
        console.log('[Service Worker] Fetching critical data from network:', url.pathname);
        return fetch(event.request).then((networkResponse) => {
          // Cache a copy of the response
          return caches.open(ASSETS_CACHE_NAME).then((cache) => {
            cache.put(event.request, networkResponse.clone());
            return networkResponse;
          });
        }).catch((error) => {
          console.error('[Service Worker] Fetch failed for critical data:', error);
          return new Response('Network error', { status: 408 });
        });
      })
    );
    return;
  }
  
  // For asset requests, use cache-first strategy
  if (isAssetRequest(url.pathname)) {
    event.respondWith(
      caches.match(event.request).then((cachedResponse) => {
        if (cachedResponse) {
          return cachedResponse;
        }
        
        return fetch(event.request).then((networkResponse) => {
          // Cache a copy of the response
          return caches.open(ASSETS_CACHE_NAME).then((cache) => {
            cache.put(event.request, networkResponse.clone());
            return networkResponse;
          });
        }).catch((error) => {
          console.error('[Service Worker] Fetch failed for asset:', error);
          return new Response('Network error', { status: 408 });
        });
      })
    );
    return;
  }
  
  // For all other requests, use network-first strategy
  event.respondWith(
    fetch(event.request).then((networkResponse) => {
      // Cache successful GET responses
      if (event.request.method === 'GET' && networkResponse && networkResponse.status === 200) {
        caches.open(CACHE_NAME).then((cache) => {
          cache.put(event.request, networkResponse.clone());
        });
      }
      return networkResponse;
    }).catch(() => {
      // If network fails, try to serve from cache
      return caches.match(event.request).then((cachedResponse) => {
        if (cachedResponse) {
          return cachedResponse;
        }
        // If not in cache and network failed, return the offline page for HTML requests
        if (event.request.headers.get('accept').includes('text/html')) {
          return caches.match('./offline.html')
            .then(response => {
              return response || new Response('<html><body><h1>Offline</h1><p>The app is currently offline.</p></body></html>', {
                headers: { 'Content-Type': 'text/html' }
              });
            });
        }
        return new Response('Offline content not available');
      });
    })
  );
});
