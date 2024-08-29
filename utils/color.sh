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

ECHO() {
  echo -e "${!1}${2}${RESET}"
}

nECHO() {
  echo -n -e "${!1}${2}${RESET}"
}

INFO() {
  echo -e "${GREEN_BOLD}INFO: ${1}${RESET}"
}

WARN() {
  echo -e "${YELLOW_BOLD}WARNING: ${1}${RESET}"
}

ERROR() {
  echo -e "${RED_BOLD}ERROR: ${1}${RESET}"
}

SUCCESS() {
  echo -e "${GREEN_BOLD}SUCCESS: ${1}${RESET}"
}

NOTE() {
  echo -e "${BLUE_BOLD}NOTE: ${1}${RESET}"
}

INPUT() {
  echo -e "${CYAN_BOLD}==INPUT==${1}${RESET}"
}

ABORT(){
    echo -e "${RED_BOLD}ABORT: ${1}${RESET}"
}

DEBUG(){
    echo -e "${YELLOW}DEBUG: ${1}${RESET}"
}

# Module and function specific functions
MODULE_INFO() {
  echo -e "${CYAN_BOLD}MODULE: ${1}${RESET}"
}

FUN_INFO() {
  echo -e "${BLUE_BOLD}FUNC: ${1}${RESET}"
}