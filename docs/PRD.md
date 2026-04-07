# Product Requirements Document — The Void

## Problem

People have fleeting thoughts throughout the day but no low-friction way to capture them without creating digital clutter. Existing note apps save everything by default, which leads to sprawling, unreviewed libraries of notes that users never revisit. The result: anxiety about unprocessed information, and valuable ideas buried alongside throwaway thoughts.

## Solution

The Void is a voice-first note app where **nothing is saved unless you choose to save it**. You speak your thought, see it transcribed in real time, and then face a simple decision: rescue it or let it disappear. The 10-second countdown creates just enough pressure to force an honest evaluation of whether the idea is worth keeping.

## Target User

- People who think out loud but don't want to maintain a giant notes app
- Journaling-curious users who are intimidated by blank pages
- Professionals who need a quick thought-capture tool during commutes, walks, or between meetings
- Privacy-conscious users who don't want their voice notes living on a server forever

## Core Experience

### Record
- One tap to start recording — no setup, no folder selection, no title prompt
- Real-time waveform shows the mic is active
- Live transcript scrolls as you speak
- Auto-stops after 5 seconds of silence or 2 minutes max

### Decide
- 10-second countdown begins after recording stops
- Full transcript visible during countdown
- Single "Rescue" button to save — everything else results in deletion
- If user does nothing, the note is voided permanently

### Browse (Gems)
- Saved notes ("Gems") appear in a reverse-chronological list
- Tap to view full transcript
- Tap title area to rename inline
- Swipe or tap delete with confirmation

### Sync (Optional)
- Sign in with Google or Apple to back up gems to the cloud
- Local-first: the app works fully offline, sync happens when available
- Auth is optional — never forced, never nagging

## Non-Functional Requirements

### Privacy
- Volatile data (transcript, audio buffer) lives only in RAM
- Backgrounding the app immediately wipes all in-progress data
- Saved gems are AES-encrypted at rest via flutter_secure_storage
- No analytics, no tracking, no third-party SDKs beyond auth
- Pending rescue transcripts (during OAuth redirect) auto-expire after 5 minutes

### Performance
- Recording → transcription latency must feel real-time (< 500ms)
- Countdown timer must be visually smooth (1-second ticks, no jank)
- Gem list must scroll smoothly with 100+ items

### Platforms
- Primary: iOS, Android (store submission planned)
- Secondary: Web (deployed on Railway), macOS desktop
- All platforms share one codebase (Flutter)

## Design Language

Dark ethereal aesthetic:
- Background: deep navy/purple (#0D0B14)
- Accent: aquamarine glow (#7FFFD4, #00FF9D)
- Typography: serif font family
- Animations: pulsing mic glow, staggered waveform bars, circular countdown

The visual tone should feel like speaking into a void — calm, dark, spacious.

## Success Metrics

- **Retention signal**: user returns to record again within 7 days
- **Rescue rate**: 20-40% of notes rescued (too high = not ephemeral enough, too low = not useful enough)
- **Session duration**: < 3 minutes average (the app should be fast in, fast out)

## Scope Boundaries

### In scope (v1)
- Voice recording + real-time transcription
- 10-second countdown with rescue
- Gems: list, detail, rename, delete
- Google + Apple OAuth with cloud sync
- Encrypted local storage
- iOS + Android store submission

### Out of scope (v1)
- Audio playback (field exists, no UI yet)
- Tags and search
- Sharing / export
- Collaborative features
- Notification reminders
- Desktop-first optimizations
