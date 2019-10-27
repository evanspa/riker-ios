#!/bin/bash

readonly projectName="riker-ios"
readonly version="$1"
readonly tagLabel="${version}"

# need to figure out how I'm going to use this tool, if at all...
#agvtool new-version -all ${version}
git add .
git commit -m "release: ${version}"

git tag -f -a $tagLabel -m "version $version"
git push -f --tags
