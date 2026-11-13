// SPDX-License-Identifier: AGPL-3.0-only
import { useEffect, useState, type MouseEvent } from 'react';
import Workspace from '../web/Workspace';
import { Brand, Icon } from '../web/icons';
function Landing({
    open,
}: {
    open: (event: MouseEvent<HTMLAnchorElement>) => void;
}) {
    return (
        <div className="landing">
            <header className="landing-nav">
                <Brand />
                <nav>
                    <a href="#approach">The approach</a>
                    <a href="#platforms">Platforms</a>
                    <a className="button small" href="/focus" onClick={open}>
                        Open Tempo <Icon name="arrow" size={17} />
                    </a>
                </nav>
            </header>
            <main>
                <section className="hero">
                    <div className="hero-copy">
                        <span className="eyebrow">
                            <span className="status-dot" /> A LITTLE SPACE TO
                            FOCUS
                        </span>
                        <h1>
                            Make time for
                            <br />
                            what <em>matters.</em>
                        </h1>
                        <p>
                            One clear intention. A little uninterrupted time.
                            <br />A calmer way to move meaningful work forward.
                        </p>
                        <div className="hero-actions">
                            <a className="button" href="/focus" onClick={open}>
                                Find your focus <Icon name="arrow" />
                            </a>
                            <a className="text-link" href="#approach">
                                Meet Tempo <span>↘</span>
                            </a>
                        </div>
                        <div className="trust-row">
                            <span>
                                <Icon name="shield" size={16} /> Private by
                                default
                            </span>
                            <span>
                                <Icon name="globe" size={16} /> Works offline
                            </span>
                            <span>AGPL open source</span>
                        </div>
                    </div>
                    <div
                        className="hero-visual"
                        aria-label="Illustration of Tempo's focus timer, not recorded session data"
                    >
                        <div className="orbit orbit-one" />
                        <div className="orbit orbit-two" />
                        <div className="timer-preview">
                            <div className="preview-head">
                                <img
                                    src="/tempo.svg"
                                    width="26"
                                    height="26"
                                    alt=""
                                />
                                <span>A moment for deep work</span>
                                <span className="pill">FOCUS</span>
                            </div>
                            <div className="preview-ring">
                                <span className="eyebrow">
                                    YOUR NEXT SESSION
                                </span>
                                <strong>25:00</strong>
                                <span>Ready when you are.</span>
                            </div>
                            <a
                                className="button preview-start"
                                href="/focus"
                                onClick={open}
                            >
                                <Icon name="play" size={17} /> Start your own
                                session
                            </a>
                            <div className="preview-footer">
                                <Icon name="break" size={16} /> Make room for a
                                break, too.
                            </div>
                        </div>
                        <span className="floating-note">
                            <Icon name="check" size={18} /> Progress at your own
                            pace.
                        </span>
                    </div>
                </section>
                <section className="approach" id="approach">
                    <div>
                        <span className="eyebrow">
                            LESS FRICTION. MORE INTENTION.
                        </span>
                        <h2>
                            A small ritual.
                            <br />A meaningful difference.
                        </h2>
                    </div>
                    <div className="steps">
                        {[
                            [
                                '01',
                                'focus',
                                'Choose what matters',
                                'Name your intention, choose a project, or simply begin. No elaborate setup.',
                            ],
                            [
                                '02',
                                'play',
                                'Give it a little space',
                                'A reliable timer keeps track while you stay with the work. Pause whenever you need.',
                            ],
                            [
                                '03',
                                'break',
                                'Reflect. Rest. Return.',
                                'Keep an honest record of your time, take a restorative break, and find your rhythm.',
                            ],
                        ].map(([n, icon, title, body]) => (
                            <article key={n}>
                                <span className="step-number">{n}</span>
                                <div>
                                    <Icon name={icon} />
                                    <h3>{title}</h3>
                                    <p>{body}</p>
                                </div>
                            </article>
                        ))}
                    </div>
                </section>
                <section className="privacy-block">
                    <Icon name="shield" size={36} />
                    <div>
                        <h2>Your time is yours.</h2>
                        <p>
                            No account required. No advertisements. No
                            productivity surveillance. Sessions and reflections
                            stay in your browser unless you choose to export
                            them.
                        </p>
                    </div>
                    <a href="/focus" onClick={open} className="text-link">
                        Make a little room <Icon name="arrow" />
                    </a>
                </section>
                <section id="platforms" className="platforms">
                    <div>
                        <span className="eyebrow">
                            AT YOUR OWN PACE. ON YOUR TERMS.
                        </span>
                        <h2>A home for your focus.</h2>
                    </div>
                    <article>
                        <Icon name="globe" />
                        <h3>Web & installed PWA</h3>
                        <p>
                            Focus, breaks, projects, tasks, reflections and
                            local analytics. Install from a supported browser
                            and return offline.
                        </p>
                        <a href="/focus" onClick={open}>
                            Open web app ↗
                        </a>
                    </article>
                    <article>
                        <Icon name="focus" />
                        <h3>Native macOS</h3>
                        <p>
                            A native menu bar experience and floating timer.
                            Local development builds are available from your
                            checkout; signed public downloads are not published.
                        </p>
                        <a href="/docs/MACOS.md">macOS documentation ↗</a>
                    </article>
                </section>
                <section className="last-call">
                    <span className="eyebrow">
                        NO PRESSURE. JUST POSSIBILITY.
                    </span>
                    <h2>What will you make time for?</h2>
                    <a className="button" href="/focus" onClick={open}>
                        Begin a focus session <Icon name="arrow" />
                    </a>
                </section>
            </main>
            <footer>
                <Brand />
                <span>Make time for what matters.</span>
                <nav>
                    <a href="/docs/INDEX.md">Documentation</a>
                    <a href="/LICENSE">AGPL-3.0-only</a>
                    <a href="/focus?section=settings">Privacy & data</a>
                </nav>
                <small>An OpenRecode project · local-first, always.</small>
            </footer>
        </div>
    );
}

export default function WebEntry() {
    const [showApp, setShowApp] = useState(false);
    const [mounted, setMounted] = useState(false);
    const [qa, setQA] = useState(false);
    function preference(qaMode: boolean) {
        return qaMode ? 'tempo.qa.opened' : 'tempo.opened';
    }
    useEffect(() => {
        function restore() {
            const query = new URLSearchParams(location.search);
            const qaMode =
                process.env.EXPO_PUBLIC_TEMPO_DEPLOYMENT !== 'xcenter' &&
                query.get('qa') === '1';
            setQA(qaMode);
            let opened = false;
            try {
                opened = localStorage.getItem(preference(qaMode)) === '1';
            } catch {}
            const enter =
                !query.has('about') &&
                (opened ||
                    location.pathname.startsWith('/focus') ||
                    query.has('open') ||
                    query.has('section'));
            if (enter) {
                try {
                    localStorage.setItem(preference(qaMode), '1');
                } catch {}
                setMounted(true);
            }
            setShowApp(enter);
        }
        restore();
        window.addEventListener('popstate', restore);
        return () => window.removeEventListener('popstate', restore);
    }, []);
    function navigate(enter: boolean, event: MouseEvent<HTMLAnchorElement>) {
        if (event.metaKey || event.ctrlKey || event.shiftKey || event.altKey)
            return;
        event.preventDefault();
        const query = new URLSearchParams();
        if (qa) query.set('qa', '1');
        query.set(enter ? 'open' : 'about', '1');
        history.pushState(history.state, '', '/?' + query);
        if (enter) {
            try {
                localStorage.setItem(preference(qa), '1');
            } catch {}
            setMounted(true);
        }
        setShowApp(enter);
        window.scrollTo(0, 0);
    }
    return (
        <>
            <div hidden={showApp}>
                <Landing open={(event) => navigate(true, event)} />
            </div>
            {mounted && (
                <div hidden={!showApp}>
                    <Workspace
                        qa={qa}
                        onAbout={(event) => navigate(false, event)}
                    />
                </div>
            )}
        </>
    );
}
