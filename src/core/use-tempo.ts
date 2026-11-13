// SPDX-License-Identifier: AGPL-3.0-only
import { useEffect, useRef, useState } from 'react';
import { AppState } from 'react-native';
import { randomUUID } from 'expo-crypto';
import { Database } from '../storage/database';
import {
    active,
    command,
    empty,
    snapshot,
    type Clock,
    type Command,
    type State,
} from './tempo';
const origin = randomUUID();
export const clock = (): Clock => ({
    wall: Date.now() / 1000,
    mono: performance.now() / 1000,
    origin,
});
export const newID = () => randomUUID();
export function useTempo(qa = false) {
    const [state, setState] = useState<State>(() => empty(qa));
    const [now, setNow] = useState(() => clock());
    const [error, setError] = useState('');
    const [ready, setReady] = useState(false);
    const db = useRef<Database | undefined>(undefined);
    const channel = useRef<BroadcastChannel | undefined>(undefined);
    async function mutate(operation: (s: State) => State) {
        if (!db.current) {
            setError('Local storage is not ready.');
            return;
        }
        try {
            const next = await db.current.mutate(operation);
            setState(next);
            setNow(clock());
            channel.current?.postMessage('changed');
            return next;
        } catch (e) {
            setError(
                e instanceof Error
                    ? e.message
                    : 'Local storage operation failed.',
            );
        }
    }
    function act(event: Command) {
        return mutate((s) => command(s, event, clock()));
    }
    useEffect(() => {
        let alive = true;
        try {
            db.current = new Database(qa);
            db.current
                .mutate((s) => command(s, { type: 'checkpoint' }, clock()))
                .then((s) => {
                    if (alive) {
                        setState(s);
                        setReady(true);
                    }
                })
                .catch((e) => {
                    if (alive) setError(String(e));
                });
        } catch (e) {
            setError(String(e));
        }
        const refresh = () => {
            setNow(clock());
            db.current
                ?.read()
                .then((s) => {
                    if (alive) setState(s);
                })
                .catch((e) => setError(String(e)));
        };
        if (typeof window !== 'undefined' && 'BroadcastChannel' in window) {
            channel.current = new BroadcastChannel(qa ? 'tempo-qa' : 'tempo');
            channel.current.onmessage = refresh;
        }
        const timer = setInterval(() => setNow(clock()), 1000);
        const checkpoint = setInterval(
            () => void act({ type: 'checkpoint' }),
            15000,
        );
        const subscription = AppState.addEventListener('change', (s) => {
            if (s === 'active') refresh();
        });
        return () => {
            alive = false;
            clearInterval(timer);
            clearInterval(checkpoint);
            subscription.remove();
            channel.current?.close();
        };
        // Storage and listeners are initialized once per isolated namespace.
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [qa]);
    const stored = active(state);
    const session = stored ? snapshot(stored, now) : undefined;
    useEffect(() => {
        if (stored && session && session.status !== stored.status)
            void act({ type: 'checkpoint' });
    }, [stored?.id, stored?.status, session?.status]);
    return { state, session, now, error, setError, ready, mutate, act };
}
export type TempoStore = ReturnType<typeof useTempo>;
