#!/usr/bin/env bash
set -e

rm -rf python.webc python cross-venv native-venv

cd crc32c
git clean -d -x -f
cd -

git submodule update --init --recursive