#!/usr/bin/env bash

set -e
cd $(dirname "$(realpath "$0")")/../../

BASE_DIR="$(pwd)"

ALL_REPOS="${ALL_REPOS:-rmm cudf cugraph
                        notebooks notebooks-contrib}"

for REPO in $ALL_REPOS; do
    cd "$BASE_DIR/$REPO" && git pull upstream $(git branch --show-current) && cd -
done