# Production Readiness Board

Last updated: 2026-07-04 (post-commit)

## Baseline

| Item | Value |
| --- | --- |
| Branch | `release/2.0.0-production-readiness` |
| HEAD | `ca2a7e0` |
| Current scope | Workstream 0 - stabilize Phase 4 ticket core |
| Initial dirty tree | Present |
| PDR document | Not found in tracked repo files during initial audit |

## Initial Dirty Working Tree

### App source and tests

- `lib/core/router/app_router.dart`
- `lib/features/ticket/data/datasources/ticket_create_exceptions.dart`
- `lib/features/ticket/data/datasources/ticket_local_data_source.dart`
- `lib/features/ticket/data/datasources/ticket_remote_data_source.dart`
- `lib/features/ticket/data/datasources/typed_ticket_remote_data_source.dart`
- `lib/features/ticket/data/models/ticket_attachment_model.dart`
- `lib/features/ticket/data/models/ticket_model.dart`
- `lib/features/ticket/di/ticket_di.dart`
- `lib/features/ticket/domain/entities/ticket_attachment_entity.dart`
- `lib/features/ticket/domain/services/ticket_attachment_viewer.dart`
- `lib/features/ticket/presentation/bloc/list/ticket_list_bloc.dart`
- `lib/features/ticket/presentation/bloc/list/ticket_list_event.dart`
- `lib/features/ticket/presentation/pages/create_ticket_page.dart`
- `lib/features/ticket/presentation/pages/ticket_detail_page.dart`
- `lib/features/ticket/presentation/widgets/ticket_attachments_section.dart`
- `test/core/router/app_router_ticket_routes_test.dart`
- `test/features/ticket/data/datasources/ticket_create_failure_mapper_test.dart`
- `test/features/ticket/data/datasources/ticket_local_data_source_test.dart`
- `test/features/ticket/data/models/ticket_attachment_model_test.dart`
- `test/features/ticket/data/models/ticket_model_test.dart`
- `test/features/ticket/presentation/bloc/list/ticket_list_bloc_test.dart`
- `test/features/ticket/presentation/create_ticket_page_contract_test.dart`
- `test/features/ticket/presentation/navigation/ticket_create_navigation_test.dart`
- `test/features/ticket/presentation/widgets/ticket_attachments_section_test.dart`

### Production sync and handoff docs

- `docs/codex_handoff.md.txt`
- `docs/phase-4-production-backend-sync.md`

### Agent skills and tooling

- `.agents/`
- `AGENT_SKILLS_SETUP.md`
- `skills-lock.json`

### Dependency metadata

- `pubspec.yaml`
- `pubspec.lock`

## Commit Audit

| Commit | Scope | Status | Notes |
| --- | --- | --- | --- |
| `1c04454` | Authenticated realtime lifecycle | PASS | Revalidated by session cleanup, list/detail realtime, and full Flutter test |
| `c1e2e11` | Ticket creation failure handling | PASS | Revalidated locally; no-attachment fallback stays narrowly gated to missing RPC drift |

## Change Classification

| Workstream bucket | Status | Related files | Test related | Manual gate | Remaining risk | Next action |
| --- | --- | --- | --- | --- | --- | --- |
| Ticket create failure handling | PASS | `ticket_create_exceptions.dart`, `ticket_remote_data_source.dart`, `ticket_create_bloc.dart`, related tests | mapper, bloc, repository, create page | No | Atomic attachment path still depends on manual production RPC sync | Keep fallback limited to zero-attachment missing-RPC scenario |
| Authenticated realtime lifecycle | PASS | realtime session service, typed remote data source, list/detail bloc, session cleanup | list/detail bloc, remote datasource, session cleanup | No | Production session lifecycle still needs device/runtime verification later | Preserve existing subscription cleanup guards |
| Navigation create -> detail -> back | PASS | `app_router.dart`, `create_ticket_page.dart`, route tests | router and navigation tests | No | None found locally | Preserve flattened ticket routes and existing route tests |
| Attachment viewer | PASS | attachment viewer datasource/service, detail page, widget tests | attachment widget tests, detail tests | No | Real device file-association behavior still platform-dependent | Defer device smoke validation to release workstream |
| Model/cache compatibility | PASS | ticket models, local datasource, entity helpers | model and local cache tests | No | None found locally | Preserve access URL stripping from user cache |
| Production sync documentation | PASS | `docs/phase-4-production-backend-sync.md` | N/A | Human production approval required for actual sync | Production remains blocked until manual Supabase verification on device | Keep as docs-only handoff |
| Agent Skills/tooling | TODO | `.agents/`, `AGENT_SKILLS_SETUP.md`, `skills-lock.json` | N/A | No | Must stay isolated from app source and commit scope | Exclude from source stabilization decisions |

## Workstreams

| Workstream | Status | Notes |
| --- | --- | --- |
| 0. Save current source state | PASS | App-source stabilization committed locally and release branch created |
| 1. Brand and design system | TODO | Not started |
| 2. Splash and app branding | TODO | Not started |
| 3. Frontend modernization | TODO | Deferred until Workstream 0 stable |
| 4. Ticket workflow and admin | BLOCKED | Outside AGENTS Phase 4 boundary for current branch |
| 5. Supabase and database | TODO | Read-only/local audit allowed; no production mutation |
| 6. Notification and observability | BLOCKED | Outside AGENTS Phase 4 boundary for current branch |
| 7. Security and privacy | TODO | Documentation and local hardening later |
| 8. Android release hardening | TODO | Later workstream |
| 9. Quality gate | TODO | Runs after each task bundle |
| 10. Play Store package | TODO | Later workstream |

## Current Focus

- Keep `.agents/`, `AGENT_SKILLS_SETUP.md`, `skills-lock.json`, and `docs/codex_handoff.md.txt` outside app-source scope.
- Start Workstream 1 on the release branch.
- Leave production Supabase sync as manual gate.

## Validation Log

| Command | Result |
| --- | --- |
| `dart format --output=none --set-exit-if-changed lib test` | PASS |
| `flutter analyze --no-pub` | PASS |
| `flutter test --no-pub --concurrency=1` | PASS |
| `git diff --check` | PASS for whitespace/conflict markers; Git emitted LF->CRLF warnings only |

## Local Fixes Completed

- Added production-readiness board as SSOT.
- Revalidated current Phase 4 tree against full local test gate.
- Normalized source corruption in `pubspec.yaml`, `ticket_remote_data_source.dart`, `create_ticket_page.dart`, and `ticket_detail_page.dart`.
- Preserved `.agents` and `skills-lock.json` outside app-source decision scope.
- Created local commit `ca2a7e0` and switched to `release/2.0.0-production-readiness`.

## Remaining Dirty Tree

- `?? .agents/`
- `?? AGENT_SKILLS_SETUP.md`
- `?? docs/codex_handoff.md.txt`
- `?? skills-lock.json`

These files are intentionally left outside the application-source stabilization commit.
