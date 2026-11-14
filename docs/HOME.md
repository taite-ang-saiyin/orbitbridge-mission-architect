# Home / Title screen

## Run and test

- 在 Godot 打开 `project.godot`，按 **F5**。Main 现在首先加载 Home。
- 打开 `scenes/screens/home/Home.tscn` 可在编辑器直接查看标题页节点与布局；单独 F6 用于预览外观，完整导航请从 Main / F5 运行。
- **Start Mission** → Mission Control 过渡页 → Create New Mission / preset → 现有任务流程。
- 流程页右上角 **Home** 返回标题页，不清除当前任务选择。
- **Settings** 打开设置面板。English / 简体中文适用于 Home 和 Settings；现有任务页面仍为英文。Midnight / Ocean 改变 Home 配色。设置仅保存于本次运行会话。
- 设置打开时背景按钮禁用。点击 Done、弹层外部或按 Escape 关闭；关闭后焦点回到 Settings。Tab / Shift+Tab 用于按钮导航，Enter / Space 激活。
- **Quit** 退出正在运行的应用。

## Files and communication

- `scenes/screens/home/Home.tscn`：真正的 Godot UI 节点，包含 TextureRect 背景、渐变遮罩、MarginContainer 安全边距、VBoxContainer 标题/按钮和设置遮罩。
- `scripts/screens/Home.gd`：连接按钮，应用 Home 配色和文案，打开/关闭设置。
- `scenes/ui/settings/SettingsPanel.tscn` + `scripts/ui/SettingsPanel.gd`：设置面板与 OptionButton 行为。
- `scripts/settings/PrototypeSettings.gd`：会话默认值及首页文案。
- `scripts/MissionController.gd`：接收 Home 的 `start_requested` / `quit_requested` 信号，管理标题页与流程页宿主。Home 不直接读取 Controller 的节点路径。
- `scenes/screens/mission_control/MissionControl.tscn`：可用的过渡入口。完整 Mission Control 视觉设计待下一屏制作。
- `assets/ui/backgrounds/home-earth-v1.png`：内置 image_gen 生成的静态无文字背景；生成提示词见 `HOME_BACKGROUND_PROMPT.md`。图中地球和卫星为美术内容，不是实时 3D。
- `assets/ui/icons/*.svg`：本地轻量图标，无外部依赖。

Home 的系统字体在当前设备优先使用 Arial，其他设备使用系统 sans-serif 回退；没有复制系统字体文件。所有资源均随项目本地加载，不发起运行时网络请求。

## Learning focus

先在编辑器查看 Home.tscn：TextureRect 的 Keep Aspect Covered 让背景铺满，容器保持按钮的间距和点击尺寸。再看 Home 的信号与 Controller 的 `show_home()` / `show_screen()`：页面负责表达用户动作，Main 决定如何导航。

Home 使用全屏 LandingHost；任务页面使用现有 ScreenHost 和共享页眉、页脚，因此标题页没有重复的应用栏。地球背景与 UI 分离，后续可将背景层替换成 SubViewport 中的 3D 场景。

## Validation

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/home_smoke.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/prototype_smoke.gd
```

自动检查覆盖两个尺寸的 Home 控件与面板边界、按钮导航、设置更新与会话内保留、语言、配色、Escape 和 Quit 信号。运行窗口已目视检查 Home 外观。原流程的布局、输入与事件播放检查继续保留。

窗口布局已更新：Home 根据窗口宽高调整安全边距、标题和按钮尺寸；整张 UI 不再按固定分辨率统一缩放。窗口放大时内容保留清晰的原生文字和图标。任务页面的连续调整检查见 `tests/responsive_layout_smoke.gd`。
