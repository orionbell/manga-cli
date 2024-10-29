#!/usr/bin/env bash

setup(){
    clear
    if [ ! -d "$DIRECTORY" ]; then
        mkdir -p ~/.cache/manga-cli
    fi
}
get_fullname(){
    search_results=$(curl --silent -G "https://api.mangadex.org/manga" --data-urlencode "title=$name" | jq -r ".data[]")
    if [ -z "$search_results" ];then
        exit
    fi
    name=$(echo $search_results | jq -r '.attributes.title.en' | fzf )
    echo "$name"
}
get_cover(){
    obj=$(curl --silent -G "https://api.mangadex.org/manga" --data-urlencode "includes[]=cover_art" --data-urlencode "title=$1" | jq -r ".data[0]")
    manga_id=$(echo $obj | jq -r .id)
    filename=$(echo $obj | jq -r '.relationships[] | select(.type=="cover_art").attributes.fileName')
    echo "https://uploads.mangadex.org/covers/$manga_id/$filename.512.jpg"
}
get_chapter(){
    chapters=$(curl --silent "https://api.mangadex.org/manga/$1/feed" | jq -r '.data[]')
    if [ -z "$chapters" ]; then
        exit
    fi
    chapter=$(echo $chapters | jq -r '"Vol \(.attributes.volume) Chapter \(.attributes.chapter)"'| fzf --height 30% --border)
    echo "$chapter"
}
#download_page(){}
#clean(){}

setup
printf "Manga name: "
read name
name=$(get_fullname "$name")
if [ -z "$name" ]; then
    printf "No result have been found :(\n"
    exit -1
fi
cover=$(get_cover "$name")
kitty icat "$cover"
id=$(echo $cover | awk -F '/' '{print $5}')
chapter=$(get_chapter $id)
if [ -z "$chapter" ]; then
    printf "No chapters have been found :("
fi
echo "$chapter"


