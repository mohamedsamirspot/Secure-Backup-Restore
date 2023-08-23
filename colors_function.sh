#!/bin/bash


#######################################
# Print a message in a given color.
# Arguments:
#   Color. eg: green, red
#######################################
function print_color(){
  NC='\033[0m' # No Color
  case $1 in
    "red") COLOR='\033[0;31m' ;;
    "green") COLOR='\033[0;32m' ;;
    "blue") COLOR='\033[0;34m' ;;
    "*") COLOR='\033[0m' ;;
  esac

  echo -e "${COLOR} $2 ${NC}"
}