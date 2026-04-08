# Gyro MIDI Bridge

`Gyro MIDI Bridge` is the local companion app for the GrandPiano web app.

It solves the browser sandbox problem by doing this locally:

- discovers Bluetooth LE MIDI devices such as WIDI
- connects to the real hardware device
- subscribes to BLE MIDI notifications
- exposes device state over `http://127.0.0.1:8765`
- streams MIDI to the browser over `ws://127.0.0.1:8765/midi`

The browser should connect to the bridge over localhost. The bridge itself is not the controller.

## Local API

- `GET /status`
- `GET /devices`
- `GET /logs`
- `POST /scan`
- `POST /connect` with JSON body `{ "deviceId": "..." }`
- `POST /disconnect`
- `WS /midi`

## Expected Flow

1. User installs and launches the bridge.
2. Bridge scans and connects to the external MIDI device.
3. Web app detects bridge status on localhost.
4. Web app subscribes to `/midi`.
5. Incoming MIDI is rendered as piano audio inside the web app.

## Build

```powershell
cd bridge
flutter pub get
flutter build windows --release
flutter build apk --release
```

## Packaging

Publish release artifacts to the app downloads path, for example:

- `downloads/bridge/manifest.json`
- `downloads/bridge/windows/gyro-midi-bridge-windows.zip`
- `downloads/bridge/android/gyro-midi-bridge-android.apk`

The main web app reads the manifest and presents the correct download for the detected OS.
