# Architecture Rules

The app uses feature-first clean architecture. Agents should preserve the
existing shape unless a task explicitly asks for a larger migration.

## Layer Order

Within a feature:

1. `domain`: entities, repository contracts, and use cases.
2. `data`: data sources, DTOs, and repository implementations.
3. `presentation`: pages, widgets, events, states, and BLoCs.

Allowed dependencies:

- `domain` may use Dart, Flutter-free utility packages, value equality, and DI
  annotations already present in the project.
- `data` may depend on `domain` and core infrastructure.
- `presentation` may depend on `domain`, BLoC, Flutter widgets, and DI access.
- `core/router/app_router.dart` may import feature pages because it is the
  explicit app composition point.

Disallowed dependencies:

- `domain` must not import `data` or `presentation`.
- `data` must not import `presentation`.
- Feature modules must not reach into another feature's internals.
- Network data must be parsed at the boundary before becoming a domain entity.

## Adding A Feature

For a feature with business logic or external data, create the same three-layer
structure:

```text
lib/features/<feature>/
  domain/
    entities/
    repositories/
    usecase/
  data/
    datasource/
    models/
    repositories/
  presentation/
    bloc/
    pages/
```

Mirror tests under `test/features/<feature>/`.

Presentation-only features may omit `domain` and `data` until behavior requires
them. Do not create empty layers just to satisfy the shape.

## Dependency Injection

- Prefer constructor injection.
- Register concrete implementations with `injectable`.
- Regenerate `lib/core/injection/injection.config.dart` after changing
  injectable annotations.
- Do not create a second service locator.

## Configuration

`AppConfig` owns flavor behavior. Add new environment-derived behavior there and
cover it with tests.

## Agent-Oriented Design

Use boring, inspectable abstractions. When a rule becomes important enough to
repeat in review, encode it as a test, lint, harness command, or short doc.
