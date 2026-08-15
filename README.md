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

1. 从 [Releases](https://github.com/msunx/menu-note/releases/latest) 下载 `Menu-Note-v0.9.0-macos-arm64.zip`。
2. 解压后将 `Menu Note.app` 移动到“应用程序”目录。
3. 首次启动时右键应用并选择“打开”。当前版本使用临时签名，尚未经过 Apple 公证。
4. 点击菜单栏中的便笺图标开始记录。

## 功能

- 粗体、斜体、删除线、行内代码、链接和引用
- 无序列表、编号列表和内嵌待办复选框
- 默认、蓝、绿、橙、紫五档文字颜色
- 浅色玻璃主题与 Catppuccin Mocha 风格深色主题
- 自动保存、旧版内容块与 Markdown 内容迁移
- 键盘访问、拼写检查与减少动态效果支持
- 自定义应用图标和菜单栏模板图标

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
- 卸载应用不会主动删除偏好数据。

## 项目结构

```text
Resources/Web/          富文本编辑器界面与交互
Sources/MenuNote/       AppKit 菜单栏、弹窗和本地存储
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
