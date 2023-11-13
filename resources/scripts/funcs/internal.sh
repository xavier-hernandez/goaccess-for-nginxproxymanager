#!/bin/bash

function checkFile(){
    if [ -z "$1" ]; then
        return 1
    else
        if [ -e "$1" ]; then
            echo -e "\tFile $1 exists"
            return 0
        else
            echo -e "\tFile $1 does not exist"
            return 1
        fi
    fi
}

function is_integer() {
    if [[ $1 =~ ^[0-9]+$ ]]; then
        return 0  # It's an integer
    else
        return 1  # It's not an integer
    fi
}