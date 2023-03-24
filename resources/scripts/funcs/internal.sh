#!/bin/bash

function checkFile(){
    if [ -z "$1" ]; then
        return 1
    else
        if [ -e "$file" ] && [ -r "$file" ]; then
            echo -e "\tFile $file exists and is readable"
            return 0
        elif [ -e "$file_path" ]; then
            echo -e "\tFile $file exists but is not readable"
            return 1
        else
            echo -e "\tFile $file does not exist"
            return 1
        fi
    fi
}