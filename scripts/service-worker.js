// SPDX-License-Identifier: AGPL-3.0-only
const CACHE = __TEMPO_CACHE__;
const ASSETS = __TEMPO_ASSETS__;
const PREFIX = 'tempo-web-';
self.addEventListener('install', (event) => {
    event.waitUntil(caches.open(CACHE).then((cache) => cache.addAll(ASSETS)));
});
self.addEventListener('activate', (event) => {
    event.waitUntil(
        (async () => {
            const older = (await caches.keys()).filter(
                (name) => name.startsWith(PREFIX) && name !== CACHE,
            );
            await Promise.all(
                older.slice(0, -1).map((name) => caches.delete(name)),
            );
            await self.clients.claim();
        })(),
    );
});
self.addEventListener('message', (event) => {
    if (event.data?.type === 'ACTIVATE_UPDATE')
        event.waitUntil(self.skipWaiting());
});
self.addEventListener('fetch', (event) => {
    const url = new URL(event.request.url);
    if (url.origin !== self.location.origin || event.request.method !== 'GET')
        return;
    let path = url.pathname;
    if (event.request.mode === 'navigate' && path.endsWith('/'))
        path = path.replace(/\/+$/, '') || '/';
    if (!ASSETS.includes(path)) return;
    event.respondWith(
        (async () => {
            const cache = await caches.open(CACHE);
            if (event.request.mode === 'navigate') {
                try {
                    const response = await fetch(event.request);
                    if (response.ok) return response;
                } catch {}
                return (
                    (await cache.match(path)) ??
                    new Response(
                        'Tempo is offline. Open the app online once to prepare this device.',
                        {
                            status: 503,
                            headers: {
                                'Content-Type': 'text/plain; charset=utf-8',
                            },
                        },
                    )
                );
            }
            return (await cache.match(path)) ?? fetch(event.request);
        })(),
    );
});
