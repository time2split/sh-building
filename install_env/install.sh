#!/usr/bin/env bash

DIR="$( dirname -- "${BASH_SOURCE[0]}" )";

echo "Installing git-cliff"
"$DIR/cargo.sh"
"$DIR/git-cliff.sh"

echo "Installing npm"
"$DIR/nvm.sh"
"$DIR/npm.sh"
