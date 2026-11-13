// SPDX-License-Identifier: AGPL-3.0-only
import { execFileSync, spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import {
    cpSync,
    mkdirSync,
    readdirSync,
    readFileSync,
    writeFileSync,
} from 'node:fs';
import { join } from 'node:path';

const result = spawnSync(
    './node_modules/.bin/expo',
    ['export', '--platform', 'web'],
    {
        stdio: 'inherit',
        env: { ...process.env, EXPO_NO_TELEMETRY: '1' },
    },
);
if (result.status !== 0) process.exit(result.status ?? 1);

mkdirSync('dist/docs', { recursive: true });
for (const file of ['INDEX.md', 'MACOS.md', 'PRIVACY.md', 'WEB.md']) {
    cpSync(join('docs', file), join('dist/docs', file));
}
cpSync('LICENSE', 'dist/LICENSE');
const commit = execFileSync('git', ['rev-parse', 'HEAD'], {
    encoding: 'utf8',
}).trim();
writeFileSync(
    'dist/version.json',
    JSON.stringify({
        commit,
        deployment:
            process.env.EXPO_PUBLIC_TEMPO_DEPLOYMENT === 'xcenter'
                ? 'xcenter'
                : 'development',
    }),
);
const outputFiles = readdirSync('dist', {
    recursive: true,
    withFileTypes: true,
})
    .filter(
        (entry) =>
            entry.isFile() && !['sw.js', 'version.json'].includes(entry.name),
    )
    .map((entry) => join(entry.parentPath, entry.name).slice('dist'.length))
    .sort();
const fingerprint = createHash('sha256');
for (const path of outputFiles)
    fingerprint.update(path).update(readFileSync('dist' + path));
const workerTemplate = readFileSync('scripts/service-worker.js', 'utf8');
fingerprint.update(workerTemplate);
const version = fingerprint.digest('hex').slice(0, 16);
const precache = [
    ...new Set(
        outputFiles.map((path) =>
            path === '/index.html'
                ? '/'
                : path.endsWith('.html')
                  ? path.slice(0, -5)
                  : path,
        ),
    ),
];
writeFileSync(
    'dist/sw.js',
    workerTemplate
        .replace('__TEMPO_CACHE__', JSON.stringify('tempo-web-' + version))
        .replace('__TEMPO_ASSETS__', JSON.stringify(precache)),
);
console.log(
    'Tempo production export',
    version,
    'includes',
    precache.length,
    'offline assets.',
);
