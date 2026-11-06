# Puimey

Puimey is a cross-stack project with a Flutter mobile app in `lib/` and a Node/Express backend in `backend/`.

## Project structure

- `lib/` — Flutter frontend/mobile application
- `backend/` — Express API, services, middleware, and SQL migrations
- `.claude/` — Claude Code repo rules and settings
- `.wolf/` — OpenWolf project context, memory, anatomy, and hooks

## Multi-agent workflow

This repo uses a **single-branch multi-agent workflow**.

### Roles
- **Orchestrator** — scopes work, assigns ownership, sequences handoffs
- **Backend agent** — routes, controllers, services, middleware, migrations, API contracts
- **Frontend agent** — Flutter services, models, routes, screens, widgets
- **Security agent** — auth, validation, uploads, secrets, authorization, sensitive data exposure
- **Git/integration agent** — working tree checks, overlap review, staging discipline, commit/PR readiness

### Operating rules
1. Claim file ownership before editing.
2. Parallelize only when agents have disjoint file sets.
3. Backend contract changes happen before Flutter integration when a task spans both layers.
4. Re-check git status before handoff, commit, or PR work.
5. Keep each commit to one coherent vertical slice.
6. Treat `.wolf/` as shared operational context, never as a place for secrets or sensitive payloads.

### Recommended Claude skills
- Orchestrator: `agent-orchestrator`, `parallel-agents`, `concise-planning`
- Backend: `backend-architect`, `nodejs-backend-patterns`, `api-design-principles`, `backend-security-coder`
- Frontend: `frontend-dev-guidelines`, `frontend-mobile-development-component-scaffold`
- Git/integration: `git-pr-workflows-git-workflow`, `code-review-checklist`, `commit`
- Security: `security-review`, `api-security-best-practices`, `backend-security-coder`, `mobile-security-coder`

## Verification

- Backend verification should use the existing scripts in `backend/package.json`.
- Flutter changes should be validated against the real backend contract.
- UI changes should be tested in-app before completion.
- Prefer `rtk`-prefixed shell commands whenever supported.

## Getting started

### Flutter app
- Install Flutter SDK compatible with `pubspec.yaml`
- Run dependencies for the mobile app
- Launch the Flutter app from the repo root
- For Android emulator use `--dart-define=PUIMEY_API_BASE_URL=http://10.0.2.2:3000`
- For local physical-phone debugging, use `--dart-define=PUIMEY_API_BASE_URL=http://<IP-LAN-PC>:3000`
- For physical phones on any network, deploy the API behind a stable HTTPS domain and run:
  `flutter run --dart-define=PUIMEY_API_BASE_URL=https://api.example.com`
- The build-time API URL takes priority over localhost, saved URLs, and LAN discovery, so phones do not depend on the developer PC's IP address.
- The Android debug/profile builds allow cleartext HTTP so the app can reach the local API host

### Backend API
- Install Node.js dependencies in `backend/`
- Configure environment values from `backend/.env.example`
- Use the existing migration scripts before starting the API
