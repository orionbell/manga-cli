#!/usr/bin/env bash

setup(){
    clear
    if [ ! -d "$DIRECTORY" ]; then
        mkdir -p ~/.cache/manga-cli
    fi
}
get_fullname(){
    search_results=$(curl --silent -G "https://api.mangadex.org/manga" --data-urlencode "title=$name" | jq -r .data)
    if [ -z "$search_results" ];then
        printf "Not results found :(\n"
        return 1
    fi
    name=$(echo $search_results | jq -r '.[].attributes.title.en' | fzf )
    echo "$name"
}

#download_page(){}
#clean(){}

setup
printf "Manga name: "
read name
name=$(get_fullname "$name")
if [ "$name" == "1" ]; then
    exit -1
fi
echo $name
