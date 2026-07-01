# Flutter E-Ticketing Helpdesk Agent Rules

## Architecture
- Follow feature-based clean architecture.
- Keep presentation, domain, and data layers separated.
- Use BLoC as the existing state-management solution.
- API access must go through datasource, repository, and use case layers.
- Use null-safe Dart 3.x and const constructors where possible.

## Phase Boundary
- Current scope is Phase 4 Ticket Core only.
- Do not implement assignment, status workflow, notifications, dashboard,
  user management, or Phase 5+ functionality.
- History and tracking in Phase 4 are read/display capabilities.
- Status transition workflow remains Phase 5.

## Security
- Never weaken Supabase RLS or replace backend authorization with UI checks.
- User data must remain scoped by authenticated user.
- Cache keys must be namespaced by user ID.
- Clear user-scoped ticket cache and subscriptions during logout.

## Validation
- Run dart format.
- Run targeted ticket tests.
- Run flutter analyze.
- Run full flutter test before declaring completion.
- Do not claim PASS when tests were skipped.

## Completion Report
Always report:
1. Root cause or gap found.
2. Files changed.
3. Tests added.
4. Commands executed and their result.
5. Remaining risks.