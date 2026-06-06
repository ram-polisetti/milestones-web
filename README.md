# Milestones

Local-first Milestones implementations for the web and iOS. Both versions keep
their data on the device and do not use iCloud.

## Web

```bash
npm install
npm run dev
```

Project data is stored in the browser with `localStorage`. No account or iCloud sync is used.

## iOS

Open the native project:

```bash
open ios/Milestones.xcodeproj
```

Or regenerate and build it from the command line:

```bash
cd ios
ruby generate_project.rb
xcodebuild \
  -project Milestones.xcodeproj \
  -scheme Milestones \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  CODE_SIGNING_ALLOWED=NO \
  build
```

The SwiftUI app currently targets iPhone and includes:

- Projects, project settings, milestones, backlog, and progress.
- Task list and optional Kanban views.
- Task creation, editing, priorities, due dates, tags, and completion.
- Today, Upcoming, and Inbox smart lists.
- Local JSON persistence in the app's Documents directory.
- Tag management, archive/delete actions, and sample-data reset.
