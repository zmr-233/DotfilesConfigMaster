#!/bin/bash

# VERSION: 1

libbash_info(){
    echo "是zmr封装了大量实用bash函数的脚本库"
}

libbash_deps(){
    echo "__predeps__ zsh"
}

libbash_check(){
    checkCfg "$HOME/libbash"
    return $?
}

libbash_install(){
genSignS "libbash" $INSTALL
cat << 'EOF' >> $INSTALL
MODULE_INFO "......正在安装libbash......"
INFO "libbash是无需安装的bash函数库"
EOF
genSignE "libbash" $INSTALL
}

libbash_config(){
# 加入配置文件更新映射
declare -A config_map=(
    ["."]=".zshrc"
    ["libbash"]="libbash.sh array_utils.sh color_utils.sh file_utils.sh input_utils.sh others_utils.sh regfile_template.sh safe_utils.sh"
)

add_configMap config_map

# 配置文件 ./.zshrc 
genSignS proxy $TEMP/./.zshrc
cat << 'EOF' >> $TEMP/./.zshrc
# libbash库函数位置
export LIBBASH_HOME="~/libbash"

EOF
genSignE proxy $TEMP/./.zshrc

# 配置文件 libbash/libbash.sh
cat << 'PPAP' >> $TEMP/libbash/libbash.sh
#!/bin/bash

# 方案来源:
# https://stackoverflow.com/questions/2683279/how-to-detect-if-a-script-is-being-sourced
# 检测自身是否被source
(return 0 2>/dev/null) && LIBBASH_SOURCED="yes" || LIBBASH_SOURCED="no"

# 注意: 该变量是DotfilesConfigMaster的环境变量，应该由DotfilesConfigMaster设置
DOTFILES_CONFIG_MASTER_HOME=$HOME/DotfilesConfigMaster

# LIBBASH_HOME=$HOME/libbash # 用于存储libbash目录的路径

libfiles=() # 用于存储libbash目录下的所有文件名

# 检查环境变量LIBBASH_HOME是否已设置并且目录是否存在
if [ -z "$LIBBASH_HOME" ] || [ ! -d "$LIBBASH_HOME" ]; then
    # echo "LIBBASH_HOME is not set or directory does not exist"
    # echo "BASH_SOURCE[0] = ${BASH_SOURCE[0]}"
    LIBBASH_HOME=$(readlink -f $(dirname "${BASH_SOURCE[0]}"))
fi

# echo "LIBBASH_HOME: $LIBBASH_HOME" && exit 0

# 加载所有文件
for file in "$LIBBASH_HOME"/*; do
    fileName=$(basename "$file")
    if [[ "$fileName" == "libbash.sh" ]] || [[ "$fileName" == "README.md" ]] ; then
        continue
    fi
    # source "$file" # 不能使用source，否则会导致所有函数都被加载
    libfiles+=("$fileName")
done

# 打印数组内容
# INFO "libfiles in LIBBASH_HOME:"
# for filename in "${libfiles[@]}"; do
#     DEBUG "$filename"
# done
__generate_libbash_regfile() {
    if [ -z "$DOTFILES_CONFIG_MASTER_HOME" ]; then
        echo "DOTFILES_CONFIG_MASTER_HOME is not set"
        exit 1
    fi
    local TARGET="$DOTFILES_CONFIG_MASTER_HOME/regfiles/libbash.sh"
cat << 'XXMN' > $TARGET
#!/bin/bash

# VERSION: 1

libbash_info(){
    echo "是zmr封装了大量实用bash函数的脚本库"
}

libbash_deps(){
    echo "__predeps__ zsh"
}

libbash_check(){
    checkCfg "$HOME/libbash"
    return $?
}

libbash_install(){
genSignS "libbash" $INSTALL
cat << 'EOF' >> $INSTALL
MODULE_INFO "......正在安装libbash......"
INFO "libbash是无需安装的bash函数库"
EOF
genSignE "libbash" $INSTALL
}

XXMN

# 使用printf来安全地处理数组元素，确保每个元素被正确引用
local strLibfiles="${libfiles[*]}"
cat << XXMN >> $TARGET
libbash_config(){
# 加入配置文件更新映射
declare -A config_map=(
    ["."]=".zshrc"
    ["libbash"]="libbash.sh ${strLibfiles}"
)

add_configMap config_map

XXMN

cat << 'XXMN' >> $TARGET
# 配置文件 ./.zshrc 
genSignS proxy $TEMP/./.zshrc
cat << 'EOF' >> $TEMP/./.zshrc
# libbash库函数位置
export LIBBASH_HOME="~/libbash"

EOF
genSignE proxy $TEMP/./.zshrc

XXMN

{

echo '# 配置文件 libbash/libbash.sh'
echo "cat << 'PPAP' >> \$TEMP/libbash/libbash.sh"
cat "$LIBBASH_HOME/libbash.sh"
echo ""
echo 'PPAP'
echo ""

} >> $TARGET

for filename in "${libfiles[@]}"; do
{
echo "# 配置文件 libbash/$filename"
echo "cat << 'RTYU' >> \$TEMP/libbash/$filename"
cat "$LIBBASH_HOME/$filename"
echo ""
echo 'RTYU'
echo ""
} >> $TARGET
done 

echo "" >> $TARGET
echo "}" >> $TARGET
echo "" >> $TARGET

}

# 用来生成README.md
__generate_libbash_readme(){
    echo "# Libbash Function Documentation"
    echo ""
    echo '这是一个zmr封装了大量实用bash函数的脚本库，用于快速开发bash脚本；该libbash函数注释全面，上手使用非常方便；但是字如其名，只能用于bash脚本，在其他环境下不能直接source'
    echo ""
    echo '### 使用方法'
    echo ""
    echo '1. 克隆脚本库 `git clone https://github.com/zmr-233/libbash.git ~/libbash`'
    echo ""
    echo '2. 在脚本中引入 `source ~/libbash/libbash.sh`'
    echo ""
    echo '3. 可以手动运行`bash ~/libbash/libbash.sh -h`查看帮助'
    echo ""
    if command -v tree > /dev/null 2>&1; then
        echo '### 目录结构'
        echo ""
        echo '```'
        tree $LIBBASH_HOME | sed -E 's/ -> .*//'
        echo '```'
        echo ""
    fi
    echo '### 函数列表'
    echo ""

    # 遍历libfiles数组中的每个文件
    for filename in "${libfiles[@]}"; do
        echo "#### $filename:"
        echo "| Function | Description |"
        echo "|----------|-------------|"

        # 读取文件内容
        while IFS= read -r line || [[ -n "$line" ]]; do
            # 检查是否是函数定义行
            if [[ "$line" =~ ^[[:space:]]*([a-zA-Z0-9_]+)\(\) ]]; then
                # 提取函数名称
                functionName="${BASH_REMATCH[1]}"
                if [[ -n "$functionComment" ]]; then
                    # 输出Markdown表格行
                    echo "| \`$functionName\` | $functionComment |"
                    # 重置functionComment为空
                    functionComment=""
                fi
            elif [[ "$line" =~ ^#[[:space:]]*(.*) ]]; then
                # 提取注释作为函数描述
                functionComment="${BASH_REMATCH[1]}"
            fi
        done < "$LIBBASH_HOME/$filename"

        echo ""
    done
}

# 用来生成git提交的
__generate_libbash_git(){
    local GIT_DIR=$(mktemp -d -t LIBBASH_XXXXXX)
    # mkdir -p $GIT_DIR/libbash
    git clone git@github.com:zmr-233/libbash.git $GIT_DIR/libbash
    pushd $GIT_DIR/libbash > /dev/null
    {
        cat "$LIBBASH_HOME/libbash.sh"
    } > libbash.sh
    for filename in "${libfiles[@]}"; do
        {
            cat "$LIBBASH_HOME/$filename"
        } > $filename
    done
    {
        __generate_libbash_readme
    } > README.md
    git add -A
    git commit -m "update libbash"
    git push
    popd > /dev/null

    echo "cd $GIT_DIR/libbash"
    
}

if [[ $# -eq 0 ]] || [[ "$LIBBASH_SOURCED" == "yes" ]]; then
    # 只允许加载一次
    if [ -z "$LIBBASH_SOURCE_ONCE" ]; then
        for filename in "${libfiles[@]}"; do
            source "$LIBBASH_HOME/$filename"
        done
        LIBBASH_SOURCE_ONCE=yes
    else
        echo "WARN: LIBBASH has been sourced!"
    fi
else
    while [[ $# -gt 0 ]]; do
        case $1 in
            --gen-regfile)
                __generate_libbash_regfile
                shift
                ;;
            --gen-git)
                __generate_libbash_git
                shift
                ;;
            --gen-readme)
                __generate_libbash_readme
                shift
                ;;
            --gen-update)
                __generate_libbash_git
                __generate_libbash_regfile
                shift
                ;;
            *)
                echo "Unknown option: $1"
                shift
                ;;
        esac
    done
fi




PPAP

# 配置文件 libbash/array_utils.sh
cat << 'RTYU' >> $TEMP/libbash/array_utils.sh

# 此函数用于将关联数组内容保存到变量或文件
# @param string $1 关联数组的名字
# @param string $2 可选，输出文件的路径
# @return void
# 保存关联数组到变量或文件
saveMap() {
    local -n __map__=$1
    local output=""
    output+="declare -A $1=("$'\n'
    for key in "${!__map__[@]}"; do
        output+="    [\"$key\"]=\"${__map__[$key]}\""$'\n'
    done
    output+=")"$'\n'

    if [ -n "$2" ]; then
        echo "$output" >> "$2"
    else
        echo "$output"
    fi
}

# 此函数用于将普通数组内容保存到变量或文件
# @param string $1 数组的名字
# @param string $2 可选，输出文件的路径
# @param string $3 可选，声明数组类型的标识（如 '-A' 用于关联数组）
# @return void
# 保存普通数组到变量或文件
saveArr() {
    local -n array=$1
    local output=""

    output+="declare $3 -a $1=("$'\n'
    for element in "${array[@]}"; do
        output+="\"$element\" "$'\n'
    done
    output+=")"$'\n'

    if [ -n "$2" ]; then
        echo "$output" >> "$2"
    else
        echo "$output"
    fi
}

# 此函数用于检查元素是否存在于数组中
# @param string $1 数组名
# @param mixed $2 要检查的元素
# @return bool 如果元素存在于数组中返回0，否则返回1
# 检查元素是否在数组中
inArr() {
    [ $# -eq 0 ] && {
        ERROR "argument error"
        exit 2
    }

    [ $# -eq 1 ] && return 0

    declare -n _arr="$1"
    declare v="$2"
    local elem

    for elem in "${_arr[@]}";do
        [ "$elem" == "$v" ] && return 0
    done

    return 1
}

# 此函数用于将字符串转换为数组
# @param string $1 目标数组的名字
# @param string $2 输入的字符串
# @return void
# 将字符串转换为数组
strToArr() {
    local var_name=$1
    local input=$2
    # 将输入分割成数组并赋值给指定的变量
    IFS=' ' read -r -a "$var_name" <<< "$input"
}

# 此函数用于从数组中删除指定的元素
# @param string $1 数组名
# @param mixed $2 要删除的元素
# @param string $3 可选，关联数组名，用于同步删除关联数组中的键
# @return void
# 从数组中删除指定元素
delFromArr() {
    [ $# -lt 2 ] || [ $# -gt 3 ] && {
        ERROR "argument error"
        exit 2
    }

    declare -n _arr="$1"
    declare v="$2"
    local tempArray=()

    for elem in "${_arr[@]}"; do
        if [[ "$elem" != "$v" ]]; then
            tempArray+=("$elem")
        fi
    done

    _arr=("${tempArray[@]}")

    # 如果传入了三个参数，则更新关联数组
    if [ $# -eq 3 ]; then
        declare -n _map="$3"
        unset _map["$v"]
        for elem in "${_arr[@]}"; do
            _map["$elem"]=1
        done
    fi
}










RTYU

# 配置文件 libbash/color_utils.sh
cat << 'RTYU' >> $TEMP/libbash/color_utils.sh

#====   Colorized variables  ====
if [[ -t 1 ]]; then # is terminal?
  BOLD="\e[1m";      DIM="\e[2m";
  RED="\e[0;31m";    RED_BOLD="\e[1;31m";
  YELLOW="\e[0;33m"; YELLOW_BOLD="\e[1;33m";
  GREEN="\e[0;32m";  GREEN_BOLD="\e[1;32m";
  BLUE="\e[0;34m";   BLUE_BOLD="\e[1;34m";
  GREY="\e[37m";     CYAN_BOLD="\e[1;36m";
  RESET="\e[0m";
fi

#====   Colorized functions  ====

# 为输出的文本提供颜色，以增强可读性和视觉区分
# 定义一系列颜色变量，用于在支持颜色的终端中显示彩色文本

# 在不换行的情况下输出带颜色的文本
# @param string $1 颜色变量名
# @param string $2 要输出的文本
# 输出不换行的彩色文本
nECHO(){ echo -n -e "${!1}${2}${RESET}"; }

# 输出带颜色的文本
# @param string $1 颜色变量名
# @param string $2 要输出的文本
# 输出彩色文本
ECHO() { echo -e "${!1}${2}${RESET}"; }

# 输出带有[INFO]前缀的绿色加粗文本
# @param string $1 要输出的信息文本
# 输出信息级别的日志
INFO(){ echo -e "${GREEN_BOLD}[INFO] ${1}${RESET}"; }

# 输出带有[WARNING]前缀的黄色加粗文本
# @param string $1 要输出的警告文本
# 输出警告级别的日志
WARN() { echo -e "${YELLOW_BOLD}[WARNING] ${1}${RESET}"; }

# 输出带有[ERROR]前缀的红色加粗文本
# @param string $1 要输出的错误文本
# 输出错误级别的日志
ERROR() { echo -e "${RED_BOLD}[ERROR] ${1}${RESET}"; }

# 输出带有[SUCCESS]前缀的绿色加粗文本
# @param string $1 要输出的成功文本
# 输出成功信息
SUCCESS() { echo -e "${GREEN_BOLD}[SUCCESS] ${1}${RESET}"; }

# 输出带有[NOTE]前缀的蓝色加粗文本
# @param string $1 要输出的注释文本
# 输出注释信息
NOTE() { echo -e "${BLUE_BOLD}[NOTE] ${1}${RESET}"; }

# 以青色加粗文本形式输出输入提示
# @param string $1 要输出的输入提示文本
# 输出输入提示信息
INPUT() { echo -e "${CYAN_BOLD}==INPUT==${1}${RESET}"; }

# 输出带有[ABORT]前缀的红色加粗文本，表示中止操作
# @param string $1 要输出的中止信息文本
# 输出中止操作信息
ABORT(){ echo -e "${RED_BOLD}[ABORT] ${1}${RESET}"; }

# 输出带有[DEBUG]前缀的黄色文本，用于调试信息
# @param string $1 要输出的调试信息文本
# 输出调试信息
DEBUG(){ echo -e "${YELLOW}[DEBUG] ${1}${RESET}"; }









RTYU

# 配置文件 libbash/file_utils.sh
cat << 'RTYU' >> $TEMP/libbash/file_utils.sh

# 该函数接受一个文件名作为输入，并返回一个附加了当前时间戳的唯一文件名
# @param string $fileName 输入的原始文件名
# @return string 返回附加了时间戳的唯一文件名
# 生成唯一文件名
genUniName() {
    local fileName=$1
    local timestamp=$(date +%Y%m%d%H%M)
    echo "${fileName}.${timestamp}"
}


# 该函数比较两个目录的内容差异
# @param string $dir1 第一个目录路径
# @param string $dir2 第二个目录路径
# @return int 当两个目录相同返回0，不同或其中一个不存在返回1
# 比较两个目录差异
diffDir() {
  local dir1="$1"
  local dir2="$2"

  # 当两个目录都不存在时，视为没有差异
  if [[ ! -d "$dir1" ]] && [[ ! -d "$dir2" ]]; then
    # echo "Both directories do not exist - no difference."
    return 0
  fi

  # 当其中一个目录不存在时，视为有差异
  if [[ ! -d "$dir1" ]] || [[ ! -d "$dir2" ]]; then
    # echo "Error: One of the directories does not exist."
    return 1
  fi

  # 包括比较内容
  if diff -rq "$dir1" "$dir2" > /dev/null; then
    # echo "Directories are identical."
    return 0
  else
    # echo "Directories differ."
    return 1
  fi
}

# 该函数比较两个文件的内容差异
# @param string $file1 第一个文件路径
# @param string $file2 第二个文件路径
# @return int 当两个文件内容相同返回0，不同或其中一个不存在返回1
# 比较两个文件差异
diffFile() {
  local file1="$1"
  local file2="$2"

  # 当两个文件都不存在时，视为没有差异
  if [[ ! -f "$file1" ]] && [[ ! -f "$file2" ]]; then
    # echo "Both files do not exist - no difference."
    return 0
  fi

  # 当其中一个文件不存在时，视为有差异
  if [[ ! -f "$file1" ]] || [[ ! -f "$file2" ]]; then
    # echo "Error: One of the files does not exist."
    return 1
  fi

  # 比较文件内容
  if diff -q "$file1" "$file2" > /dev/null; then
    # echo "Files are identical."
    return 0
  else
    # echo "Files differ."
    return 1
  fi
}










RTYU

# 配置文件 libbash/input_utils.sh
cat << 'RTYU' >> $TEMP/libbash/input_utils.sh

# 此函数用于读取用户的yes/no输入，并根据输入返回相应的状态码
# @param string $prompt 提示信息
# @return int 根据用户输入返回0（yes）或1（no）
# 作为if条件
readReturn(){
    local prompt=$1
    local input

    while true; do
        INPUT "$prompt [y/n] default: y"
        read -r input

        if [ -z "$input" ]; then
            return 0
            break
        fi

        case $input in
            [yY][eE][sS]|[yY])
                return 0
                break
                ;;
            [nN][oO]|[nN])
                return 1
                break
                ;;
            *)
                WARN "请输入 yes 或 no"
                ;;
        esac
    done

}

# 此函数用于读取用户的yes/no输入，并将结果赋值给指定的变量
# @param string $varName 变量名
# @param string $prompt 提示信息
# 读取-yes/no
readBool() {
    local varName=$1
    local prompt=$2
    local input

    while true; do
        INPUT "$prompt [y/n] default: y"
        read -r input

        if [ -z "$input" ]; then
            eval "$varName=\"y\""
            break
        fi

        case $input in
            [yY][eE][sS]|[yY])
                eval "$varName=\"y\""
                break
                ;;
            [nN][oO]|[nN])
                eval "$varName=\"n\""
                break
                ;;
            *)
                WARN "请输入 yes 或 no"
                ;;
        esac
    done
}

# 此函数用于读取用户输入的一整行文本，并将结果赋值给指定的变量
# @param string $varName 变量名
# @param string $prompt 提示信息
# 读取输入-一整行
readLine() {
    local varName=$1
    local prompt=$2
    local input

    INPUT "LINE= $prompt"
    read -r input

    # 使用 eval
    eval "$varName=\"$input\""
    # 使用间接引用
    # printf -v "$varName" '%s' "$input"
}

# 此函数用于读取用户输入的文本，将其分割成数组，并赋值给指定的变量
# @param string $var_name 变量名
# @param string $prompt_message 提示信息
# 读取输入-数组
readArr() {
    local var_name=$1
    local prompt_message=$2
    local input

    # 使用提供的提示信息来读取输入
    INPUT "ARRAY= $prompt_message"
    read -r input

    # 将输入分割成数组并赋值给指定的变量
    IFS=' ' read -r -a "$var_name" <<< "$input"
}

# 此函数用于读取用户输入的文本，确保输入中不含空格或特殊字符，并将结果赋值给指定的变量
# @param string $varName 变量名
# @param string $prompt 提示信息
# 读取输入-无空格
readNoSpace() {
    local varName=$1
    local prompt=$2
    local input

    while true; do
        INPUT "NO_SPACE= $prompt"
        read -r input

        # 检查输入是否包含空格或特殊字符
        if [[ "$input" =~ [[:space:][:punct:]] ]]; then
            WARN "输入不能包含空格或特殊字符，请重新输入。"
        else
            break
        fi
    done

    # 使用 eval 动态设置变量名
    eval "$varName=\"$input\""
}

# 此函数用于读取用户输入的多行文本直到Ctrl+D，并将结果赋值给指定的变量
# @param string $varName 变量名
# @param string $prompt 提示信息
# 读取输入-多行直到Ctrl+D
readMultiLine() {
    local varName=$1
    local prompt=$2
    local result=""

    INPUT "<Ctrl-D>= $prompt"

    while IFS= read -r line; do
        result="${result}${line}"$'\n'
    done

    # 确保变量内容包含换行符并且未解析任何 $ 符号
    eval "$varName=\"\$result\""
}







RTYU

# 配置文件 libbash/others_utils.sh
cat << 'RTYU' >> $TEMP/libbash/others_utils.sh
# 检查指定的命令是否存在于系统的路径中
# @param string $1 要检查的命令名
# @return 无返回值，如果命令不存在则将错误输出重定向到 /dev/null
# 检查命令是否存在
checkCmd(){ type $1 > /dev/null 2>&1; }


ISCONFIG="" # 用来判断是否需要跳过配置检查

# 根据ISCONFIG变量的值决定是否跳过配置文件或目录的存在性检查
# @param string $1 需要检查的文件或目录路径
# @return int 如果ISCONFIG为空并且文件或目录存在则返回0，否则返回1；如果ISCONFIG非空则直接返回0
# 检查配置文件或目录是否存在
checkCfg(){
    if [[ -z $ISCONFIG ]];then
        if [[ -e "$1" ]] || [[ -d "$1" ]] ;then
            return 0
        else
            return 1
        fi
    else
        return 0
    fi
}

# 执行一个倒计时，期间在命令行显示剩余时间
# @param int $1 倒计时的总秒数
# @return 无返回值，显示倒计时并在每秒更新一次显示
# 执行倒计时
countDown() {
    local tn=$1
    nECHO "YELLOW" "... "
    while [ $tn -ge 1 ]; do
        nECHO "YELLOW" "${tn} "
        sleep 1
        ((tn--))
    done
    nECHO "YELLOW" "0 ..."
    sleep 1
    echo ""
}

# =======================一个用于生成函数描述的模版=======================:

### 函数描述格式要求

# 1. **详细描述**（可选）：在函数定义上方，使用多行注释来提供对函数功能的详细描述。这些描述应该清晰地解释函数的行为、边界条件或其他复杂的细节。如果该函数十分简单，只写简短描述即可。

# 2. **简短描述**：在详细描述之后，紧接着在函数定义之前的最后一行使用注释提供一个简洁的语句，概括函数的基本作用。

# 3. **参数描述**：对每个参数进行描述，包括它的类型、用途和任何默认值。使用`@param`标签来标记这些行。如果没有参数，或者参数异常明显，比如`ECHO()`函数，就不需要参数描述了。

# 4. **返回值描述**：描述函数的返回值，包括类型和条件。使用`@return`标签来标记这行。

# ### 示例

# ```bash
# # 这个函数接受两个整数作为输入，并返回它们的算术和
# # @param int $num1 第一个整数
# # @param int $num2 第二个整数
# # @return int 返回两个数的和
# # 计算两个数的和
# sum() {
#     local num1=$1
#     local num2=$2
#     echo $((num1 + num2))
# }
# ```

# 这种格式调整保证了简短描述始终位于函数定义的最后一行注释，便于在生成README时提取。

# ========================================

# 请根据如上要求，用中文为如下的函数生成函数描述：











RTYU

# 配置文件 libbash/regfile_template.sh
cat << 'RTYU' >> $TEMP/libbash/regfile_template.sh
# 该函数是用于生成DotfilesConfigMaster的配置文件模板
# 该函数与https://github.com/zmr-233/DotfilesConfigMaster深度相关
# 但是经过解耦合，可以不依赖该项目生成模板文件
# 使用样例： 以changeflow.sh为代表性样例

# # 生成regfile模板函数
# __generate_changeflow_regfile(){
#     # local SCRIPT_NAME='.changeflowrc'
#     local REG_NAME=changeflow
#     local REG_INFO='轻松切换和管理工作流的工具'
#     local REG_DEPS='zsh libbash'
#     local REG_CHECK="checkCfg \$HOME/.changeflowrc"
#     local REG_INSTALL=""
#     declare -A REG_CONFIG_MAP=(
#         ["."]=".zshrc .changeflowrc"
#     )
#     local ZSHRC_CONTENT=$(cat << 'EOM'
# # Alias for changeflow
# alias changeflow='bash ~/.changeflowrc'
# alias cflow=changeflow

# EOM
# )
#     local CHANGEFLOW_CONTENT=$(cat "$0")
#     declare -A REG_CONFIG_FILE_MAP=(
#         ["./.zshrc"]=$ZSHRC_CONTENT
#         ["./.changeflowrc"]=$CHANGEFLOW_CONTENT
#     )
#     local REG_UPDATE=""
#     local REG_UNINSTALL=""

#     regfileTemplate "$REG_NAME" "$REG_INFO" "$REG_DEPS" "$REG_CHECK" "$REG_INSTALL" REG_CONFIG_MAP REG_CONFIG_FILE_MAP "$REG_UPDATE" "$REG_UNINSTALL"
# }

# 生成regfile模板函数
regfileTemplate(){
    if [ -z "$DOTFILES_CONFIG_MASTER_HOME" ]; then
        echo "DOTFILES_CONFIG_MASTER_HOME is not set"
        exit 1
    fi
    local DOT_CFG_TEMP=$DOTFILES_CONFIG_MASTER_HOME/regfiles
    mkdir -p $DOT_CFG_TEMP

    local REG_NAME=$1
    local REG_INFO=$2
    local REG_DEPS=$3
    local REG_CHECK=${4:-"checkCmd $1; return \$?;"}
    local REG_INSTALL=$5
    local -n REG_CONFIG_MAP__=$6
    local -n REG_CONFIG_FILE_MAP__=$7
    local REG_UPDATE=${8:-""}
    local REG_UNINSTALL=${9:-""}

#========================== gen_info ========================== 
    if [ -z "$(echo -e "$REG_INFO" | tr -d '[:space:]')" ]; then
        WARN "介绍为空，默认填入---- no info ----"
        REG_INFO="---- no info ----"
    fi
    {
        echo "#!/bin/bash"
        echo ""
        echo "# VERSION: 1"
        echo ""
        echo "${1}_info(){"
        echo "    echo \"$REG_INFO\""
        echo "}"
    } >$DOT_CFG_TEMP/$1.sh

#========================== gen_deps ==========================
    if [ -z "$(echo -e "$REG_DEPS" | tr -d '[:space:]')" ]; then
        WARN "依赖项为空，默认返回空"
        REG_DEPS=""
    fi
    {
        echo ""
        echo "${1}_deps(){"
        echo "    echo \"__predeps__ $REG_DEPS\""
        echo "}"
    } >> $DOT_CFG_TEMP/$1.sh

#========================== gen_check ==========================
    {
        echo ""
        echo "${1}_check(){"
        echo "$REG_CHECK"
        echo "return \$?"
        echo "}"
    } >> $DOT_CFG_TEMP/$1.sh

#========================== gen_install ==========================
    if [ -z "$(echo -e "$REG_INSTALL" | tr -d '[:space:]')" ]; then
        WARN "安装命令为空，跳过"
    {
        echo ""
        echo "${1}_install(){"
        echo "genSignS \"$1\" \$INSTALL"
        echo "cat << 'EOF' >> \$INSTALL"
        echo "MODULE_INFO \"......正在安装${1}......\""
        echo "INFO \"${1}是无需安装的配置文件\""
        echo "EOF"
        echo "genSignE \"$1\" \$INSTALL"
        echo "}"
    } >> $DOT_CFG_TEMP/$1.sh
    else
    {
        echo ""
        echo "${1}_install(){"
        echo "genSignS \"$1\" \$INSTALL"
        echo "cat << 'EOF' >> \$INSTALL"
        echo "MODULE_INFO \"......正在安装${1}......\""
        echo "if ${1}_check; then"
        echo "    WARN \"${1}已经安装，不再执行安装操作\""
        echo "else"
        echo "$REG_INSTALL"
        echo "fi"
        echo "EOF"
        echo "genSignE \"$1\" \$INSTALL"
        echo "}"
    } >> $DOT_CFG_TEMP/$1.sh
    fi

#========================== gen_config ==========================
    {
        echo ""
        echo "${1}_config(){"
        echo "# 加入配置文件更新映射"
        saveMap REG_CONFIG_MAP__
        echo "add_configMap REG_CONFIG_MAP__"
    } >> $DOT_CFG_TEMP/$1.sh

    for key in ${!REG_CONFIG_MAP__[@]}; do
        for file in ${REG_CONFIG_MAP__[$key]}; do
            curconfigcmd=${REG_CONFIG_FILE_MAP__[$key/$file]}
            if [ -z "$(echo -e "$curconfigcmd" | tr -d '[:space:]')" ]; then
                WARN "该文件配置为空，默认写入一个换行符"
    {
    echo "# 配置文件 $key/$file 为空--默认写入一个换行符"
    echo "cat << 'EOF' >> \$TEMP/$key/$file"
    echo ""
    echo "EOF"
    }>> $DOT_CFG_TEMP/$1.sh

            else
    {
    echo "cat << 'XUVYP' >> \$TEMP/$key/$file"
    echo "$curconfigcmd"
    echo "XUVYP"
    }>> $DOT_CFG_TEMP/$1.sh
            fi
        done
    done

    echo "return 0" >> $DOT_CFG_TEMP/$1.sh
    echo "}" >> $DOT_CFG_TEMP/$1.sh

#========================== gen_update ==========================
    if [ -z "$(echo -e "$REG_UPDATE" | tr -d '[:space:]')" ]; then
        WARN "升级命令为空，跳过"
    else
    {
        echo ""
        echo "${1}_update(){"
        echo "genSignS \"$1\" \$UPDATE"
        echo "cat << 'EOF' >> \$UPDATE"
        echo ""
        echo "MODULE_INFO \"......正在升级${1}......\""
        echo "$REG_UPDATE"
        echo "EOF"
        echo "genSignE \"$1\" \$UPDATE"
        echo "}"
    }>>$DOT_CFG_TEMP/$1.sh
    fi

#========================== gen_uninstall ==========================
    if [ -z "$(echo -e "$REG_UNINSTALL" | tr -d '[:space:]')" ]; then
        WARN "卸载命令为空，跳过"
    else
    {
        echo ""
        echo "${1}_uninstall(){"
        echo "genSignS \"$1\" \$UNINSTALL"
        echo "cat << 'EOF' >> \$UNINSTALL"
        echo ""
        echo "MODULE_INFO \"......正在卸载${1}......\""
        echo "if ${1}_check; then"
        echo "$REG_UNINSTALL"
        echo "else"
        echo "    WARN \"${1}已经卸载，不再执行卸载操作\""
        echo "fi"
        echo "EOF"
        echo "genSignE \"$1\" \$UNINSTALL"
        echo "}"
    }>>$DOT_CFG_TEMP/$1.sh
    fi

#========================== 最终生成阶段 ==========================
    INFO "临时注册文件生成完毕，文件路径: $DOT_CFG_TEMP/$1.sh"
}


RTYU

# 配置文件 libbash/safe_utils.sh
cat << 'RTYU' >> $TEMP/libbash/safe_utils.sh

#==============================Safe系列==============================

# 用来控制是否发生备份的全局变量:
isMakeup=DO_MAKEUP

# 用于创建文件或目录的备份
# @param string $source 源文件或目录路径
# @param string $backupDir 备份目录路径
# @return void
# 创建文件或目录的备份
_createBackup() {
    if [[ "$isMakeup" == "NO_MAKEUP" ]]; then
        return 0
    fi
    local source=$1
    local backupDir=$2
    local backupName="$(date +%Y%m%d%H%M%S).$(basename "$source").bak"
    local target="$backupDir/$backupName"

    mkdir -p "$backupDir" || { ERROR "Could not create backup directory: $backupDir"; return 1; }
    cp -r "$source" "$target" || { ERROR "Could not create backup of $source"; return 1; }
    INFO "Backup created as $target"
}

# 用于创建不包含父路径的文件或目录的tar备份
# @param string $source 源文件或目录路径
# @param string $backupDir 备份目录路径
# @return void
# 创建不包含父路径的tar备份
_createTarBackup() {
    if [[ "$isMakeup" == "NO_MAKEUP" ]]; then
        return 0
    fi
    local source=$1
    local backupDir=$2
    local sourceBaseName=$(basename "$source")
    local sourceDirName=$(dirname "$source")
    local backupName="$(date +%Y%m%d%H%M%S).$sourceBaseName.tar.gz"

    # Convert backupDir to an absolute path
    mkdir -p "$backupDir" || { ERROR "Could not create backup directory: $backupDir"; return 1; }
    local absBackupDir=$(cd "$backupDir"; pwd)
    local target="$absBackupDir/$backupName"

    # Change to the directory containing the source to avoid including parent paths in the tar archive
    pushd "$sourceDirName" > /dev/null
    # echo "$(pwd) $target $sourceBaseName"
    tar -czf "$target" "./$sourceBaseName" || { ERROR "Could not create tar backup of $source"; popd > /dev/null; return 1; }
    popd > /dev/null
    
    INFO "Tar backup created as $target"
}

# 用于检查源文件或目录是否存在
# @param string $source 源文件或目录路径
# @return void
# 检查源文件或目录是否存在
_checkSourceExists() {
    local source=$1
    if [[ -z "$source" ]] || [[ ! -e "$source" ]]; then
        ERROR "The source does not exist: $source"
        return 1
    fi
    return 0
}

# 用于检查目标目录是否存在
# @param string $targetDir 目标目录路径
# @return void
# 检查目标目录是否存在
_checkTargetDirExists() {
    local targetDir=$1
    if [[ -z "$targetDir" ]] || [[ ! -d "$targetDir" ]]; then
        [[ "$2" ==  "NO_ECHO" ]] || ERROR "The target directory does not exist: $targetDir"
        return 1
    fi
    return 0
}

# 安全复制文件，如目标文件存在则备份
# @param string $sourceFile 源文件路径
# @param string $targetDir 目标目录路径
# @param string $backupSubdir 备份子目录路径（可选，默认为目标目录下的backup目录）
# @return void
# 安全复制文件
copySafe() {
    local sourceFile=$1
    local targetDir=$2
    local backupSubdir=${3:-$targetDir/backup}

    _checkSourceExists "$sourceFile" || return 1
    _checkTargetDirExists "$targetDir" "NO_ECHO" || mkdir -p "$targetDir" || return 1

    local targetFile="$targetDir/$(basename "$sourceFile")"

    if [ -f "$targetFile" ]; then
        _createBackup "$targetFile" "$backupSubdir" || return 1
    fi

    cp -r "$sourceFile" "$targetFile" && INFO "File $sourceFile has been copied to $targetFile"
}

# 安全移动文件或目录，如目标存在则备份
# @param string $source 源文件或目录路径
# @param string $targetDir 目标目录路径
# @param string $backupSubdir 备份子目录路径（可选，默认为目标目录下的backup目录）
# @return void
# 安全移动文件或目录
moveSafe() {
    local source=$1
    local targetDir=$2
    local backupSubdir=${3:-$targetDir/backup}

    _checkSourceExists "$source" || return 1
    _checkTargetDirExists "$targetDir" "NO_ECHO" || mkdir -p "$targetDir" || return 1

    local target="$targetDir/$(basename "$source")"

    if [[ -f "$target" ]] || [[ -d "$target" ]]; then
        _createBackup "$target" "$backupSubdir" || return 1
    fi

    mv "$source" "$target" && INFO "$source has been moved and overwritten at $target"
}

# 安全删除文件或目录，删除前备份
# @param string $source 源文件或目录路径
# @param string $backupDir 备份目录路径（可选，默认为backup目录）
# @return void
# 安全删除文件或目录
removeSafe() {
    local source=$1
    local backupDir=${2:-backup}

    _checkSourceExists "$source" || return 1

    _createBackup "$source" "$backupDir" || return 1
    rm -rf "$source" && INFO "Original $source has been removed."
}

# 备份文件或目录
# @param string $source 源文件或目录路径
# @param string $backupDir 备份目录路径（可选，默认为backup目录）
# @return void
# 备份文件或目录
saveSafe() {
    local source=$1
    local backupDir=${2:-backup}

    _checkSourceExists "$source" || return 1

    _createBackup "$source" "$backupDir"
}

# 以tar格式安全备份文件或目录
# @param string $source 源文件或目录路径
# @param string $backupDir 备份目录路径（可选，默认为backup目录）
# @return void
# 以tar格式安全备份文件或目录
tarSafe() {
    local source=$1
    local backupDir=${2:-backup}

    _checkSourceExists "$source" || return 1

    _createTarBackup "$source" "$backupDir"
}

# ==============================映射操作系列==============================


# declare -A config_map=(
#    ["."]=".zshrc .valgrindsh"
#    [".config/bat/syntaxes"]="valgrind.sublime-syntax"
# )
# declare -A workflow_map=(
#    ["."]="MODULE.cfg"
#    ["vsrc"]="*"
#    ["csrc"]="*"
# )
# 给一个像上面一样的映射，可以对映射中的文件进行保存/删除/移动/复制操作
# operateMapFiles move workflow_map "." "$WF/$SAVEN" "$WF/backup/$SAVEN"

# 对映射中的文件进行保存/删除/移动/复制操作
# @param string $operation 操作类型：save, remove, copy, move
# @param array $map_ref 文件映射引用
# @param string $src_prefix 源路径前缀
# @param string $dest_prefix 目标路径前缀
# @param string $backup_dir 备份目录
# @return void
# 操作映射中的文件
operateMapFiles() {
    local operation=$1  # 操作类型：save, remove, copy, move
    local map_ref=$2    # 引用workflow_map或init_map
    local src_prefix=$3 # 源路径前缀
    local dest_prefix=$4 # 目标路径前缀
    local backup_dir=$5  # 备份目录

    declare -n map=$map_ref

    for key in "${!map[@]}"; do
        if [[ "${map[$key]}" = "*" ]]; then
            case $operation in
                save|remove)
                    "${operation}Safe" "$dest_prefix/$key" "$backup_dir";;
                copy|move)
                    "${operation}Safe" "$src_prefix/$key" "$dest_prefix" "$backup_dir";;
            esac
        else
            eval "files=(${map[$key]})"
            for file in "${files[@]}"; do
                case $operation in
                    save|remove)
                        "${operation}Safe" "$dest_prefix/$key/$file" "$backup_dir";;
                    copy|move)
                        "${operation}Safe" "$src_prefix/$key/$file" "$dest_prefix/$key" "$backup_dir";;
                esac
            done
        fi
    done
}










RTYU


}

