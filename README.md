# Visitor Management

Front-desk and security staff use this Android app to register visitors, issue a QR pass, and record one check-in and one check-out per registration.

Visitors move through a single visit:

`Registered` → `Checked In` → `Checked Out`

There is no custom backend. Visitor records live in a mock REST API so they survive an app restart.

## Versions

- Flutter 3.47.5
- Dart 3.13.4
- Android minSdk 23 (or the Flutter default, whichever is higher)

## Setup

1. Install Flutter and connect an Android device, or start an emulator. QR scanning needs a camera, so a physical phone is the reliable option.
2. The app already points at a shared CrudCrud resource:

   `https://crudcrud.com/api/c21a2bccad2f47c182433093c92a54dd`

   Sample visitors are already stored there. The server id is the `_id` field, and that value is what the QR code contains.

3. To use your own endpoint, open [crudcrud.com](https://crudcrud.com/), copy the generated root (do not append `/visitors`), and either replace the URL in [`lib/core/config/api_config.dart`](lib/core/config/api_config.dart) or run:

   ```bash
   flutter run --dart-define=API_BASE_URL=https://crudcrud.com/api/your-id
   ```

4. From this folder:

   ```bash
   flutter pub get
   flutter run
   ```

## Packages

- `flutter_riverpod` — app state
- `go_router` — tabs and pushed screens
- `dio` — HTTP client, used only by the repository
- `qr_flutter` — draws the visitor pass
- `mobile_scanner` — reads the pass with the camera

## State management

Riverpod keeps one `VisitorsNotifier` as the list of visitors (`AsyncNotifier`). Registration, edits, deletes, check-in, and check-out write through `VisitorRepository`, then replace that list. The visitor list, the details screen, and the dashboard all watch the same list, so a check-in shows up everywhere without restarting the app.

Dashboard counts are a separate provider. They are computed from the list and the phone’s local date. Search text and the project/status filters are small `Notifier`s. The filtered list is derived from those values. Forms keep their own text controllers. Riverpod does not own the form fields.

Visit transitions live in `VisitRules`, which has no Flutter imports, so the rules can be unit tested on their own.

## API

| Method | Path | Use |
| --- | --- | --- |
| GET | `/visitors` | Load the list |
| GET | `/visitors/{id}` | Look up a scanned id |
| POST | `/visitors` | Register. Status is `Registered`. `created_at` is the device time. |
| PUT | `/visitors/{id}` | Edit visitor details, and save check-in or check-out |
| DELETE | `/visitors/{id}` | Delete after confirmation |

Sample record:

```json
{
  "id": "VIS001",
  "name": "Rahul Sharma",
  "mobile": "9876543210",
  "email": "rahul@example.com",
  "visitor_type": "Customer",
  "project": "Project A",
  "purpose": "Site Visit",
  "status": "Registered",
  "created_at": "2026-10-26T10:00:00+05:30",
  "check_in_time": null,
  "check_out_time": null
}
```

Failed requests become a short message. The screen stays up, and a Try again action reloads the list.

## Features

- Dashboard: visitors registered today, visitors currently checked in, visitors checked out today, plus shortcuts to register and scan
- Visitor list: search by name or mobile, filter by status or project, pull to refresh, open, edit, delete
- Registration and edit with validation (name, 10-digit mobile, optional email, type, project, purpose)
- Details screen with the QR pass, timestamps, and check-in or check-out when the rules allow it
- Scanner tab: camera preview, permission message, invalid QR message, unknown visitor message, and a lock so one scan does not fire twice
- Loading, empty, and network-error states

Today’s counts use the device’s local calendar day. A visitor checked in on an earlier day still counts as currently checked in until they check out.

## Tests

```bash
flutter test
```

The tests cover visit rules, dashboard dates, search and filters, JSON parsing, and a dashboard widget that reads an in-memory list.

## Release APK

```bash
flutter build apk --release
```

The installable file is `build/app/outputs/flutter-apk/app-release.apk`. The release build is signed with the debug key so it can be installed for review. Replace that signing config before any store upload.

Build with the API URL baked in:

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://crudcrud.com/api/your-id
```

## Limitations

- One visit per registration. A completed visit cannot be checked in again, and there is no visit history.
- Search and filters run on the records already loaded. They are not server queries.
- Android only.
- The camera turns off when you leave the Scan tab. Scanning still needs a device with a camera.
- Dark mode, offline cache, and visit history are not included.
- The demo API is a CrudCrud sandbox. It stores records with `_id`, and it accepts PUT rather than PATCH. A fresh sandbox can be empty until visitors are registered.
