#!/bin/bash

../../Projects/mirror/main -config ./mirror.yaml

rm -rf docs

hugo -d docs

hugo serve

git status

git add .

git commit -m "hugo build"

hashid=`git rev-parse --short HEAD`

echo $hashid

replaceCdn(){
    find ./docs -type f -name "*.html" | xargs sed -i '' "s+$1+$2+g"
    find ./docs -type f -name "*.xml" | xargs sed -i '' "s+$1+$2+g"
}

replaceCdn https://gitee.com/befovy/images/raw/master https://cdn.jsdelivr.net/gh/befovy/images@master

replaceCdn /manifest.json https://cdn.jsdelivr.net/gh/befovy/blogback@$hashid/docs/manifest.json
replaceCdn \"/dist/ \"https://cdn.jsdelivr.net/gh/befovy/blogback@$hashid/docs/dist/
replaceCdn /favicon-32x32.png https://cdn.jsdelivr.net/gh/befovy/blogback@$hashid/docs/favicon-32x32.png
replaceCdn /favicon-16x16.png https://cdn.jsdelivr.net/gh/befovy/blogback@$hashid/docs/favicon-16x16.png
replaceCdn https://befovy.com/css/ https://cdn.jsdelivr.net/gh/befovy/blogback@$hashid/docs/css/
replaceCdn https://befovy.com/js/ https://cdn.jsdelivr.net/gh/befovy/blogback@$hashid/docs/js/
replaceCdn https://befovy.com/images/ https://cdn.jsdelivr.net/gh/befovy/blogback@$hashid/docs/images/
replaceCdn https:\\\\/\\\\/befovy.com\\\\/\\\\/searchindex.json  https:\\\\/\\\\/cdn.jsdelivr.net\\\\/gh\\\\/befovy\\\\/blogback@$hashid\\\\/docs\\\\/searchindex.json

git add .

git commit -m "hugo build"

git push
