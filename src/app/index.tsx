// SPDX-License-Identifier: AGPL-3.0-only
import { useState } from 'react';
import {
    Pressable,
    ScrollView,
    StyleSheet,
    Text,
    TextInput,
    useColorScheme,
    View,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { elapsed } from '../core/tempo';
import { newID, useTempo } from '../core/use-tempo';

export default function NativeFocus() {
    const { act, error, ready, session, state } = useTempo();
    const [intention, setIntention] = useState('');
    const [minutes, setMinutes] = useState(25);
    const dark = useColorScheme() === 'dark';
    const text = dark ? '#f8f7fc' : '#232238';
    const surface = dark ? '#252438' : '#eeedf8';
    const running =
        session?.status === 'running' || session?.status === 'paused';
    const remaining = running
        ? session.planned === null
            ? elapsed(session)
            : session.planned - elapsed(session)
        : minutes * 60;
    const seconds = Math.max(0, Math.ceil(remaining));
    return (
        <SafeAreaView
            style={[
                styles.screen,
                { backgroundColor: dark ? '#171624' : '#f9f8ff' },
            ]}
        >
            <ScrollView
                contentContainerStyle={styles.content}
                keyboardShouldPersistTaps="handled"
            >
                <Text style={[styles.title, { color: text }]}>
                    Make room for focus.
                </Text>
                <Text
                    style={[styles.timer, { color: text }]}
                    accessibilityLabel={`Timer ${seconds} seconds`}
                >
                    {Math.floor(seconds / 60)}:
                    {String(seconds % 60).padStart(2, '0')}
                </Text>
                {error && (
                    <Text accessibilityRole="alert" style={{ color: text }}>
                        {error}
                    </Text>
                )}
                {running ? (
                    <>
                        <Text style={{ color: text }}>
                            {session.intention || 'Focus session'}
                            {session.estimated ? ' · estimated recovery' : ''}
                        </Text>
                        <Pressable
                            style={styles.primary}
                            accessibilityRole="button"
                            onPress={() =>
                                void act({
                                    type:
                                        session.status === 'paused'
                                            ? 'resume'
                                            : 'pause',
                                    id: session.id,
                                })
                            }
                        >
                            <Text style={styles.buttonLabel}>
                                {session.status === 'paused'
                                    ? 'Resume'
                                    : 'Pause'}
                            </Text>
                        </Pressable>
                        <Pressable
                            style={[
                                styles.secondary,
                                { backgroundColor: surface },
                            ]}
                            accessibilityRole="button"
                            onPress={() =>
                                void act({ type: 'finish', id: session.id })
                            }
                        >
                            <Text style={{ color: text }}>Finish session</Text>
                        </Pressable>
                    </>
                ) : (
                    <>
                        <TextInput
                            style={[
                                styles.secondary,
                                { color: text, backgroundColor: surface },
                            ]}
                            placeholderTextColor={dark ? '#bbb8ce' : '#625f78'}
                            placeholder="Your focus intention"
                            accessibilityLabel="Your focus intention"
                            value={intention}
                            onChangeText={setIntention}
                            maxLength={10000}
                        />
                        <View style={styles.presets}>
                            {[15, 25, 45, 60, 90].map((value) => (
                                <Pressable
                                    accessibilityRole="button"
                                    accessibilityState={{
                                        selected: minutes === value,
                                    }}
                                    key={value}
                                    style={[
                                        styles.secondary,
                                        { backgroundColor: surface },
                                    ]}
                                    onPress={() => setMinutes(value)}
                                >
                                    <Text style={{ color: text }}>
                                        {minutes === value ? '✓ ' : ''}
                                        {value}m
                                    </Text>
                                </Pressable>
                            ))}
                        </View>
                        <Pressable
                            style={styles.primary}
                            accessibilityRole="button"
                            disabled={!ready}
                            onPress={() =>
                                void act({
                                    type: 'start',
                                    id: newID(),
                                    kind: 'focus',
                                    intention,
                                    duration: minutes * 60,
                                })
                            }
                        >
                            <Text style={styles.buttonLabel}>
                                Start session
                            </Text>
                        </Pressable>
                        <Pressable
                            style={[
                                styles.secondary,
                                { backgroundColor: surface },
                            ]}
                            accessibilityRole="button"
                            disabled={!ready}
                            onPress={() =>
                                void act({
                                    type: 'start',
                                    id: newID(),
                                    kind: 'shortBreak',
                                    intention: 'Time to recharge',
                                    duration: state.settings.shortBreak * 60,
                                })
                            }
                        >
                            <Text style={{ color: text }}>Take a break</Text>
                        </Pressable>
                    </>
                )}
                <Text style={[styles.heading, { color: text }]}>
                    Recent sessions
                </Text>
                {state.sessions
                    .filter((s) => s.end !== undefined)
                    .slice(-8)
                    .reverse()
                    .map((s) => (
                        <View
                            key={s.id}
                            style={[
                                styles.secondary,
                                { backgroundColor: surface },
                            ]}
                        >
                            <Text style={{ color: text }}>
                                {s.intention || s.kind} ·{' '}
                                {Math.floor(elapsed(s) / 60)} min · {s.status}
                            </Text>
                        </View>
                    ))}
            </ScrollView>
        </SafeAreaView>
    );
}

const styles = StyleSheet.create({
    screen: { flex: 1 },
    content: {
        padding: 24,
        paddingBottom: 120,
        gap: 14,
        width: '100%',
        maxWidth: 600,
        alignSelf: 'center',
    },
    title: { fontSize: 32, fontWeight: '700', letterSpacing: -1 },
    timer: {
        fontSize: 78,
        fontWeight: '200',
        textAlign: 'center',
        fontVariant: ['tabular-nums'],
        marginVertical: 22,
    },
    primary: {
        padding: 14,
        minHeight: 48,
        backgroundColor: '#5048cc',
        borderRadius: 14,
        alignItems: 'center',
        justifyContent: 'center',
    },
    secondary: {
        padding: 12,
        minHeight: 48,
        borderRadius: 12,
        justifyContent: 'center',
    },
    buttonLabel: { color: 'white', fontSize: 17, fontWeight: '600' },
    presets: { flexDirection: 'row', flexWrap: 'wrap', gap: 8 },
    heading: { fontSize: 21, fontWeight: '700', marginTop: 14 },
});
