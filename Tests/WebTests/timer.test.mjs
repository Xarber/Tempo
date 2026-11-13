// SPDX-License-Identifier: AGPL-3.0-only
import assert from 'node:assert/strict';
import { test } from 'node:test';
import {
    active,
    command,
    dayTotal,
    elapsed,
    empty,
    focused,
    merge,
    validate,
} from '../../src/core/tempo.ts';

const clock = (seconds, origin = 'first') => ({
    wall: 1000 + seconds,
    mono: seconds,
    origin,
});
const start = (kind = 'focus', duration = 60) =>
    command(
        empty(),
        { type: 'start', id: 'one', kind, intention: 'Read', duration },
        clock(0),
    );

test('restores a paused session without adding focus time and finishes only once', () => {
    let state = command(start(), { type: 'pause', id: 'one' }, clock(10));
    state = command(
        validate(JSON.parse(JSON.stringify(state))),
        { type: 'checkpoint' },
        clock(150, 'second'),
    );
    assert.equal(elapsed(active(state)), 10);
    assert.equal(active(state).estimated, true);
    state = command(state, { type: 'resume', id: 'one' }, clock(151, 'second'));
    state = command(state, { type: 'finish', id: 'one' }, clock(156, 'second'));
    assert.equal(focused(state.sessions[0]), 15);
    assert.equal(state.settings.completed, 1);
    assert.deepEqual(
        command(state, { type: 'finish', id: 'one' }, clock(157, 'second')),
        state,
    );
});

test('caps elapsed time at deadline and keeps breaks out of focus analytics', () => {
    const state = command(
        start('shortBreak'),
        { type: 'checkpoint' },
        clock(120),
    );
    assert.equal(active(state), undefined);
    assert.equal(elapsed(state.sessions[0]), 60);
    assert.equal(state.sessions[0].end, 1060);
    assert.equal(dayTotal(state.sessions, 1000, 1120), 0);
});

test('intersects active segments with analytics boundaries', () => {
    const state = command(start(), { type: 'checkpoint' }, clock(120));
    assert.equal(dayTotal(state.sessions, 1020, 1050), 30);
    assert.equal(dayTotal(state.sessions, 1050, 1100), 10);
});

test('rejects a competing start and simulated imports into recorded history', () => {
    assert.throws(
        () =>
            command(
                start(),
                {
                    type: 'start',
                    id: 'two',
                    kind: 'focus',
                    intention: '',
                    duration: 60,
                },
                clock(1),
            ),
        /already active/,
    );
    assert.throws(() => merge(empty(true), empty()));
});
