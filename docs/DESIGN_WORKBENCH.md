# Mission Creator and Spacecraft Builder

## 运行与体验

F5 从 Main 运行 → Home / Start Mission → Mission Control → Create New Mission 或选择预设。

Creator：

- 名称必填（48 字以内），可选描述最多 200 字。
- Capture Imagery：交付数量在所选目标间合并计数；需要相机。
- Survey Target Regions：总交付量达到要求，并包含每个目标至少一次完整观测；需要 survey sensor。
- 选择 1 或 2 个目标。至少保留一个；达到上限后，新卡片替换最后一个目标。区域按钮只过滤显示，不清除其他区域的已选目标；再次点击当前区域显示全部目标。
- 观测数量 1–8；时长 3 / 6 / 9 轨道；预算 60–150 credits，步长 10。
- 摘要和成功条件立即更新。轨道下拉框显示不同预设的固定参考窗口，不自动替玩家选择轨道。
- 覆盖条是固定六轨道样本，修改任务时长不会计算窗口。Creator 的地球为生成的概念插图；窗口数量叠加在独立控件中，不是地理覆盖计算。

Builder：

- 点击六类组件按钮，弹窗选择两个本地选项之一。
- 3D Model：左键拖动旋转；预览内滚轮缩放。Auto rotate 切换自动旋转，手动拖动会停止自动旋转。Reset view 恢复初始取景。
- Exploded View：AnimationPlayer 将模型分组拆开；返回 3D Model 会合拢。
- Subsystems：显示子系统色彩；点击左侧组件可高亮相应模型组。
- Enlarge：打开独立大视口，仍可拖动与缩放。
- Orbit / Launcher 和 Observe First / Downlink First 保存到会话状态。
- 组件更改会修改模型的展示尺寸或部件高亮，并更新摘要。规格来自预设展示数据；不根据组件求和或计算工程性能。
- Next → 现有 Flight Readiness。其报告仍是固定 mock，页面已按参考图实现；见 FLIGHT_READINESS.md。

两页支持 1280×720 与 1024×768。小窗口会将摘要移至表单下方。长页面纵向滚动，Back / Next 留在独立底部区域。

## 文件与通信

```text
scenes/screens/mission_creator/MissionCreator.tscn
scenes/screens/spacecraft_builder/SpacecraftBuilder.tscn
scripts/screens/Workbench.gd               # 共享标题、滚动区、表单工具、导航
scripts/screens/MissionCreator.gd         # Creator UI 与输入状态
scripts/screens/SpacecraftBuilder.gd      # Builder UI 与组件选择
ui/theme/WorkbenchTheme.gd                # 两页的深色面板与选中样式
ui/components/TargetThumbnail.gd          # 风景图集裁切显示

data/mock/DesignCatalog.gd                # 默认任务、目标、窗口、组件及固定规格
scenes/ui/components/CraftPreview.tscn    # 独立 World3D 视口、灯光、摄像机
scripts/visualization/CraftPreview.gd     # 鼠标、自动旋转、分解动画与高亮
scenes/3d/actors/ArchitectSpacecraft.tscn  # 可替换的原生模型
assets/3d/materials/IllustrativeEarth.gdshader
```

原 `scenes/screens/MissionCreator.tscn` 和 `SpacecraftBuilder.tscn` 路径保留为新场景的实例，已有导航引用继续有效。旧集中式 Screen.gd 中这两页的实现已移除。

Controller 持有一个普通 Dictionary，页面读取并修改它，通过 `navigate(index)` 请求切页。返回页面时选择仍存在；Start New Mission 则用 DesignCatalog.DEFAULTS 深拷贝重置。没有网络或文件持久化。

## 3D 模型替换

当前卫星为本项目用 Godot 网格制作的概念模型，包含带太阳能电池片的双翼、金色机身、相机镜头、天线、电池和存储盒；无需下载模型或安装 DCC 工具。

导入 `.glb` 后，在 ArchitectSpacecraft 的 ModelSlot 中替换视觉内容。为保持当前拆解与高亮功能，请保留 Bus / Payload / Battery / Solar / Storage / Radio 六个 Node3D 分组。将对应的 MeshInstance3D 作为分组直接子节点；多层模型需调整 CraftPreview 的遍历方式。

`configure()` 用于切换概念模型的展示比例。若换成不同结构的真实资产，应同步更新该方法。AnimationPlayer 的拆解轨道绑定分组 `position`，与任务事件或 HPC 数据无关。

## 学习重点

1. Creator 的信号 → Dictionary → `refresh()`：一份输入驱动摘要、成功条件和覆盖条。
2. Builder 的目录和视口分离：组件选择改变 UI 状态，视口只负责展示。
3. SubViewport 使用独立 World3D；界面摄像机与运营场景互不干扰。
4. `AnimationPlayer` 播放分组位移，`_gui_input()` 管理旋转与缩放；两者不构成模拟引擎。

## 检查

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/design_workflow_smoke.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/prototype_smoke.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/home_smoke.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/3d/preview_smoke.gd
```

新检查覆盖输入约束、目标替换规则、两种尺寸边界、六类组件、拆解/合拢、子系统高亮、拖动/缩放、选择弹窗和返回后的状态。

## 可调整窗口布局

全屏和大窗口以 1440×900 桌面设计画布等比例缩放，避免 Retina 下 UI 过小；较小窗口按自身尺寸重排。宽窗口使用三栏；工作区宽度不足 1180 时将摘要移到下方。常用按钮、下拉框与输入框保持至少 44 像素高，Back / Next 至少 48 像素；大窗口适度增加字体与间距。Home 按窗口宽高调整安全边距、标题和主按钮。

3D 预览高度随工作区变化。摄像机根据六个分组的包围盒和视口比例自动取景，适用于旋转、组件尺寸变化及拆解动画；模型没有被拉伸。滚轮仍可主动放大查看细节，Reset view 回到完整取景。Enlarge 弹窗按当前窗口比例打开，且可继续调整大小。

`tests/responsive_layout_smoke.gd` 验证连续调整到 1024×768、1280×720、1440×900、1920×1080 后，节点不会水平溢出，按钮与摘要位置正确，模型在组装/拆解和多个旋转角度下投影均位于视口内。


## 按参考图重排的版本

- Creator：左栏为任务详情、横向 objective 卡片、区域按钮和三列目标卡片；中间为主覆盖插图、并排观测数量/时长、预算滑块；右栏为带风景图的 mission summary 和成功条件。
- Builder：左侧六类带图标组件；中间预览顶部带视图切换，右侧浮动旋转/重置/放大工具；其下方并排 Orbit & Launcher / Operating Policy。System Check 横跨左侧和中间，摘要独立放在右侧。
- 共享 Header 加入品牌和本地模式标识；流程步骤位于页面标题右侧，不再额外占用一整行导航栏。此前删除的额外侧栏入口没有恢复。
- 默认 1440×900 下，两页主要面板完整显示。较窄或较矮的窗口允许纵向滚动，并在窄窗口下将摘要移到下方。
- Builder 模型保持实时 3D，使用独立透明视口叠在 Earth 背景上；Creator 覆盖插图为静态概念美术。
- 新素材与生成提示词见 [REFERENCE_ART_PROMPTS.md](REFERENCE_ART_PROMPTS.md)。
- `tests/responsive_layout_smoke.gd` 增加了默认窗口下整页不滚动、objective 卡片横排与三列目标区的检查。

Flight Readiness 已在后续阶段按参考图实现；Operations 已在后续阶段按参考图实现；Debrief 仍保留既有原型布局，结果数据已同步。
