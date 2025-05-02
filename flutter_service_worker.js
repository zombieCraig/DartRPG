'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"assets/AssetManifest.json": "1559f05f77e9ca560ef3682f1fe4409e",
"assets/AssetManifest.bin": "345263cba24d6592b23e1c3d83065d7c",
"assets/assets/data/changelog.json": "d1633e2067ab04eaf1198663dea0b279",
"assets/assets/data/custom_oracles.json": "9cfa269de22df2448dc53942bfe1f869",
"assets/assets/data/fe_runners.json": "6a447679e60e5a24f7958f16f06aaa2b",
"assets/assets/docs/overview.md": "a3ebd9abbe198942031d64f200787fc2",
"assets/assets/images/saved/README.md": "fb64407bbf21d35ffcacbec7e1392f5c",
"assets/assets/images/sentient_ai/the_archivist.webp": "5adcc7a8a631eac0a3afabf72b0dd7c2",
"assets/assets/images/sentient_ai/the_broken_doll.webp": "ee9d1d6106e372483a1a5d0073e8cc0c",
"assets/assets/images/sentient_ai/the_puppeteer.webp": "e8f989ce99baeb516be8aa25b285872a",
"assets/assets/images/sentient_ai/a_glitch.webp": "d9c154d0260fc2eee4b1f75b8718108d",
"assets/assets/images/sentient_ai/broken_code.webp": "e15a5e72cbf27f1ef7ff5c8ddff7b0d4",
"assets/assets/images/sentient_ai/the_swarm.webp": "42077ac40871f1a22e538715b70e5773",
"assets/assets/images/sentient_ai/the_gambler.webp": "8afc1cfef2422a748375876ebec5f936",
"assets/assets/images/sentient_ai/the_jester.webp": "068ad2dc5359c1bb0a0aee020a559a60",
"assets/assets/images/sentient_ai/the_virus.webp": "f41434ee1798efd0fe5c60fdc4ae7dd1",
"assets/assets/images/sentient_ai/the_ghost.webp": "603b3da4997898fe9c1460621e227783",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/fonts/MaterialIcons-Regular.otf": "3a6c6b89420d2db496812ca33a47e80b",
"assets/AssetManifest.bin.json": "b7d54416872e1f3616bf54e633aa6d07",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/NOTICES": "bd3a3ed583f8a15712f432ae8db6703f",
"assets/packages/quill_native_bridge_linux/assets/xclip": "d37b0dbbc8341839cde83d351f96279e",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"manifest.json": "589e037b1ef77d2fb7405cec9d168530",
"version.json": "ad38c684c089b4aea4d2a98d5f9b6b33",
"flutter.js": "76f08d47ff9f5715220992f993002504",
"canvaskit/chromium/canvaskit.js": "34beda9f39eb7d992d46125ca868dc61",
"canvaskit/chromium/canvaskit.wasm": "64a386c87532ae52ae041d18a32a3635",
"canvaskit/chromium/canvaskit.js.symbols": "5a23598a2a8efd18ec3b60de5d28af8f",
"canvaskit/skwasm.js": "f2ad9363618c5f62e813740099a80e63",
"canvaskit/skwasm.wasm": "f0dfd99007f989368db17c9abeed5a49",
"canvaskit/canvaskit.js": "86e461cf471c1640fd2b461ece4589df",
"canvaskit/skwasm_st.wasm": "56c3973560dfcbf28ce47cebe40f3206",
"canvaskit/canvaskit.wasm": "efeeba7dcc952dae57870d4df3111fad",
"canvaskit/skwasm.js.symbols": "80806576fa1056b43dd6d0b445b4b6f7",
"canvaskit/skwasm_st.js": "d1326ceef381ad382ab492ba5d96f04d",
"canvaskit/canvaskit.js.symbols": "68eb703b9a609baef8ee0e413b442f33",
"canvaskit/skwasm_st.js.symbols": "c7e7aac7cd8b612defd62b43e3050bdd",
"index.html": "1300938921caa0d761a01f1e397fe142",
"/": "1300938921caa0d761a01f1e397fe142",
"flutter_bootstrap.js": "a000b28a168f11a5dee59c07f75f24ba",
"icons/site.webmanifest": "053100cb84a50d2ae7f5492f7dd7f25e",
"icons/favicon.ico": "26ab35cafea81aabee7f7c4a7914129b",
"icons/android-chrome-512x512.png": "5f73aa68c27fefe7ac6ebbe9a71f8158",
"icons/favicon-32x32.png": "28369c8aed711b77bada4e0633150228",
"icons/apple-touch-icon.png": "12665ad3d0ed36a17f7725b8f8d854c7",
"icons/Icon-192.png": "d3376fb72f5e0bcf1e760e8f4b78ce72",
"icons/favicon-16x16.png": "34ec9efdd8499fad4411092cf9408c2c",
"icons/Icon-maskable-192.png": "d3376fb72f5e0bcf1e760e8f4b78ce72",
"icons/Icon-maskable-512.png": "f5882e93fc4f9488e530c335961dce68",
"icons/Icon-512.png": "64f77c06076f003627a2b8a467013ff3",
"icons/android-chrome-192x192.png": "d3376fb72f5e0bcf1e760e8f4b78ce72",
"favicon.png": "28369c8aed711b77bada4e0633150228",
"main.dart.js": "7af061d4e7f9dae6917c0517ab784ccb"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
