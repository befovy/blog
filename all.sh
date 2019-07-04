#!/bin/bash

../../Projects/mirror/main -config ./mirror.yaml

hugo

hugo serve

cd public

git status

git add -u

git add post/.

git commit -m "hugo build"

git push

cd -
