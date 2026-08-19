<p align="center">
  <img src="./assets/readme/hero.svg" width="100%" alt="Menu Note，一款本地优先的 macOS 菜单栏富文本临时记事本">
</p>

<p align="center">
  <a href="https://github.com/msunx/menu-note/releases/latest">下载最新版</a> ·
  <a href="#源码构建">源码构建</a> ·
  <a href="#参与贡献">参与贡献</a>
</p>

Menu Note 是一款常驻 macOS 菜单栏的轻量富文本临时记事本。点击菜单栏图标即可展开，在同一篇文档里记录正文、列表和可勾选待办；内容只保存在本机，不需要账号，也不会发起网络请求。

<p align="center">
  <img src="./assets/readme/showcase.png" width="100%" alt="Menu Note 浅色与 Catppuccin Mocha 深色界面预览">
</p>

## 为什么使用 Menu Note

- **打开即写**：没有文件选择、页面管理或分类流程，适合临时记录与当前任务。
- **一篇富文本文档**：正文、引用、列表、链接、代码和待办都在同一个编辑器里完成。
- **本地优先**：内容保存到 macOS `UserDefaults`，应用没有账号体系和网络请求。
- **原生菜单栏体验**：使用 AppKit、WebKit 和 macOS 动态玻璃材质，支持浅色与深色主题。

## 安装

当前 Release 提供 Apple Silicon（`arm64`）版本，要求 macOS 14 或更高版本。

1. 从 [Releases](https://github.com/msunx/menu-note/releases/latest) 下载 `Menu-Note-v0.11.0-macos-arm64.zip`。
2. 解压后将 `Menu Note.app` 移动到“应用程序”目录。
3. 首次启动时右键应用并选择“打开”。当前版本使用临时签名，尚未经过 Apple 公证。
4. 点击菜单栏中的便笺图标开始记录。
5. 如需使用 Finder 右键菜单，点击弹窗右上角的文件夹按钮，在系统扩展管理界面中启用“Menu Note Finder 菜单”。

## 功能

- 粗体、斜体、删除线、行内代码、链接和引用
- 无序列表、编号列表和内嵌待办复选框
- 默认色与 Pink、Mauve、Red、Peach、Green、Blue、Maroon 七种 Catppuccin 自适应文字颜色（浅色 Latte、深色 Frappé）
- 弹窗内一键启动或停止 `caffeinate`，在 Menu Note 运行期间阻止 Mac 空闲睡眠
- Finder 右键菜单支持彻底删除、复制绝对路径，以及 Windows 风格的剪切后移动
- 浅色玻璃主题与 Catppuccin Mocha 风格深色主题
- 自动保存、旧版内容块与 Markdown 内容迁移
- 键盘访问、拼写检查与减少动态效果支持
- 自定义应用图标和菜单栏模板图标

### Finder 右键菜单

- **彻底删除**：直接删除所选文件或文件夹，不会移入废纸篓，也不会再次弹出确认框；文件系统根目录和当前用户主目录不会被删除。
- **复制目录**：右键文件或文件夹时复制所选项目的绝对路径；在 Finder 空白处右键时复制当前文件夹的绝对路径。多选时每行复制一个路径。
- **剪切**：右键项目并选择“剪切”，进入目标文件夹后在空白处右键选择“粘贴并移动”；再次复制其他内容会取消本次剪切状态。
- 菜单使用 macOS 原生 SF Symbols，为剪切、复制目录、彻底删除和粘贴并移动提供对应图标，并自动适配系统外观。

> “彻底删除”不可撤销。使用前请确认所选项目无需保留。

### v0.11.0 更新

- 新增 Finder Sync 扩展，为文件、文件夹和 Finder 空白区域提供原生右键菜单。
- 新增彻底删除与绝对路径复制；彻底删除会保护文件系统根目录和当前用户主目录。
- 新增剪切与“粘贴并移动”闭环；剪切状态使用路径数据保存到系统剪贴板，兼容 Finder 扩展沙箱，并对同名冲突、源目标相同和移动到自身子目录等情况进行校验。
- 为 Finder 菜单加入剪刀、文稿复制、废纸篓和剪贴板等原生图标，移除菜单项之间的多余空白分隔。
- 弹窗右上角新增 Finder 扩展管理入口，并显示扩展当前启用状态。

### v0.10.2 更新

- 开启保持唤醒后，菜单栏会切换为橙色非模板图标；停止保持唤醒或 `caffeinate` 异常退出时自动恢复系统自适应图标。
- 菜单栏图标的悬浮提示和辅助功能文案会同步显示保持唤醒状态。

### v0.10.0 更新

- 文字颜色扩展为 Pink、Mauve、Red、Peach、Green、Blue、Maroon 七种，并根据主题使用浅色 Latte、深色 Frappé 配色。
- Todo 默认使用 Peach；完成态保留颜色并适度降低透明度，兼顾状态区分与可读性。
- 主题按钮旁新增保持唤醒按钮，可在应用运行期间启动或停止 macOS 自带的 `caffeinate`。
- 保留旧版橙色和紫色富文本内容的兼容显示。

## 快捷键

| 操作 | 快捷键 |
| --- | --- |
| 粗体 | `Command + B` |
| 斜体 | `Command + I` |
| 添加链接 | `Command + K` |
| 撤销 / 重做 | `Command + Z` / `Command + Shift + Z` |
| 退出应用 | `Command + Q` |

## 源码构建

项目不依赖第三方包，只需要 macOS 自带的 Apple Clang 和 Command Line Tools。

```bash
git clone https://github.com/msunx/menu-note.git
cd menu-note
./scripts/build-app.sh
open "dist/Menu Note.app"
```

构建脚本默认使用当前 Mac 的 CPU 架构，也可以显式指定：

```bash
ARCH=arm64 ./scripts/build-app.sh
```

开发时可以用普通窗口打开预置内容：

```bash
"dist/Menu Note.app/Contents/MacOS/MenuNote" --preview
```

## 数据与隐私

- 富文本内容存储在偏好设置域 `com.muyang.menunote` 中。
- 主题选择和编辑内容仅保留在本机。
- 应用不收集分析数据，不包含遥测、广告或网络请求。
- 保持唤醒功能仅启动系统自带的 `/usr/bin/caffeinate`，不会联网；合盖行为仍受 Mac 机型、电源和外接显示器状态影响。
- Finder 右键菜单只处理用户当前选择的本地文件路径；剪切状态保存在系统剪贴板中，复制其他内容后自动失效。
- Finder 扩展单独进行沙箱签名，不在后台扫描或修改文件；文件写入只会在用户主动选择彻底删除或粘贴并移动后发生。
- 卸载应用不会主动删除偏好数据。

## 项目结构

```text
Resources/Web/          富文本编辑器界面与交互
Sources/MenuNote/       AppKit 菜单栏、弹窗和本地存储
Sources/MenuNoteFinder/ Finder 右键菜单扩展
scripts/build-app.sh    应用构建与临时签名
scripts/generate_icon.m 原生应用图标生成器
```

## 参与贡献

欢迎提交 Issue 和 Pull Request。提交前请确保：

1. 修改范围聚焦，避免提交 `.build/`、`dist/` 或本机配置。
2. 运行 `./scripts/build-app.sh` 并确认签名验证通过。
3. 说明变更动机、用户影响和验证方式。

## License

[MIT](./LICENSE) © 2026 Xu Ximing

联系邮箱：[xuximing728@163.com](mailto:xuximing728@163.com)
