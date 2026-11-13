// SPDX-License-Identifier: AGPL-3.0-only
import { useEffect, useState, type MouseEvent } from 'react';
import {
    active,
    dayTotal,
    elapsed,
    focused,
    merge,
    validate,
    type Kind,
    type State,
} from '../core/tempo';
import { clock, newID, useTempo, type TempoStore } from '../core/use-tempo';
import { Brand, Icon } from './icons';
const sections = [
    ['Focus', 'focus'],
    ['Projects', 'projects'],
    ['Tasks', 'tasks'],
    ['History', 'history'],
    ['Analytics', 'analytics'],
    ['Settings', 'settings'],
] as const;
export function format(seconds: number) {
    const n = Math.max(0, Math.ceil(seconds));
    return `${Math.floor(n / 60)
        .toString()
        .padStart(2, '0')}:${(n % 60).toString().padStart(2, '0')}`;
}
function download(name: string, text: string, type = 'application/json') {
    const url = URL.createObjectURL(new Blob([text], { type }));
    const a = document.createElement('a');
    a.href = url;
    a.download = name;
    a.click();
    setTimeout(() => URL.revokeObjectURL(url), 1000);
}
function Heading({ title, subtitle }: { title: string; subtitle: string }) {
    return (
        <header className="page-heading">
            <div>
                <h1>{title}</h1>
                <p>{subtitle}</p>
            </div>
            <span className="local-badge">
                <span className="status-dot" /> On this device
            </span>
        </header>
    );
}
export default function Workspace({
    qa,
    onAbout,
}: {
    qa: boolean;
    onAbout: (event: MouseEvent<HTMLAnchorElement>) => void;
}) {
    const store = useTempo(qa);
    const { state, error, setError, ready, mutate } = store;
    const [section, setSection] = useState('Focus');
    const [developerUntil, setDeveloperUntil] = useState(0);
    const [taps, setTaps] = useState(0);
    const [reflection, setReflection] = useState<string | undefined>(undefined);
    const [imported, setImported] = useState<State | undefined>(undefined);
    const developer = developerUntil > Date.now();
    useEffect(() => {
        const route = new URLSearchParams(location.search).get('section');
        if (route === 'settings') setSection('Settings');
    }, []);
    // Explicit reflection remains available in History, including after automatic deadline completion.
    const navigate = (name: string) => {
        setSection(name);
        setDeveloperUntil(0);
        setTaps(0);
    };
    const exportJSON = () =>
        download(
            'Tempo-web.json',
            JSON.stringify(
                { ...state, exportedAt: new Date().toISOString() },
                null,
                2,
            ),
        );
    async function readImport(file?: File) {
        if (!file) return;
        try {
            if (file.size > 25_000_000) throw new Error('Import limit: 25 MB.');
            setImported(validate(JSON.parse(await file.text())));
        } catch (e) {
            setError(e instanceof Error ? e.message : 'Invalid archive.');
        }
    }
    return (
        <div className="workspace">
            <aside className="sidebar">
                <Brand onClick={onAbout} />
                <nav aria-label="Main navigation">
                    {sections.map(([name, icon]) => (
                        <button
                            key={name}
                            aria-current={section === name ? 'page' : undefined}
                            onClick={() => navigate(name)}
                        >
                            <Icon name={icon} />
                            {name}
                        </button>
                    ))}
                    {developer && (
                        <button
                            onClick={() => {
                                setSection('Developer');
                                setDeveloperUntil(Date.now() + 30000);
                            }}
                        >
                            <Icon name="idea" />
                            Developer Ideas
                        </button>
                    )}
                </nav>
                <div className="sidebar-bottom">
                    <Icon name="shield" size={17} />
                    <p>
                        Private by default.
                        <br />
                        <strong>
                            {qa
                                ? 'QA · simulated records only'
                                : 'A little space, just for you.'}
                        </strong>
                    </p>
                    <a href="/?about=1" onClick={onAbout}>
                        About Tempo ↗
                    </a>
                </div>
            </aside>
            <main className="workspace-main">
                {error && (
                    <div className="error-banner" role="alert">
                        <span>{error}</span>
                        <button onClick={() => setError('')}>Dismiss</button>
                    </div>
                )}
                {!ready && !error && (
                    <p role="status">Opening your local workspace…</p>
                )}
                {section === 'Focus' && (
                    <Focus store={store} onReflect={setReflection} />
                )}
                {section === 'Projects' && (
                    <Projects store={store} onFocus={() => navigate('Focus')} />
                )}
                {section === 'Tasks' && (
                    <Tasks store={store} onFocus={() => navigate('Focus')} />
                )}
                {section === 'History' && (
                    <History store={store} onReflect={setReflection} />
                )}
                {section === 'Analytics' && <Analytics store={store} />}
                {section === 'Settings' && (
                    <>
                        <Heading
                            title="Make it yours."
                            subtitle="A focus practice that fits you."
                        />
                        <div className="settings-grid">
                            <section className="panel">
                                <h2>
                                    <Icon name="focus" /> Focus & breaks
                                </h2>
                                {(
                                    [
                                        'focus',
                                        'shortBreak',
                                        'longBreak',
                                        'cycleCount',
                                        'dailyGoal',
                                    ] as const
                                ).map((key) => (
                                    <label key={key}>
                                        {
                                            {
                                                focus: 'Focus duration · minutes',
                                                shortBreak:
                                                    'Short break · minutes',
                                                longBreak:
                                                    'Long break · minutes',
                                                cycleCount:
                                                    'Sessions before a long break',
                                                dailyGoal:
                                                    'Optional daily goal · minutes',
                                            }[key]
                                        }
                                        <input
                                            type="number"
                                            min="1"
                                            max="1440"
                                            value={state.settings[key]}
                                            onChange={(e) => {
                                                const value = Number(
                                                    e.target.value,
                                                );
                                                if (value >= 1 && value <= 1440)
                                                    void mutate((s) => ({
                                                        ...s,
                                                        settings: {
                                                            ...s.settings,
                                                            [key]: value,
                                                        },
                                                    }));
                                            }}
                                        />
                                    </label>
                                ))}
                                <label className="check-label">
                                    <input
                                        type="checkbox"
                                        checked={state.settings.digital}
                                        onChange={(e) =>
                                            void mutate((s) => ({
                                                ...s,
                                                settings: {
                                                    ...s.settings,
                                                    digital: e.target.checked,
                                                },
                                            }))
                                        }
                                    />
                                    Minimal digital timer
                                </label>
                                <details>
                                    <summary>How browser timers behave</summary>
                                    <p>
                                        Timers derive from timestamps, not tick
                                        counts. Browser suspension can delay
                                        completion reminders. Durations
                                        reconciled after restart or clock
                                        divergence are labelled estimated.
                                        Browser timers cannot guarantee native
                                        background notifications.
                                    </p>
                                </details>
                            </section>
                            <section className="panel">
                                <h2>
                                    <Icon name="shield" /> Your data stays here
                                </h2>
                                <p>
                                    Sessions, reflections and ideas are stored
                                    in this browser’s IndexedDB. No account,
                                    tracking or synchronization service is
                                    connected.
                                </p>
                                <button onClick={exportJSON}>
                                    <Icon name="download" />
                                    Export all data
                                </button>
                                <label className="file-label">
                                    Review a JSON import
                                    <input
                                        type="file"
                                        accept="application/json,.json"
                                        onChange={(e) =>
                                            void readImport(e.target.files?.[0])
                                        }
                                    />
                                </label>
                                <details>
                                    <summary>Storage & portability</summary>
                                    <p>
                                        Browser storage may be cleared by
                                        private browsing, system cleanup or
                                        browser settings. Keep deliberate
                                        exports. Web and native Swift JSON
                                        schemas are different; this importer
                                        accepts Tempo Web archives only.
                                        Existing IDs and preferences win when
                                        merging. Incoming active timers become
                                        interrupted history.
                                    </p>
                                </details>
                                <button
                                    className="quiet"
                                    onClick={() => {
                                        if (navigator.storage?.persist)
                                            void navigator.storage
                                                .persist()
                                                .then((granted) =>
                                                    setError(
                                                        granted
                                                            ? 'Persistent browser storage granted.'
                                                            : 'Browser did not grant persistent storage. Keep regular exports.',
                                                    ),
                                                );
                                    }}
                                >
                                    Request persistent storage
                                </button>
                            </section>
                            <section className="panel">
                                <h2>
                                    <Icon name="idea" /> What’s new · 0.1.0
                                </h2>
                                <p>
                                    <Icon name="globe" /> Local-first web
                                    workspace and installable PWA.
                                </p>
                                <p>
                                    <Icon name="projects" /> Projects, tasks,
                                    reflection and real-time records.
                                </p>
                                <details>
                                    <summary>Fixes & Improvements</summary>
                                    <p>
                                        Transactional multi-tab storage, bounded
                                        import review, offline assets and
                                        reduced-motion controls. The first
                                        installation does not show an update
                                        popup.
                                    </p>
                                </details>
                                <button
                                    className="quiet"
                                    onClick={() => {
                                        const count = taps + 1;
                                        setTaps(count);
                                        if (count >= 3) {
                                            setDeveloperUntil(
                                                Date.now() + 30000,
                                            );
                                            setTaps(0);
                                        }
                                    }}
                                >
                                    Tempo 0.1.0 · version
                                </button>
                                {developer && (
                                    <button
                                        onClick={() => setSection('Developer')}
                                    >
                                        Open Developer Ideas
                                    </button>
                                )}
                            </section>
                        </div>
                    </>
                )}
                {section === 'Developer' &&
                    (developer ? (
                        <Ideas
                            store={store}
                            touch={() => setDeveloperUntil(Date.now() + 30000)}
                        />
                    ) : (
                        <div className="empty">
                            <Icon name="shield" size={38} />
                            <h2>Developer access expired</h2>
                            <p>
                                Tap the version three times in Settings to
                                reopen.
                            </p>
                            <button onClick={() => navigate('Settings')}>
                                Open Settings
                            </button>
                        </div>
                    ))}
                <footer className="app-footer">
                    <span>Make time for what matters.</span>
                    <a href="/docs/PRIVACY.md">Privacy</a>
                    <a href="/LICENSE">AGPL-3.0-only</a>
                    <span>Tempo Web 0.1.0</span>
                </footer>
            </main>
            {reflection && (
                <Reflection
                    store={store}
                    id={reflection}
                    close={() => setReflection(undefined)}
                />
            )}
            {imported && (
                <section
                    className="import-review panel"
                    role="region"
                    aria-label="Import preview"
                >
                    <h2>Review your import</h2>
                    <p>
                        {imported.sessions.length} sessions ·{' '}
                        {imported.projects.length} projects ·{' '}
                        {imported.tasks.length} tasks · {imported.ideas.length}{' '}
                        ideas
                    </p>
                    <p>
                        Existing records and preferences are preserved. Active
                        incoming sessions become interrupted history.
                    </p>
                    <button
                        onClick={() =>
                            void mutate((s) => merge(imported, s)).then(
                                (result) => {
                                    if (result) setImported(undefined);
                                },
                            )
                        }
                    >
                        Merge new records
                    </button>
                    <button
                        className="quiet"
                        onClick={() => setImported(undefined)}
                    >
                        Cancel
                    </button>
                </section>
            )}
        </div>
    );
}
function Focus({
    store,
    onReflect,
}: {
    store: TempoStore;
    onReflect: (id: string) => void;
}) {
    const { state, session, now, act, ready } = store;
    const [intention, setIntention] = useState('');
    const [minutes, setMinutes] = useState(state.settings.focus);
    const [kind, setKind] = useState<Kind>('focus');
    const [project, setProject] = useState('');
    const running = !!session && ['running', 'paused'].includes(session.status);
    const seconds = running
        ? session.planned === null
            ? elapsed(session)
            : Math.max(0, session.planned - elapsed(session))
        : minutes * 60;
    const progress =
        running && session.planned
            ? Math.min(1, elapsed(session) / session.planned)
            : 0;
    const day = new Date(now.wall * 1000);
    day.setHours(0, 0, 0, 0);
    const today = dayTotal(state.sessions, day.getTime() / 1000, now.wall);
    const nextBreak =
        state.settings.completed > 0 &&
        state.settings.completed % state.settings.cycleCount === 0
            ? 'longBreak'
            : 'shortBreak';
    async function startBreak() {
        await act({
            type: 'start',
            id: newID(),
            kind: nextBreak,
            intention: 'Time to recharge',
            duration: state.settings[nextBreak] * 60,
        });
    }
    return (
        <>
            <Heading
                title="Make room for focus."
                subtitle="One intention. A little uninterrupted time."
            />
            <div className="focus-content">
                <div
                    className={`timer-face ${state.settings.digital ? 'digital' : ''}`}
                >
                    <svg viewBox="0 0 300 300" aria-hidden="true">
                        <circle
                            className="timer-track"
                            cx="150"
                            cy="150"
                            r="140"
                        />
                        <circle
                            className="timer-progress"
                            cx="150"
                            cy="150"
                            r="140"
                            strokeDasharray="879.65"
                            strokeDashoffset={879.65 * progress}
                        />
                    </svg>
                    <div>
                        <span className="eyebrow">
                            {running
                                ? session.kind === 'focus'
                                    ? 'FOCUS'
                                    : session.kind === 'stopwatch'
                                      ? 'OPEN-ENDED FOCUS'
                                      : 'TIME TO RECHARGE'
                                : 'YOUR NEXT SESSION'}
                        </span>
                        <output aria-label={`Timer ${format(seconds)}`}>
                            {format(seconds)}
                        </output>
                        <span>
                            {session?.status === 'paused'
                                ? 'Paused · take your time'
                                : running
                                  ? 'Stay with what matters.'
                                  : 'Ready when you are.'}
                        </span>
                    </div>
                </div>
                {running ? (
                    <>
                        <h2 className="active-intention">
                            {session.intention || 'A moment of focused work'}
                        </h2>
                        {session.estimated && (
                            <p className="provenance">
                                Estimated recovery · reconciled from saved
                                timestamps.
                            </p>
                        )}
                        <div className="timer-actions">
                            <button
                                className="button"
                                onClick={() =>
                                    void act({
                                        type:
                                            session.status === 'paused'
                                                ? 'resume'
                                                : 'pause',
                                        id: session.id,
                                    })
                                }
                            >
                                <Icon
                                    name={
                                        session.status === 'paused'
                                            ? 'play'
                                            : 'pause'
                                    }
                                />
                                {session.status === 'paused'
                                    ? 'Resume'
                                    : 'Pause'}
                            </button>
                            <button
                                onClick={() =>
                                    void act({
                                        type: 'finish',
                                        id: session.id,
                                    }).then((result) => {
                                        if (result && session.kind === 'focus')
                                            onReflect(session.id);
                                    })
                                }
                            >
                                <Icon name="check" />
                                Finish
                            </button>
                            <button
                                className="quiet"
                                onClick={() =>
                                    void act({ type: 'extend', id: session.id })
                                }
                            >
                                +5 min
                            </button>
                        </div>
                        <button
                            className="quiet subtle"
                            onClick={() =>
                                void act({ type: 'abandon', id: session.id })
                            }
                        >
                            Abandon this session
                        </button>
                    </>
                ) : (
                    <form
                        className="focus-form"
                        onSubmit={(e) => {
                            e.preventDefault();
                            void act({
                                type: 'start',
                                id: newID(),
                                kind,
                                intention,
                                duration:
                                    kind === 'stopwatch' ? null : minutes * 60,
                                project: project || undefined,
                            });
                        }}
                    >
                        <label className="sr-only" htmlFor="intention">
                            Your focus intention
                        </label>
                        <input
                            id="intention"
                            className="intention-input"
                            placeholder="What would you like to focus on?"
                            value={intention}
                            onChange={(e) => setIntention(e.target.value)}
                            maxLength={10000}
                        />
                        <div className="form-row">
                            <label>
                                Project
                                <select
                                    value={project}
                                    onChange={(e) => setProject(e.target.value)}
                                >
                                    <option value="">No project</option>
                                    {state.projects
                                        .filter((p) => !p.archived)
                                        .map((p) => (
                                            <option value={p.id} key={p.id}>
                                                {p.name}
                                            </option>
                                        ))}
                                </select>
                            </label>
                            <label>
                                Session
                                <select
                                    value={kind}
                                    onChange={(e) =>
                                        setKind(e.target.value as Kind)
                                    }
                                >
                                    <option value="focus">Focus</option>
                                    <option value="shortBreak">
                                        Short break
                                    </option>
                                    <option value="longBreak">
                                        Long break
                                    </option>
                                    <option value="stopwatch">
                                        Open-ended focus
                                    </option>
                                </select>
                            </label>
                        </div>
                        <div
                            className="preset-row"
                            role="group"
                            aria-label="Focus duration"
                        >
                            {[15, 25, 45, 50, 60, 90].map((value) => (
                                <button
                                    type="button"
                                    key={value}
                                    aria-pressed={minutes === value}
                                    onClick={() => setMinutes(value)}
                                >
                                    {value}m
                                </button>
                            ))}
                            <label className="custom-duration">
                                <span className="sr-only">
                                    Custom duration in minutes
                                </span>
                                <input
                                    type="number"
                                    min="1"
                                    max="1440"
                                    value={minutes}
                                    onChange={(e) =>
                                        setMinutes(Number(e.target.value))
                                    }
                                />
                                <span>min</span>
                            </label>
                        </div>
                        <button
                            className="button start-button"
                            disabled={!ready || minutes < 1 || minutes > 1440}
                        >
                            <Icon name="play" size={18} />
                            Start session
                        </button>
                        <button
                            type="button"
                            className="quiet break-link"
                            onClick={() => void startBreak()}
                        >
                            <Icon name="break" size={18} />
                            Take a restorative break
                        </button>
                    </form>
                )}
                <div className="focus-summary">
                    <div>
                        <strong>{Math.floor(today / 60)} min</strong>
                        <span>Focused today</span>
                    </div>
                    <div>
                        <strong>{state.settings.completed} sessions</strong>
                        <span>
                            Next: {nextBreak === 'longBreak' ? 'long' : 'short'}{' '}
                            break
                        </span>
                    </div>
                    <div>
                        <strong>At your pace</strong>
                        <span>Rest counts, too.</span>
                    </div>
                </div>
            </div>
        </>
    );
}
function Projects({
    store,
    onFocus,
}: {
    store: TempoStore;
    onFocus: () => void;
}) {
    const [name, setName] = useState('');
    const { state, mutate, act, session } = store;
    return (
        <>
            <Heading
                title="Meaningful work, together."
                subtitle="Give your focused time a home."
            />
            <form
                className="inline-form"
                onSubmit={(e) => {
                    e.preventDefault();
                    if (name.trim())
                        void mutate((s) => ({
                            ...s,
                            projects: [
                                ...s.projects,
                                {
                                    id: newID(),
                                    name: name.trim(),
                                    archived: false,
                                },
                            ],
                        })).then(() => setName(''));
                }}
            >
                <label className="sr-only" htmlFor="project-name">
                    Project name
                </label>
                <input
                    id="project-name"
                    value={name}
                    maxLength={200}
                    onChange={(e) => setName(e.target.value)}
                    placeholder="Name a new project"
                />
                <button disabled={!name.trim()}>
                    <Icon name="plus" />
                    Create project
                </button>
            </form>
            <div className="project-grid">
                {state.projects.map((p) => (
                    <article className="panel project-card" key={p.id}>
                        <Icon name="projects" size={28} />
                        <h2>{p.name}</h2>
                        <p>
                            {Math.floor(
                                state.sessions
                                    .filter((s) => s.project === p.id)
                                    .reduce((n, s) => n + focused(s), 0) / 60,
                            )}{' '}
                            minutes recorded ·{' '}
                            {
                                state.tasks.filter(
                                    (t) => t.project === p.id && !t.done,
                                ).length
                            }{' '}
                            open tasks
                        </p>
                        <div>
                            <button
                                disabled={!!session || p.archived}
                                onClick={() =>
                                    void act({
                                        type: 'start',
                                        id: newID(),
                                        kind: 'focus',
                                        intention: p.name,
                                        duration: state.settings.focus * 60,
                                        project: p.id,
                                    }).then((result) => {
                                        if (result) onFocus();
                                    })
                                }
                            >
                                <Icon name="play" size={16} />
                                Focus
                            </button>
                            <button
                                className="quiet"
                                onClick={() =>
                                    void mutate((s) => ({
                                        ...s,
                                        projects: s.projects.map((x) =>
                                            x.id === p.id
                                                ? {
                                                      ...x,
                                                      archived: !x.archived,
                                                  }
                                                : x,
                                        ),
                                    }))
                                }
                            >
                                {p.archived ? 'Restore' : 'Archive'}
                            </button>
                        </div>
                    </article>
                ))}
            </div>
            {!state.projects.length && (
                <Empty
                    icon="projects"
                    title="A fresh start"
                    detail="Add your first project. There’s no need to plan everything at once."
                />
            )}
        </>
    );
}
function Tasks({ store, onFocus }: { store: TempoStore; onFocus: () => void }) {
    const [title, setTitle] = useState(''),
        [project, setProject] = useState('');
    const { state, mutate, act, session } = store;
    return (
        <>
            <Heading
                title="One small step."
                subtitle="Lightweight tasks for the work that matters."
            />
            <form
                className="inline-form"
                onSubmit={(e) => {
                    e.preventDefault();
                    if (title.trim())
                        void mutate((s) => ({
                            ...s,
                            tasks: [
                                ...s.tasks,
                                {
                                    id: newID(),
                                    title: title.trim(),
                                    project: project || undefined,
                                    done: false,
                                },
                            ],
                        })).then(() => setTitle(''));
                }}
            >
                <input
                    aria-label="Task title"
                    placeholder="What’s your next step?"
                    value={title}
                    onChange={(e) => setTitle(e.target.value)}
                    maxLength={10000}
                />
                <select
                    aria-label="Task project"
                    value={project}
                    onChange={(e) => setProject(e.target.value)}
                >
                    <option value="">No project</option>
                    {state.projects.map((p) => (
                        <option key={p.id} value={p.id}>
                            {p.name}
                        </option>
                    ))}
                </select>
                <button disabled={!title.trim()}>
                    <Icon name="plus" />
                    Add task
                </button>
            </form>
            <div className="record-list">
                {state.tasks.map((t) => (
                    <article key={t.id} className="task-row">
                        <button
                            className="task-check quiet"
                            aria-label={
                                t.done ? 'Reopen task' : 'Complete task'
                            }
                            aria-pressed={t.done}
                            onClick={() =>
                                void mutate((s) => ({
                                    ...s,
                                    tasks: s.tasks.map((x) =>
                                        x.id === t.id
                                            ? { ...x, done: !x.done }
                                            : x,
                                    ),
                                }))
                            }
                        >
                            <Icon name={t.done ? 'check' : 'focus'} />
                        </button>
                        <div>
                            <h3 className={t.done ? 'completed-text' : ''}>
                                {t.title}
                            </h3>
                            <p>
                                {state.projects.find((p) => p.id === t.project)
                                    ?.name || 'Unassigned'}{' '}
                                ·{' '}
                                {Math.floor(
                                    state.sessions
                                        .filter((s) => s.task === t.id)
                                        .reduce((n, s) => n + focused(s), 0) /
                                        60,
                                )}{' '}
                                minutes focused
                            </p>
                        </div>
                        <button
                            disabled={!!session}
                            onClick={() =>
                                void act({
                                    type: 'start',
                                    id: newID(),
                                    kind: 'focus',
                                    intention: t.title,
                                    duration: state.settings.focus * 60,
                                    task: t.id,
                                    project: t.project,
                                }).then((result) => {
                                    if (result) onFocus();
                                })
                            }
                        >
                            <Icon name="play" size={16} />
                            Focus
                        </button>
                    </article>
                ))}
            </div>
            {!state.tasks.length && (
                <Empty
                    icon="tasks"
                    title="Nothing on your list"
                    detail="Add a task, or start a focus session without one."
                />
            )}
        </>
    );
}
function History({
    store,
    onReflect,
}: {
    store: TempoStore;
    onReflect: (id: string) => void;
}) {
    const [query, setQuery] = useState('');
    const rows = store.state.sessions
        .filter(
            (s) =>
                !['running', 'paused'].includes(s.status) &&
                s.intention.toLowerCase().includes(query.toLowerCase()),
        )
        .toReversed();
    return (
        <>
            <Heading
                title="An honest record."
                subtitle="Your focused work and restorative breaks, in one place."
            />
            <div className="inline-form">
                <input
                    aria-label="Search history"
                    placeholder="Search intentions…"
                    value={query}
                    onChange={(e) => setQuery(e.target.value)}
                />
                <button
                    onClick={() => {
                        const quote = (v: string) =>
                            `"${(/^[\s]*[=+@-]/.test(v) ? "'" : '') + v.replaceAll('"', '""')}"`;
                        download(
                            'Tempo-web-sessions.csv',
                            'id,intention,kind,start_utc,active_seconds,paused_seconds,status\n' +
                                rows
                                    .map((s) =>
                                        [
                                            s.id,
                                            s.intention,
                                            s.kind,
                                            new Date(
                                                s.start * 1000,
                                            ).toISOString(),
                                            String(elapsed(s)),
                                            String(
                                                s.segments
                                                    .filter((g) => g.paused)
                                                    .reduce(
                                                        (n, g) => n + g.elapsed,
                                                        0,
                                                    ),
                                            ),
                                            s.status,
                                        ]
                                            .map(quote)
                                            .join(','),
                                    )
                                    .join('\n'),
                            'text/csv',
                        );
                    }}
                >
                    <Icon name="download" />
                    Export CSV
                </button>
            </div>
            <div className="record-list">
                {rows.map((s) => (
                    <details key={s.id} className="session-record">
                        <summary>
                            <Icon
                                name={
                                    s.kind === 'focus' || s.kind === 'stopwatch'
                                        ? 'focus'
                                        : 'break'
                                }
                            />
                            <div>
                                <h3>{s.intention || s.kind}</h3>
                                <p>
                                    {new Date(s.start * 1000).toLocaleString()}
                                </p>
                            </div>
                            <div className="record-total">
                                <strong>{format(elapsed(s))}</strong>
                                <span>{s.status}</span>
                            </div>
                        </summary>
                        <div className="record-detail">
                            <p>
                                Planned:{' '}
                                {s.planned === null
                                    ? 'Open-ended'
                                    : format(s.planned)}{' '}
                                · Active: {format(elapsed(s))} · Paused:{' '}
                                {format(
                                    s.segments
                                        .filter((g) => g.paused)
                                        .reduce((n, g) => n + g.elapsed, 0),
                                )}
                            </p>
                            {s.estimated && (
                                <p>Estimated recovery from saved timestamps.</p>
                            )}
                            {s.reflection && (
                                <blockquote>{s.reflection}</blockquote>
                            )}
                            <button onClick={() => onReflect(s.id)}>
                                Add or edit reflection
                            </button>
                        </div>
                    </details>
                ))}
            </div>
            {!rows.length && (
                <Empty
                    icon="history"
                    title="Your story starts here"
                    detail="Complete a session to see your own records. No sample history is included."
                />
            )}
        </>
    );
}
function Analytics({ store }: { store: TempoStore }) {
    const { state, now } = store;
    const days = Array.from({ length: 7 }, (_, i) => {
        const d = new Date(now.wall * 1000);
        d.setHours(0, 0, 0, 0);
        d.setDate(d.getDate() - 6 + i);
        const end = new Date(d);
        end.setDate(d.getDate() + 1);
        return {
            date: d,
            seconds: dayTotal(
                state.sessions,
                d.getTime() / 1000,
                end.getTime() / 1000,
            ),
        };
    });
    const max = Math.max(60, ...days.map((d) => d.seconds));
    return (
        <>
            <Heading
                title="Your time, understood."
                subtitle="Recorded active time. Pauses and breaks excluded."
            />
            <div className="stats">
                <div className="panel">
                    <span>This week</span>
                    <strong>
                        {Math.floor(
                            days.reduce((n, d) => n + d.seconds, 0) / 60,
                        )}
                        <small> min</small>
                    </strong>
                </div>
                <div className="panel">
                    <span>Completed focus sessions</span>
                    <strong>
                        {
                            state.sessions.filter(
                                (s) =>
                                    s.status === 'completed' &&
                                    s.kind === 'focus',
                            ).length
                        }
                    </strong>
                </div>
                <div className="panel">
                    <span>Today’s optional goal</span>
                    <strong>
                        {Math.floor(days[6].seconds / 60)}
                        <small> / {state.settings.dailyGoal} min</small>
                    </strong>
                </div>
            </div>
            <section className="panel">
                <h2>
                    <Icon name="analytics" /> Your last seven days
                </h2>
                <div
                    className="bar-chart"
                    role="img"
                    aria-label={days
                        .map(
                            (d) =>
                                `${d.date.toLocaleDateString()}: ${Math.floor(d.seconds / 60)} minutes`,
                        )
                        .join('; ')}
                >
                    {days.map((d) => (
                        <div className="bar-column" key={d.date.toISOString()}>
                            <span>{Math.floor(d.seconds / 60)}m</span>
                            <div className="bar-track">
                                <div
                                    className="bar"
                                    style={{
                                        height: `${(d.seconds / max) * 100}%`,
                                    }}
                                />
                            </div>
                            <span>
                                {d.date.toLocaleDateString(undefined, {
                                    weekday: 'short',
                                })}
                            </span>
                        </div>
                    ))}
                </div>
            </section>
            <p className="provenance">
                Recovered intervals may be estimated and are labelled in
                History. Focus ratings are personal assessments, not objective
                productivity measurements.
            </p>
        </>
    );
}
function Reflection({
    store,
    id,
    close,
}: {
    store: TempoStore;
    id: string;
    close: () => void;
}) {
    const session = store.state.sessions.find((s) => s.id === id);
    const [note, setNote] = useState(session?.reflection || ''),
        [rating, setRating] = useState(session?.rating || 3);
    return (
        <section
            className="reflection-panel panel"
            aria-label="Optional session reflection"
        >
            <h2>
                <Icon name="idea" />A moment to reflect
            </h2>
            <p>What did you accomplish? This is entirely optional.</p>
            <textarea
                aria-label="Reflection note"
                value={note}
                maxLength={10000}
                onChange={(e) => setNote(e.target.value)}
                rows={3}
            />
            <label>
                How focused did you feel?{' '}
                <select
                    value={rating}
                    onChange={(e) => setRating(Number(e.target.value))}
                >
                    {[1, 2, 3, 4, 5].map((n) => (
                        <option key={n} value={n}>
                            {n} / 5
                        </option>
                    ))}
                </select>
            </label>
            <div>
                <button className="quiet" onClick={close}>
                    Skip
                </button>
                <button
                    onClick={() =>
                        void store
                            .mutate((s) => ({
                                ...s,
                                sessions: s.sessions.map((r) =>
                                    r.id === id
                                        ? {
                                              ...r,
                                              reflection: note,
                                              rating,
                                              revision: r.revision + 1,
                                          }
                                        : r,
                                ),
                            }))
                            .then((result) => {
                                if (result) close();
                            })
                    }
                >
                    Save reflection
                </button>
            </div>
        </section>
    );
}
function Ideas({ store, touch }: { store: TempoStore; touch: () => void }) {
    const [title, setTitle] = useState(''),
        [search, setSearch] = useState('');
    return (
        <div onPointerDown={touch} onKeyDown={touch}>
            <Heading
                title="Developer Ideas"
                subtitle="Private, local notes. Separate from your ordinary tasks."
            />
            <p className="provenance">
                Web 0.1.0 · schema 1 · IndexedDB · No synchronization ·{' '}
                {store.state.provenance}
            </p>
            <form
                className="inline-form"
                onSubmit={(e) => {
                    e.preventDefault();
                    if (title.trim())
                        void store
                            .mutate((s) => ({
                                ...s,
                                ideas: [
                                    ...s.ideas,
                                    {
                                        id: newID(),
                                        title,
                                        detail: '',
                                        status: 'Pending',
                                        modified: clock().wall,
                                    },
                                ],
                            }))
                            .then(() => setTitle(''));
                }}
            >
                <input
                    aria-label="Idea title"
                    value={title}
                    onChange={(e) => setTitle(e.target.value)}
                    placeholder="Record a new idea"
                />
                <button disabled={!title.trim()}>Add idea</button>
            </form>
            <input
                className="idea-search"
                aria-label="Search ideas"
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                placeholder="Search ideas"
            />
            {store.state.ideas
                .filter((i) =>
                    i.title.toLowerCase().includes(search.toLowerCase()),
                )
                .toReversed()
                .map((i) => (
                    <details key={i.id} className="panel">
                        <summary>
                            <Icon name="idea" />
                            {i.title} · {i.status}
                        </summary>
                        <label>
                            Description
                            <textarea
                                defaultValue={i.detail}
                                onBlur={(e) =>
                                    void store.mutate((s) => ({
                                        ...s,
                                        ideas: s.ideas.map((x) =>
                                            x.id === i.id
                                                ? {
                                                      ...x,
                                                      detail: e.target.value,
                                                      modified: clock().wall,
                                                  }
                                                : x,
                                        ),
                                    }))
                                }
                            />
                        </label>
                        <label>
                            Status
                            <select
                                value={i.status}
                                onChange={(e) =>
                                    void store.mutate((s) => ({
                                        ...s,
                                        ideas: s.ideas.map((x) =>
                                            x.id === i.id
                                                ? {
                                                      ...x,
                                                      status: e.target
                                                          .value as typeof i.status,
                                                      modified: clock().wall,
                                                  }
                                                : x,
                                        ),
                                    }))
                                }
                            >
                                {[
                                    'Pending',
                                    'Approved',
                                    'Deferred',
                                    'In Progress',
                                    'Implemented',
                                    'Rejected',
                                ].map((status) => (
                                    <option key={status}>{status}</option>
                                ))}
                            </select>
                        </label>
                    </details>
                ))}
        </div>
    );
}
function Empty({
    icon,
    title,
    detail,
}: {
    icon: string;
    title: string;
    detail: string;
}) {
    return (
        <div className="empty">
            <Icon name={icon} size={36} />
            <h2>{title}</h2>
            <p>{detail}</p>
        </div>
    );
}
