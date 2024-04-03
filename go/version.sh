#!/bin/sh
version=$(git name-rev --tags --name-only HEAD | cut -d^ -f1)
[ $version = "undefined" ] && version=$(git rev-parse --short HEAD)
echo $version
