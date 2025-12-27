# Voice Todo Assistant

A Flutter-based voice AI todo assistant that simulates a daily phone call to help you manage your tasks. Connects to a local Gradio TTS server for voice synthesis.

## Features

- **Simulated Phone Call Interface**: Accept incoming calls from your AI assistant
- **Voice Synthesis**: Text-to-speech using local Gradio API (port 7860)
- **Todo Management**: Add, complete, and delete tasks
- **Daily Check-ins**: Review tasks and add new ones via voice conversation
- **Local Storage**: Tasks persist between sessions
- **Dark Theme**: Modern, eye-friendly UI

## Prerequisites

- Flutter SDK 3.0+
- Android Studio / VS Code with Flutter extensions
- Local TTS server running on port 7860 (Gradio-based)

## Project Structure

```
lib/
├── main.dart                    # App entry point
├── models/
│   ├── todo.dart                # Todo data model
│   └── call_state.dart          # Call session state machine
├── services/
│   ├── gradio_tts_service.dart  # Gradio /gen_single API client
│   ├── audio_service.dart       # Audio playback (audioplayers)
│   └── todo_service.dart        # Todo CRUD + local persistence
├── providers/
│   └── call_provider.dart       # State management (ChangeNotifier)
└── screens/
    ├── home_screen.dart         # Main todo list + call button
    └── call_screen.dart         # Phone call simulation UI
```

## Setup

### 1. Install Dependencies

```bash
cd personal-assisant-app
flutter pub get
```

### 2. Run on Android Emulator

```bash
flutter run
```

**Note**: When running on Android emulator, the app automatically uses `10.0.2.2:7860` to reach the host machine's localhost.

### 3. Run on Physical Android Device

For physical devices, ensure:
- Your phone and computer are on the same network
- Update the TTS server URL in `lib/main.dart` to use your computer's IP address

```dart
String ttsHost = 'http://YOUR_COMPUTER_IP:7860';
```

## TTS Server (Gradio)

The app expects a Gradio TTS server running locally with the `/gen_single` endpoint.

### API Endpoint Used

```
POST http://localhost:7860/gradio_api/call/gen_single
```

**Request format**:
```json
{
  "data": [
    "Same as the voice reference",  // Emotion control method
    null,                           // Voice reference
    "Hello, how are you?",          // Text to synthesize
    null,                           // Emotion reference audio
    0, 0, 0, 0, 0, 0, 0, 0, 0,      // Emotion sliders
    "",                             // Emotion description
    true,                           // Randomize emotion
    20,                             // Max tokens
    true,                           // do_sample
    0, 0, 0.1, -2, 1, 0.1, 50      // Generation params
  ]
}
```

**Response**: Returns an `event_id`, then stream results from:
```
GET http://localhost:7860/gradio_api/call/gen_single/{event_id}
```

## Call Flow

1. **Incoming Call** - User sees call notification
2. **Greeting** - AI greets based on time of day
3. **Review Todos** - AI summarizes pending tasks
4. **Add Todos** - User can add new tasks by voice/text
5. **Summary** - AI wraps up and ends call

## Android Permissions

The app requires these permissions (already configured):

- `INTERNET` - API calls to TTS server
- `RECORD_AUDIO` - Voice input (future)
- `POST_NOTIFICATIONS` - Daily call reminders
- `VIBRATE` - Call notifications

## Configuration

### Change TTS Server URL

Edit `lib/main.dart`:

```dart
String ttsHost = 'http://YOUR_SERVER:7860';
```

### Change User Name

Edit `lib/providers/call_provider.dart`:

```dart
String _userName = 'YourName';
```

## Building for Release

```bash
# Build APK
flutter build apk --release

# Build App Bundle
flutter build appbundle --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

## Troubleshooting

### TTS not working on Android emulator
- Ensure server is running on host machine port 7860
- The app uses `10.0.2.2` to reach host from emulator

### Network errors
- Check `android:usesCleartextTraffic="true"` in AndroidManifest
- Verify `network_security_config.xml` includes your server IP

### Audio not playing
- Check device volume
- Verify audio file downloads correctly (check logs)

## Dependencies

| Package | Purpose |
|---------|---------|
| `provider` | State management |
| `http` | HTTP client for API calls |
| `audioplayers` | Audio playback |
| `shared_preferences` | Local todo storage |
| `path_provider` | Temp file paths |
| `flutter_local_notifications` | Call reminders |
| `speech_to_text` | Voice input (future) |

## License

MIT
