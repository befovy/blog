#!/bin/bash

go run github.com/befovy/mirror/app -config ./mirror.yaml

hugo

hugo serve

cd public

git status

git add -u

git commit -m "hugo build"

git push

cd -
