#!/usr/bin/env bash

Read_file(){
    while read -r LINE; do
        echo  "--- $LINE"
    done < <(jq -c .[] < "$1")
}

# Путь к настройкам из json файла можно передать параметром в скрипт или сам
# файл положить в туже дерикторию со скриптом с названием json.json.
#
# Проверяем возможность прочитать файл

if [[ -r "$1" ]]; then
    Read_file "$1"
elif [[ -r "./json.json" ]]; then
    Read_file "./json.json"
else
    echo "The file does not exist or cannot be read"
fi

exit
#-----=====-----=====-----=====-----=====-----=====-----=====-----=====-----=====
