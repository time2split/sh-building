#!/usr/bin/env bash
# Install the build/CI system dependencies


DIR="$( dirname -- "${BASH_SOURCE[0]}" )";
RES="$DIR/resources"

rsync --ignore-existing -r $RES/* .

npm install

