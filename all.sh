#!/bin/bash

../../Projects/mirror/main -config ./mirror.yaml

rm -rf docs

hugo -d docs


# replaceCdn(){
#     echo "第一个参数为 $1 !"
#     echo "第二个参数为 $2 !"
#     echo "第二个参数为 $3 !"
#     find ./docs -type f -name "*.$1" | xargs sed -i '' "s+$2+$3+g"
# }

# replaceCdn html /manifest.json https://cdn.jsdelivr.net/gh/befovy/blogback@master/docs/manifest.json

find ./docs -type f -name "*.html" | xargs sed -i '' 's+/manifest.json+https://cdn.jsdelivr.net/gh/befovy/blogback@master/docs/manifest.json+g'
find ./docs -type f -name "*.html" | xargs sed -i '' 's+"/dist/+"https://cdn.jsdelivr.net/gh/befovy/blogback@master/docs/dist/+g'
find ./docs -type f -name "*.html" | xargs sed -i '' 's+https://gitee.com/befovy/images/raw/master+https://cdn.jsdelivr.net/gh/befovy/images@master+g'

find ./docs -type f -name "*.xml" | xargs sed -i '' 's+/manifest.json+https://cdn.jsdelivr.net/gh/befovy/blogback@master/docs/manifest.json+g'
find ./docs -type f -name "*.xml" | xargs sed -i '' 's+"/dist/+"https://cdn.jsdelivr.net/gh/befovy/blogback@master/docs/dist/+g'
find ./docs -type f -name "*.xml" | xargs sed -i ''  's+https://gitee.com/befovy/images/raw/master+https://cdn.jsdelivr.net/gh/befovy/images@master+g'


hugo serve

git status

git add -u

git commit -m "hugo build"

# git push
