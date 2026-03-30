# FYP Supervision Platform — MVP Feature Specification & System Architecture

**Purpose:** Address lost emails, lack of reminders, fragmented communication, and the absence of a unified supervision space by delivering a single place for thread-based communication, documents, and smart alerts.

**Context:** Current supervision relies on email and shared documents. Supervisors want email-style messaging, stronger alerts/reminders, document-in-thread sharing, deadline and stale-conversation alerts, and a minimalist, supervisor-first UI.

---

## System Architecture (High Level)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              CLIENT (Browser)                                 │
│  ERB + Turbo + Stimulus │ Dashboard │ Thread view │ Notifications bell        │
└─────────────────────────────────────────────────────────────────────────────┘
                                        │
                                        ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                           RAILS APPLICATION                                  │
│  Controllers: Dashboard, Messages, Notifications, Projects, Tasks, etc.      │
│  Models: User, Project, Message, Task, Notification, Document, Feedback      │
│  Services: ThreadStatus, NotificationBuilder (optional)                      │
└─────────────────────────────────────────────────────────────────────────────┘
         │                    │                      │
         ▼                    ▼                      ▼
┌──────────────┐    ┌─────────────────┐    ┌──────────────────────────────┐
│  PostgreSQL  │    │  Active Storage │    │  Solid Queue (background jobs) │
│  (SQLite dev)│    │  (attachments)  │    │  • StaleCheckJob (daily)       │
│  users,      │    │  message files  │    │  • DeadlineReminderJob (daily) │
│  projects,   │    │  document blobs │    │  • NoReplyReminderJob (daily)  │
│  messages,   │    │                 │    │  • SendNotificationEmailJob    │
│  tasks,      │    │                 │    └──────────────────────────────┘
│  notifications│   │                 │
└──────────────┘    └─────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  Action Mailer (optional) — reminder / deadline / stale emails               │
└─────────────────────────────────────────────────────────────────────────────┘
```

**Data flow (alerts):** Time → Scheduled Job → Query (messages/tasks) → Create Notification (+ optional email job).  
**Data flow (thread):** User opens project → Load messages (ordered) → Show thread; on reply → Create message, update `last_message_at`, attach files → Notify other party (in-app).

---

## 1. MVP Feature Breakdown

### 1.1 Unified Thread-Based Communication

| Feature | Description | Acceptance criteria |
|--------|-------------|---------------------|
| **Email-style messaging** | Compose and send messages in a familiar inbox/thread layout (subject optional, body + attachments). | User can write multi-line messages and send; layout resembles email (sender, date, body). |
| **One conversation thread per student** | Each project has a single ongoing thread between student and supervisor (no separate “conversations” to choose from). | From project context, user sees one chronological thread; no conversation picker. |
| **Thread status** | Each thread shows status: **awaiting_reply** (other party should respond), **responded** (recent reply from other party), **stale** (no reply after N days). | Status is computed and displayed on dashboard and thread view; configurable N (e.g. 7 days). |
| **Read/unread** | Messages can be marked read when viewed by the recipient. | Unread count per thread and globally; marking as read on view (and optional “mark all read”). |
| **Reply in thread** | Replies append to the same thread in chronological order. | New message in same project thread; order by `created_at`. |

**Gap from current codebase:** Messages are already project-scoped and 1:1 (student ↔ supervisor). Missing: **conversation/thread abstraction** (or keep project = thread), **read_at**, **thread status** (awaiting_reply / responded / stale).

---

### 1.2 Smart Alerts System

| Feature | Description | Acceptance criteria |
|--------|-------------|---------------------|
| **No-reply reminder** | If the expected responder has not replied after X days, send a reminder (in-app and/or email). | Configurable X (e.g. 3–7 days); reminder created and delivered; can target supervisor or student. |
| **Deadline alerts** | Notify about upcoming task deadlines (e.g. 7 days, 1 day, day-of). | Configurable windows; alerts for tasks with `deadline` in window; student primary recipient, supervisor optional. |
| **Stale conversation detection** | Flag threads with no activity for N days and surface on dashboard + optional reminder. | Thread marked stale when last message older than N days; dashboard shows count and list; optional email digest. |
| **Escalation reminders for students** | Remind students of overdue tasks or missing replies. | Student receives reminder for their overdue tasks / unanswered supervisor messages; configurable. |

**In-app delivery:** Notifications table + navbar/bell indicator. **Email delivery:** Optional, via background job (e.g. Solid Queue).

---

### 1.3 Document Integration

| Feature | Description | Acceptance criteria |
|--------|-------------|---------------------|
| **Attach files in thread** | Attach one or more files to a message. | Message can have attachments (Active Storage); display filenames and links in thread. |
| **Version tracking** | Documents (e.g. thesis drafts) have versions; link feedback/context to version if needed. | Existing `documents` + `document_versions` retained; versions visible in UI. |
| **Inline document previews** | Where applicable, show preview (e.g. PDF thumbnail or “Open” link) in thread. | In thread, attachments show preview link or thumbnail for supported types (MVP: link + icon by type). |

**Gap from current codebase:** Documents and versions exist at project level. MVP: add **attachments on messages** (Active Storage `has_many_attached :attachments` on Message); keep project-level documents as separate “Documents” area; optional “attach existing project document” in thread later.

---

### 1.4 Dashboard Overview

| Feature | Description | Acceptance criteria |
|--------|-------------|---------------------|
| **All supervised students** | Supervisor sees list/cards of all supervisees (existing). | Current supervisor dashboard list retained and enhanced. |
| **Deadline status** | Per student/project: next deadline, overdue count. | Show next deadline and overdue task count on each student card; risk indicator. |
| **Unread / stale threads** | Counts and list of threads with unread messages or stale status. | Dashboard shows “Unread (n)”, “Stale (n)”; links to filter or open thread. |
| **Risk indicators** | Missed deadlines, long inactivity, stale thread. | Reuse/refine `supervision_status`; show at-risk badge; optional “Students at risk” section. |

**UI:** Keep minimalist; supervisor sees one place for “who needs attention” (unread, stale, deadlines, risk).

---

### 1.5 Minimalist UI

| Principle | Implementation |
|-----------|----------------|
| Clean layout | Plenty of whitespace; clear hierarchy; no redundant nav. |
| Low cognitive load | One primary action per card/section; status via small badges, not long text. |
| No unnecessary features | No forums, no public feeds; only threads, documents, tasks, alerts. |
| Supervisor-first workflow | Default dashboard = supervisor; student dashboard = my project + my thread + my tasks/deadlines. |

---

### 1.6 Role Structure

| Role | Responsibility | Key screens |
|------|----------------|------------|
| **Student** | Own project; submit drafts; meet deadlines; reply in thread. | Dashboard (project summary, next deadlines, thread), Thread view, Tasks, Documents. |
| **Supervisor** | Monitor all supervisees; reply in thread; give feedback; optional deadline reminders. | Dashboard (all students, unread/stale/risk), Thread per student, Tasks/Documents/Feedback per project. |

Students are primarily responsible for deadline submissions; supervisor guides and monitors.

---

## 2. Database Schema Proposal

Existing tables to **keep** (conceptually): `users`, `projects`, `tasks`, `meetings`, `messages`, `documents`, `document_versions`, `feedbacks`, `active_storage_*`.

### 2.1 New / Modified Tables

**Messages (extend existing)**

- Add `read_at:datetime` (nullable) — set when receiver first views the message.
- Add `parent_id:integer` (nullable) — optional for explicit “reply to” (MVP can keep flat thread by project and omit `parent_id`).
- **Attachments:** use Active Storage: `Message has_many_attached :attachments`.

**Conversation threads (optional abstraction)**

- Option A — **No new table:** treat “project” as the thread. One thread per project; status derived from `messages` and `tasks`. Simpler.
- Option B — **Thread table:** `conversation_threads(id, project_id, status, last_message_at, last_message_by_id, created_at, updated_at)`. Status: `awaiting_supervisor_reply | awaiting_student_reply | responded | stale`. Denormalised for fast dashboard.

**Recommendation for MVP:** Option A. Add to `projects`: `last_message_at`, `last_message_by_id` (optional cache). Compute **thread status** in the app: e.g. `awaiting_reply` if last message was from the other party and no reply since; `stale` if `last_message_at < N.days.ago`.

**Notifications**

```ruby
# create_table :notifications
t.references :user, null: false, index: true
t.string :type, null: false, index: true   # e.g. 'Notification::DeadlineReminder'
t.references :subject, polymorphic: true   # task, message, project
t.string :title, null: false
t.text :body
t.datetime :read_at
t.json :metadata                           # e.g. { deadline: ..., days_until: ... }
t.timestamps
# index on [user_id, read_at] for “unread for user”
```

**Alert configuration (supervisor / system settings)**

```ruby
# create_table :alert_settings (or store in settings table / env)
# Suggested: system-wide first; per-supervisor later
# key-value or columns: stale_threshold_days, no_reply_reminder_days, deadline_alert_days (array or json)
```

MVP can use a single `settings` table or Rails credentials/ENV for global defaults (e.g. `STALE_DAYS=7`, `NO_REPLY_DAYS=3`).

### 2.2 Schema Summary (additions only)

| Table / change | Purpose |
|----------------|--------|
| `messages.read_at` | Read receipts; unread counts. |
| `messages` + Active Storage | Attachments on messages. |
| `projects.last_message_at`, `projects.last_message_by_id` (optional) | Cache for thread order and “last sender”. |
| `notifications` | In-app alerts (deadline, no-reply, stale). |
| `alert_settings` or ENV | Configurable thresholds. |

---

## 3. Notification Logic System Design

### 3.1 Notification Types

| Type | Trigger | Recipient | In-app | Email (optional) |
|------|--------|-----------|--------|-------------------|
| **No-reply reminder** | Last message from A, no reply from B for N days | B | ✓ | ✓ |
| **Deadline upcoming** | Task deadline in window (e.g. 7d, 1d) | Student (primary), Supervisor (optional) | ✓ | ✓ |
| **Stale conversation** | No message in thread for N days | Both (or supervisor only) | ✓ | Digest possible |
| **Overdue task** | Task past deadline, still pending | Student | ✓ | ✓ |

### 3.2 Flow

1. **Events:** Message created, Task created/updated (deadline), time-based (daily job).
2. **Jobs (Solid Queue):**
   - **Daily:** “Check stale threads” (projects with `last_message_at < N.days.ago` → create notifications, maybe send email).
   - **Daily:** “Deadline reminders” (tasks with deadline in next 7 days / 1 day → create notifications).
   - **Daily:** “No-reply reminders” (last message from supervisor with no student reply for N days, and vice versa).
3. **Creation:** Jobs create `Notification` records and optionally enqueue mailer jobs.
4. **Delivery:** In-app = navbar bell + notifications index; email = Action Mailer + background job.

### 3.3 Idempotency and Frequency

- One notification per “event” per user (e.g. one “no-reply” per thread per day until reply).
- Use `metadata` or a key (e.g. `[user_id, type, subject_type, subject_id, date]`) to avoid duplicates.

### 3.4 Configuration

- Global: `STALE_DAYS`, `NO_REPLY_DAYS`, `DEADLINE_ALERT_DAYS`.
- Later: per-supervisor or per-project overrides in `alert_settings`.

---

## 4. UI Structure

### 4.1 Supervisor

- **Dashboard**
  - Stats: total students, at risk, unread threads, stale threads.
  - List of students (cards): name, project, last activity, **thread status** (badge: awaiting reply / responded / stale), **unread count**, next deadline, risk badge.
  - Shortcuts: Unread, Stale, Overdue tasks, Upcoming meetings (existing).
- **Project (student) view**
  - Tabs or sections: Overview, **Thread**, Tasks, Documents, Feedback, Meetings.
  - **Thread:** Single chronological feed; compose at bottom; attachments; unread state.
- **Notifications**
  - Bell icon with count; dropdown or dedicated page; “Mark all read”.

### 4.2 Student

- **Dashboard**
  - My project summary; next deadlines; **thread** preview (last message, unread); tasks progress.
- **Project**
  - Same structure: **Thread** prominent, then Tasks, Documents, etc.
- **Notifications**
  - Same pattern as supervisor.

### 4.3 Thread View (shared)

- Email-style: messages in order; each line shows sender, date, read state (e.g. “Read” or “Unread”); body; attachments (list + link or preview).
- Reply box at bottom (body + attach files).
- Optional: “Mark as read” when scrolling into view (or on open).

### 4.4 Navigation

- Minimal: Dashboard, (current project if in context), Notifications. Avoid clutter; supervisor sees “Dashboard” and “All projects” or per-student entry from dashboard.

---

## 5. Suggested Tech Stack

Aligned with current repo:

| Layer | Choice | Notes |
|-------|--------|--------|
| Backend | **Rails 8** | Already in use. |
| Auth | **Devise** | Keep; roles already (student/supervisor). |
| DB | **SQLite** (dev/test), **PostgreSQL** (prod) | Keep. |
| Jobs | **Solid Queue** | Already present; use for reminder and notification jobs. |
| Real-time | **Solid Cable** (optional) | For live “new message” or “new notification” later. |
| Storage | **Active Storage** | Message attachments; existing document versions. |
| Frontend | **ERB + Turbo + Stimulus** | Keep; minimal JS; server-rendered threads. |
| Email | **Action Mailer** | Optional reminder emails; use Solid Queue for delivery. |

No new heavy dependencies for MVP; add **in-app notifications** (model + controller + UI) and **scheduled jobs** for alerts.

---

## 6. Future Expansion Roadmap

| Phase | Additions |
|-------|-----------|
| **Post-MVP** | Email delivery for all alert types; per-supervisor alert preferences; “attach existing project document” in thread. |
| **V2** | Rich inline document preview (PDF viewer in app); optional SMS for critical reminders; read receipts per message in UI. |
| **V2** | Multiple threads per project (e.g. “Chapter 1 feedback”, “General”) if needed. |
| **V2** | Export thread + attachments; audit log for compliance. |
| **Later** | Mobile-friendly or PWA; push notifications; calendar integration for deadlines/meetings. |

---

## 7. Problem → Solution Mapping

| Problem | MVP solution |
|---------|--------------|
| Lost emails | Single thread per project; all communication in one place; visible on dashboard. |
| Lack of reminders | No-reply, deadline, and stale-conversation alerts (in-app + optional email). |
| Fragmented communication | One thread per student; documents attachable in thread; dashboard shows unread/stale. |
| No unified space | Dashboard + project view combine thread, tasks, documents, feedback, meetings in one app. |

This document can be used as the single source of truth for MVP scope, schema changes, notification design, UI layout, and tech choices. Implementation can proceed in order: schema + thread status → read/unread → notifications (model + jobs) → dashboard enhancements → document attachments in thread.
