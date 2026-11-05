// AMD BC-250 Titanium Studio Service Worker
const CACHE_NAME = 'bc250-v2-cache-v1';
const STATIC_ASSETS = [
  '/v2/',
  '/v2/index.html',
  '/v2/style.css',
  '/v2/bc250-board.css',
  '/v2/memory.js',
  '/v2/app.js',
  '/v2/manifest.json',
  '/v2/favicon.ico',
  '/v2/favicon-32x32.png',
  '/v2/favicon-16x16.png',
  '/v2/icon-192.png',
  '/v2/icon-512.png',
  '/v2/apple-touch-icon.png'
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      return cache.addAll(STATIC_ASSETS).catch((err) => {
        console.warn('SW pre-cache warning:', err);
      });
    }).then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) => {
      return Promise.all(
        keys.filter((key) => key !== CACHE_NAME).map((key) => caches.delete(key))
      );
    }).then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', (event) => {
  const url = new URL(event.request.url);

  // CRITICAL: Live telemetry & control APIs are NEVER cached
  if (url.pathname.startsWith('/api/')) {
    event.respondWith(fetch(event.request));
    return;
  }

  // Network-first strategy for UI assets, with cache fallback
  event.respondWith(
    fetch(event.request)
      .then((networkResponse) => {
        if (networkResponse && networkResponse.status === 200 && networkResponse.type === 'basic') {
          const responseClone = networkResponse.clone();
          caches.open(CACHE_NAME).then((cache) => {
            cache.put(event.request, responseClone);
          });
        }
        return networkResponse;
      })
      .catch(() => {
        return caches.match(event.request);
      })
  );
});
