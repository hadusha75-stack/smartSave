# SaveSmart — Project Documentation for Graduation Report

This file contains all the documentation you need for your thesis defense:
use case descriptions, UML diagrams (PlantUML source), and sequence diagrams.

---

## 1. Use Case Descriptions

### UC-1: Register Account

| Field | Value |
|---|---|
| **Actor** | User |
| **Precondition** | User has not registered before |
| **Main flow** | 1. User opens app → Onboarding → Login screen. 2. User taps "Create Account". 3. User enters name, email, password, confirm password. 4. System validates fields. 5. System creates Firebase Auth account. 6. System creates Firestore user document with role=user, status=active. 7. System logs in the user and navigates to Home. |
| **Alternative flows** | A1: Email already exists → System shows "account already exists" error. A2: Password < 6 chars → validator shows "at least 6 characters". |
| **Postcondition** | User is logged in and on Home screen |

### UC-2: Log In

| Field | Value |
|---|---|
| **Actor** | User |
| **Precondition** | User has a registered account |
| **Main flow** | 1. User enters email and password. 2. System validates format. 3. System calls Firebase Auth signIn. 4. System loads Firestore user document. 5. System checks status != suspended. 6. System navigates to Home. |
| **Alternative flows** | A1: Wrong password → "Invalid email or password". A2: Account suspended → "Your account has been suspended". |
| **Postcondition** | User is on Home screen with goals loaded |

### UC-3: Create Savings Goal

| Field | Value |
|---|---|
| **Actor** | User |
| **Precondition** | User is logged in |
| **Main flow** | 1. User taps "New Goal" FAB. 2. User enters title, selects category, enters target amount, picks deadline, optionally picks color. 3. User taps "Create Goal". 4. System validates all fields. 5. System writes goal document to Firestore with status=active, streak=0. 6. System pops back to Home. 7. Goal appears in the list. |
| **Postcondition** | Goal is visible on Home screen and its detail screen is accessible |

### UC-4: Record Saving

| Field | Value |
|---|---|
| **Actor** | User |
| **Precondition** | User has at least one active goal |
| **Main flow** | 1. User opens a goal. 2. User taps "Record Saving" FAB. 3. User enters amount, selects date, selects "Saved In" (Bank/Wallet/Cash/Group/Other), optional note. 4. User taps "Record Saving". 5. System opens a Firestore transaction. 6. Transaction reads the goal, calculates new currentAmount, checks if streak is met, computes milestones, checks if goal is complete. 7. Transaction writes the transaction document and updates the goal atomically. 8. System pops back to Goal Detail. 9. Progress bar, plan, and milestones update in real time via stream. |
| **Alternative flows** | A1: currentAmount >= targetAmount → Goal status changes to "completed", milestone 100 unlocked. |
| **Postcondition** | Goal's currentAmount, streak, milestones, and status are updated |

### UC-5: Set Reminder

| Field | Value |
|---|---|
| **Actor** | User |
| **Precondition** | User has at least one goal |
| **Main flow** | 1. User opens goal detail → menu → Reminders. 2. User taps "Add Reminder". 3. User selects frequency (daily/weekly/monthly), picks time (and weekday or day-of-month if applicable). 4. User taps "Save Reminder". 5. System writes reminder document to Firestore. 6. System calls flutter_local_notifications.zonedSchedule with the appropriate repeat pattern. 7. Reminder appears in the list with active switch ON. |
| **Postcondition** | Local notification is scheduled and will fire at the configured time |

### UC-6: View Progress

| Field | Value |
|---|---|
| **Actor** | User |
| **Precondition** | User has a goal with at least one saving |
| **Main flow** | 1. User opens goal detail → taps "View Charts & Badges". 2. System loads the goal and its transactions. 3. System renders: stats strip (saved/remaining/days left), streak card, line chart of cumulative savings, milestone badges, pie chart of savings by location. |
| **Postcondition** | User sees full progress visualization |

### UC-7: Send Feedback

| Field | Value |
|---|---|
| **Actor** | User |
| **Precondition** | User is logged in |
| **Main flow** | 1. User goes to Settings → Send Feedback. 2. User writes a message. 3. System validates message ≥ 10 chars. 4. System writes to feedback collection with status=open. 5. System shows success and pops back. |
| **Postcondition** | Feedback is visible in the admin dashboard feedback inbox |

### UC-8: Admin — Manage Users

| Field | Value |
|---|---|
| **Actor** | Administrator |
| **Precondition** | Admin is logged into the web dashboard |
| **Main flow** | 1. Admin navigates to Users. 2. System streams all user documents. 3. Admin can search by name, suspend/unsuspend, or delete. 4. System updates the Firestore document. |
| **Constraint** | Admin cannot see individual user transactions. Admin accounts cannot be suspended or deleted from the UI. |
| **Postcondition** | User status is updated in Firestore |

### UC-9: Admin — Post Tip

| Field | Value |
|---|---|
| **Actor** | Administrator |
| **Precondition** | Admin is logged in |
| **Main flow** | 1. Admin navigates to Tips. 2. Admin taps "New Tip". 3. Admin enters tip message. 4. System writes to tips collection. 5. Tip appears on all users' home screens via latestTip stream. |
| **Postcondition** | Tip is live in the mobile app |

### UC-10: Admin — Send System Notification

| Field | Value |
|---|---|
| **Actor** | Administrator |
| **Precondition** | Admin is logged in; Cloud Function is deployed |
| **Main flow** | 1. Admin navigates to Notifications. 2. Admin enters title and body. 3. System writes to system_notifications collection. 4. A Cloud Function triggers, reads all user FCM tokens, and sends the push via FCM Admin SDK. |
| **Postcondition** | All users with the app receive a push notification |

---

## 2. Use Case Diagram (PlantUML)

```plantuml
@startuml
left to right direction
skinparam packageStyle rectangle

actor "User" as U
actor "Administrator" as A
actor "Notification\nService" as N

rectangle "SaveSmart" {
  U --> (Register)
  U --> (Log In)
  U --> (Create Goal)
  U --> (Edit Goal)
  U --> (Record Saving)
  U --> (Edit Saving)
  U --> (Delete Saving)
  U --> (Set Reminder)
  U --> (View Progress)
  U --> (View History)
  U --> (Send Feedback)
  U --> (Change Settings)

  A --> (Manage Users)
  A --> (Post Tip)
  A --> (Reply to Feedback)
  A --> (Send Notification)
  A --> (Manage Categories)

  N --> (Send Reminder)
  N --> (Send Milestone Notification)
  N --> (Send System Notification)
}

U ..> N : receives notifications
A ..> N : triggers via Firestore
@enduml
```

---

## 3. Class Diagram (PlantUML)

```plantuml
@startuml
skinparam classAttributeIconSize 0

class AppUser {
  +uid: String
  +name: String
  +email: String
  +currency: String
  +language: String
  +role: String
  +status: String
  +createdAt: DateTime
  +fcmToken: String
  +isAdmin: bool
  +isActive: bool
  +fromFirestore()
  +toFirestore()
}

class Goal {
  +id: String
  +userId: String
  +title: String
  +category: String
  +targetAmount: double
  +currentAmount: double
  +deadline: DateTime
  +status: String
  +streak: int
  +achievedMilestones: List<int>
  +progressFraction: double
  +progressPercent: double
  +fromFirestore()
  +toFirestore()
}

class SavingTransaction {
  +id: String
  +goalId: String
  +amount: double
  +date: DateTime
  +note: String
  +savedIn: String
  +fromFirestore()
  +toFirestore()
}

class Reminder {
  +id: String
  +goalId: String
  +frequency: String
  +weekday: int
  +dayOfMonth: int
  +hourOfDay: int
  +minute: int
  +active: bool
}

class Tip {
  +id: String
  +message: String
  +createdAt: DateTime
  +createdBy: String
}

class UserFeedback {
  +id: String
  +userId: String
  +message: String
  +status: String
  +reply: String
  +createdAt: DateTime
}

class SavingsCalculator {
  +requiredPerPeriod()
  +expectedSavedByToday()
  +behindAmount()
  +progressPercent()
  +projectedCompletionDate()
  +crossedMilestones()
  +metPlanThisPeriod()
}

class GoalRepository {
  +watchGoals()
  +watchGoal()
  +createGoal()
  +updateGoal()
  +deleteGoal()
  +archiveGoal()
}

class TransactionRepository {
  +watchTransactions()
  +addTransaction()
  +editTransaction()
  +deleteTransaction()
}

class AuthRepository {
  +register()
  +login()
  +logout()
  +sendPasswordReset()
  +updateProfile()
}

AppUser "1" --> "0..*" Goal : owns
Goal "1" --> "0..*" SavingTransaction : has
Goal "1" --> "0..*" Reminder : has
AppUser "1" --> "0..*" UserFeedback : submits
SavingsCalculator ..> Goal : calculates
SavingsCalculator ..> SavingTransaction : uses
TransactionRepository --> Goal : updates
TransactionRepository --> SavingTransaction : manages
GoalRepository --> Goal : manages
AuthRepository --> AppUser : authenticates
@enduml
```

---

## 4. ER Diagram (PlantUML)

```plantuml
@startuml
entity "users" as users {
  *uid : String <<PK>>
  --
  name : String
  email : String
  currency : String
  language : String
  role : String
  status : String
  createdAt : Timestamp
  fcmToken : String
}

entity "goals" as goals {
  *goalId : String <<PK>>
  --
  userId : String <<FK>>
  title : String
  category : String
  targetAmount : double
  currentAmount : double
  deadline : Timestamp
  status : String
  streak : int
  lastSavedAt : Timestamp
  achievedMilestones : array
}

entity "transactions" as tx {
  *txId : String <<PK>>
  --
  goalId : String <<FK>>
  amount : double
  date : Timestamp
  note : String
  savedIn : String
  createdAt : Timestamp
}

entity "reminders" as reminders {
  *reminderId : String <<PK>>
  --
  goalId : String <<FK>>
  frequency : String
  weekday : int
  dayOfMonth : int
  hourOfDay : int
  minute : int
  active : bool
}

entity "tips" as tips {
  *tipId : String <<PK>>
  --
  message : String
  createdAt : Timestamp
  createdBy : String <<FK>>
}

entity "feedback" as feedback {
  *id : String <<PK>>
  --
  userId : String <<FK>>
  message : String
  status : String
  reply : String
  createdAt : Timestamp
}

entity "categories" as categories {
  *id : String <<PK>>
  --
  name : String
}

entity "system_notifications" as notif {
  *id : String <<PK>>
  --
  title : String
  body : String
  sentBy : String <<FK>>
  sentAt : Timestamp
  processed : bool
}

users ||--o{ goals
goals ||--o{ tx
goals ||--o{ reminders
users ||--o{ feedback
users ||--o{ tips : "creates"
users ||--o{ notif : "sends (admin)"
@enduml
```

---

## 5. Sequence Diagram: Add Saving

```plantuml
@startuml
actor User
participant "Add Saving\nScreen" as Screen
participant "Transaction\nRepository" as Repo
participant "Firestore\nTransaction" as FSTx
database "Firestore" as DB

User -> Screen: Enter amount, date, savedIn, note
User -> Screen: Tap "Record Saving"
Screen -> Screen: Validate form fields
alt Invalid
  Screen -> User: Show validation error
else Valid
  Screen -> Repo: addTransaction(goalId, amount, date, savedIn, note)
  Repo -> FSTx: runTransaction()
  FSTx -> DB: Read goal document
  DB -> FSTx: Return goal (currentAmount, target, streak)
  FSTx -> DB: Read recent transactions
  DB -> FSTx: Return transactions list
  FSTx -> FSTx: Calculate newCurrentAmount
  FSTx -> FSTx: Check metPlanThisPeriod (streak)
  FSTx -> FSTx: Calculate crossedMilestones
  FSTx -> FSTx: Check if newCurrent >= target (complete)
  FSTx -> DB: Write transaction document
  FSTx -> DB: Update goal (currentAmount, streak, milestones, status)
  FSTx -> Repo: Transaction committed
  Repo -> Screen: Return success
  Screen -> User: Show "Saving recorded!" snackbar
  Screen -> User: Pop back to Goal Detail

  note over DB
    Firestore streams automatically
    push updates to all screens
    watching the goal document
  end note
end
@enduml
```

---

## 6. Sequence Diagram: Send Reminder

```plantuml
@startuml
actor User
participant "Reminders\nScreen" as Screen
participant "Reminder\nRepository" as Repo
participant "Notification\nService" as NotifSvc
participant "Local Notifications\nPlugin" as Plugin
database "Firestore" as DB

User -> Screen: Open Reminders for a goal
Screen -> DB: watchReminders(goalId)
DB -> Screen: Stream of existing reminders

User -> Screen: Tap "Add Reminder"
User -> Screen: Select frequency, time
User -> Screen: Tap "Save Reminder"
Screen -> Repo: createReminder(goalId, frequency, hour, minute)
Repo -> DB: Write reminder document (active=true)
DB -> Repo: Write confirmed
Repo -> NotifSvc: scheduleDailyReminder(notifId, title, body, hour, minute)
alt frequency == daily
  NotifSvc -> Plugin: zonedSchedule(matchDateTimeComponents: time)
else frequency == weekly
  NotifSvc -> Plugin: zonedSchedule(matchDateTimeComponents: dayOfWeekAndTime)
else frequency == monthly
  NotifSvc -> Plugin: zonedSchedule(matchDateTimeComponents: dayOfMonthAndTime)
end
Plugin -> NotifSvc: Scheduled successfully
NotifSvc -> Repo: Return
Repo -> Screen: Return reminder id
Screen -> User: Show "Reminder saved!" snackbar

note over Plugin
  At the scheduled time,
  the OS fires the notification
  even if the app is closed.
  The user sees a notification banner
  with the goal name and plan amount.
end note
@enduml
```

---

## 7. Data Flow Summary

```
User Action          → UI Screen → Riverpod Provider → Repository → Firestore
                     ↑                                                ↓
  Auto-update (stream) ← Riverpod Provider ← Firestore snapshots ←───┘
```

All screens use `ref.watch(...)` on stream providers. When Firestore data changes (locally or from the cloud), the stream emits a new value, Riverpod notifies the widget, and the UI rebuilds. No manual refresh is ever needed.

---

## 8. Security Model Summary

| Collection | Who can read | Who can write |
|---|---|---|
| users/{uid} | Owner + Admin | Owner (no role/status change), Admin (any field) |
| users/{uid}/goals | Owner | Owner (if active) |
| goals/transactions | Owner | Owner (if active) |
| goals/reminders | Owner | Owner (if active) |
| tips | Any active user | Admin only |
| categories | Any active user | Admin only |
| feedback | Owner + Admin | Owner creates, Admin updates |
| system_notifications | No one (Cloud Function) | Admin only |

Suspended users are blocked at the rules layer: `isActive()` returns false, so all reads and writes fail for that user.
