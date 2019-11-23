#!/bin/bash

../../Projects/mirror/main -config ./mirror.yaml

rm -rf docs

hugo -d docs

find ./docs -type f -name "*.html" | xargs sed -i -e  's+/manifest.json+https://cdn.jsdelivr.net/gh/befovy/blogback@master/docs/manifest.json+g'
find ./docs -type f -name "*.html" | xargs sed -i -e  's+"/dist/+"https://cdn.jsdelivr.net/gh/befovy/blogback@master/docs/dist/+g'
find ./docs -type f -name "*.html" | xargs sed -i -e  's+https://gitee.com/befovy/images/raw/master+https://cdn.jsdelivr.net/gh/befovy/images@master+g'

find ./docs -type f -name "*.xml" | xargs sed -i -e  's+/manifest.json+https://cdn.jsdelivr.net/gh/befovy/blogback@master/docs/manifest.json+g'
find ./docs -type f -name "*.xml" | xargs sed -i -e  's+"/dist/+"https://cdn.jsdelivr.net/gh/befovy/blogback@master/docs/dist/+g'
find ./docs -type f -name "*.xml" | xargs sed -i -e  's+https://gitee.com/befovy/images/raw/master+https://cdn.jsdelivr.net/gh/befovy/images@master+g'


hugo serve

git status

git add -u

git commit -m "hugo build"

git push
