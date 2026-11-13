// SPDX-License-Identifier: AGPL-3.0-only
import { createServer } from 'node:http';
import { createReadStream } from 'node:fs';
import { stat } from 'node:fs/promises';
import { extname, resolve, sep } from 'node:path';

const root = resolve('dist');
const types = {
    '.html': 'text/html; charset=utf-8',
    '.js': 'text/javascript',
    '.css': 'text/css',
    '.png': 'image/png',
    '.svg': 'image/svg+xml',
    '.ico': 'image/x-icon',
    '.webmanifest': 'application/manifest+json',
    '.md': 'text/plain; charset=utf-8',
    '.woff2': 'font/woff2',
    '.ttf': 'font/ttf',
};
createServer(async (request, response) => {
    try {
        const pathname = decodeURIComponent(
            new URL(request.url, 'http://localhost').pathname,
        );
        const relative = pathname === '/' ? 'index.html' : pathname.slice(1);
        let path = resolve(root, relative);
        if (!path.startsWith(root + sep)) throw new Error('Invalid path');
        if (!extname(path) && !(await stat(path).catch(() => null))?.isFile())
            path += '.html';
        const file = await stat(path);
        if (!file.isFile()) throw new Error('Missing file');
        response.writeHead(200, {
            'Content-Type': types[extname(path)] ?? 'application/octet-stream',
            'Content-Length': file.size,
            'Cache-Control': 'no-cache',
        });
        if (request.method === 'HEAD') response.end();
        else createReadStream(path).pipe(response);
    } catch {
        response.writeHead(404).end('Not found');
    }
}).listen(Number(process.argv[2] ?? 4173), '127.0.0.1');
