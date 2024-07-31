#!/bin/bash

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

cecho() {
  echo -e "${!1}${2}${RESET}"
}

cline() {
  echo -n -e "${!1}${2}${RESET}"
}

cinfo() {
  echo -e "${GREEN_BOLD}INFO: ${1}${RESET}"
}

cwarn() {
  echo -e "${YELLOW_BOLD}WARNING: ${1}${RESET}"
}

cerror() {
  echo -e "${RED_BOLD}ERROR: ${1}${RESET}"
}

csuccess() {
  echo -e "${GREEN_BOLD}SUCCESS: ${1}${RESET}"
}

cnote() {
  echo -e "${BLUE_BOLD}NOTE: ${1}${RESET}"
}

cinput() {
  echo -e "${CYAN_BOLD}==INPUT==${1}${RESET}"
}

cabort(){
    echo -e "${RED_BOLD}ABORT: ${1}${RESET}"
}

cdebug(){
    echo -e "${YELLOW}DEBUG: ${1}${RESET}"
}

# Module and function specific functions
minfo() {
  echo -e "${CYAN_BOLD}MODULE: ${1}${RESET}"
}

finfo() {
  echo -e "${BLUE_BOLD}FUNC: ${1}${RESET}"
}