// SPDX-License-Identifier: AGPL-3.0-only
import * as SQLite from 'expo-sqlite';
import { empty, validate, type State } from '../core/tempo';
export class Database {
    private readonly connection: Promise<SQLite.SQLiteDatabase>;
    private queue: Promise<unknown> = Promise.resolve();
    constructor(private readonly qa: boolean) {
        this.connection = SQLite.openDatabaseAsync(
            qa ? 'tempo-universal-qa.sqlite' : 'tempo-universal.sqlite',
        ).then(async (db) => {
            await db.execAsync(
                'PRAGMA journal_mode=WAL; PRAGMA synchronous=FULL; CREATE TABLE IF NOT EXISTS state(id INTEGER PRIMARY KEY CHECK(id=1),payload TEXT NOT NULL);',
            );
            return db;
        });
    }
    async read(): Promise<State> {
        const db = await this.connection;
        const row = await db.getFirstAsync<{ payload: string }>(
            'SELECT payload FROM state WHERE id=1',
        );
        return row ? validate(JSON.parse(row.payload)) : empty(this.qa);
    }
    mutate(operation: (s: State) => State): Promise<State> {
        const run = async () => {
            const db = await this.connection;
            let result: State;
            await db.withExclusiveTransactionAsync(async (tx) => {
                const row = await tx.getFirstAsync<{ payload: string }>(
                    'SELECT payload FROM state WHERE id=1',
                );
                result = validate(
                    operation(
                        row
                            ? validate(JSON.parse(row.payload))
                            : empty(this.qa),
                    ),
                );
                if (this.qa && result.provenance !== 'simulated')
                    throw new Error('QA records must remain isolated.');
                await tx.runAsync(
                    'INSERT INTO state(id,payload) VALUES(1,?) ON CONFLICT(id) DO UPDATE SET payload=excluded.payload',
                    JSON.stringify(result),
                );
            });
            return result!;
        };
        const result = this.queue.then(run);
        this.queue = result.catch(() => {});
        return result;
    }
}
