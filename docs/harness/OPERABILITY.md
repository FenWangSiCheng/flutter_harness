# Operability

The harness exposes lightweight runtime events through `HarnessLogger`. In debug
builds these events are printed with a `[harness]` prefix and JSON payloads.

## Event Shape

```json
{
  "timestamp": "2026-06-18T00:00:00.000Z",
  "name": "app.bootstrap.ready",
  "fields": {
    "flavor": "dev",
    "mock_api_data_source": true,
    "elapsed_ms": 120
  }
}
```

## Current Events

| Event | Meaning |
| --- | --- |
| `app.bootstrap.start` | Flutter bindings are initialized and boot is beginning. |
| `app.config.loaded` | `AppConfig` has been derived from dart defines. |
| `app.dependencies.ready` | Dependency injection completed. |
| `app.bootstrap.ready` | App is about to render. |
| `dio.initialize.start` | Dio initialization started. |
| `dio.mock_adapter.ready` | Mock API adapter is configured. |
| `dio.http_adapter.ready` | Real HTTP adapter is configured. |
| `dio.initialize.ready` | Dio initialization finished. |
| `flow.user_profile.loading` | User profile flow entered a loading state. |
| `flow.user_profile.user_loaded` | User profile data loaded for a mock user. |
| `flow.user_profile.switch_user.requested` | A user-switch action was requested from the UI. |
| `flow.user_profile.error` | User profile flow entered an error state. |
| `flow.user_profile.succeeded` | User profile flow reached a successful loaded state. |
| `flow.user_profile.failed` | User profile flow reached a failed state. |
| `flow.home_todolist.initial` | Home todo list page initialized. |
| `flow.home_todolist.add_empty_ignored` | Empty todo submission was ignored. |
| `flow.home_todolist.task_added` | A todo item was added from the Home tab. |
| `flow.home_todolist.task_completed` | A todo item was marked complete. |
| `flow.home_todolist.task_reopened` | A completed todo item was reopened. |
| `flow.home_todolist.task_deleted` | A todo item was deleted. |
| `flow.home_todolist.succeeded` | Home todo flow reached a successful interaction point. |

## Agent Usage

When debugging runtime issues, launch the app in `dev` and search logs for
`[harness]`. The fields are deliberately stable so an agent can compare before
and after behavior without needing screenshots for every check. Acceptance
reports include the stable event names from `docs/harness/policy.yaml` so a
reviewer knows which runtime signals to inspect when a Maestro flow fails.
