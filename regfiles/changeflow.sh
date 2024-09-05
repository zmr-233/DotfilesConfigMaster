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

# 项目地址: https://github.com/zmr-233/ChangeFlow/tree/main
ChangeFlowVERSION="2.3"

# ==========加载.libbash函数库==========
source $HOME/libbash/libbash.sh

if [ $? -ne 0 ]; then
    echo "Unable to load libbash library"
    # 提示用户是否进行克隆操作
    read -p "Would you like to automatically clone libbash from GitHub? (y/n) " -n 1 -r
    echo # 添加一个新行

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # 用户同意，执行 git 克隆操作
        echo "Cloning libbash..."
        git clone https://github.com/zmr-233/libbash/ ~/libbash
        if [ $? -ne 0 ]; then
            echo "Error occurred during git clone operation"
            exit 1
        fi
        # 尝试再次加载 libbash
        echo "Attempting to source libbash again..."
        source $HOME/libbash/libbash.sh
        if [ $? -ne 0 ]; then
            echo "Unable to load libbash library after cloning"
            exit 1
        fi
    else
        # 用户不同意克隆操作
        echo "User declined to clone libbash. Exiting..."
        exit 1
    fi
fi

WF=.workflows
PREFIX=wf_
# 用来控制在切换旧工作流的时候是否备份
OPTIONAL_MAKEUP=yes

# 检查是否具有保存价值
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

# 递归删除空目录的函数
recursive_remove_empty_dirs() {
    local dir=$1

    # 检查目录是否存在
    if [[ ! -d $dir ]]; then
        ERROR "Directory '$dir' does not exist."
        return 1
    fi

    # 遍历目录中的所有项
    local empty=true
    for item in "$dir"/* "$dir"/.[!.]* "$dir"/..?*; do
        if [ -e "$item" ]; then
            empty=false
            # 如果是目录，递归调用函数
            if [ -d "$item" ]; then
                recursive_remove_empty_dirs "$item" || return 1
            else
                # 如果找到文件，报错并退出
                ERROR "Non-empty directory found at '$dir'"
                return 1
            fi
        fi
    done

    # 如果目录为空，则删除
    if [ "$empty" = true ]; then
        INFO "Removing empty directory: $dir"
        rmdir "$dir"
    fi
}

# A.保存当前工作流
_changeflow_A(){
    local cur=$1 # 应该来源于外部参数
    [ -z "$cur" ] && ERROR "A: Impossible! NO_CUR_WORKFLOW_NAME!" && exit 1
    
    local SAVEN="${PREFIX}${cur}"
    INFO "===== Check weather save ====="
    local isempty

    source $WF/MODULE.cfg
    if _check_empty_dir init_map "$WF";then
        isempty=yes
    else
        isempty=no
    fi

    if [ -f "MODULE.cfg" ]; then
        INFO "Using MODULE.cfg workflow configuration file."
        source MODULE.cfg
    else
        WARN "The MODULE.cfg file does not exist. Using the default $WF/MODULE.cfg."
        source $WF/MODULE.cfg
    fi

    # 检查部分
    local issave=no
    if [[ $isempty == "no" ]]; then
        if [ -d $WF/$SAVEN ]; then
            WARN "The target workflow $cur already exists!"
            if readReturn "Do you want to overwrite it? (yes/no)"; then
                tarSafe $WF/$SAVEN $WF/backup
                rm -rf $WF/$SAVEN
                issave=yes
            else
                issave=no
                INFO "Skipping overwrite, you can choose another workflow name."
                exit 1
            fi
        else
            issave=yes
        fi
    fi
 
    # 保存部分
    #v1.1修改: 把保存部分单独抽离为一个函数
    #v1.1修改: cflow -s -s/--save 仅保存备份，不切换工作流
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
}

# B.切换到目标工作流
_changeflow_B(){
    local target=$1
    [ -z "$target" ] && ERROR "A: Impossible! NO_TARGET_WORKFLOW_NAME!" && exit 1
    local TARN="${PREFIX}${target}"

    # 切换部分
    #v1.1修改: 4.现在，当目标工作流存在的时候，会使用目标工作流下的MODULE.cfg文件作为工作流配置文件
    #v1.1修改: 5.为了兼容无MODULE.cfg文件的老工作流，仍然使用.workflows下的MODULE.cfg文件作为默认配置文件
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

        if [ -f "$WF/$TARN/MODULE.cfg" ]; then
            INFO "Using $WF/$TARN/MODULE.cfg workflow configuration file."
            source $WF/$TARN/MODULE.cfg
        else
            WARN "The $WF/$TARN/MODULE.cfg file does not exist. Using the default MODULE.cfg."
            source $WF/MODULE.cfg
        fi

        operateMapFiles move workflow_map "$WF/$TARN" "." "$WF/backup"
        # rmdir $WF/$TARN
        # [ -d $WF/$TARN ] && 
        recursive_remove_empty_dirs $WF/$TARN
        [ -d $WF/$TARN ] && rmdir $WF/$TARN

        return 0
    else
        #v1.1修改: 3.现在，当目标工作流不存在的时候，会查看.workflows下是否有MODULE.cfg文件作为默认的工作流配置文件
        source $WF/MODULE.cfg
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

#==============================Main==============================
# 0. cflow <cur> <target> 切换工作流 主函数
change_workflow(){
    local cur=$1
    local target=$2
    if [[ "$1" == "$2" ]];then
        ERROR "Current workflow Target workflow are the same name."
        return 1
    fi
    _changeflow_A $cur # A.保存当前工作流
    _changeflow_B $target # B.切换到目标工作流
}

# 1. cflow --init 初始化.workflows和用于设定的MODULE.cfg文件
init_workflow(){
    if [ ! -d "$WF" ]; then
        mkdir -p $WF
    else
        ERROR "The .workflows folder already exists."
    fi

    if [ ! -f "$WF/MODULE.cfg" ] && [ ! -f "MODULE.cfg" ]; then
        {
            echo "MODULE=NAME_HERE"
            echo "# You need to set the MODULE variable to the name of the current workflow"
            echo ""
            echo "# The workflow_map array defines which files you want to contain in current workflow."
            echo "declare -A workflow_map=("
            echo "    [.]=\"MODULE.cfg\""
            echo "    [vsrc]=\"*\""
            echo "    [csrc]=\"*\""
            echo ")"
            echo ""
            echo "# The init_map array defines which files you want to contain in new workflow."
            echo "declare -A init_map=("
            echo "    [.]=\"Makefile\""
            echo "    [vsrc]=\"*\""
            echo "    [csrc]=\"*\""
            echo "    # init_map does not need to contain MODULE.cfg"
            echo ")"
            echo ""
            echo "# MODULE.cfg is created by changeflow script"
            echo ""
        } > MODULE.cfg
    elif [ -f "$WF/MODULE.cfg" ] && [ ! -f "MODULE.cfg" ];then
        WARN "The MODULE.cfg exists, but $WF/MODULE.cfg does not exist."
        WARN "Quickly use 'cflow --set-init' to set default workflow."
    else
        ERROR "The $WF/MODULE.cfg file already exists."
    fi

    INFO "Modify the files and MODULE.cfg you want to contain in default workflow."
    INFO "After that, use 'cflow --set-init' to set default workflow."
}

# 设定新工作流
# 2. cflow --set-init 设定当前工作流内容为默认工作流(原来的会进行备份)
setinit_workflow(){
    # 1.保存旧的工作流
    if [ -f $WF/MODULE.cfg ]; then
        INFO "Backup previous default workflow..."
        source $WF/MODULE.cfg
        mkdir -p $WF/wf_DEFAULT_FLOW
        operateMapFiles move init_map "$WF" "$WF/wf_DEFAULT_FLOW" "$WF/backup/__set_init"
        tarSafe "$WF/wf_DEFAULT_FLOW" "$WF/backup"
        rm -rf $WF/wf_DEFAULT_FLOW
        rm -f "$WF/backup/__set_init"
    fi
    # 2.将当前文件夹下的文件作为新的默认工作流
    INFO "Setting current workflow as default...(Use current init_map)"
    source MODULE.cfg
    operateMapFiles copy init_map "." "$WF" "$WF/backup"
    {
        echo "MODULE=NULL"
        echo ""
        saveMap workflow_map
        echo ""
        saveMap init_map
        echo ""
    } > $WF/MODULE.cfg
}

# 3. cflow -q -q/--quick 快速切换到最近的工作流
quick_workflow(){
    local cur=$1
    local target=$(list_workflows "LAST")
    if [ -z "$target" ]; then
        ERROR "No workflow found."
        return 1
    fi
    nECHO CYAN_BOLD "Change to: ";nECHO RED_BOLD "$target\n"
    change_workflow $cur $target 
}

# 4. cflow -s -s/--save 仅保存备份，不切换工作流
save_workflow(){
    local cur=$1
    _changeflow_A $cur
    _changeflow_B $cur
}

# 5. cflow -r -r/--restore 恢复备份
restore_workflow(){
    local cur=$1
    local target=$2
    local tarfile=$3
    TAR_ABS_PATH="$(pwd)/$WF/backup/$tarfile"
    # DEBUG "TAR_ABS_PATH=$TAR_ABS_PATH"
    if [ ! -f "$TAR_ABS_PATH" ]; then
        ERROR "The backup file $TAR_ABS_PATH does not exist."
        return 1
    fi
    mkdir -p $WF/__restore
    
    pushd $WF/__restore > /dev/null
    
    tar -xzvf "$TAR_ABS_PATH" > /dev/null
    if [ $? -ne 0 ]; then
        echo "Error: tar command failed."
        popd > /dev/null
        return 1
    fi
    popd > /dev/null
    if [ ! -z $cur ]; then
        _changeflow_A $cur
    else
        WARN "No current workflow name provided.Is it truly empty?"
        if readReturn "Still to save"; then
            WARN "Save as CUR_WORKFLOW"
            _changeflow_A CUR_WORKFLOW
            # tarSafe "$WF/CUR_WORKFLOW" "$WF/backup"
            # rm -rf "$WF/CUR_WORKFLOW"
        fi
    fi


    # 增加不冲突后缀------------------------------------------------
    local suffix=00
    while [[ -d "$WF/${PREFIX}${TARGET_WORKFLOW}_$suffix" ]]; do
        suffix=$(printf "%02d" $((10#$suffix + 1)))
    done
    TARGET_WORKFLOW="${TARGET_WORKFLOW}_$suffix"
    #-------------------------------------------------------------
    mv $WF/__restore/${PREFIX}${target} $WF/${PREFIX}${TARGET_WORKFLOW}
    rm -rf $WF/__restore
    
    _changeflow_B $TARGET_WORKFLOW
}

# 6. cflow --clone <new_workflow> 克隆当前工作流为新的工作流(在创建新工作流的时候很有用)
clone_workflow() {
    local cur=$1
    local target="${cur}_clone"
    local SAVEN="${PREFIX}${cur}"
    local TARN="${PREFIX}${target}"
    _changeflow_A $cur # A.保存当前工作流
    if [ -d "$WF/${PREFIX}${cur}" ]; then # 如果没有，说明可能是被认定为和默认工作流毫无更改
        cp -r "$WF/${PREFIX}${cur}" "$WF/${PREFIX}${target}" # 克隆当前工作流为目标工作流
    fi
    _changeflow_B $target # B.切换到目标工作流
}

# 7. cflow --delete <workflow> 删除工作流
delete_workflow() {
    local cur=$1
    local target=$2
    local DLETE_FLOW_NAME=""

    if [ ! -z $target ]; then
        mv "$WF/${PREFIX}${target}" "$WF/${PREFIX}DELETE_${target}"
        DLETE_FLOW_NAME="${PREFIX}DELETE_${target}"
    elif [ -z $cur ]; then
        cur=CUR_WORKFLOW
        DLETE_FLOW_NAME="${PREFIX}DELETE_${cur}"
        _changeflow_A $cur
    elif [ ! -z $cur ]; then
        cur="DELETE_${cur}"
        DLETE_FLOW_NAME="${PREFIX}${cur}"
        _changeflow_A $cur
    else
        ERROR "Not provid target to --delete"
        return 1
    fi
    
    tarSafe "$WF/$DLETE_FLOW_NAME" "$WF/backup"
    rm -rf "$WF/$DLETE_FLOW_NAME"
}

#==============================用来列表化打印和选择的函数==============================
# 显示/选择工作流工作流信息
# TARGET_WORKFLOW="" 修改
# SELECT_EXETYPE="" 修改
list_workflows() {
    # local WF=".workflows"
    # local PREFIX="wf_"
    local showTYPE=${1:-"ALL"}

    if [[ ! -d $WF ]]; then
        if [[ $showTYPE == "LAST" ]]; then
            echo ""
            return
        else
            ERROR "Directory $WF does not exist."
            return 1
        fi
    fi

    # 按照时间戳排序
    local workflows=($(find "$WF" -type d -name "${PREFIX}*" -printf "%T@ %f\n" | sort -nr | awk '{print substr($2, length("'"$PREFIX"'") + 1)}'))

    # 选择打印模式
    if [[ $showTYPE == "LAST" ]]; then
        echo "${workflows[0]}"
    elif [[ $showTYPE == "ALL" ]]; then
        if [[ ${#workflows[@]} -eq 0 ]]; then
            ERROR "No workflow found."
            return 0
        fi
        nECHO CYAN_BOLD "Sorted by time, you can choose one as target:"
        echo -e "${YELLOW}"
        select choice in "${workflows[@]}"; do
            if [[ -n $choice ]]; then
                TARGET_WORKFLOW=$choice
                SELECT_EXETYPE="change_workflow"
                nECHO CYAN_BOLD "Change to: ";nECHO RED_BOLD "$TARGET_WORKFLOW"
                break
            else
                nECHO RED_BOLD "Invalid choice, please try again."
                echo -e "${YELLOW}"
            fi
        done
        echo -e "${RESET}"
    fi
}

# 显示备份信息
list_backups() {
    local moduleName=$1
    local BACKUP_DIR="$WF/backup"

    if [[ ! -d $BACKUP_DIR ]]; then
        ERROR "Directory $BACKUP_DIR does not exist."
        return 1
    fi

    # 按照时间戳排序
    local backups=($(ls -1 $BACKUP_DIR | sort -r))
    local filtered_backups_A=() # 用于存储原始备份文件名
    local filtered_backups_B=() # 用于存储格式化后的备份信息

    # 处理文件名并进行模块名匹配
    for file in "${backups[@]}"; do
        timestamp="${file%%.*}"
        workflow_name="${file#*.wf_}"
        workflow_name="${workflow_name%%.*}"

        # 模糊匹配模块名
        if [[ ! -d "$BACKUP_DIR/$file" ]] && [[ $workflow_name =~ $moduleName ]]; then
            year=${timestamp:0:4}
            month=${timestamp:4:2}
            day=${timestamp:6:2}
            hour=${timestamp:8:2}
            minute=${timestamp:10:2}
            second=${timestamp:12:2}

            new_format="$year/$month/$day $hour:$minute:$second $workflow_name"
            filtered_backups_A+=("$file")         # 原始备份文件名
            filtered_backups_B+=("$new_format")   # 格式化后的备份信息
        fi
    done

    if [[ ${#filtered_backups_B[@]} -eq 0 ]]; then
        if [[ -z $moduleName ]]; then
            ERROR "No backups found."
        else
            ERROR "No backups found for module '$moduleName'."
        fi
        return 0
    fi

    if [[ -z $moduleName ]]; then
        nECHO CYAN_BOLD "Backups, sorted by time:"
    else
        nECHO CYAN_BOLD "Backups for module '$moduleName', sorted by time:"
    fi
    echo -e "${YELLOW}"
    select choice in "${filtered_backups_B[@]}"; do
        if [[ -n $choice ]]; then
            local index=$REPLY-1 # select命令给出的选项是从1开始的，所以我们需要减去1来得到正确的数组索引
            TARGET_TARFILE="${filtered_backups_A[$index]}" # 直接使用原始备份文件名

            # 解析选择的备份文件格式
            TARGET_WORKFLOW="${choice##* }"
            # 增加不冲突后缀------------------------------------------------
            local suffix=00
            while [[ -d "$WF/${PREFIX}${TARGET_WORKFLOW}_$suffix" ]]; do
                suffix=$(printf "%02d" $((10#$suffix + 1)))
            done
            # TARGET_WORKFLOW="${TARGET_WORKFLOW}_$suffix"
            #-------------------------------------------------------------
            nECHO CYAN_BOLD "Selected: "; nECHO RED_BOLD "$TARGET_TARFILE"
            nECHO CYAN_BOLD "    Restore to: "; nECHO RED_BOLD "${TARGET_WORKFLOW}_$suffix"; nECHO CYAN_BOLD " <==INACCURATE\n"
            nECHO CYAN_BOLD "Due to the current MODULE, the "; nECHO RED_BOLD "$suffix";nECHO CYAN_BOLD " might be added one to avoid conflict.\n"
            
            SELECT_EXETYPE="restore_workflow"
            break
        else
            nECHO RED_BOLD "Invalid choice, please try again."
            echo -e "${YELLOW}"
        fi
    done
    echo -e "${RESET}"
}

#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
#==============================测试相关函数==============================

README_PATH=""
CFLOW_PATH=$(readlink -f "$0")

__test__MODULE_name(){
    if [ ! -z "$README_PATH" ]; then
        echo "" >> $README_PATH
        echo -e "\tSet \`MODULE=$1\`" >> $README_PATH
    fi
    source MODULE.cfg
    {
        echo "MODULE=$1"
        echo ""
        saveMap workflow_map
        echo ""
        saveMap init_map
        echo ""
    } > MODULE.cfg
}
__test_generate_file(){
    __test__MODULE_name "$1"
    rm -rf csrc && rm -rf vsrc
    mkdir csrc && mkdir vsrc
    if [ ! -z "$README_PATH" ]; then
        echo "" >> $README_PATH
        echo -e "\tTouch \`csrc/$1.cpp\` and \`vsrc/$1.v\`" >> $README_PATH
    fi
    echo "Marco Marco..." > csrc/marco.h
    echo "CSRCfile$1 $1" > csrc/$1.cpp
    echo "VSRCfile$1 $1" > vsrc/$1.v
}
__test_eval_CMD(){

    while [[ "1" -gt 0 ]]; do
        readLine CMDLINE "请输入需要执行的指令"
        clear
        if [[ $CMDLINE == "EXIT" ]]; then
            echo "cd $(pwd)"
            exit 0
        elif [[ $CMDLINE == "TREE" ]]; then
            tree -a -L 4
        elif [[ $CMDLINE == "RET" ]]; then
            return 0
        else
            eval "CFL=\"bash $HOME/.changeflowrc\" && $CMDLINE"
        fi
    done
}
__test_CMD(){
    if [ ! -z "$README_PATH" ]; then
        if [[ "$2" == "Makefile" ]] || [[ "$2" == "bash" ]] ;then
            local tree_result=$1
            tree_result=$(echo -e "$tree_result" | awk '{print "\t" $0}')
            echo "" >> $README_PATH
            echo -e "\t\`\`\`$2" >> $README_PATH
            echo "$tree_result" >> $README_PATH
            echo -e "\t\`\`\`" >> $README_PATH
        else
            local tree_result=$($@)
            tree_result=$(echo -e "$tree_result" | awk '{print "\t" $0}')
            echo "" >> $README_PATH
            echo -e "\t\`\`\`bash" >> $README_PATH
            echo "$tree_result" >> $README_PATH
            echo -e "\t\`\`\`" >> $README_PATH
        fi
    fi
}
__test_tree(){
    local dep=("-a" "-L" "${1:-3}" "-I" "${2:-backup}")
    if [ ! -z "$README_PATH" ]; then
        local total_lines=$(tree "${dep[@]}" | wc -l)
        local start_line=2 # 因为下标从0开始，所以第1行实际上是第2行
        local end_line=$((total_lines - 2)) # 去掉最后3行
        local tree_result=$(tree "${dep[@]}" | head -n $end_line | tail -n +$start_line)
        tree_result=$(echo -e "$tree_result" | awk '{print "\t" $0}')
        echo "" >> $README_PATH
        echo -e "\t\`\`\`bash" >> $README_PATH
        if [ -f MODULE.cfg ];then
            local MODULE____=$(awk -F '=' '/^MODULE=/{print $$2}' MODULE.cfg)
            echo -e "\t==> $MODULE____ <==" >> $README_PATH
        else
            echo -e "\tNO_CURRENT_MODULE" >> $README_PATH
        fi
        echo "$tree_result" >> $README_PATH
        echo -e "\t\`\`\`" >> $README_PATH

        # 仍然打印
        # tree "${dep[@]}"
    else
        tree "${dep[@]}"
        if readReturn "是否通过测试?";then
            clear
            SUCCESS "...........继续测试..........."
        else
            __test_eval_CMD
        fi
    fi
}

DCNT=0
___________________DEBUG(){
    ((DCNT++))
    if [ ! -z "$README_PATH" ]; then
        echo "" >> $README_PATH
        echo "${DCNT}. **$1**" >> $README_PATH   
    fi
    DEBUG "=======$1=======" 
}
___________________INFO(){
    if [ ! -z "$README_PATH" ]; then
        echo "" >> $README_PATH
        echo -e "\t$1" >> $README_PATH
    else
        if [[ "$2" == "y" ]];then
            DEBUG "+++ $1"
        fi
    fi
}

# 生成测试
CFLOWN(){
    if [ ! -z "$README_PATH" ]; then
        echo "" >> $README_PATH
        echo -e "\tCommand : \`cflow $@\`" >> $README_PATH
    fi
    bash $CFLOW_PATH $@
}

# 生成测试
__generate_changeflow_test(){
    local TDIR=$(mktemp -d -t CHANGEFLOW_XXXXXX) 
    chmod +x $HOME/.changeflowrc
# local RDIR=$(mktemp -d -t CHANGEFLOW_XXXXXX)
# local RDIR="/tmp/CHANGEFLOW_JjDeQS/"
# README_PATH="$RDIR/README.md"
# [ ! -z "$README_PATH" ] && echo "" > README_PATH
DEBUG '==================测试开始=================='
pushd $TDIR > /dev/null
[ -z "$README_PATH" ] && INFO "cd $(pwd)"
#==============================================================================
___________________DEBUG "cflow --init初始化.workflows"
___________________INFO '创建了一个MODULE.cfg的模板文件和一个空文件夹' "y"
CFLOWN "--init"
__test_tree
#==============================================================================
___________________DEBUG "cflow --set-init 设定默认工作流"
___________________INFO "创建你每次创建新工作流都会自带的默认文件(比如头文件之类)，然后在\`MODULE.cfg\`中设定相应的映射\`init_map\`" "y"
___________________INFO "比如此处创建两个文件并修改模块名称:"
___________________INFO "Touch \`csrc/marco.h\`, \`vsrc/TEMPLATE.v\` and \`Makefile\`"
mkdir csrc && mkdir vsrc
echo "Marco Marco..." > csrc/marco.h
echo "ALU ALU..." > vsrc/TEMPLATE.v
___________________INFO "其中让你不得不使用cflow的，可能是因为你在Makefile里需要固定编译的目录，更有可能是一个每次都必须要手动更改的变量；但是现在你可以用如下命令，让你的Makefile去MODULE.cfg中查找它需要的变量："
echo "MODULE := \$(shell awk -F '=' '/^MODULE=/{print \$\$2}' MODULE.cfg)" > Makefile
__test_CMD "MODULE := \$(shell awk -F '=' '/^MODULE=/{print \$\$2}' MODULE.cfg)" "Makefile"
___________________INFO "于是\`MODULE.cfg\`就要按照如上文件目录填写 \`--set-init\`，键为目录，值为文件名(用空格分隔)，也可以填写*符号代表所有文件:"
__test_CMD 'cat MODULE.cfg'
___________________INFO "接着执行 \`--set-init\`参数，该参数将按照\`init_map\`把对应文件复制到\`.workflows\`文件夹下作为真正的默认文件"
CFLOWN "--set-init"
__test_tree
#==============================================================================
___________________DEBUG "cflow A/B 基础切换工作流功能"
___________________INFO "这是cflow的基础功能，用于快速在不同的工作流之间切换" "y"
___________________INFO "比如初始化如下两个工作流\`A_v0\`和\`B\`；首先设置工作流A_v0的文件:"
__test_generate_file "A_v0"
__test_tree 2
___________________INFO "现在我需要一个新工作流\`B\`，可以直接输入如下指令进行切换："
CFLOWN "B"
___________________INFO "可以看到\`A_v0\`工作流被存储了起来，由于存储中并没有\`B\`，这里使用默认文件进行创建了"
__test_tree 4
___________________INFO "在工作流\`B\`中，修改/增加了不少文件，同时不要忘记修改模块名称："
__test__MODULE_name "B"
___________________INFO "Touch \`csrc/B.cpp\` 、\`csrc/Just_for_fun.h\` and \`vsrc/B.v\`"
echo "Just_for_fun" > csrc/Just_for_fun.cpp
echo "CSRCfile" > csrc/B.cpp
echo "VSRCfile" > vsrc/B.v
___________________INFO "现在的目录结构如下："
__test_tree 2
___________________INFO "如果我需要切换回\`A_v0\`工作流，可以直接输入如下指令进行切换："
CFLOWN "A"
___________________INFO "可以看到\`B\`工作流被存储，\`A_v0\`工作流被恢复"
__test_tree 4
#==============================================================================
___________________DEBUG "cflow -l / --list 交互式列出所有历史工作流"
___________________INFO "如果你有很多工作流，可以用\`-l\`参数列出所有历史工作流，并直接用序号选择目标工作流" "y"
___________________INFO "Command : \`cflow -l\`"
__test_CMD "Sorted by time, you can choose one as target:\n1) top                  6) alu32b             11) mux41b\n2) Map_Scan2ASCII_NV    7) testseg            12) adder\n3) LSFR_seg             8) decode24           13) top\n#? 3\nChange to: LSFR_seg" "bash"
#==============================================================================
___________________DEBUG 'cflow -q / --quick 快速切换到最近工作流'
___________________INFO "如果你需要反复在最近两个工作流之间来回切换，可以使用\`-q\`参数，这里我们又从\`B\`快速切回来\`A_v0\`工作流" "y"
CFLOWN -q
__test_tree 2
#==============================================================================
___________________DEBUG 'cflow --clone 克隆当前工作流'
___________________INFO "如果你需要克隆当前工作流(相当于git创建新分支)，那么仅仅需要--clone参数即可" "y"
CFLOWN --clone
___________________INFO "你可以看到\`wf_B\`中的文件和当前的完全相同，但是请注意，此时我们还没修改MODULE=B，意味着有同名情况"
__test_tree 4
#==============================================================================
___________________DEBUG '测试A: 完全同名覆盖问题'
___________________INFO "不修改当前的MODULE.cfg，如果直接cflow B，会发生同名覆盖问题；你会看到报错，但cflow什么也不会做，你不用担心文件丢失" "y"
CFLOWN B
__test_CMD "[ERROR] Current workflow Target workflow are the same name." "bash"
#==============================================================================
___________________DEBUG '测试B: 可选覆盖问题'
___________________INFO "从刚才可知，自己切换到自己非常愚蠢，不被允许；可是在.workflows/wf_B同名的情况下，切换到\`A_v0\`，按照逻辑，为了保存当前工作流，会使得.workflows/wf_B被覆盖造成文件丢失吗？"
___________________INFO "为了更加直观，进行一些修改，并尝试切换到\`A_v0\`："
___________________INFO "Touch \`csrc/B_over.cpp\` and \`vsrc/B_over.v\`"
rm -rf csrc && rm -rf vsrc
mkdir csrc && mkdir vsrc
echo "CSRCfile" > csrc/B_over.cpp
echo "VSRCfile" > vsrc/B_over.v
__test_tree 4
echo "y" | CFLOWN A_v0
___________________INFO "弹出了警告，询问你是否需要覆盖.workflows/wf_B；如果选择y，就能看到.workflows/wf_B已经被覆盖了，同时工作流\`A_v0\`被恢复"  "y"
__test_CMD "[WARNING] The target workflow B already exists!\n==INPUT==Do you want to overwrite it? (yes/no) [y/n] default: y\nyes" "bash"
__test_tree 4
#==============================================================================
___________________DEBUG 'cflow -c B_over -t A_v0 区分 工作流名称 && MODULE=xxx'
___________________INFO "其实你有另外的办法让两个B共存，现在我可以告诉你————__**工作流名称 和 MODULE=xxx 实际上毫不相干**__"
___________________INFO "只是为了方便，我让绝大多数时候工作流名称都直接等于\`MODULE.cfg\`其中定义的\`MODULE=xxx\`；于是你可以用其他命令行参数设置工作流名称"
__test_CMD "$ cflow A_v0 B_over # 基于位置：第一个默认是目标工作流名称，第二个是当前工作流名称 \n$ cflow -c B_over -t A_v0 # 基于命令行参数 \n$ cflow --cur B_over --target A_v0 # 基于命令行参数" "bash"
___________________INFO "这里快速用A_v0来克隆并进行测试，并尝试把\`B\`工作流切换出来:" "y"
CFLOWN --clone
CFLOWN -c A_over -t B
__test_tree 4
___________________INFO "可以看到两个有着完全相同MODULE的工作流同时存储了，用cat可以查看"
__test_CMD "$ cat .workflows/wf_A_v0/MODULE.cfg | head -n 1\nMODULE=A_v0\n$ cat .workflows/wf_A_over/MODULE.cfg | head -n 1\nMODULE=A_v0" "bash"
#==============================================================================
___________________DEBUG 'cflow --delete <可选> 删除工作流'
___________________INFO "如果你需要删除\`A_over\`工作流的一切，可以--delete参数"  "y"
CFLOWN --delete A_over
___________________INFO "可以看到\`wf_A_over\`已经消失了"
__test_tree 2
___________________INFO "如果你需要删除当前工作流的一切，可以："
CFLOWN --delete
___________________INFO "可以看到当前目录里按照\`workflow_map\`映射的文件/文件夹已经消失了"
__test_tree 2
#==============================================================================
___________________DEBUG 'cflow -r / --restore <可选模糊匹配> 恢复备份'
___________________INFO "在之前的所有高危险操作中，包括删除/覆盖/移动等，其实都进行了备份，并被存储为.tar.gz文件，位于backup文件夹下" "y"
__test_tree 4 y
___________________INFO "如果你需要恢复，可以使用\`-r\`参数交互选择，并可能看到如下列表"
___________________INFO "Command : \`cflow -r\`"
__test_CMD  "Backups, sorted by time: \n1) 2024/09/05 05:34:26 B \n2) 2024/09/05 05:34:26 B_clone \n3) 2024/09/05 05:34:27 A_v0 \n4) 2024/09/05 05:34:27 A_v0_clone \n5) 2024/09/05 05:34:27 B \n6) 2024/09/05 05:34:27 DELETE_A_over \n7) 2024/09/05 05:34:27 DELETE_B \n#? Selected: 20240905053426.wf_B.tar.gz    Restore to: B_00 <==INACCURATE \nDue to the current MODULE, the 00 might be added one to avoid conflict." "bash"
___________________INFO "如果你需要恢复，也可以使用\`-r B\`限定模糊匹配只与B相关的，并可能看到如下列表"
echo -e "1\nn\n" | CFLOWN -r B
__test_CMD "Backups for module 'B', sorted by time: \n1) 2024/09/05 05:44:32 B \n2) 2024/09/05 05:44:32 B_clone \n3) 2024/09/05 05:44:33 B \n4) 2024/09/05 05:44:33 DELETE_B \n#? Selected: 20240905054432.wf_B.tar.gz    Restore to: B_00 <==INACCURATE \nDue to the current MODULE, the 00 might be added one to avoid conflict.  " "bash"
___________________INFO "这里直接选择恢复工作流\`B\`，然后被删除的工作流就又回来了"
__test_tree 4 y
#==============================================================================
___________________DEBUG 'cflow -s / --save 仅保存备份不切换目录'
___________________INFO "该命令可以看作是\`cflow --clone\`的新版本，但是区别是\`--save\`不会占用.workflows文件夹，而是直接打包成.tar.gz在\`backup\`文件夹中"  "y"
CFLOWN -s
___________________INFO "可以看到现在有两个时间戳的\`B\`，最新的那个是刚刚保存的"
__test_tree 4 y
#==============================================================================
___________________DEBUG 'cflow --clean-backup 删除备份目录'
___________________INFO "__**警告：删除备份目录意味着再也无法恢复，这也是作为最后一个介绍的参数的原因**__" "y"
___________________INFO "可能后面的版本会使用时间戳过滤删除较为久远的备份，不过现在只能一次性删除"

# DEBUG "cd $TDIR" && DEBUG "code $RDIR/README.md" && exit 0 # 比较方便的调试
# ___________________DEBUG ''
# ___________________DEBUG ''
# __test_eval_CMD
# INFO "cd $(pwd)"
# [ ! -z "$README_PATH" ] && DEBUG "code $RDIR/README.md"
popd > /dev/null
SUCCESS '==================测试结束=================='
}

#==============================生成相关函数=============================

# 用来生成README.md
__generate_changeflow_readme(){

cat << EOF
# ChangeFlow / cflow $ChangeFlowVERSION Document
EOF
cat << 'EOF'

changeflow | cflow 是一个用于轻松切换和管理工作流的脚本工具，它介于手动管理和 git 管理之间，虽然提供了一种轻量化的解决方案，但却功能完备实用性强。

## 安装方法(以bash为例)

1. 克隆项目 `git clone https://github.com/zmr-233/changeflow ~/changeflow`
2. 设置别名 `echo -e " alias changeflow='bash ~/.changeflowrc';\n alias cflow=changeflow;" >> ~/.bashrc`
3. 重载终端 `source ~/.bashrc`
4. 正常使用 `cflow -h`

## 命令行选项

- `-h, --help [lang]`           **显示帮助信息 (default: en, support: en, zh)**
- `--init`                      **初始化.workflows文件夹和MODULE.cfg文件**
- `--set-init`                  **将当前工作流设置为默认工作流**
- `-c, --cur [名称]`            **指定当前工作流的名称**
- `-t, --target [名称]`         **指定要切换到的目标工作流**
- `-l, --list`                  **列出所有历史工作流**
- `-q, --quick`                 **快速切换到最后一个工作流**
- `--clone [新名称]`            **克隆当前工作流为新的工作流**
- `-s, --save`                  **保存当前工作流而不切换**
- `-r, --restore [名称]`        **恢复指定工作流的备份**
- `--backup [值]`               **使用指定的方法备份当前工作流**
    - `yes`                     **备份（默认行为）**
    - `no`                      **不进行备份**
    - `tar`                     **以tar文件形式备份**
    - `folder`                  **以文件夹形式备份**
- `--delete [名称]`             **删除指定的工作流**
- `--clean-backup`              **清除所有备份文件**

## 详细使用步骤
EOF

local RDIR=$(mktemp -d -t CHANGEFLOW_XXXXXX)
# local RDIR="/tmp/CHANGEFLOW_JjDeQS/"
README_PATH="$RDIR/README.md"
[ ! -z "$README_PATH" ] && echo "" > $README_PATH

__generate_changeflow_test &> /dev/null

cat $README_PATH
cat << 'EOF'

## 其他说明

除了上述用法之外，提供了一些额外的功能，方便上传/配置/整理等操作，其中有`[zmr233]`标记则表明不应该去动它

- `--test` 生成并进行交互性测试
- `--gen-readme` 生成README.md(标准输出)
- [zmr233]`--gen-regfile` 生成regfiles配置文件(读取libbash的DOTFILES_CONFIG_MASTER_HOME变量)
- [zmr233]`--gen-git` 生成git提交的脚本(直接git push到Github)
- [zmr233]`--gen-update` 实际上是--gen-regfile和--gen-git的合并命令

## 许可证

本项目采用 MIT 许可证。详情请见 [LICENSE](LICENSE) 文件。

EOF
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

cat << 'EOF' > LICENSE
MIT License

Copyright (c) [2024] [zmr233]

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOF

cat << 'EOF' > ADD_TO_BASHRC_ZSHRC.sh
# Add the following line to your .bashrc or .zshrc file
# Alias for changeflow
alias changeflow='bash ~/.changeflowrc'
alias cflow=changeflow
EOF
    git add -A
    git commit -m "Update changeflow in $ChangeFlowVERSION"
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
    ECHO "YELLOW_BOLD" "Usage: ${BLUE_BOLD}changeflow|cflow${RESET} [options]"
    echo ""
    ECHO "YELLOW_BOLD" "Examples:"
    ECHO "GREEN" "    changeflow foo            # Switch to foo workflow, save current as MODULE"
    ECHO "GREEN" "    changeflow foo bar        # Switch to foo workflow, save current as bar"
    ECHO "GREEN" "    changeflow -t foo -c bar  # Switch to foo workflow, save current as bar"
    echo ""
    ECHO "YELLOW_BOLD" "Options:"
    nECHO "GREEN" "  -h, --help [lang]    "; ECHO "RESET" "Show help information (default: en, support: en, zh)"
    nECHO "GREEN" "  --init               "; ECHO "RESET" "Initialize .workflows folder and MODULE.cfg file"
    nECHO "GREEN" "  --set-init           "; ECHO "RESET" "Set the current workflow as the default"
    nECHO "GREEN" "  -c, --cur [name]     "; ECHO "RESET" "Specify the name of the current workflow"
    nECHO "GREEN" "  -t, --target [name]  "; ECHO "RESET" "Specify the target workflow to switch to"
    nECHO "GREEN" "  -l, --list           "; ECHO "RESET" "List all historical workflows"
    nECHO "GREEN" "  -q, --quick          "; ECHO "RESET" "Quickly switch to the last workflow"
    nECHO "GREEN" "  --clone [new_name]   "; ECHO "RESET" "Clone the current workflow as a new workflow"
    nECHO "GREEN" "  -s, --save           "; ECHO "RESET" "Save the current workflow without switching"
    nECHO "GREEN" "  -r, --restore [name] "; ECHO "RESET" "Restore the backup of the specified workflow"
    nECHO "GREEN" "  --backup [value]     "; ECHO "RESET" "Backup the current workflow with the specified method"
    nECHO "GREEN" "      yes              "; ECHO "RESET" "Backup (default behavior)"
    nECHO "GREEN" "      no               "; ECHO "RESET" "Do not backup"
    nECHO "GREEN" "      tar              "; ECHO "RESET" "Backup as tar file"
    nECHO "GREEN" "      folder           "; ECHO "RESET" "Backup as folder"
    nECHO "GREEN" "  --delete [name]      "; ECHO "RESET" "Delete the specified workflow"
    nECHO "GREEN" "  --clean-backup       "; ECHO "RESET" "Clean all backup files"
    echo ""
    ECHO "YELLOW_BOLD" "Advanced options (for development use):"
    nECHO "GREEN" "  --test               "; ECHO "RESET" "Generate a test for changeflow"
    nECHO "GREEN" "  --gen-readme         "; ECHO "RESET" "Generate README.md for changeflow (stdout)"
    nECHO "GREEN" "  --gen-git            "; ECHO "RESET" "Generate git submit/push for changeflow"
    nECHO "GREEN" "  --gen-regfile        "; ECHO "RESET" "Generate regfile for changeflow"
    nECHO "GREEN" "  --gen-update         "; ECHO "RESET" "Generate update for changeflow"
}

# 显示中文帮助信息
__generate_changeflow_help_zh() {
    ECHO "YELLOW_BOLD" "Usage: ${BLUE_BOLD}changeflow|cflow${RESET} [options]"
    echo ""
    ECHO "YELLOW_BOLD" "Examples:"
    ECHO "GREEN" "    changeflow foo            # 切换到foo工作流，将当前保存为MODULE"
    ECHO "GREEN" "    changeflow foo bar        # 切换到foo工作流，将当前保存为bar"
    ECHO "GREEN" "    changeflow -t foo -c bar  # 切换到foo工作流，将当前保存为bar"
    echo ""
    ECHO "YELLOW_BOLD" "Options:"
    nECHO "GREEN" "  -h, --help [lang]    "; ECHO "RESET" "显示帮助信息 (default: en, support: en, zh)"
    nECHO "GREEN" "  --init               "; ECHO "RESET" "初始化.workflows文件夹和MODULE.cfg文件"
    nECHO "GREEN" "  --set-init           "; ECHO "RESET" "将当前工作流设置为默认工作流"
    nECHO "GREEN" "  -c, --cur [名称]     "; ECHO "RESET" "指定当前工作流的名称"
    nECHO "GREEN" "  -t, --target [名称]  "; ECHO "RESET" "指定要切换到的目标工作流"
    nECHO "GREEN" "  -l, --list           "; ECHO "RESET" "列出所有历史工作流"
    nECHO "GREEN" "  -q, --quick          "; ECHO "RESET" "快速切换到最后一个工作流"
    nECHO "GREEN" "  --clone [新名称]     "; ECHO "RESET" "克隆当前工作流为新的工作流"
    nECHO "GREEN" "  -s, --save           "; ECHO "RESET" "保存当前工作流而不切换"
    nECHO "GREEN" "  -r, --restore [名称] "; ECHO "RESET" "恢复指定工作流的备份"
    nECHO "GREEN" "  --backup [值]        "; ECHO "RESET" "使用指定的方法备份当前工作流"
    nECHO "GREEN" "      yes              "; ECHO "RESET" "备份（默认行为）"
    nECHO "GREEN" "      no               "; ECHO "RESET" "不进行备份"
    nECHO "GREEN" "      tar              "; ECHO "RESET" "以tar文件形式备份"
    nECHO "GREEN" "      folder           "; ECHO "RESET" "以文件夹形式备份"
    nECHO "GREEN" "  --delete [名称]      "; ECHO "RESET" "删除指定的工作流"
    nECHO "GREEN" "  --clean-backup       "; ECHO "RESET" "清除所有备份文件"
    echo ""
    ECHO "YELLOW_BOLD" "Advanced options (for development use):"
    nECHO "GREEN" "  --test               "; ECHO "RESET" "生成测试"
    nECHO "GREEN" "  --gen-readme         "; ECHO "RESET" "生成README.md (标准输出)"
    nECHO "GREEN" "  --gen-git            "; ECHO "RESET" "生成git提交/推送"
    nECHO "GREEN" "  --gen-regfile        "; ECHO "RESET" "生成注册文件"
    nECHO "GREEN" "  --gen-update         "; ECHO "RESET" "生成更新"
}
#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
#==========================================全局变量================================================
# 默认值
# OPTIONAL_MAKEUP="tar"

SELECT_EXETYPE="" # 函数名称

CURRENT_WORKFLOW=""
TARGET_WORKFLOW=""
TARGET_TARFILE="" # 用来处理备份的tar文件名

ARGS_CNT=$#
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -h|--help|-help|-h=en|--help=en|-help=en)
            __generate_changeflow_help_en
            exit 0
            ;;
        -h=zh|--help=zh|-help=zh)
            __generate_changeflow_help_zh
            exit 0
            ;;
        -h=*|--help=*|-help=*)
            ERROR "Invalid language for help: ${1#*=}"
            exit 1
            ;;
        -l|--list|-list)
            INFO "Listing all historical workflows ..."
            if [ -f MODULE.cfg ]; then
                ____MODULE=$(awk -F '=' '/^MODULE=/{print $2}' MODULE.cfg)
                nECHO YELLOW "======> " ; nECHO GREEN_BOLD "$____MODULE";  nECHO YELLOW " <======\n"
            fi
            list_workflows
            [ -z $SELECT_EXETYPE ] && exit 0
            ;;
        --backup|-backup)
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
        -c|--cur|-cur)
            shift
            if [[ "$#" -gt 0 ]]; then
                CURRENT_WORKFLOW=$1
            else
                ERROR "Missing value for -c|--cur"
                __generate_changeflow_help_en
                exit 1
            fi
            ;;
        -t|--target|-target)
            shift
            if [[ "$#" -gt 0 ]]; then
                TARGET_WORKFLOW=$1
            else
                ERROR "Missing value for -t|--target"
                __generate_changeflow_help_en
                exit 1
            fi
            ;;
        #v1.1修改: B.快捷操作
        #v1.1修改: 6. cflow -q -q/--quick 快速切换到最近的工作流
        -q|--quick|-quick)
            INFO "Quickly switch to the last workflow..."
            SELECT_EXETYPE="quick_workflow"
            ;;
        #v1.1修改: 7. cflow -s -s/--save 仅保存备份，不切换工作流
        -s|--save|-save)
            INFO "Saving the current workflow..."
            SELECT_EXETYPE="save_workflow"
            ;;
        #v1.1修改: 5. cflow -r -r/--restore 恢复备份
        -r|--restore|-restore)
            shift
            INFO "Restoring the backup..."
            if [[ "$#" -gt 0 ]]; then
                list_backups $1
            else
                list_backups
            fi
            SELECT_EXETYPE="restore_workflow"
            ;;
        # 6. cflow --clone <new_workflow> 克隆当前工作流为新的工作流
        --clone|-clone)
            INFO "Cloning the current workflow..."
            SELECT_EXETYPE="clone_workflow"
            ;;
        #v1.1修改: D.创建/设定新工作流
        #v1.1修改: 9. cflow --init 初始化.workflows和用于设定的MODULE.cfg文件
        --init|-init)
            INFO "Initializing .workflows folder..."
            init_workflow
            exit 0
            ;;
        --set-init|-set-init)
            INFO "Setting current workflow as default..."
            setinit_workflow
            exit 0
            ;;
        #v1.1修改: 7. cflow --delete <name> 删除工作流
        --delete|-delete)
            INFO "Deleting the workflow..."
            SELECT_EXETYPE="delete_workflow"
            ;;
        #v1.1修改: 8. cflow --clean-backup 列出所有工作流
        --clean-backup)
            WARN "Cleaning all backups..."
            if readReturn "You are deleting all backups!" ; then
                rm -rf $WF/backup
            fi
            exit 0
            ;;
        #v1.1修改: C.生成测试
        --test|-test)
            INFO "Generating test for changeflow..."
            __generate_changeflow_test
            exit 0
            ;;
        # ___________________下面的参数不要放入help中___________________
        --gen-readme)
            INFO "Generating README.md for changeflow..."
            __generate_changeflow_readme
            exit 0
            ;;
        # v1.1修改: 10. cflow --set-init 设定当前工作流内容为默认工作流原来的会进行备份
        --gen-git)
            INFO "Generating git submit/push(Github) for changeflow..."
            __generate_changeflow_git
            exit 0
            ;;
        --gen-regfile)
            INFO "Generating regfile for changeflow..."
            __generate_changeflow_regfile
            exit 0
            ;;
        --gen-update)
            INFO "Generating update(Github/regfiles) for changeflow..."
            __generate_changeflow_git
            __generate_changeflow_regfile
            exit 0
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

#v1.1：9. cflow --init 初始化.workflows和用于设定的MODULE.cfg文件
# 检查是否存在.workflows文件夹 
if [ ! -d "$WF" ]; then
    ECHO CYAN_BOLD "==============================================================================="
    nECHO RED_BOLD "The .workflows folder does not exist.! Please run '"; nECHO CYAN_BOLD "changeflow --init"; nECHO RED_BOLD "' to initialize it."
    ERROR "Use changeflow -h to get help."
    ERROR "But I think you need to run changeflow --readme to learn how to use it."
    ECHO CYAN_BOLD "==============================================================================="
    exit 1
elif [ ! -f "$WF/MODULE.cfg" ]; then
    ECHO CYAN_BOLD "==============================================================================="
    nECHO RED_BOLD "The $WF/MODULE.cfg file does not exist.! Please run '"; nECHO CYAN_BOLD "changeflow --set-init"; nECHO RED_BOLD "' to initialize it."
    ERROR "Use changeflow -h to get help."
    ERROR "But I think you need to run changeflow --readme to learn how to use it."
    ECHO CYAN_BOLD "==============================================================================="
    exit 1
fi


if [ -z "$CURRENT_WORKFLOW" ] && [ ! -f MODULE.cfg ];then
    # 如下两个函数允许在没有MODULE.cfg文件的情况下，直接切换工作流
    if [[ "$SELECT_EXETYPE" != "delete_workflow" ]] && [[ "$SELECT_EXETYPE" != "restore_workflow" ]]; then
        ECHO CYAN_BOLD "==============================================================================="
        nECHO RED_BOLD "The MODULE.cfg file does not exist.!"
        nECHO RED_BOLD "Use -c <name> to set the current workflow name, or define MODULE.cfg file."
        ERROR "Use changeflow -h to get help."
        ERROR "But I think you need to run changeflow --readme to learn how to use it."
        ECHO CYAN_BOLD "==============================================================================="
        exit 1
    fi
elif [ -z "$CURRENT_WORKFLOW" ] && [ -f MODULE.cfg ]; then
    source MODULE.cfg
    CURRENT_WORKFLOW="$MODULE"
fi

# 解析命令行选项
if [[ $ARGS_CNT -eq 0 ]]; then
    ERROR "No arguments provided."
    __generate_changeflow_help_en
    exit 0
fi

# 重新设计此处逻辑
# if [[ "$MODULE_FILE_EXIST" == "no" ]]; then
#     exit 1
# fi

# # 如果只提供了一个参数，则假定当前工作流为 $MODULE
# if [[ -n "$TARGET_WORKFLOW" && -z "$CURRENT_WORKFLOW" ]]; then
#     CURRENT_WORKFLOW="$MODULE"
# fi

#==========================================执行对应函数==========================================
if [ -z "$SELECT_EXETYPE" ]; then
    SELECT_EXETYPE="change_workflow"
fi
# DEBUG "$SELECT_EXETYPE $CURRENT_WORKFLOW $TARGET_WORKFLOW $TARGET_TARFILE"
$SELECT_EXETYPE "$CURRENT_WORKFLOW" "$TARGET_WORKFLOW" "$TARGET_TARFILE"
if [[ $? -ne 0 ]]; then
    ERROR "$SELECT_EXETYPE $CURRENT_WORKFLOW $TARGET_WORKFLOW $TARGET_TARFILE =====FAILED====="
    exit 1
fi
XUVYP
return 0
}
