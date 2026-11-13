// SPDX-License-Identifier: AGPL-3.0-only
import { ScrollViewStyleReset } from 'expo-router/html';
import type { PropsWithChildren } from 'react';
export default function Root({ children }: PropsWithChildren) {
    return (
        <html lang="en">
            <head>
                <meta charSet="utf-8" />
                <title>Tempo — Make time for what matters</title>
                <meta property="og:title" content="Tempo" />
                <meta
                    property="og:description"
                    content="An open-source focus timer and time tracker."
                />
                <meta property="og:type" content="website" />
                <meta
                    name="viewport"
                    content="width=device-width,initial-scale=1,viewport-fit=cover"
                />
                <meta name="theme-color" content="#6269f5" />
                <meta
                    name="description"
                    content="Make time for what matters. Tempo is an open-source, local-first focus timer and time tracker."
                />
                <link rel="manifest" href="/manifest.webmanifest" />
                <link rel="icon" href="/tempo.svg" type="image/svg+xml" />
                <link
                    rel="apple-touch-icon"
                    href="/icons/apple-touch-icon.png"
                />
                <ScrollViewStyleReset />
            </head>
            <body>{children}</body>
        </html>
    );
}
