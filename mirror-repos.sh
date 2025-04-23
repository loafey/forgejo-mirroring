textBold=$(tput bold)
textNormal=$(tput sgr0)
textOrange="\e[94m"
textRed="\e[91m"

githubPass=$(cat settings.json | jq ".github.api" -r)
githubUser=$(cat settings.json | jq ".github.user" -r)
forgejoUser=$(cat settings.json | jq ".forgejo.user" -r)
pass=$(cat settings.json | jq ".forgejo.admin" -r)
mirrorPass=$(cat settings.json | jq ".forgejo.api" -r)
forgejoURL=$(cat settings.json | jq ".forgejo.url" -r)
forgejoMirrorInterval=$(cat settings.json | jq ".forgejo.mirror_interval" -r)
forgejoMirrorDelay=$(cat settings.json | jq ".forgejo.mirror_delay" -r)

rm -rf temp
mkdir temp
mkdir temp/github
mkdir temp/forgejo
index=1
while [ true ]; do
    curl -L -s \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer $githubPass" \
        -H "X-GitHub-Api-Version: 2022-11-28" "https://api.github.com/search/repositories?q=user:$githubUser&page=$index" > temp.json
    if [[ $(cat temp.json | jq ".items[].full_name" -r) ]]; then
        index=$((index + 1))
        cat temp.json | jq ".items[]" -c | while read line; do
            name=$(echo $line | jq ".name" -r)
            echo $line > temp/github/$name.json
        done 
        sleep 1
    else 
        break
    fi
done
index=1
while [ true ]; do
    curl -s \
        -H "Content-Type: application/json" \
        -H "Authorization: token $mirrorPass" \
        -X "GET" \
        "$forgejoURL/api/v1/user/repos?page=$index" > temp.json
    if [[ $(cat temp.json | jq ".[]" -r) ]]; then
        index=$((index + 1))
        cat temp.json | jq ".[]" -c | while read line; do
            name=$(echo $line | jq ".name" -r)
            echo $line > temp/forgejo/$name.json
        done 
    else
        break
    fi
done

num=$(ls temp/github -1 | wc -l)
index=0
for line in temp/github/* ; do
    index=$((index + 1))
    if [ ! -f "temp/forgejo/$(basename $line)" ]; then
        echo "($index/$num) ❌ \"$line\" is not mirrored! Mirroring!"
        body="{
            \"auth_token\": \"$githubPass\",
            \"repo_name\": \"$(cat "$line" | jq ".name" -r)\",
            \"clone_addr\": \"$(cat "$line" | jq ".html_url" -r)\",
            \"mirror\": true,
            \"mirror_interval\": \"$forgejoMirrorInterval\",
            \"description\": $(cat "$line" | jq ".description"),
            \"private\": false,
            \"repo_owner\": \"$forgejoUser\",
            \"service\": \"github\",
            \"pull_requests\": true,
            \"releases\": true,
            \"issues\": true,
            \"labels\": true
        }"
        # echo $body | jq
        curl -s -i \
            -H "Accept: application/json" \
            -H "Content-Type: application/json" \
            -H "Authorization: token $pass" \
            -X POST \
            -H "Authorization: token $pass" \
            -d "$body" \
            "$forgejoURL/api/v1/repos/migrate" > log.json
        
        sleep $forgejoMirrorDelay
    else
        echo "($index/$num) ✅ \"$line\"! Is already mirrored!"
    fi
done
