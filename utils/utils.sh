#!/usr/bin/bash

# 命令检查
cmdCheck(){ type $1 > /dev/null 2>&1; }

# 纯配置检查
configCheck(){
    if [[ -z $ISCONFIG ]];then
        
        if [[ -e "$1" ]];then
            return 0
        else
            return 1
        fi
    else
        return 0
    fi
}
# 生成标注
genSignS(){
    local name=$1
    if [ -n "$2" ]; then
cat <<EOF >> $2
# >>>> [$name] >>>>Start
EOF
    else
cat <<EOF
# >>>[$name]>>>Start
EOF
    fi
}
genSignE(){
    local name=$1
    if [ -n "$2" ]; then
cat <<EOF >> $2
# <<<< [$name] <<<<End

EOF
    else
cat <<EOF
# <<<< [$name] <<<<End

EOF
    fi
}

# 保存和加载数组
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
saveArray() {
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

# 利用拓扑排序来生成安装序列
resolve_deps(){
    declare -n regF=$1    # 需要解析的命令列表
    declare -n preCMD_=$2 # 未出现的命令
    declare -A inregF # 是否在regF中
    declare -A inDeg # 入度
    declare -A deps # 依赖关系
    declare -A after # 依赖关系
    

    # --------------------如下部分需要封装为函数:

    # 首先判断是否是regF已经有的指令
    for reg in "${regF[@]}"; do
        inregF[$reg]=1
    done

    # 初始化依赖关系
    for reg in "${regF[@]}"; do
        deps[$reg]="$(eval ${reg}_deps)" # 使用 eval 调用函数
        declare -i cCmd=0 # 不属于regF的命令
        for dep in ${deps[$reg]}; do
            if [ -z ${inregF[$dep]} ]; then
                preCMD_+=("$dep")
                ((cCmd++))
            else
                after[$dep]+="$reg "
            fi
        done
        inDeg[$reg]=$[$(echo ${deps[$reg]} | wc -w) - $cCmd]
    done

    # 打印依赖关系
    # for reg in "${regF[@]}"; do
    #     echo "$reg: ${inDeg[$reg]}"
    # done

    queueZ=()
    sortedZ=()
    declare -i iq=0
    declare -i jq=0

    # 将所有入度为0的节点加入队列
    for reg in "${regF[@]}"; do
        if [ ${inDeg[$reg]} -eq 0 ]; then
            queueZ[$jq]=$reg
            ((jq++))
        fi
    done

    # 拓扑排序
    while [ $iq -lt $jq ]; do
        reg=${queueZ[$iq]}
        ((iq++))
        sortedZ+=("$reg")

        for dep in ${after[$reg]}; do
            ((inDeg[$dep]--))
            if [ ${inDeg[$dep]} -eq 0 ]; then
                queueZ[$jq]=$dep
                ((jq++))
            fi
        done
    done

    # 检查是否存在循环依赖
    if [ ${#sortedZ[@]} -ne ${#regF[@]} ]; then
        # echo "存在循环依赖，无法确定安装顺序"
        return 1
    fi

    # 输出安装顺序
    # echo "安装顺序: ${sortedZ[@]}"
    # 输出未出现的命令
    # echo "未出现的命令: ${preCMD[@]}"
    
    # 更新安装顺序
    regF=("${sortedZ[@]}")
}

# 读取用户输入的配置文件路径并解析到对应的键
resolve_configFiles() {
    declare -n configFiles_=$1
    declare -n config_map_=$2

    if [ ${#configFiles_[@]} -eq 0 ]; then
        echo "未输入配置文件。"
        return 1
    fi

    for file in "${configFiles_[@]}"; do
        # 去除前缀
        file="${file/#~\//}"
        file="${file/#.\//}"

        # 提取目录和文件名
        dir="${file%/*}"
        base="${file##*/}"

        # 特殊处理根目录下的文件
        if [[ "$dir" == "$base" ]]; then
            dir="."
        fi

        # 将文件路径分类到对应的键中
        if [[ -z "${config_map_[$dir]}" ]]; then
            config_map_[$dir]="$base"
        else
            config_map_[$dir]+=" $base"
        fi
    done

    # 打印结果
    # echo "["
    # for key in "${!config_map_[@]}"; do
    #     echo "[$key]=\"${config_map_[$key]}\""
    # done
    # echo "]"
}

# allConfigMap注册所有配置文件函数
# declare -A allConfigMap=()
add_configMap(){
    declare -n config_map_=$1
    for key in "${!config_map_[@]}"; do
        local skey=$key
        if [[ $skey == "." ]];then
            skey="_dot_"
        fi
        # 如果 allConfigMap 中还没有这个 key
        if [[ -z "${allConfigMap[$key]}" ]]; then
            allConfigMap[$key]="${config_map_[$key]}"
            declare -g -A "__${skey}__map"
            mkdir -p $TEMP/$key
            for file in ${config_map_[$key]}; do
                declare -n key_map="__${skey}__map"
cat <<EOF > $TEMP/$key/$file
#!/bin/bash

EOF
                key_map[$file]=1
            done
        else
            for file in ${config_map_[$key]}; do
                declare -n key_map="__${skey}__map"
                if [[ -z "${key_map[$file]}" ]]; then
                    allConfigMap[$key]+=" $file"
cat <<EOF > $TEMP/$key/$file
#!/bin/bash

EOF
                    key_map[$file]=1
                fi
            done
        fi
    done
}

# 作为if条件
readReturn(){
    local prompt=$1
    local input

    while true; do
        cinput "$prompt [y/n] default: y"
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
                cwarn "请输入 yes 或 no"
                ;;
        esac
    done

}

# 读取-yes/no
readBool() {
    local varName=$1
    local prompt=$2
    local input

    while true; do
        cinput "$prompt [y/n] default: y"
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
                cwarn "请输入 yes 或 no"
                ;;
        esac
    done
}

# 读取输入-一整行
readLine() {
    local varName=$1
    local prompt=$2
    local input

    cinput "LINE= $prompt"
    read -r input

    # 使用 eval
    eval "$varName=\"$input\""
    # 使用间接引用
    # printf -v "$varName" '%s' "$input"
}

# 读取输入-数组
readArray() {
    local var_name=$1
    local prompt_message=$2
    local input

    # 使用提供的提示信息来读取输入
    cinput "ARRAY= $prompt_message"
    read -r input

    # 将输入分割成数组并赋值给指定的变量
    IFS=' ' read -r -a "$var_name" <<< "$input"
}

# 读取输入-无空格
readNoSpace() {
    local varName=$1
    local prompt=$2
    local input

    while true; do
        cinput "NO_SPACE= $prompt"
        read -r input

        # 检查输入是否包含空格或特殊字符
        if [[ "$input" =~ [[:space:][:punct:]] ]]; then
            cwarn "输入不能包含空格或特殊字符，请重新输入。"
        else
            break
        fi
    done

    # 使用 eval 动态设置变量名
    eval "$varName=\"$input\""
}

# 读取输入-多行直到Ctrl+D
readMultiLine() {
    local varName=$1
    local prompt=$2
    local result=""

    cinput "<Ctrl-D>= $prompt"

    while IFS= read -r line; do
        result="${result}${line}"$'\n'
    done

    # 确保变量内容包含换行符并且未解析任何 $ 符号
    eval "$varName=\"\$result\""
}

# 字符串转数组
toArray() {
    local var_name=$1
    local input=$2
    # 将输入分割成数组并赋值给指定的变量
    IFS=' ' read -r -a "$var_name" <<< "$input"
}

# 生成唯一文件名
genUniName() {
    local fileName=$1
    local timestamp=$(date +%Y%m%d%H%M)
    echo "${fileName}.${timestamp}"
}

# 打包备份
safeTarBackup() {
    local curDotFilesDir=$1

    # 检查CURDOTFILES是否非空且存在
    if [ -n "$curDotFilesDir" ] && [ -d "$curDotFilesDir" ]; then
        # 设置备份目录
        local backupDir="${BACKUPP:-./backup}"
        mkdir -p "$backupDir"
        
        # 生成备份文件名
        local timestamp=$(date +%Y%m%d%H%M)
        local backupName="${timestamp}_$(basename "$curDotFilesDir").tar.gz"
        
        # 创建tar包
        tar -czf "$backupDir/$backupName" -C "$(dirname "$curDotFilesDir")" "$(basename "$curDotFilesDir")"
        
        echo "Backup of $curDotFilesDir created as $backupDir/$backupName"
    else
        echo "CURDOTFILES is empty or does not exist. No backup created."
    fi
}

# 创建备份文件
safeBackup() {
    local fileName=$1
    local targetDir=$2
    local backupSubdir=$3

    if [ -f "$targetDir/$fileName" ]; then
        # 设置历史备份目录
        local historyDir="${BACKUPP:-./backup}"
        if [ -n "$backupSubdir" ]; then
            historyDir="$historyDir/$backupSubdir"
        fi
        mkdir -p "$historyDir"
        # 生成备份文件名
        local backupName="$(date +%Y%m%d%H%M).${fileName}.bak"
        cp "$targetDir/$fileName" "$historyDir/$backupName"
        cwarn "Target file exists. Backup created as $historyDir/$backupName"
    fi
}

# 安全覆盖文件
safeOverwrite() {
    # 参数校验
    if [ $# -lt 3 ] || [ $# -gt 4 ]; then
        echo "Usage: safeOverwrite <fileName> <sourceDir> <targetDir> [optionalBackupSubdir]"
        return 1
    fi
    
    local fileName=$1
    local sourceDir=$2
    local targetDir=$3
    local backupSubdir=$4
    
    
    # 检查源文件是否存在
    if [ ! -f "$sourceDir/$fileName" ]; then
        cerror "Source file $sourceDir/$fileName does not exist."
        return 1
    fi
    
    # 如果目标文件存在，则备份
    safeBackup $fileName $targetDir $backupSubdir
    
    # 移动文件到目标目录
    mv "$sourceDir/$fileName" "$targetDir/$fileName"
    cinfo "File has been overwritten at $targetDir/$fileName"
}


# 检查是否在数组内
inArray() {
    [ $# -eq 0 ] && {
        echo "argument error"
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

# 函数：从数组中删除指定元素
deleteFromArray() {
    [ $# -lt 2 ] || [ $# -gt 3 ] && {
        echo "argument error"
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

# 定义倒计时函数
countdown() {
    local tn=$1
    cline "YELLOW" "... "
    while [ $tn -ge 1 ]; do
        cline "YELLOW" "${tn} "
        sleep 1
        ((tn--))
    done
    cline "YELLOW" "0 ..."
    sleep 1
    echo ""
}