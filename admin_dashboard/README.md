# SaveSmart Admin Dashboard

A Flutter Web app for administrators to manage users, tips, feedback, categories, and send system-wide notifications.

## Prerequisites

Same as the main app: Flutter 3.24+, Dart 3.5+, Firebase project.

## Setup

```bash
cd admin_dashboard
flutter pub get
```

### Firebase configuration

The admin dashboard uses the same Firebase project as the mobile app, but needs its own web app configuration:

1. In the Firebase console, add a **Web app** (</> icon) to your project
2. Register it as "SaveSmart Admin"
3. Run `flutterfire configure` inside the `admin_dashboard/` folder:

```bash
flutterfire configure --project=YOUR_PROJECT_ID
```

This generates `lib/firebase_options.dart` with web-specific config.

### Create an admin account

1. Register a normal user in the mobile app
2. In the Firebase console → Firestore → `users/{uid}` document
3. Change the `role` field from `user` to `admin`

The admin dashboard login checks the `role` field in Firestore. If it is not `admin`, login is rejected.

## Running

```bash
cd admin_dashboard
flutter run -d chrome
```

The dashboard opens at `http://localhost:8080`. Log in with an admin account.

## Features

| Screen | Capabilities |
|---|---|
| Dashboard | Total users, active goals, completed goals, open feedback, most popular categories bar chart |
| Users | Search by name, suspend/unsuspend, delete (admin accounts are protected) |
| Tips | Create, edit, delete saving tips |
| Notifications | Send a system-wide push notification (writes to Firestore; a Cloud Function fans it out via FCM) |
| Feedback | Read all user feedback, reply, mark resolved |
| Categories | Add and delete goal categories |

## Security

- The admin login verifies the `role` field in Firestore is `admin`
- Firestore security rules enforce that only admins can read the full users list
- The dashboard never shows individual user transactions — only aggregate counts
- The dashboard never shows individual user transactions — only aggregate counts
- Admin accounts cannot be suspended or deleted from the dashboard UI
- System notification writes are admin-only in the rules

## Architecture

```
admin_dashboard/
├── lib/
│   ├── core/
│   │   ├── theme/          AdminTheme (deep blue seed)
│   │   └── widgets/        Shared widgets
│   ├── features/
│   │   ├── auth/            Admin login (role-checked)
│   │   ├── dashboard/      Stats overview
│   │   ├── users/           User management
│   │   ├── tips/            Tips CRUD
│   │   ├── feedback/        Feedback inbox
│   │   ├── notifications/   System-wide push
│   │   └── categories/     Category management
│   ├── routing/            go_router with auth redirect
│   ├── services/           AdminFirestoreService + providers
│   ├── firebase_options.dart
│   └── main.dart
├── pubspec.yaml
└── web/
    └── index.html
```

## Responsive design

- **Wide screens** (≥720px): left side-navigation panel with all items visible
- **Narrow screens** (<720px): bottom NavigationBar with icons
