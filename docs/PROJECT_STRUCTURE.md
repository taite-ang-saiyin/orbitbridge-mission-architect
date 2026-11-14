# Project structure / 3D preparation

目录与可运行的 3D 展示基础已建立。现已加入 Home 标题页、设置弹层和 Mission Control 过渡入口；Mission Creator 与含 3D 预览的 Spacecraft Builder 也已迁移，其余流程继续使用现有原型。

```text
res://
├── project.godot
├── assets/
│   ├── 3d/
│   │   ├── models/{spacecraft,earth,ground_stations}/
│   │   ├── textures/
│   │   ├── materials/
│   │   └── animations/
│   └── ui/{icons,backgrounds,fonts}/
├── scenes/
│   ├── Main.tscn                     # 当前入口
│   ├── screens/
│   │   ├── *.tscn                    # 保留现有六屏原型
│   │   ├── home/                     # 后续七屏设计的预留目录
│   │   ├── mission_control/
│   │   ├── mission_creator/
│   │   ├── spacecraft_builder/
│   │   ├── flight_readiness/
│   │   ├── mission_operations/
│   │   └── debrief_compare/
│   ├── 3d/
│   │   ├── actors/{EarthVisual,SpacecraftVisual}.tscn
│   │   ├── stages/OrbitStage.tscn
│   │   └── PreviewDemo.tscn
│   └── ui/
│       ├── components/OrbitViewport.tscn
│       └── settings/                 # 预留 Language / Theme UI
├── scripts/
│   ├── MissionController.gd
│   ├── prototype/                    # 现有 UI 行为
│   ├── visualization/                # 纯展示与动画控制
│   └── settings/                     # 后续设置逻辑
├── ui/{components,theme}/            # 保留共享 UI 工具与主题
├── data/
│   ├── mock/                         # 原型 fixtures
│   └── catalogs/                     # 后续确认后的组件、目标目录
├── localization/                     # 后续翻译资源
├── docs/
└── tests/3d/
```

空目录中的 `.keep` 只用于版本控制，不是 Godot 资源。

## 展示层如何工作

`OrbitViewport` 是可嵌入 UI 的 SubViewportContainer，内部 SubViewport 使用独立 World3D。OrbitStage 包含 Camera3D、WorldEnvironment、DirectionalLight3D、地球、卫星、轨道环和 AnimationPlayer。

页面以后可以实例化这个组件，并取得 `SubViewport/OrbitStage`，调用：

```gdscript
stage.play_preview()
stage.pause_preview()
stage.reset_preview()
stage.set_preview_speed(2.0)
```

这是固定 16 秒循环的美术动画，不代表真实时间、轨道高度或速度。目前不自动播放，按 Play 启动。独立演示：打开 `scenes/3d/PreviewDemo.tscn`，按 F6。F5 仍进入原 UI 原型。

## 导入模型约定

1. 建议将 `.glb` 和关联纹理放到 `assets/3d/` 对应目录，交由 Godot 导入；不需要外部运行时依赖。
2. 在 `scenes/3d/actors/` 创建包装场景，或替换现有 actor 的 `ModelSlot` 子节点。不要把摄像机或 UI 控制代码放进模型文件。
3. Godot 使用 Y 轴向上。展示场景约定地球半径为 1 个显示单位，卫星是缩放后的视觉模型；不映射真实米/千米。
4. 在 ModelSlot 内调整模型朝向和大小，保留 actor 根节点、OrbitPivot 与 ObservationOrigin 标记的名称和路径。
5. 模型自带的展开动画由 actor 自己的 AnimationPlayer 管理；流程动画（环绕、后续观测/下传效果）放在 stage。当前只提供环绕示例，其他流程动画待制作。
6. 保留模型来源和许可说明，与资源一起提交；不要手动编辑 `.godot/` 导入缓存。

当前 Compatibility 渲染器支持这些基础 3D 网格、材质和灯光，暂不切换渲染器。后续若需要高级大气、辉光效果，再根据目标设备评估。

## 后续迁移顺序

Home → Mission Control → Mission Creator → Spacecraft Builder → Flight Readiness → Operations → Debrief。Settings 为独立面板，含 Language / Theme，不计入主流程。

Home、Settings、Mission Control 过渡入口、Mission Creator 和 Spacecraft Builder 已实现；Flight Readiness 已加入参考图布局与 mock 报告；Operations 已加入参考布局、3D 展示与 mock 播放；Debrief 保留原型布局。后续逐屏迁移现有原型。Creator 规则已应用；已确认的 Debrief mock 结果已同步，视觉布局待迁移。

## 检查

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/3d/preview_smoke.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/prototype_smoke.gd
```

3D 检查验证资源加载、独立视口、摄像机、动画位移和控制信号；渲染外观需运行 PreviewDemo 目视检查。

新增 CraftPreview 与 ArchitectSpacecraft 的模型替换约定见 [DESIGN_WORKBENCH.md](DESIGN_WORKBENCH.md)。
