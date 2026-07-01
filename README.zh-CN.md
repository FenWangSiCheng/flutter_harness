# Flutter Harness 项目

[English](README.md)

这是一个用于展示 repository-local AI coding harness 的 Flutter 示例项目。应用本身保持轻量，重点在它外层的工程框架：指令、持久状态、可重复验证、架构守卫、功能规格、验收证据、运行时信号、CI，以及项目内置的 agent skills。

这个 harness 的目标，是把 Flutter 代码库变成一个 agent 可以稳定进入、理解、验证、修改和交接的工作空间。它适合作为 Flutter 项目接入 AI coding agent 的模板，而不是依赖一次性的 prompt 记忆或对话上下文。

## Harness 框架目标

- 把仓库内的文档、脚本、状态和证据作为系统事实来源。
- 为每一次 agent session 提供标准启动路径。
- 显式记录功能范围、状态、依赖、阻塞和验收证据。
- 用结构测试守住 Flutter clean architecture 分层边界。
- 区分非 UI 逻辑验证和设备驱动的 UI 验收。
- 要求用户可见功能在完成前留下可提交的验收报告。
- 保留 session 状态，让工作可以跨 agent、跨时间继续推进。
- 把重复出现的问题沉淀到文档、测试、工具或状态文件里。

## 从这里开始

| 文件 | 作用 |
| --- | --- |
| [`AGENTS.md`](AGENTS.md) | agent 启动流程、范围规则、验证命令和 Definition of Done。 |
| [`docs/harness/README.md`](docs/harness/README.md) | harness 子系统地图和仓库结构概览。 |
| [`feature_list.json`](feature_list.json) | 功能状态、依赖、规格和证据。 |
| [`progress.md`](progress.md) | 当前 session 状态、决策、风险、改动文件和验证记录。 |
| [`session-handoff.md`](session-handoff.md) | 给下一次 session 的恢复说明。 |
| [`docs/harness/VALIDATION.md`](docs/harness/VALIDATION.md) | 本地命令参考和失败排查顺序。 |

建立新 baseline 时运行：

```bash
./init.sh
```

`init.sh` 会先解析 Flutter 依赖，再执行 bootstrap，最后运行完整 harness check。需要证明仓库可以从标准生命周期入口重新启动时，优先使用这个命令。

## Harness 提供什么

### 持久指令

根目录指令保持简短，只负责把 agent 路由到更具体的本地规则：

- [`AGENTS.md`](AGENTS.md) 是 agent 入口地图。
- [`docs/harness/ARCHITECTURE.md`](docs/harness/ARCHITECTURE.md) 定义架构分层规则。
- [`docs/harness/TASKS.md`](docs/harness/TASKS.md) 定义较大任务的计划和交接方式。
- [`docs/harness/SKILLS.md`](docs/harness/SKILLS.md) 记录项目内置 Flutter / Dart agent skills。

### 功能状态

功能范围和完成证据记录在 [`feature_list.json`](feature_list.json)。当前 session 的连续性记录在 [`progress.md`](progress.md)，重启和交接说明记录在 [`session-handoff.md`](session-handoff.md)。

默认工作方式是一次只处理一个功能。只有当行为实现、文档和状态更新、验证结果、双平台 Maestro 证据，以及已提交的报告都齐备时，才可以把功能标记为完成。

### 验证入口

[`tool/harness.dart`](tool/harness.dart) 是本地验证和诊断的稳定入口：

```bash
# 查看工具、生成文件、文档和 skills 状态
fvm dart run tool/harness.dart doctor

# 运行结构守卫测试
fvm dart run tool/harness.dart structure

# 解析依赖并重新生成需要提交的 generated files
fvm dart run tool/harness.dart bootstrap

# 运行 format、structure、analyzer 和 coverage-gated tests
fvm dart run tool/harness.dart check

# 在不重新跑测试的情况下复查已有 coverage report
fvm dart run tool/harness.dart coverage --check-only
```

默认完整检查包含：

1. `fvm dart format --set-exit-if-changed lib test tool`
2. `fvm dart run tool/harness.dart structure`
3. `fvm flutter analyze`
4. `fvm dart run tool/harness.dart coverage`

### 结构守卫

[`test/harness/architecture_guard_test.dart`](test/harness/architecture_guard_test.dart) 负责保护 harness 的关键假设，包括：

- 必需的根目录生命周期文件。
- 功能状态和已提交验收证据是否匹配。
- Flutter clean architecture import 边界。
- UI 测试策略。
- 生成的 canonical UI map 是否最新。
- 本地 skills 是否存在并已记录。
- 标准检查和 Maestro 验收的 CI 配置。

### 覆盖率门禁

`tool/harness.dart coverage` 会用 coverage 运行 Flutter 测试，并对非 UI 逻辑执行默认 90% 行覆盖率门禁。

```bash
fvm dart run tool/harness.dart coverage
```

这个门禁会排除由 Maestro 负责验收的 UI shell 文件、generated files、router/widgets/resources 和 `main.dart`，让 Flutter tests 专注于 logic、data、BLoC、networking、configuration 和 harness 规则。

### Specs、UI Map 和 Maestro

面向人阅读的规格文件放在 [`docs/harness/specs/`](docs/harness/specs/)。每个 UI spec 可以通过自己的 `ui-map.delta.yaml` 增加 UI target；共享的 canonical UI map 会生成到 [`docs/harness/specs/ui-map.yaml`](docs/harness/specs/ui-map.yaml)：

```bash
fvm dart run tool/harness.dart spec ui-map
fvm dart run tool/harness.dart spec ui-map --check
```

用户可见 UI 行为由 Maestro 验收，不用 Flutter widget tests 代替。功能标记完成前，需要运行：

```bash
fvm dart run tool/harness.dart spec accept <spec-id> --maestro --platform all
```

双平台验收会写出：

- `report-ios.json`
- `report-android.json`
- `report.json`

将这些报告从 `build/harness/evidence/<spec-id>/` 复制到 `docs/harness/evidence/<spec-id>/`，再更新 `feature_list.json`。如果 iOS 或 Android 任一平台不可用，应记录为 `BLOCKED`，不要标记为完成。

### CI

仓库包含两个面向 harness 的 GitHub Actions workflow：

- [`.github/workflows/harness.yml`](.github/workflows/harness.yml) 运行 `./init.sh`。
- [`.github/workflows/maestro.yml`](.github/workflows/maestro.yml) 启动 hosted iOS simulator 和 Android emulator，并对所有 `done` spec 执行 Maestro 验收。

Maestro workflow 会在模拟器中安装并运行 dev app。它不会产出 IPA、APK 或 AAB 发布产物，也不需要签名证书。

### 运行时信号

app 侧的 harness logging 位于 [`lib/core/harness/`](lib/core/harness/)。它会输出可搜索的 `[harness]` JSON 风格 debug events，让 agent 可以从日志中检查启动和网络行为。事件目录和排查方式见 [`docs/harness/OPERABILITY.md`](docs/harness/OPERABILITY.md)。

## Flutter 应用结构

示例 app 使用 feature-first clean architecture：

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
    widgets/
```

请求流：

```text
UI -> Event -> BLoC -> UseCase -> Repository -> DataSource -> API/mock data
```

响应流：

```text
API/mock data -> Model -> Entity -> UseCase -> BLoC -> State -> UI
```

当前技术栈：

- Flutter SDK `3.44.0`，通过 FVM 管理。
- Dart SDK `>=3.9.2 <4.0.0`。
- flavors：`dev`、`stg`、`prod`。
- 状态管理：`flutter_bloc`。
- 路由：`go_router`。
- 网络：Dio，支持 mock API。
- 依赖注入：`get_it` 和 `injectable`。
- generated Dart files 已提交到仓库，修改 annotations 后需要保持同步。

## 运行应用

```bash
# Development flavor，使用本地 mock API
fvm flutter run --flavor dev --dart-define-from-file=dart_defines/dev.json

# Staging flavor
fvm flutter run --flavor stg --dart-define-from-file=dart_defines/stg.json

# Production flavor
fvm flutter run --flavor prod --dart-define-from-file=dart_defines/prod.json
```

## 构建

```bash
# Development APK
fvm flutter build apk --flavor dev --dart-define-from-file=dart_defines/dev.json

# Staging APK
fvm flutter build apk --flavor stg --dart-define-from-file=dart_defines/stg.json

# Production APK
fvm flutter build apk --flavor prod --dart-define-from-file=dart_defines/prod.json

# Production iOS
fvm flutter build ios --flavor prod --dart-define-from-file=dart_defines/prod.json
```

## Harness 参考资料

- [OpenAI harness engineering field report](https://openai.com/index/harness-engineering/)
- [walkinglabs learn-harness-engineering](https://github.com/walkinglabs/learn-harness-engineering)
- [walkinglabs awesome-harness-engineering](https://github.com/walkinglabs/awesome-harness-engineering)

## License

Licensed under the Apache License, Version 2.0. See [`LICENSE`](LICENSE) for the full license text.
