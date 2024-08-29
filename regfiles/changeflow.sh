#!/bin/bash

# VERSION: 1

changeflow_info(){
    echo "轻松切换和管理工作流的工具"
}

changeflow_deps(){
    echo "__predeps__ zsh libbash"
}

changeflow_check(){
checkCfg $HOME/.changeflowrc
return $?
}

changeflow_install(){
genSignS "changeflow" $INSTALL
cat << 'EOF' >> $INSTALL
MODULE_INFO "......正在安装changeflow......"
INFO "changeflow是无需安装的配置文件"
EOF
genSignE "changeflow" $INSTALL
}

changeflow_config(){
# 加入配置文件更新映射
declare -A REG_CONFIG_MAP__=(
    ["."]=".zshrc .changeflowrc"
)

add_configMap REG_CONFIG_MAP__
cat << 'XUVYP' >> $TEMP/./.zshrc
# Alias for changeflow
alias changeflow='bash ~/.changeflowrc'
alias cflow=changeflow
XUVYP
cat << 'XUVYP' >> $TEMP/./.changeflowrc
#!/bin/bash

# ==========加载.libbash函数库==========
source $HOME/libbash/libbash.sh
[ $? -ne 0 ] && echo "Unable to load libbash library" && echo "You can download github.com/zmr-233/libbash ~/libbash" && exit 1

# ==========主要逻辑==========
if checkCfg "MODULE.cfg";then
    source MODULE.cfg
    export MODULE
    MODULE_FILE_EXIST=yes
else
    ECHO CYAN_BOLD "==============================================================================="
    ERROR "MODULE.cfg not found! Please create it first."
    ERROR "Use changeflow -h to get help."
    ERROR "But I think you need to run changeflow --readme to learn how to use it."
    ECHO CYAN_BOLD "==============================================================================="
    MODULE_FILE_EXIST=no
fi

WF=.workflows
PREFIX=wf_
mkdir -p $WF

# 用来控制在切换旧工作流的时候是否备份
OPTIONAL_MAKEUP=yes

# 检查目录是否为空
_check_empty_dir() {
    local map_ref=$1
    local prefix=$2

    declare -n map=$map_ref

    for key in "${!map[@]}"; do
        if [[ "${map[$key]}" == "*" ]]; then
            if ! diffDir "$key" "$prefix/$key"; then
                return 1  # 目录不为空
            fi
        else
            eval "files=(${map[$key]})"
            for file in "${files[@]}"; do
                if ! diffFile "$key/$file" "$prefix/$key/$file"; then
                    return 1  # 文件不同，目录不为空
                fi
            done
        fi
    done

    return 0  # 目录为空
}

#==============================Main==============================
# changeflow 主函数
changeflow() {
    local target=$1
    local cur=${2:-$MODULE}
    local SAVEN="${PREFIX}${cur}"
    local TARN="${PREFIX}${target}"
    
    INFO "===== Check weather save ====="
    local isempty
    if _check_empty_dir init_map "$WF";then
        isempty=yes
    else
        isempty=no
    fi

    # 检查部分
    local issave=no
    if [[ $isempty == "no" ]]; then
        if [ -d $WF/$SAVEN ]; then
            WARN "The target workflow $cur already exists!"
            if readReturn "Do you want to overwrite it? (yes/no)"; then
                rm -rf $WF/$SAVEN
                issave=yes
            else
                issave=no
                INFO "Skipping saving current workflow as user opted not to overwrite."
                return 1
            fi
        else
            issave=yes
        fi
    fi

    # 保存部分
    if [[ $issave == "yes" ]]; then
        INFO "===== Saving to $WF/$SAVEN ====="
        operateMapFiles move workflow_map "." "$WF/$SAVEN" "$WF/backup/$SAVEN"
    else
        isMakeup=NO_MAKEUP
        INFO "... Do not need to save ..."
        INFO "===== Removing $WF/$SAVEN ====="
        operateMapFiles remove workflow_map "" "." "$WF/backup/$SAVEN"
        isMakeup=DO_MAKEUP
    fi

    # 切换部分
    if [ -d "$WF/$TARN" ]; then
        INFO "===== Switching to $target ====="
        case $OPTIONAL_MAKEUP in
            yes|tar)
                tarSafe "$WF/$TARN" "$WF/backup" # 打成tar包
                ;;
            folder)
                saveSafe "$WF/$TARN" "$WF/backup" # 完全不打包
                ;;
        esac
        operateMapFiles move workflow_map "$WF/$TARN" "." "$WF/backup"
        rmdir $WF/$TARN # 经常用于检查错误
    else
        INFO "===== Initializing to $target ====="
        operateMapFiles copy init_map "$WF" "." "$WF/backup"
        {
            echo "MODULE=$target"
            echo ""
            saveMap workflow_map
            echo ""
            saveMap init_map
            echo ""
        } > MODULE.cfg
    fi
}

#==============================剩下全是使用说明+更新脚本==============================

__generate_changeflow_readme(){
cat << 'EOF'

# changeflow 使用说明

changeflow | cflow 是一个用于轻松切换和管理工作流的脚本工具，它介于手动管理和 git 管理之间，提供了一种轻量化的解决方案。

## 命令行选项

- `-h|--help|-h=zh|--help=zh`   **显示帮助信息**
- `--readme `                   **显示极为详细的使用说明(可以重定向到README.md)**
- `-l, --list`                  **列出所有历史工作流(以及当前MODULE名称)**
- `--clean`                     **清除所有备份($WF/backup)**
- `--backup`                    **实际控制OPTIONAL_MAKEUP变量**
    - `yes`     使用默认
    - `no`      不备份(仅适用于切换旧工作流时不备份)
    - `tar`     打包备份(默认)
    - `folder`  不打包备份
- `-c xxx |--cur xxx`           **设置当前工作流名称xxx(默认用MODULE)**
- `-t xxx |--target xxx`        **切换到目标工作流xxx**


## 使用步骤

1. **准备 MODULE.cfg 文件**：首先，需要创建一个 `MODULE.cfg` 文件来定义工作流的结构。

   示例 `MODULE.cfg` 文件内容：
   ```shell
   MODULE=top

   declare -A workflow_map=(
       ["."]="MODULE.cfg"
       ["csrc"]="*"
       ["vsrc"]="*"
   )

   declare -A init_map=(
       ["csrc"]="*"
       ["vsrc"]="*"
   )
   ```

2. **初始工作流状态**：假设你的项目目录已经按照 `MODULE.cfg` 中的定义进行了初始化，目录结构可能如下所示：
   ```
   MODULE=top
   ├── .workflows
   │   ├── csrc
   │   │   └── marco.h
   │   └── vsrc
   │       └── TEMPLATE.v
   ├── MODULE.cfg
   ├── csrc
   │   ├── main.cpp
   │   ├── marco.h
   │   ├── top.cpp
   │   └── utils.cpp
   ├── .changeflowrc
   └── vsrc
       ├── TEMPLATE.v
       └── top.v
   ```

3. **创建新工作流**：若要创建一个名为 `add` 的新工作流，可使用以下命令之一：
   ```shell
   changeflow add
   changeflow add top
   changeflow -c top -t add
   ```
   创建后，目录结构更新如下：
   ```
   MODULE=add
   ├── .workflows
   │   ├── csrc
   │   │   └── marco.h
   │   ├── vsrc
   │   │   └── TEMPLATE.v
   │   └── wf_top
   │       ├── MODULE.cfg
   │       ├── csrc
   │       │   ├── main.cpp
   │       │   ├── marco.h
   │       │   ├── top.cpp
   │       │   └── utils.cpp
   │       └── vsrc
   │           ├── TEMPLATE.v
   │           └── top.v
   ├── MODULE.cfg
   ├── csrc
   │   ├── adder.cpp
   │   └── marco.h
   ├── .changeflowrc
   └── vsrc
       └── add.v
   ```

4. **切换回之前的工作流**：要切换回 `top` 工作流，可以使用以下命令之一：
   ```shell
   changeflow top
   changeflow top add
   changeflow -c add -t top
   ```
   切换回后，目录结构如下：
   ```
   MODULE=top
   ├── .workflows
   │   ├── backup
   │   │   └── 20240828165616.wf_top.tar.gz
   │   ├── csrc
   │   │   └── marco.h
   │   ├── vsrc
   │   │   └── TEMPLATE.v
   │   └── wf_add
   │       ├── MODULE.cfg
   │       ├── csrc
   │       │   ├── adder.cpp
   │       │   └── marco.h
   │       └── vsrc
   │           └── add.v
   ├── MODULE.cfg
   ├── csrc
   │   ├── main.cpp
   │   ├── marco.h
   │   ├── top.cpp
   │   └── utils.cpp
   ├── .changeflowrc
   └── vsrc
       ├── TEMPLATE.v
       └── top.v
   ```

## 其他说明

- **无修改时不备份**：如果在新创建的工作流中没有进行任何修改，切换或创建下一个工作流时，脚本不会进行备份操作。
- **强制备份**：即使设置了 `--backup no` 参数，遇到冲突操作时，脚本仍会进行强制备份，以避免数据丢失。
- **删除工作流**：出于安全考虑，脚本不支持直接删除工作流的操作。如果需要删除某个工作流，需要手动进行。


EOF

}


# 显示工作流信息
_list_workflows() {
    # local WF=".workflows"
    # local PREFIX="wf_"

    if [[ ! -d $WF ]]; then
        ERROR "Directory $WF does not exist."
        return 1
    fi

    # Find directories with the given prefix, sort by modification time, and extract the suffix
    local workflows=($(find "$WF" -type d -name "${PREFIX}*" -printf "%T@ %f\n" | sort -nr | awk '{print substr($2, length("'"$PREFIX"'") + 1)}'))

    # Display the results, 8 per line
    local count=0
    for workflow in "${workflows[@]}"; do
        nECHO CYAN_BOLD "$workflow "
        ((count++))
        if (( count % 8 == 0 )); then
            echo
        fi
    done

    # Print a final newline if the last line didn't end with one
    if (( count % 8 != 0 )); then
        echo
    fi
}

# 用来生成git提交的脚本
__generate_changeflow_git(){
    local GIT_DIR=$(mktemp -d -t CHANGEFLOW_XXXXXX)
    # mkdir -p "$GIT_DIR/changeflow"
    git clone git@github.com:zmr-233/ChangeFlow.git $GIT_DIR/changeflow
    pushd $GIT_DIR/changeflow > /dev/null
    {
        cat "$0"
    } > .changeflowrc
    {
        __generate_changeflow_readme
    } > README.md

cat << 'QWE' > ADD_TO_BASHRC_ZSHRC.sh
# Add the following line to your .bashrc or .zshrc file

# Alias for changeflow
alias changeflow='bash ~/.changeflowrc'
alias cflow=changeflow
QWE
    git add -A
    git commit -m "update changeflow"
    git push
    popd > /dev/null

    echo "cd $GIT_DIR/changeflow"
}

# 专门用来生regfiles配置文件的函数
# https://github.com/zmr-233/DotfilesConfigMaster 的
# DOTFILES_CONFIG_MASTER_HOME 应该由libbash而来
# 生成regfile模板函数
__generate_changeflow_regfile(){
    # local SCRIPT_NAME='.changeflowrc'
    local REG_NAME=changeflow
    local REG_INFO='轻松切换和管理工作流的工具'
    local REG_DEPS='zsh libbash'
    local REG_CHECK="checkCfg \$HOME/.changeflowrc"
    local REG_INSTALL=""
    declare -A REG_CONFIG_MAP=(
        ["."]=".zshrc .changeflowrc"
    )
    local ZSHRC_CONTENT=$(cat << 'EOM'
# Alias for changeflow
alias changeflow='bash ~/.changeflowrc'
alias cflow=changeflow

EOM
)
    local CHANGEFLOW_CONTENT=$(cat "$0")
    declare -A REG_CONFIG_FILE_MAP=(
        ["./.zshrc"]=$ZSHRC_CONTENT
        ["./.changeflowrc"]=$CHANGEFLOW_CONTENT
    )
    local REG_UPDATE=""
    local REG_UNINSTALL=""

    regfileTemplate "$REG_NAME" "$REG_INFO" "$REG_DEPS" "$REG_CHECK" "$REG_INSTALL" REG_CONFIG_MAP REG_CONFIG_FILE_MAP "$REG_UPDATE" "$REG_UNINSTALL"
}

# 显示英文帮助信息
__generate_changeflow_help_en() {
    ECHO "YELLOW_BOLD" "Usage: ${BLUE_BOLD}changeflow${RESET} [options]"
    echo ""
    ECHO "YELLOW_BOLD" "Examples:"
    ECHO "GREEN" "    changeflow foo            # Switch to foo workflow, save cur as MODULE"
    ECHO "GREEN" "    changeflow foo bar        # Switch to foo workflow, save cur as bar"
    ECHO "GREEN" "    changeflow -t foo -c bar  # Switch to foo workflow, save cur as bar"
    echo ""
    ECHO "YELLOW_BOLD" "Options:"
    nECHO "GREEN" "  -h, --help [lang]    "; ECHO "GREY" "Show help information (default: en)"
    nECHO "GREEN" "      --readme         "; ECHO "GREY" "Show detailed usage instructions (can be redirected to README.md)"
    nECHO "GREEN" "  -l, --list           "; ECHO "GREY" "List all historical workflows (and the current MODULE name)"
    nECHO "GREEN" "      --clean          "; ECHO "GREY" "Clean all backups (.workflow/backup)"
    nECHO "GREEN" "      --backup         "; ECHO "GREY" "Control the OPTIONAL_MAKEUP variable"
    nECHO "GREEN" "          yes          "; ECHO "GREY" "Use default"
    nECHO "GREEN" "          no           "; ECHO "GREY" "Do not backup (only applicable when switching to old workflows)"
    nECHO "GREEN" "          tar          "; ECHO "GREY" "Backup as tar (default)"
    nECHO "GREEN" "          folder       "; ECHO "GREY" "Backup as folder"
    nECHO "GREEN" "  -c xxx, --cur xxx    "; ECHO "GREY" "Set the current workflow name to xxx (default is MODULE)"
    nECHO "GREEN" "  -t xxx, --target xxx "; ECHO "GREY" "Switch to the target workflow xxx"
}

# 显示中文帮助信息
__generate_changeflow_help_zh() {
    ECHO "YELLOW_BOLD" "Usage: ${BLUE_BOLD}changeflow${RESET} [options]"
    echo ""
    ECHO "YELLOW_BOLD" "Examples:"
    ECHO "GREEN" "    changeflow foo            # Switch to foo workflow, save cur as MODULE"
    ECHO "GREEN" "    changeflow foo bar        # Switch to foo workflow, save cur as bar"
    ECHO "GREEN" "    changeflow -t foo -c bar  # Switch to foo workflow, save cur as bar"
    echo ""
    ECHO "YELLOW_BOLD" "Options:"
    nECHO "GREEN" "  -h, --help [语言]    "; ECHO "GREY" "显示帮助信息 (默认: en)"
    nECHO "GREEN" "      --readme         "; ECHO "GREY" "显示详细的使用说明 (可以重定向到 README.md)"
    nECHO "GREEN" "  -l, --list           "; ECHO "GREY" "列出所有历史工作流 (以及当前 MODULE 名称)"
    nECHO "GREEN" "      --clean          "; ECHO "GREY" "清除所有备份 (.workflow/backup)"
    nECHO "GREEN" "      --backup         "; ECHO "GREY" "控制 OPTIONAL_MAKEUP 变量"
    nECHO "GREEN" "          yes          "; ECHO "GREY" "使用默认"
    nECHO "GREEN" "          no           "; ECHO "GREY" "不备份 (仅适用于切换旧工作流时不备份)"
    nECHO "GREEN" "          tar          "; ECHO "GREY" "打包备份 (默认)"
    nECHO "GREEN" "          folder       "; ECHO "GREY" "不打包备份"
    nECHO "GREEN" "  -c xxx, --cur xxx    "; ECHO "GREY" "设置当前工作流名称为 xxx (默认是 MODULE)"
    nECHO "GREEN" "  -t xxx, --target xxx "; ECHO "GREY" "切换到目标工作流 xxx"
}

# 默认值
# OPTIONAL_MAKEUP="tar"
CURRENT_WORKFLOW=""
TARGET_WORKFLOW=""

# 解析命令行选项
if [[ $# -eq 0 ]]; then
    ERROR "No arguments provided."
    __generate_changeflow_help_en
    exit 0
fi
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -h|--help|-h=en|--help=en)
            __generate_changeflow_help_en
            exit 0
            ;;
        -h=zh|--help=zh)
            __generate_changeflow_help_zh
            exit 0
            ;;
        -h=*|--help=*)
            ERROR "Invalid language for help: ${1#*=}"
            exit 1
            ;;
        --readme)
            __generate_changeflow_readme
            exit 0
            ;;
        -l|--list|-H|--history)
            INFO "Listing all historical workflows ..."
            nECHO YELLOW "======> " ; nECHO GREEN_BOLD "$MODULE";  nECHO YELLOW " <======\n"
            _list_workflows
            exit 0
            ;;
        --clean)
            INFO "Cleaning all backups..."
            rm -rf $(WF)/backup
            exit 0
            ;;
        --backup)
            shift
            if [[ "$#" -gt 0 ]]; then
                case $1 in
                    yes|no|tar|folder)
                        OPTIONAL_MAKEUP=$1
                        ;;
                    *)
                        ERROR "Invalid value for --backup: $1"
                        __generate_changeflow_help_en
                        exit 1
                        ;;
                esac
            else
                ERROR "Missing value for --backup"
                __generate_changeflow_help_en
                exit 1
            fi
            ;;
        -c|--cur)
            shift
            if [[ "$#" -gt 0 ]]; then
                CURRENT_WORKFLOW=$1
            else
                ERROR "Missing value for -c|--cur"
                __generate_changeflow_help_en
                exit 1
            fi
            ;;
        -t|--target)
            shift
            if [[ "$#" -gt 0 ]]; then
                TARGET_WORKFLOW=$1
            else
                ERROR "Missing value for -t|--target"
                __generate_changeflow_help_en
                exit 1
            fi
            ;;
        --gen-git)
            __generate_changeflow_git
            exit 0
            ;;
        --gen-regfile)
            INFO "Generating regfile for changeflow..."
            __generate_changeflow_regfile
            exit 0
            ;;
        --gen-update)
            __generate_changeflow_git
            __generate_changeflow_regfile
            shift
            ;;
        *)
            if [[ -z "$TARGET_WORKFLOW" ]]; then
                TARGET_WORKFLOW=$1
            elif [[ -z "$CURRENT_WORKFLOW" ]]; then
                CURRENT_WORKFLOW=$1
            else
                ERROR "Unexpected argument: $1"
                __generate_changeflow_help_en
                exit 1
            fi
            ;;
    esac
    shift
done

if [[ "$MODULE_FILE_EXIST" == "no" ]]; then
    exit 1
fi

# 如果只提供了一个参数，则假定当前工作流为 $MODULE
if [[ -n "$TARGET_WORKFLOW" && -z "$CURRENT_WORKFLOW" ]]; then
    CURRENT_WORKFLOW="$MODULE"
fi

# 在这里添加主逻辑
# echo "OPTIONAL_MAKEUP = $OPTIONAL_MAKEUP"
# echo "CURRENT_WORKFLOW = $CURRENT_WORKFLOW"
# echo "TARGET_WORKFLOW = $TARGET_WORKFLOW"

changeflow "$TARGET_WORKFLOW" "$CURRENT_WORKFLOW"
XUVYP
return 0
}
