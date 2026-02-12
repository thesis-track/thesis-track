# ThesisTrack

A web-based Final Year Project Supervision Platform built with **Ruby on Rails** and **PostgreSQL**.

## Features

- **Role-based authentication**: Student and Supervisor
- **Messaging**: Project-scoped conversation between student and supervisor with search
- **Task management**: Tasks with deadlines, status (pending/completed), overdue highlighting, progress %
- **Meeting scheduling**: Upcoming and past meetings per project
- **Document upload & versioning**: Active Storage; version history; feedback linkable to a document version
- **Structured feedback**: Section, comments, implementation status (pending/implemented), optional link to document version

## Requirements

- Ruby (see `.ruby-version`)
- **Development/test**: SQLite (no server; file-based)
- **Production**: PostgreSQL
- Bundler

## Setup

1. **Install dependencies**

   ```bash
   bundle install
   ```

2. **Database**

   Development and test use SQLite (no install or server needed). Create and migrate:

   ```bash
   bin/rails db:create
   bin/rails db:migrate
   ```

   For production, set `THESIS_TRACK_DATABASE_PASSWORD` and use PostgreSQL.

3. **Seed development data (optional)**

   Creates a supervisor and a student with a project (both password: `password`):

   ```bash
   bin/rails db:seed
   ```

   Log in at `/users/sign_in` as:
   - **Supervisor**: `supervisor@example.com` / `password`
   - **Student**: `student@example.com` / `password`

4. **Sign up (role-based)**

   New users register at `/users/sign_up`. They choose **Student** or **Supervisor** and fill in:
   - All: first name, last name, university email, password.
   - Students: supervisor email (must match an existing supervisor), optional student ID, degree programme.
   - Supervisors: department, optional staff ID.

5. **Run the app**

   ```bash
   bin/rails server
   ```

   Open [http://localhost:3000](http://localhost:3000). You will be redirected to the login page if not signed in.

## Architecture

- **MVC**: Controllers and views per resource; models with associations and validations.
- **REST**: Projects, tasks, meetings, messages, documents, feedback use RESTful routes (nested where appropriate).
- **Authorization**: `Authenticatable` and `Authorizable` concerns; students see only their project; supervisors see all assigned students and projects.
- **Dashboards**: Role-specific (student: progress, tasks, meetings, messages, feedback; supervisor: supervisees, project status, pending feedback, upcoming meetings).

## Database schema (summary)

| Model            | Key associations / notes                                      |
|------------------|---------------------------------------------------------------|
| User             | role (student/supervisor), supervisor_id (students), has_secure_password |
| Project          | belongs_to student; has_many tasks, meetings, messages, documents, feedbacks |
| Task             | project, deadline, status (pending/completed)                 |
| Meeting          | project, scheduled_at                                         |
| Message          | project, sender, receiver, body                              |
| Document         | project; has_many document_versions                           |
| DocumentVersion  | document, version_number, has_one_attached :file              |
| Feedback         | project, optional document_version, section_name, comments, implementation_status |

## License

Private / educational use as required.
