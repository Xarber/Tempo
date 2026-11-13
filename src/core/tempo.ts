// SPDX-License-Identifier: AGPL-3.0-only
export type Kind = 'focus' | 'shortBreak' | 'longBreak' | 'stopwatch';
export type Status =
    | 'running'
    | 'paused'
    | 'completed'
    | 'abandoned'
    | 'interrupted';
export interface Clock {
    wall: number;
    mono: number;
    origin: string;
}
export interface Segment {
    start: number;
    elapsed: number;
    paused: boolean;
}
export interface Session {
    id: string;
    intention: string;
    project?: string;
    task?: string;
    kind: Kind;
    planned: number | null;
    start: number;
    end?: number;
    status: Status;
    segments: Segment[];
    anchor: Clock;
    revision: number;
    estimated: boolean;
    reflection: string;
    rating?: number;
}
export interface Project {
    id: string;
    name: string;
    archived: boolean;
}
export interface Task {
    id: string;
    title: string;
    project?: string;
    done: boolean;
}
export interface Idea {
    id: string;
    title: string;
    detail: string;
    status:
        | 'Pending'
        | 'Approved'
        | 'Deferred'
        | 'In Progress'
        | 'Implemented'
        | 'Rejected';
    modified: number;
}
export interface Settings {
    focus: number;
    shortBreak: number;
    longBreak: number;
    cycleCount: number;
    completed: number;
    dailyGoal: number;
    digital: boolean;
}
export interface State {
    schemaVersion: 1;
    application: 'org.openrecode.tempo.web';
    provenance: 'recorded' | 'simulated';
    sessions: Session[];
    projects: Project[];
    tasks: Task[];
    ideas: Idea[];
    settings: Settings;
}
export const empty = (qa = false): State => ({
    schemaVersion: 1,
    application: 'org.openrecode.tempo.web',
    provenance: qa ? 'simulated' : 'recorded',
    sessions: [],
    projects: [],
    tasks: [],
    ideas: [],
    settings: {
        focus: 25,
        shortBreak: 5,
        longBreak: 15,
        cycleCount: 4,
        completed: 0,
        dailyGoal: 90,
        digital: false,
    },
});
export const active = (state: State) =>
    state.sessions.find((s) => s.status === 'running' || s.status === 'paused');
export const elapsed = (session: Session) =>
    session.segments
        .filter((s) => !s.paused)
        .reduce((n, s) => n + s.elapsed, 0);
export const focused = (session: Session) =>
    session.kind === 'focus' || session.kind === 'stopwatch'
        ? elapsed(session)
        : 0;
export function snapshot(session: Session, clock: Clock): Session {
    if (!['running', 'paused'].includes(session.status))
        return structuredClone(session);
    const next = structuredClone(session),
        last = next.segments.at(-1)!;
    const wallDelta = clock.wall - next.anchor.wall;
    let delta: number;
    if (clock.origin === next.anchor.origin && clock.mono >= next.anchor.mono) {
        const monoDelta = clock.mono - next.anchor.mono;
        // Some browser monotonic clocks stop in system sleep. Divergence cannot distinguish sleep from a clock edit.
        delta = monoDelta;
        if (wallDelta > monoDelta + 2) {
            delta = wallDelta;
            next.estimated = true;
        }
    } else {
        next.estimated = true;
        if (wallDelta < -2 || wallDelta > 604800) {
            next.status = 'interrupted';
            next.end = clock.wall;
            return next;
        }
        delta = Math.max(0, wallDelta);
    }
    last.elapsed += Math.max(0, delta);
    next.anchor = clock;
    if (
        next.status === 'running' &&
        next.planned !== null &&
        elapsed(next) >= next.planned
    ) {
        const excess = elapsed(next) - next.planned;
        last.elapsed = Math.max(0, last.elapsed - excess);
        next.status = 'completed';
        next.end = clock.wall - excess;
        next.revision++;
    }
    return next;
}
export type Command =
    | {
          type: 'start';
          id: string;
          kind: Kind;
          intention: string;
          duration: number | null;
          project?: string;
          task?: string;
      }
    | { type: 'pause' | 'resume' | 'finish' | 'abandon' | 'extend'; id: string }
    | { type: 'checkpoint' };
export function command(input: State, event: Command, clock: Clock): State {
    const state = structuredClone(input);
    const index = state.sessions.findIndex(
        (s) => s.status === 'running' || s.status === 'paused',
    );
    let session =
        index >= 0 ? snapshot(state.sessions[index], clock) : undefined;
    if (session && index >= 0) {
        if (
            state.sessions[index].status !== 'completed' &&
            session.status === 'completed' &&
            session.kind === 'focus'
        )
            state.settings.completed++;
        state.sessions[index] = session;
    }
    if (event.type === 'checkpoint') return state;
    if (event.type === 'start') {
        if (session && ['running', 'paused'].includes(session.status))
            throw new Error('A session is already active in this browser.');
        if (
            event.duration !== null &&
            (!Number.isFinite(event.duration) ||
                event.duration < 1 ||
                event.duration > 86400)
        )
            throw new Error(
                'Choose a duration between one second and 24 hours.',
            );
        if (event.duration === null && event.kind !== 'stopwatch')
            throw new Error('This session needs a duration.');
        if (
            event.project &&
            !state.projects.some((p) => p.id === event.project)
        )
            throw new Error('Project not found.');
        if (event.task && !state.tasks.some((t) => t.id === event.task))
            throw new Error('Task not found.');
        if (state.sessions.some((s) => s.id === event.id))
            throw new Error('Duplicate session ID.');
        state.sessions.push({
            id: event.id,
            intention: event.intention.trim().slice(0, 10000),
            project: event.project,
            task: event.task,
            kind: event.kind,
            planned: event.duration,
            start: clock.wall,
            status: 'running',
            segments: [{ start: clock.wall, elapsed: 0, paused: false }],
            anchor: clock,
            revision: 1,
            estimated: false,
            reflection: '',
        });
        return state;
    }
    if (!session || session.id !== event.id) {
        if (
            ['finish', 'abandon'].includes(event.type) &&
            state.sessions.some(
                (s) =>
                    s.id === event.id &&
                    ['completed', 'abandoned'].includes(s.status),
            )
        )
            return state;
        throw new Error(
            'The active session changed. Refresh before trying again.',
        );
    }
    if (!['running', 'paused'].includes(session.status)) return state;
    if (event.type === 'pause' || event.type === 'resume') {
        const pause = event.type === 'pause';
        if (session.status !== (pause ? 'running' : 'paused'))
            throw new Error(
                'This action is unavailable for the current timer state.',
            );
        session.status = pause ? 'paused' : 'running';
        session.segments.push({ start: clock.wall, elapsed: 0, paused: pause });
    } else if (event.type === 'extend') {
        if (session.planned === null || session.planned + 300 > 86400)
            throw new Error('This timer cannot be extended.');
        session.planned += 300;
    } else {
        session.status = event.type === 'abandon' ? 'abandoned' : 'completed';
        session.end = clock.wall;
        if (event.type === 'finish' && session.kind === 'focus')
            state.settings.completed++;
    }
    session.revision++;
    return state;
}
export function validate(value: unknown): State {
    if (!value || typeof value !== 'object')
        throw new Error('Invalid Tempo web archive.');
    const s = value as State;
    if (
        s.schemaVersion !== 1 ||
        s.application !== 'org.openrecode.tempo.web' ||
        !['recorded', 'simulated'].includes(s.provenance)
    )
        throw new Error(
            'Use a version-1 Tempo Web JSON archive. Native Swift exports use a different schema.',
        );
    for (const list of [s.sessions, s.projects, s.tasks, s.ideas])
        if (
            !Array.isArray(list) ||
            list.length > 100000 ||
            new Set(list.map((x) => x.id)).size !== list.length ||
            list.some((x) => typeof x.id !== 'string' || x.id.length > 100)
        )
            throw new Error('Invalid or duplicated records.');
    const text = (v: unknown, max = 10000) =>
        typeof v === 'string' && v.length <= max;
    const number = (v: unknown) =>
        typeof v === 'number' && Number.isFinite(v) && Math.abs(v) < 1e13;
    if (
        s.projects.some(
            (p) => !text(p.name, 200) || typeof p.archived !== 'boolean',
        ) ||
        s.tasks.some(
            (t) =>
                !text(t.title) ||
                typeof t.done !== 'boolean' ||
                (t.project && !s.projects.some((p) => p.id === t.project)),
        )
    )
        throw new Error('Invalid project or task.');
    if (
        s.ideas.some(
            (i) =>
                !text(i.title) ||
                !text(i.detail) ||
                !number(i.modified) ||
                ![
                    'Pending',
                    'Approved',
                    'Deferred',
                    'In Progress',
                    'Implemented',
                    'Rejected',
                ].includes(i.status),
        )
    )
        throw new Error('Invalid developer idea.');
    if (
        s.sessions.filter((x) => ['running', 'paused'].includes(x.status))
            .length > 1
    )
        throw new Error('More than one active session.');
    for (const r of s.sessions) {
        if (
            !text(r.intention) ||
            !text(r.reflection) ||
            !['focus', 'shortBreak', 'longBreak', 'stopwatch'].includes(
                r.kind,
            ) ||
            ![
                'running',
                'paused',
                'completed',
                'abandoned',
                'interrupted',
            ].includes(r.status) ||
            !number(r.start) ||
            !Number.isSafeInteger(r.revision) ||
            r.revision < 1 ||
            typeof r.estimated !== 'boolean' ||
            (r.end !== undefined && !number(r.end)) ||
            (r.rating !== undefined &&
                (!Number.isInteger(r.rating) ||
                    r.rating < 1 ||
                    r.rating > 5)) ||
            !Array.isArray(r.segments) ||
            !r.segments.length ||
            r.segments.length > 10000 ||
            r.segments.some(
                (g) =>
                    !number(g.start) ||
                    !number(g.elapsed) ||
                    g.elapsed < 0 ||
                    g.elapsed > 31536000 ||
                    typeof g.paused !== 'boolean',
            ) ||
            !r.anchor ||
            !number(r.anchor.wall) ||
            !number(r.anchor.mono) ||
            !text(r.anchor.origin, 200) ||
            (r.planned !== null &&
                (!number(r.planned) || r.planned < 1 || r.planned > 86400)) ||
            (r.project && !s.projects.some((p) => p.id === r.project)) ||
            (r.task && !s.tasks.some((t) => t.id === r.task))
        )
            throw new Error('Invalid session timing or references.');
    }
    if (
        !s.settings ||
        !['focus', 'shortBreak', 'longBreak', 'cycleCount', 'dailyGoal'].every(
            (key) => {
                const n = s.settings[key as keyof Settings];
                return (
                    typeof n === 'number' &&
                    Number.isFinite(n) &&
                    n >= 1 &&
                    n <= 1440
                );
            },
        ) ||
        !Number.isSafeInteger(s.settings.completed) ||
        s.settings.completed < 0 ||
        typeof s.settings.digital !== 'boolean'
    )
        throw new Error('Invalid timer preferences.');
    return s;
}
export function merge(incoming: State, existing: State): State {
    validate(incoming);
    if (
        incoming.provenance === 'simulated' &&
        existing.provenance !== 'simulated'
    )
        throw new Error('QA records cannot enter recorded history.');
    const next = structuredClone(existing);
    for (const key of ['projects', 'tasks', 'ideas'] as const) {
        const ids = new Set(existing[key].map((x) => x.id));
        (next[key] as (Project | Task | Idea)[]).push(
            ...incoming[key].filter((x) => !ids.has(x.id)),
        );
    }
    const ids = new Set(existing.sessions.map((x) => x.id));
    next.sessions.push(
        ...incoming.sessions
            .filter((x) => !ids.has(x.id))
            .map((r) => ({
                ...r,
                status: ['running', 'paused'].includes(r.status)
                    ? ('interrupted' as const)
                    : r.status,
                end: r.end ?? r.anchor.wall,
            })),
    );
    return validate(next);
}
export function dayTotal(
    sessions: Session[],
    start: number,
    end: number,
): number {
    return sessions
        .filter((s) => s.kind === 'focus' || s.kind === 'stopwatch')
        .reduce(
            (total, s) =>
                total +
                s.segments
                    .filter((g) => !g.paused)
                    .reduce(
                        (sum, g) =>
                            sum +
                            Math.max(
                                0,
                                Math.min(g.start + g.elapsed, end) -
                                    Math.max(g.start, start),
                            ),
                        0,
                    ),
            0,
        );
}
