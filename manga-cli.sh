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
show_cover(){
    obj=$(curl --silent -G "https://api.mangadex.org/manga" --data-urlencode "includes[]=cover_art" --data-urlencode "title=$1" | jq -r ".data[0]")
    manga_id=$(echo $obj | jq -r .id)
    filename=$(echo $obj | jq -r '.relationships[] | select(.type=="cover_art").attributes.fileName')
    kitty icat "https://uploads.mangadex.org/covers/$manga_id/$filename.512.jpg"
    echo "$manga_id"
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
id=$(show_cover "$name")
echo $id
