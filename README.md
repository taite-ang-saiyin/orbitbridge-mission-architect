# OrbitBridge – Mission Architect

Godot 4 clickable desktop UI prototype. Mission workflow UI is English; Home and Settings also support Simplified Chinese. No network, simulator, backend, evaluator, or external asset dependency is used.

## 运行

使用 Godot 4（已在 4.7.2 验证）导入本目录的 `project.godot`，按 **F6** 运行 Main 或 **F5** 运行项目。入口为 `scenes/Main.tscn`，默认进入新 Home 标题页；Start Mission 进入 Mission Control 过渡页。

默认全屏启动并适配当前显示器。按 F11 切换全屏与可调整桌面窗口；窗口模式使用 1440×900，并自动适配屏幕可用区域。保留 1280×720 与 1024×768 布局支持。页面内容可纵向滚动，Back / Continue 在独立底部区域。任务流程顶部六个导航按钮允许探索流程页面，Home 按钮返回标题页。键盘 Tab 可切换焦点。

## 手动测试

1. Home → Start Mission 进入 Mission Control；Settings 修改首页语言/配色；Quit 退出。Mission Control 的 Create New Mission 或预设按钮进入 Creator。
2. Mission Creator 修改名称、描述、两种 objective、1–2 个目标、观测次数、时长和预算，确认摘要和成功条件即时更新。
3. Builder 分别选择 Payload / Bus / Battery / Solar / Storage / Radio，查看 3D 模型与摘要；切换拆解和子系统视图，修改轨道、发射器和策略。
4. Readiness 查看固定 PASS / WARNING / BLOCKED 示例；Launch Mission 进入本地 mock 运营页。BLOCKED 指真实集成未连接，不阻止原型启动。
5. Operations 使用 Play、Pause、Step、1x/2x/4x/8x、Skip to End；点击六种事件，确认时间、遥测、说明、卫星位置与高亮更新。完成后 Play 显示 Replay。
6. Debrief 切换 Run A / Run B，确认结果变化；Modify Design 返回 Builder；Start New Mission 重置选择。
7. 测试各页 Back / Continue 与顶部导航，分别调整窗口到两个目标分辨率。

自动检查：

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/prototype_smoke.gd
```

检查覆盖六个 PackedScene、单一 ScreenHost 实例、两种尺寸的水平边界、名称摘要、组件状态、播放/暂停/单步/跳结尾、Run B 结果和 Back / Continue 信号。

## 结构与学习重点

- `scenes/Main.tscn` + `scripts/MissionController.gd`：共享页眉、导航、ScreenHost、页脚。Controller 加载 PackedScene，只保留一个页面；普通 Dictionary 保存本次会话选择。
- `scenes/screens/*.tscn`：六个独立可导航场景。运行时使用容器构建 UI，编辑器中场景只显示根节点；实际界面请运行查看。
- `scripts/prototype/Screen.gd`：六页的轻量 UI 行为。页面发出 `navigate(index)` 信号，由 Main 执行切换；无 autoload 或复杂状态框架。
- `ui/components/UI.gd`：Label、Button、PanelContainer 的小型创建工具。
- `ui/components/OrbitIllustration.gd`：Control `_draw()` 原生绘图；位置来自事件索引，无轨道计算。
- `ui/theme/PrototypeTheme.gd`：Theme + StyleBoxFlat 统一颜色、边框、间距和圆角。
- `data/mock/PrototypeData.gd`：独立固定组件规格、事件、Run A / B 数据。它不是生产 RunTrace schema。
- `tests/prototype_smoke.gd`：可独立运行的 UI 行为与布局检查。

实现顺序对应 A 导航 → B 主题 → C 开始/任务 → D 设计/检查 → E 运营 → F 对比 → G 验证。学习时优先阅读 Controller 的 `show_screen()`，然后 Screen 的 `choice()`、`select_event()`：分别展示场景替换、控件信号更新状态、固定数据驱动多个 UI 元素。

## 后续真实集成边界

以下均为 mock，需要未来团队按确认后的接口替换：组件与任务目录、质量/成本/功率/存储规格、可行性与 readiness 检查、轨道与光照、事件时间和遥测、观测捕获与下传、Run A/B 对比和任务评价。

当前策略和轨道选择仅保存并展示；不会改变固定事件或生成新的结果。HPC / KE2 / KE3 数据适配、MissionEvaluator、生产 RunTrace、持久化均未实现。

## 3D-ready structure

新增可嵌入 UI 的独立 3D 视口、地球/卫星占位模型、固定环绕动画与播放演示。打开 `scenes/3d/PreviewDemo.tscn` 按 F6 运行；原项目 F5 入口保留。详细目录与模型导入约定见 [docs/PROJECT_STRUCTURE.md](docs/PROJECT_STRUCTURE.md)。七屏新设计及 Language / Theme 设置目前仅预留目录。

## New Home screen

已制作独立 Home 标题页及 Language / Theme 设置弹层。完整使用和学习说明见 [docs/HOME.md](docs/HOME.md)。Mission Control 目前为过渡入口；Creator、Builder、Readiness 和 Operations 已按参考图逐步实现，Debrief 暂保留原布局。

## Mission Creator + 3D Spacecraft Builder

任务定义与航天器设计页已更新，Creator 支持两种目标模板、1–2 个目标、1–8 次观测、3/6/9 轨道和 60–150 credits；Builder 提供六类独立组件选择和原生 3D 卫星预览（旋转、缩放、拆解、高亮）。按 F5 从 Home 进入。使用、学习及模型替换说明见 [docs/DESIGN_WORKBENCH.md](docs/DESIGN_WORKBENCH.md)。

Fullscreen 使用 1440×900 桌面设计画布，按屏幕等比例缩放，避免 Retina 显示器上控件过小；较小的窗口仍按可用空间重排。F11 切换窗口模式。

## Flight Readiness

Readiness 已按参考图实现六项可展开检查、交互式 3D 航天器/轨道预览、半圆资源仪表、目标覆盖条、Launch Ready 与警告面板。所有检查仍为固定 mock。操作、文件结构与集成边界见 [docs/FLIGHT_READINESS.md](docs/FLIGHT_READINESS.md)。

## Mission Operations

已加入按参考图排布的 Operations 仪表盘、真实 3D 地球/卫星、播放时间轴、三种视图、遥测、事件过滤与地面轨迹。播放与结果均为本地 mock，最终结果与现有 Debrief 的 Run A 一致。操作、数据边界和学习说明见 [docs/MISSION_OPERATIONS.md](docs/MISSION_OPERATIONS.md)。
