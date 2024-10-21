#!/bin/bash

# 生成安装脚本
finalgen_installsh(){
    MODULE_INFO "......最终合并生成install.sh......"
    local fileName=$INSTALL

    # 备份allConfigMap
    # for key in "${!allConfigMap[@]}"; do
    #     for file in "${allConfigMap[$key]}"; do
    #         safeBackup $file $CURDOTFILES/$key CURDOTFILES/$key
    #     done
    # done    
    # 备份整个CURDOTFILES
    safeTarBackup $CURDOTFILES
    # 备份$(hostname).sh
    [[ -f $CONFIGP/$(hostname).sh ]] && safeBackup $(hostname).sh $CONFIGP config

    # 更新recordInstall和recordConfig
    saveArray recordInstall $fileName
    saveArray recordConfig  $fileName
    saveMap allConfigMap $fileName

    # 写入检查安装效果的代码
cat <<EOF >> $fileName

# ===============================================
# 生成时间: $(date)
# ===============================================
CURDOTFILES=$CURDOTFILES
TEMP=$TEMP
OPWD=$OPWD
CONFIGP=$CONFIGP
IFTEST=${IFTEST:-n}
BACKUPP=$BACKUPP
AFTERINSTALL=$AFTERINSTALL
EOF

cat << 'EOF' >> $fileName
declare -i ifER=0
MODULE_INFO "检测安装状态"
for file in "${recordInstall[@]}"; do
    if ${file}_check; then
        INFO "==> $file : [y]"
    else
        ERROR "==> $file : [n]"
        ifER=$((ifER+1))
    fi
done

declare -i stillInstall=0
if [[ $ifER -eq 0 ]]; then
    stillInstall=1
else
    ERROR "安装失败 未安装个数${ifER}"
    if readReturn "是否强制继续安装？[y/n]";then
        stillInstall=1
    else
        ABORT "安装失败,退出"
        exit 1
    fi
fi

if [[ $stillInstall -eq 1 ]]; then
    SUCCESS "安装成功，准备更新配置文件"
    [ "$IFTEST" = "y" ] && DEBUG "此处注释了cp 仅供调试使用"
    [ "$IFTEST" = "n" ] && rm -rf ./CURDOTFILES/* && INFO "rm -rf ./CURDOTFILES/*"
    for key in "${!allConfigMap[@]}"; do
        mkdir -p "$CURDOTFILES/$key"
        # 将字符串转换为数组
        eval "files=(${allConfigMap[$key]})"
        for file in "${files[@]}"; do
            if [ "$IFTEST" = "n" ]; then
                cp "$TEMP/$key/$file" "$CURDOTFILES/$key/$file"
                if [ $? -eq 0 ]; then
                    INFO "==> $key/$file : [y]" # INFO "cp $TEMP/$key/$file $CURDOTFILES/$key/$file"
                else
                    ERROR "==> $key/$file : [n] Failed to copy $TEMP/$key/$file to $CURDOTFILES/$key/$file"
                fi
            elif [ "$IFTEST" = "y" ]; then
                DEBUG "cp $TEMP/$key/$file $CURDOTFILES/$key/$file"
            fi
            if [ -f "$HOME/$key/$file" ] && [ ! -L "$HOME/$key/$file" ] && [ ! -L "$HOME/$key" ]; then
                if readReturn "文件$HOME/$key/$file已存在，是否备份后删除？[y/n]"; then
                    safeBackup "$HOME/$key/$file" "$CURDOTFILES" "$key"
                    rm "$HOME/$key/$file"
                else
                    WARN "文件$HOME/$key/$file未删除"
                fi
            fi
        done
    done
    MODULE_INFO "......配置文件创建符号链接......"
    cd $CURDOTFILES
    # 使用了一个高级技巧 https://www.reddit.com/r/linux4noobs/comments/b5ig2h/is_there_any_way_to_force_gnu_stow_to_overwrite/
    # 用来强制覆盖现有文件
    # https://www.reddit.com/r/linuxquestions/comments/x5uvc5/stow_only_create_symlinks_to_files_not_directories/
    # 令人困惑的为整个文件夹创建符号链接问题 --no-folding
    [ "$IFTEST" = "n" ] && stow --no-folding -R -t ~ . && INFO "> stow --no-folding -R -t ~ ."
    [ "$IFTEST" = "y" ] && DEBUG "此处注释了stow 仅供调试使用 stow --no-folding -R -t ~ ."
    cd $OPWD
    MODULE_INFO "......合并生成$(hostname).sh......"
    echo "#/bin/bash" > $CONFIGP/$(hostname).sh
    saveArray recordInstall $CONFIGP/$(hostname).sh "-g"
    saveArray recordConfig $CONFIGP/$(hostname).sh "-g"
    MODULE_INFO "......处理installafter.sh....."
    MODULE_INFO "$OPWD"
    [ -f "$OPWD/installafter.sh" ] && $OPWD/installafter.sh
    SUCCESS "......ALL_DONE......"
fi

INFO "......删除临时文件......"
rm -rf $OPWD/temp
# ===============================================
EOF

    # 覆盖install.sh
    if [[ -f $fileName ]]; then
        safeOverwrite install.sh $TEMP $OPWD
    fi
    chmod +x $OPWD/install.sh

    # 覆盖installafter.sh
    if [[ -f $AFTERINSTALL ]]; then
        safeOverwrite installafter.sh $TEMP $OPWD
    fi
    chmod +x $OPWD/installafter.sh
}

# 生成卸载脚本
finalgen_uninstallsh(){
    MODULE_INFO "暂时不能使用finalgen_uninstallsh"
    exit 1
    MODULE_INFO "......最终合并生成uninstall.sh......"
    local fileName=$UNINSTALL

    # 备份allConfigMap
    # for key in "${!allConfigMap[@]}"; do
    #     for file in "${allConfigMap[$key]}"; do
    #         safeBackup $file $CURDOTFILES/$key CURDOTFILES/$key
    #     done
    # done 

    # 备份整个CURDOTFILES
    safeTarBackup $CURDOTFILES
    # 备份$(hostname).sh
    [[ -f $CONFIGP/$(hostname).sh ]] && safeBackup $(hostname).sh $CONFIGP config

    # 更新recordInstall和recordConfig
    saveArray recordInstall $fileName
    saveArray recordConfig  $fileName
    saveMap allConfigMap $fileName

    # 写入检查卸载效果的代码
cat <<EOF >> $fileName

# ===============================================
# 生成时间: $(date)
# ===============================================
CURDOTFILES=$CURDOTFILES
TEMP=$TEMP
OPWD=$OPWD
CONFIGP=$CONFIGP
IFTEST=${IFTEST:-n}
EOF

cat << 'EOF' >> $fileName
declare -i ifER=0
MODULE_INFO "检测卸载状态"
for file in "${recordInstall[@]}"; do
    if ! ${file}_check; then
        INFO "==> $file : [y]"
    else
        ERROR "==> $file : [n]"
        ifER=$((ifER+1))
    fi
done

if [[ $ifER -eq 0 ]]; then
    SUCCESS "开始卸载配置文件"
    [ "$IFTEST" = "y" ] && DEBUG "此处注释了rm 仅供调试使用"
    [ "$IFTEST" = "n" ] && rm -rf ./CURDOTFILES/* && INFO "rm -rf ./CURDOTFILES/*"
    for key in "${!allConfigMap[@]}"; do
        # 将字符串转换为数组
        eval "files=(${allConfigMap[$key]})"
        for file in "${files[@]}"; do
            if [ "$IFTEST" = "n" ]; then
                rm -f "$CURDOTFILES/$key/$file"
                if [ $? -eq 0 ]; then
                    INFO "==> $key/$file : [y]"  # INFO "rm -f $CURDOTFILES/$key/$file"
                else
                    ERROR "==> $key/$file : [n]  Failed to delete $CURDOTFILES/$key/$file"
                fi
            elif [ "$IFTEST" = "y" ]; then
                DEBUG "rm -f $CURDOTFILES/$key/$file"
            fi
        done
    done
    cd $CURDOTFILES
    MODULE_INFO "......删除符号链接......"
    # [ "$IFTEST" = "n" ] && stow -D -t ~ .
    # [ "$IFTEST" = "y" ] && DEBUG "此处注释了stow 仅供调试使用 stow -D -t ~ ."
    DEBUG "有bug, 反正不能用-D选项，此处注释了"
    cd $OPWD
    MODULE_INFO "......合并生成$(hostname)_uninstall.sh......"
    echo "#/bin/bash" > $CONFIGP/$(hostname)_uninstall.sh
    saveArray recordInstall $CONFIGP/$(hostname)_uninstall.sh "-g"
    saveArray recordConfig $CONFIGP/$(hostname)_uninstall.sh "-g"
    SUCCESS "......ALL_DONE......"   
else
    ERROR "卸载失败 未卸载个数${ifER}"
fi
# ===============================================
EOF

    # 覆盖uninstall.sh
    if [[ -f $fileName ]]; then
        safeOverwrite uninstall.sh $TEMP $OPWD
    fi

    chmod +x $OPWD/uninstall.sh
}

finalgen_updatesh(){
    MODULE_INFO "暂时不能使用finalgen_updatesh"
    exit 1
    MODULE_INFO "......最终合并生成update.sh......"
    local fileName=$UPDATE

    # 更新recordUpdate
    saveArray recordUpdate $fileName

    # 写入检查更新效果的代码
cat <<EOF >> $fileName

# ===============================================
# 生成时间: $(date)
# ===============================================
CURDOTFILES=$CURDOTFILES
TEMP=$TEMP
OPWD=$OPWD
CONFIGP=$CONFIGP
IFTEST=${IFTEST:-n}
EOF

cat << 'EOF' >> $fileName
WARN "无法自动检测更新状态，请手动检查"
SUCCESS "......ALL_DONE......" 
# ===============================================
EOF

    # 覆盖update.sh
    if [[ -f $fileName ]]; then
        safeOverwrite update.sh $TEMP $OPWD
    fi

    chmod +x $OPWD/update.sh
}

finalgen_readme(){
    MODULE_INFO "......最终合并生成README.md......"
cat << 'EOF' >> $TEMP/README.md
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
EOF

for reg in "${regFiles[@]}"; do
    # 执行 ${reg}_info 函数并捕获输出
    reg_info_output=$(${reg}_info)

    # 将捕获的输出插入到文件中
    cat << EOF >> $TEMP/README.md
| ${reg} | ${reg_info_output} |
EOF
done

cat << 'EOF' >> $TEMP/README.md

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


EOF
    SUCCESS "README.md 生成成功"
}