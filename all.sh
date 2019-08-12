#!/bin/bash

../../Projects/mirror/main -config ./mirror.yaml

hugo -d docs

hugo serve

git status

git add -u

git commit -m "hugo build"

git push
