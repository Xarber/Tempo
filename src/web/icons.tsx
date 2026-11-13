// SPDX-License-Identifier: AGPL-3.0-only
import type { CSSProperties, MouseEvent } from 'react';
const paths: Record<string, string> = {
    focus: 'M12 3a9 9 0 1 1-8 13 M12 7v5l3 2',
    projects: 'm3 7 9-4 9 4-9 4-9-4Zm0 5 9 4 9-4M3 17l9 4 9-4',
    tasks: 'm4 6 2 2 4-4M13 6h7M4 13l2 2 4-4m3 2h7M4 20l2 2 4-4m3 2h7',
    history: 'M3 10a9 9 0 1 1 1 8M3 4v6h6m3-3v5l4 2',
    analytics: 'M4 20V10m8 10V4m8 16v-7',
    settings:
        'M12 8a4 4 0 1 0 0 8 4 4 0 0 0 0-8M12 2v3m0 14v3M2 12h3m14 0h3M5 5l2 2m10 10 2 2M5 19l2-2M17 7l2-2',
    play: 'm8 5 11 7-11 7V5Z',
    pause: 'M8 5v14M16 5v14',
    check: 'm5 12 4 4 10-10',
    break: 'M5 4h12v10a6 6 0 0 1-12 0V4Zm12 2h2a3 3 0 1 1 0 6h-2M3 22h16',
    arrow: 'M5 12h14m-5-5 5 5-5 5',
    shield: 'm12 3 8 3v6c0 5-8 9-8 9s-8-4-8-9V6l8-3Z',
    download: 'M12 3v12m-5-5 5 5 5-5M4 17v4h16v-4',
    sun: 'M12 8a4 4 0 1 1 0 8 4 4 0 0 1 0-8M12 2v2m0 16v2M2 12h2m16 0h2M5 5l1 1m12 12 1 1M5 19l1-1M18 6l1-1',
    idea: 'M9 21h6M9 17v-2a6 6 0 1 1 6 0v2H9Z',
    globe: 'M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0M3 12h18M12 3c5 5 5 13 0 18-5-5-5-13 0-18',
    plus: 'M12 5v14M5 12h14',
};
export function Icon({
    name,
    size = 20,
    style,
}: {
    name: string;
    size?: number;
    style?: CSSProperties;
}) {
    return (
        <svg
            width={size}
            height={size}
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="1.6"
            strokeLinecap="round"
            strokeLinejoin="round"
            aria-hidden="true"
            style={style}
        >
            <path d={paths[name] ?? paths.focus} />
        </svg>
    );
}
export function Brand({
    onClick,
}: { onClick?: (event: MouseEvent<HTMLAnchorElement>) => void } = {}) {
    return (
        <a
            className="brand"
            href={onClick ? '/?about=1' : '/'}
            onClick={onClick}
        >
            <img src="/tempo.svg" alt="" width="34" height="34" />
            <span>Tempo</span>
        </a>
    );
}
