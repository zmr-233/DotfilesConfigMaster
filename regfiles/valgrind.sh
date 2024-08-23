#!/bin/bash

# VERSION: 1

valgrind_info(){
    echo "用于检测程序中的内存错误和性能问题的工具"
}

valgrind_deps(){
    echo "__predeps__ bat"
}
valgrind_check(){
cmdCheck "valgrind"
return $?
}


valgrind_install(){
genSignS "valgrind" $INSTALL
cat << 'EOF' >> $INSTALL
minfo "......正在安装valgrind......"
if valgrind_check; then
    cwarn "valgrind已经安装，不再执行安装操作"
else
sudo apt install valgrind -y

fi
EOF
genSignE "valgrind" $INSTALL
}

valgrind_config(){
# 加入配置文件更新映射
declare -A config_map=(
    ["."]=".zshrc"
    [".config/bat/syntaxes"]="valgrind.sublime-syntax"
)

add_configMap config_map

# 配置文件 ./.zshrc 
genSignS valgrind $TEMP/./.zshrc
cat << 'EOF' >> $TEMP/./.zshrc
VALFLAGS=("--num-callers=40"        # 设置追踪的最大堆栈
          "--track-origins=yes"     # 追踪未初始化行为
          "--read-inline-info=yes"  # 正确显示内嵌函数
          "--leak-check=full"       # 执行完整的内存泄漏检查,报告所有已分配但未释放的内存
          "--show-reachable=yes"    # 报告可达的内存块, 即使没有泄露
          "--leak-resolution=high"  # 设置内存泄漏报告的分辨率为“高”
          "--trace-children=yes"    #  追踪子进程的内存使用情况
)
valgrind_bat() {
    local stdout_tmp=$(mktemp)
    local stderr_tmp=$(mktemp)
    local combined_tmp=$(mktemp)
    local merge=false
    if [ "$1" = "--merge" ] || [ "$1" = "-m" ]; then
        shift
        merge=true
    fi

    { 
      { valgrind "${VALFLAGS[@]}" "$@" 2> >(tee "$stderr_tmp" >&2); } | tee "$stdout_tmp"
    } > >(cat -v > "$combined_tmp") 2>&1 | tee -a "$combined_tmp" > /dev/null


    if [ -t 1 ] && [ -t 2 ] && [ "$merge" = "true" ]; then
        cat "$combined_tmp" | bat --language=valgrind
    else
        if [ -t 1 ]; then
            cat "$stdout_tmp" | bat --paging=always
        else
            cat "$stdout_tmp"
        fi

        if [ -t 2 ]; then
            cat "$stderr_tmp" | bat --language=valgrind >&2
        else
            cat "$stderr_tmp" >&2
        fi
    fi

    rm "$stdout_tmp" "$stderr_tmp" "$combined_tmp"
}
# 用bat给valgrind彩色输出的别名
alias val=valgrind_bat

EOF
genSignE valgrind $TEMP/./.zshrc

# 配置文件 .config/bat/syntaxes/valgrind.sublime-syntax 
cat << 'EOF' >> $TEMP/.config/bat/syntaxes/valgrind.sublime-syntax
%YAML 1.2

---

name: valgrind
file_extensions:
  - val
  - valgrind
scope: source.val
first_line_match: 'Memcheck, a memory error detector'

variables:
  basic_types: 'asm|__asm__|auto|bool|_Bool|char|_Complex|double|float|_Imaginary|int|long|short|signed|unsigned|void'

contexts:
  main:
    # 匹配Valgrind启动信息
    - match: Memcheck, a memory error detector
      scope: keyword
      
    - match: Copyright \(C\) \d+-\d+, and GNU GPL\'d, by Julian Seward et al.
      scope: comment

    - match: (Using )(Valgrind-3.22.0)( and LibVEX; rerun with -h for copyright info)
      captures:
        1: keyword
        2: support.constant
        3: keyword
        
    - match: "(Command: )(.+)"
      captures:
        1: keyword
        2: markup.bold

    # 匹配函数调用及内存地址
    - match: '(at|by)\s(0x[0-9A-F]+):\s(.+)\s(\(([^:]+):?(\d*)\))'
      captures:
        1: keyword
        2: constant.numeric
        3: entity.name.function
        4: storage.type
        5: variable.parameter

    - match: ==\d+==
      scope: comment

    # 匹配内存错误类型
    - match: 'Conditional jump or move depends on uninitialised value\(s\)'
      scope: invalid
      comment: "匹配未初始化值导致的条件跳转或移动"

    - match: 'Use of uninitialised value of size \d+'
      scope: invalid

    - match: 'Invalid (free|read|write) of size \d+'
      scope: invalid

    - match: 'Mismatched free\(\)'
      scope: invalid

    - match: 'Address 0x[0-9A-Fa-f]+ is \d+ bytes inside a block of size \d+ free.?d'
      scope: invalid

    # 匹配堆内存摘要部分
    - match: 'HEAP SUMMARY:'
      scope: markup.heading

    - match: 'total heap usage: \d+ allocs, \d+ frees, \d+ bytes allocated'
      scope: markup.bold

    - match: 'LEAK SUMMARY:'
      scope: markup.heading

    - match: 'definitely lost: \d+ bytes in \d+ blocks'
      scope: markup.changed

    - match: 'indirectly lost: \d+ bytes in \d+ blocks'
      scope: markup.changed

    - match: 'possibly lost: \d+ bytes in \d+ blocks'
      scope: markup.changed

    - match: 'still reachable: \d+ bytes in \d+ blocks'
      scope: markup.inserted

    - match: 'suppressed: \d+ bytes in \d+ blocks'
      scope: markup.changed

    # 内存地址匹配
    - match: '0x[0-9A-Fa-f]+'
      scope: constant.numeric

    # 匹配错误摘要部分
    - match: 'ERROR SUMMARY: \d+ errors from \d+ contexts \(suppressed: \d+ from \d+\)'
      scope: message.error

    - match: 'Rerun with --leak-check=full to see details of leaked memory'
      scope: keyword
    - match: 'Use --track-origins=yes to see where uninitialised values come from'
      scope: keyword    
    - match: 'For lists of detected and suppressed errors, rerun with: -s'
      scope: keyword 
    # 匹配数字
    - match: '\b\d+\b'
      scope: constant.numeric

EOF

cat << 'EOF' >> $AFTERINSTALL
# bat必要的更新缓存操作
bat cache --build
EOF
return 0
}
