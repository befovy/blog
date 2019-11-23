#!/bin/bash

../../Projects/mirror/main -config ./mirror.yaml

rm -rf docs

hugo -d docs


replaceCdn(){
    find ./docs -type f -name "*.html" | xargs sed -i '' "s+$1+$2+g"
    find ./docs -type f -name "*.xml" | xargs sed -i '' "s+$1+$2+g"
}

replaceCdn /manifest.json https://cdn.jsdelivr.net/gh/befovy/blogback@master/docs/manifest.json
replaceCdn https://gitee.com/befovy/images/raw/master https://cdn.jsdelivr.net/gh/befovy/images@master
replaceCdn \"/dist/ \"https://cdn.jsdelivr.net/gh/befovy/blogback@master/docs/dist/


hugo serve

git status

git add -u

git commit -m "hugo build"

git push
