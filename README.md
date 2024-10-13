# DotfilesConfigMaster

———模块化生成 dotfiles 的工具———

## 介绍

面对多设备同步开发环境的需求，传统的将所有 dotfiles 直接同步到 GitHub 的方式显得不够灵活且难以管理。
不同设备间可能需要安装不同的软件，硬编码大量的条件判断使得管理变得复杂，而且配置文件的同步在软件尚未安装时几乎没有意义。
手动安装软件，尤其是需要从源码构建或有多种安装方式的软件，以及处理软件间复杂的依赖关系，都是非常耗时且易出错的。
软件更新、配置文件中环境变量的正确处理、以及记录和回溯配置变化等，都是管理过程中的常见痛点。

为解决这些问题，**DotfilesConfigMaster** 应运而生。它不是简单地“同步” dotfiles，而是“生成” dotfiles 的工具。
通过为每个软件填写注册文件并存放在 regfiles 目录下，详细描述软件的安装、卸载、更新、配置等操作，
**DotfilesConfigMaster** 实现了 dotfiles 的模块化生成，大大简化了配置管理的复杂度。

## 使用方法

### 快速开始

1. **克隆仓库**：
   ```bash
   git clone https://github.com/your-repo/DotfilesConfigMaster.git
   ```

2. **执行安装**：
   直接运行 `./config.sh` 脚本，根据提示选择相应的操作，如安装、配置或卸载软件
   
### 当前已经注册的软件

| 软件名称 | 软件介绍 |
| :--------- | :--------------------------------------------------- |
| __predeps__ | 预先安装的软件，例如stow |
| git | 分布式版本控制系统 |
| nvim | 直接用的小彭老师开箱即用nvim配置 |
| strace | 用于追踪syscall的工具 |
| tmux | 终端多路复用 |
| zsh | 功能强大的命令行Shell |
| zstree | 是zmr233写的类似于pstree用于显示进程树的工具 |
| Emscripten | 编译 C/C++ 为 WebAssembly |
| GLEW | The OpenGL Extension Wrangler Library |
| GLFW | Open Source, multi-platform library for OpenGL |
| libbash | 是zmr封装了大量实用bash函数的脚本库 |
| moonbit | MoonBit  Cloud and Edge using WASM. |
| proxy | 保留代理的sudop |
| sdkman | Switch different Java-SDK |
| sml | SML/NJ complier fot Standard ML |
| ssh | Secure Shell这里加载私钥的配置 |
| vcpkg | C/C++ dependency manager from Microsoft |
| zshplugins | oh-my-zsh管plugins=(插件 |
| changeflow | 轻松切换和管理工作流的工具 |
| autojump | 智能目录跳转工具 |
| bat | 颜色高亮和分页显示的cat命令增强版 |
| fd | 更好的find |
| miniconda | 轻量级的Python发行版和包管理系统 |
| pipx | 用于全局安装和管理Python应用程序的工具 |
| rg | 快速搜索文件内容的命令行工具 |
| rust | Rust Programming Language |
| ysyx | 用作环境变量配置 |
| valgrind | 用于检测程序中的内存错误和性能问题的工具 |
| fzf | 命令行模糊查找工具 |
| ysyx_gtkwave | 波形查看器 |
| ysyx_systemc | 用于系统级设计和硬件建模的开源硬件描述语言HDL |
| ysyx_z3 | 是微软研究院的一个定理证明器 |
| ysyx_verilator | 最快的 Verilog/SystemVerilog 模拟器 |

## 执行逻辑

1. **配置注册表**：在 `config/$(hostname).sh` 中为每台电脑维护类似于注册表的数组 `recordInstall` 和 `recordConfig`，分别存储安装软件和配置文件的路径

2. **依赖处理**：使用图算法处理软件间的依赖关系，修改这两个数组以反映选择和安装的变化

3. **注册文件加载**：在 regfiles 目录下加载各软件的注册文件，这些文件提供了生成该软件安装、配置、更新脚本的函数，如 `fzf_install`、`fzf_config`、`fzf_update` 等

4. **代码生成**：遍历数组 `recordInstall` 和 `recordConfig`，依次调用 `${reg}_install()` 等函数，将执行代码写入 `install.sh`、`uninstall.sh`、`update.sh`

5. **执行安装和配置**：最后通过运行 `install.sh`、`uninstall.sh`、`update.sh` 执行实际的安装、卸载、更新操作。只有当所有软件都成功安装后才执行配置文件的生成，以保证安装和配置的一致性

6. **配置备份和回滚**：备份所有历史配置文件至 backup 目录，便于错误发生时快速回滚

## 将来可能更新的功能

1. **dotfiles 钩子**：实现守护进程监控 dotfiles 的修改，当配置被悄悄改动时发出提醒并重新配置。
2. **更细致的插件管理**：实现更高颗粒度的插件管理，如直接在 `.zshrc` 中管理 oh-my-zsh 的插件。
3. **强大的依赖管理**：处理非必须依赖，实现基于依赖项目的自动差异化配置。
4. **自动转换注册文件**：对于注册文件模板的更新，提供自动转换旧注册文件的能力，减少手动重写的工作量。

## 许可证

本项目采用 MIT 许可证。详情请见 [LICENSE](LICENSE) 文件。


