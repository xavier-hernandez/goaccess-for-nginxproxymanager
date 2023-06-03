#!/bin/bash

function checkFile(){
    if [ -z "$1" ]; then
        return 1
    else
        if [ -e "$1" ] && [ -r "$1" ]; then
            echo "\tDebug1=$1"
            echo -e "\tFile $1 exists and is readable"
            return 0
        elif [ -e "$1" ]; then
            echo "\tDebug2=$1"
            echo -e "\tFile $1 exists but is not readable"
            return 1
        else
            echo "\tDebug3=$1"
            echo -e "\tFile $1 does not exist"
            return 1
        fi
    fi
}