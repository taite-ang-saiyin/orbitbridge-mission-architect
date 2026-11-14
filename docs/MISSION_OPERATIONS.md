# Mission Operations

## 运行和操作

按 F5 从 Main 启动，Home → Start Mission，选择顶部 Operations，或沿 Creator → Builder → Readiness → Launch Mission 进入。默认全屏；F11 切换窗口模式。

布局遵循提供的 Operations 图片：左侧 Mission Status / Mission Progress，中间三种视图及播放控制，右侧 Telemetry / Recent Events 和详情，底部 Live Ground Track / Next Events。

- **Play / Pause**：开始或暂停本地演示。1x 下，90 分钟的参考时间约用 30 秒播放。
- **Step**：跳到下一个固定事件并暂停。
- **1x / 2x / 4x / 8x**：更改播放速度，保持当前时间。
- **时间轴**：拖动到任意参考时间并暂停。卫星位置、地面轨迹、遥测、事件详情同步更新。
- **Skip to End**：显示最终快照。Play 变成 Replay，再次点击重置整段演示。
- **Earth & Orbit**：真实 Godot 3D 地球、轨道环、所选航天器和固定目标/地面站标记。OBSERVE / TX 时显示演示光束。
- **Ground Track**：放大显示地图轨迹；下方的小地图持续显示当前播放位置。
- **Data View**：查看六个事件的时间、battery、captured 和 delivered 快照，高亮当前事件。
- **Recent Events**：点击列表跳到该事件。All Events / Observations / Downlink / Warnings 过滤列表，过滤后的行仍正确对应原始事件。
- **Expand**：打开可调整大小的 3D 预览窗口，继续同步播放；Close 关闭。
- **Back**：返回 Readiness 并保留任务选择。
- **View Debrief**：进入现有比较页面。

六种事件为 LAUNCH、DEPLOY、OBSERVE、TX、SKIP_POWER、SLOT_STATE。

## 数据边界

所有事件、时间、遥测、观测数量、下传数据及结果都是本地 fixture。`OperationsFixture.gd` 的数组仅供 UI 播放，不是生产 RunTrace，也没有提出生产接口。

轨道运动、地球转动、轨迹和光束都是播放位置驱动的美术效果。它们不运行轨道传播、可见性、功率、存储、观测调度或传输算法。

任务名称、目标名称、轨道标签、任务轨道数和航天器展示读取当前会话选择。参考播放始终为 90 分钟、5 次观测的样本；修改任务不会生成新结果。面板内明确标注固定 reference / mock。

本轮同步修正比较 fixture，以遵循已确认的 Debrief 图片：Run A 返回 5 次观测、1.24 GB、MET；Run B 返回 4 次、0.96 GB、PARTIAL。Operations 的最终快照与 Run A 一致。Debrief 的完整视觉重做仍留待后续。

## 文件和学习重点

- `scenes/screens/mission_operations/MissionOperations.tscn`：独立 UI 页面，旧场景路径保留为兼容实例。
- `scripts/screens/MissionOperations.gd`：播放、seek、事件选择、过滤、三种视图、放大窗口和 UI 绑定。
- `data/mock/OperationsFixture.gd`：固定快照、参考时间、目标进度和时间格式。
- `data/mock/PrototypeData.gd`：比较结果，与 Operations 最终快照一致。
- `scenes/3d/stages/OperationsStage.tscn` + `scripts/visualization/OperationsStage.gd`：地球、轨道、卫星、光束、星空及纯展示位移。
- `scenes/ui/components/OperationsOrbitViewport.tscn`：隔离的 World3D / SubViewport。
- `scripts/visualization/OperationsOrbitViewport.gd`：摄像机尺寸适配与场景退出保护。
- `scenes/3d/actors/OperationsEarth.tscn`：带本地表面纹理的地球模型。
- `ui/components/GroundTrack.gd`：地图、固定示意路径和播放标记。
- `assets/3d/materials/Atmosphere.gdshader`：简单大气边缘效果。
- `assets/3d/textures/earth-albedo-v1.png`：内置 image_gen 生成的美术纹理，提示词见 `OPERATIONS_ART_PROMPT.md`。

建议先读 `seek()`：它是唯一的播放位置入口。再读 `refresh()`：同一份 playhead / event_index 更新全部 UI 和视图。最后看 `rebuild_timeline()`：过滤只改变可见行与原始事件的映射，不改变原始数组。

页面通过 `navigate(index)` 与 Main 通信，没有后台服务或持久化。3D 组件在退出场景后忽略尺寸回调，避免已移出树的 Camera3D 被再次更新。

## 验证

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/operations_smoke.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/readiness_smoke.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/prototype_smoke.gd
```

覆盖 1440×900、1280×720、1024×768、1920×1080、3360×2100，检查控件边界、默认整页显示、播放/暂停/单步/倍速/拖动/重播、过滤、三种视图、3D 光束、扩大预览、前后导航及 Run A 结果一致性。已目视检查全屏 Operations 画面。
