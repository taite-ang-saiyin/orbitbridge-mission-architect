# Flight Readiness

## Run

按 F5 从 Main 启动。Home → Mission Control → Mission Creator → Spacecraft Builder → Flight Readiness，也可使用流程导航直接进入。默认全屏，F11 可切换窗口模式。

## Layout and interaction

布局按提供的参考图制作：左侧六项 Readiness Checklist，右上 Spacecraft & Orbit Preview，右下并排 Resource Summary / Mission Coverage，底部绿色 LAUNCH READY 与黄色 Warnings 面板，独立 Back / Launch Mission 按钮。

- 每项检查右侧的 `+` 展开当前选择和 mock 说明；再次点击收起。展开较长内容时允许页面纵向滚动。
- 预览显示 Builder 选择的原生 3D 航天器，可拖动旋转、滚轮缩放。右上规格卡和左下轨道卡显示当前选择。
- 半圆仪表显示预设的质量、峰值功率、存储规格及示例限额。显示位置来自预先写好的样本，不计算资源平衡。
- 覆盖区列出所选目标以及固定的六轨道窗口条。最后一个所选目标带示例 WARNING；报告始终为五项 PASS 和一项 WARNING。
- View Details 打开当前任务的覆盖警告说明。
- Back 返回 Spacecraft Builder 并保留任务选择；Launch Mission 导航到现有 mock Operations 页面。

默认 1440×900 桌面画布及 Retina 全屏下，收起全部详情时完整显示主要面板。1280×720、1024×768 可纵向滚动，底部导航保持可见。

## Files and learning

- `scenes/screens/flight_readiness/FlightReadiness.tscn`：独立 UI 页面；原 `scenes/screens/FlightReadiness.tscn` 路径保留为实例，兼容既有导航。
- `scripts/screens/FlightReadiness.gd`：构建容器、绑定当前任务、展开详情、警告弹窗及响应式布局。
- `data/mock/ReadinessFixture.gd`：固定检查状态、说明、仪表位置、轨道说明及窗口样本。替换真实集成时从这里开始，不把样本当作生产接口。
- `ui/components/ReadinessStatus.gd`：原生绘制绿色勾和黄色警告符号。
- `ui/components/ResourceGauge.gd`：原生绘制半圆仪表及文本。
- `ui/components/CoverageStrip.gd`：原生绘制六个示例窗口槽。
- `scripts/screens/Workbench.gd`：复用页标题、步骤导航、主题与底部按钮；`fit_navigation()` 可独立用于两栏 Readiness 布局。
- `scenes/ui/components/CraftPreview.tscn`：复用独立 World3D、摄像机和卫星模型；开启 4× MSAA 改善模型轮廓。

学习时先看 `build_checklist()`：PanelContainer / VBoxContainer 负责自然排版，按钮只切换详情 Label 的可见性。然后看 `build_preview()`：同一份 state 驱动规格卡和模型，页面没有自己的持久化。最后看父类的 `navigate` 信号：Main 执行场景切换。

## Mock boundary

显示的任务、组件、轨道、策略来自本次会话选择；PASS / WARNING、轨道周期、倾角、资源限额、仪表位置和覆盖槽都是明确分离的样本。任何组件组合都不会触发真实验证、阻止 mock launch 或调用 HPC。真实验证、覆盖计算、质量/功率/存储计算和生产数据接入均留待后续团队集成。

## Checks

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/readiness_smoke.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/design_workflow_smoke.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/prototype_smoke.gd
```

检查覆盖 1440×900、1280×720、1024×768、1920×1080、3360×2100，验证状态带入、六项展开/收起、规格与仪表、警告弹窗、整页边界及 Back / Launch。已在全屏运行窗口目视检查布局。
