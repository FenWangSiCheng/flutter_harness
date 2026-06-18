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

## Agent Usage

When debugging runtime issues, launch the app in `dev` and search logs for
`[harness]`. The fields are deliberately stable so an agent can compare before
and after behavior without needing screenshots for every check.
