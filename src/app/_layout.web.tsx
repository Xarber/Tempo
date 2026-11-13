// SPDX-License-Identifier: AGPL-3.0-only
import { Slot } from 'expo-router';
import { useEffect, useState } from 'react';
import '../web/tempo.css';
export default function WebLayout() {
    const [waiting, setWaiting] = useState<ServiceWorker | undefined>(
        undefined,
    );
    useEffect(() => {
        if (!('serviceWorker' in navigator) || __DEV__) return;
        let disposed = false;
        void navigator.serviceWorker
            .register('/sw.js')
            .then((reg) => {
                if (disposed) return;
                if (reg.waiting) setWaiting(reg.waiting);
                reg.addEventListener('updatefound', () => {
                    const worker = reg.installing;
                    worker?.addEventListener('statechange', () => {
                        if (
                            worker.state === 'installed' &&
                            navigator.serviceWorker.controller
                        )
                            setWaiting(worker);
                    });
                });
            })
            .catch(() => {});
        return () => {
            disposed = true;
        };
    }, []);
    return (
        <>
            <Slot />
            {waiting && (
                <aside className="update-banner" role="status">
                    <strong>✦ Tempo update ready</strong>
                    <span>
                        A new version is ready. Your saved sessions stay on this
                        device.
                    </span>
                    <details>
                        <summary>Fixes & Improvements</summary>Reloading
                        switches to the new offline cache. Finish editing any
                        unsaved fields first.
                    </details>
                    <button
                        onClick={() => {
                            navigator.serviceWorker.addEventListener(
                                'controllerchange',
                                () => location.reload(),
                                { once: true },
                            );
                            waiting.postMessage({ type: 'ACTIVATE_UPDATE' });
                        }}
                    >
                        Reload to update
                    </button>
                    <button
                        className="quiet"
                        onClick={() => setWaiting(undefined)}
                    >
                        Later
                    </button>
                </aside>
            )}
        </>
    );
}
