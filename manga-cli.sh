#!/usr/bin/env bash

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
get_pages(){
    selected_chapters=$(curl --silent "https://api.mangadex.org/manga/$1/feed" | jq -r ".data[] | select(.attributes.volume==\"$2\" and .attributes.chapter==\"$3\")" )
    lang=$(echo $selected_chapters | jq -r ".attributes.translatedLanguage" | fzf --height 20% --border)
    chapter_id=$(echo $selected_chapters | jq -r ". | select(.attributes.translatedLanguage==\"$lang\").id")
    pages_obj=$(curl --silent "https://api.mangadex.org/at-home/server/$chapter_id")
    if [ -z "$pages_obj" ]; then
        exit
    fi
    echo $pages_obj
}
get_page(){
    base_url=$(echo "$1" | jq -r '.baseUrl')
    chapter_hash=$(echo "$1" | jq -r '.chapter.hash')
    page=$(echo "$1" | jq -r ".chapter.dataSaver[$2]")
    echo "$base_url/data-saver/$chapter_hash/$page"
}

clear
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
    exit -1
fi

volume=$(echo "$chapter" | awk '{print $2}')
chapter=$(echo "$chapter" | awk '{print $4}')

pages_obj=$(get_pages $id "$volume" "$chapter")
length=$(echo $pages_obj | jq -r '.chapter.data | length')
num=0
page=$(get_page "$pages_obj" $num)
clear
kitty icat "$page"
printf "\nn - next, p - previous, j - jump, q - quit"
read -rsn1 choice
while [ "$choice" != "q" ]
do
    while :
    do
        if [ "$choice" = "n" ]; then
            if [ $num -ge $((length-1)) ]; then
                num=0
            else
                ((num=num+1))
            fi
            break
        elif [ "$choice" = "p" ]; then
            if [ $num -le 0 ]; then
                $num=$(echo $length)
            fi
            ((num=num-1))
            break
        elif [ "$choice" = "j" ]; then
            printf "\npage number (0 - %s): " "$length"
            read new_num
            if [ $num -ge $length ] || [ $num -lt 0 ]; then
                read -rsn1 choice
                continue
            else
                num=$(echo $new_num)
                break
            fi
        else
            read -rsn1 choice
            continue
        fi
    done
    page=$(get_page "$pages_obj" $num)
    clear
    kitty icat "$page"
    printf "\nn - next, p - previous, j - jump, q - quit"
    read -rsn1 choice   
done


