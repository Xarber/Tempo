// SPDX-License-Identifier: AGPL-3.0-only
import { empty, validate, type State } from '../core/tempo';
export function databaseName(qa: boolean) {
    return qa ? 'tempo-web-qa-v1' : 'tempo-web-v1';
}
export class Database {
    private readonly connection: Promise<IDBDatabase>;
    constructor(private readonly qa: boolean) {
        this.connection = new Promise((resolve, reject) => {
            const request = indexedDB.open(databaseName(qa), 1);
            request.onupgradeneeded = () =>
                request.result.createObjectStore('state');
            request.onsuccess = () => resolve(request.result);
            request.onerror = () => reject(request.error);
            request.onblocked = () =>
                reject(new Error('Close other Tempo tabs to upgrade storage.'));
        });
    }
    async read(): Promise<State> {
        const db = await this.connection;
        return new Promise((resolve, reject) => {
            const tx = db.transaction('state', 'readonly');
            const req = tx.objectStore('state').get('archive');
            req.onsuccess = () => {
                try {
                    resolve(req.result ? validate(req.result) : empty(this.qa));
                } catch (e) {
                    reject(e);
                }
            };
            req.onerror = () => reject(req.error);
        });
    }
    async mutate(operation: (s: State) => State): Promise<State> {
        const db = await this.connection;
        return new Promise((resolve, reject) => {
            const tx = db.transaction('state', 'readwrite');
            const store = tx.objectStore('state');
            const request = store.get('archive');
            let next: State;
            let problem: unknown;
            request.onsuccess = () => {
                try {
                    next = validate(
                        operation(
                            request.result
                                ? validate(request.result)
                                : empty(this.qa),
                        ),
                    );
                    if (this.qa && next.provenance !== 'simulated')
                        throw new Error('QA data must stay isolated.');
                    store.put(next, 'archive');
                } catch (e) {
                    problem = e;
                    tx.abort();
                }
            };
            tx.oncomplete = () => resolve(next);
            tx.onabort = () =>
                reject(
                    problem ??
                        tx.error ??
                        new Error('Storage transaction interrupted.'),
                );
            tx.onerror = () => reject(tx.error);
        });
    }
}
