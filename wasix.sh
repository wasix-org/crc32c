#!/usr/bin/env bash
set -e
WORKDIR=$(pwd)

export PATH="$WORKDIR:$PATH"

# Assert that the required dependencies are available
assert_deps() {
  for cmd in "$@"; do
    if ! command -v "$1" >/dev/null 2>&1; then
      echo "❌ You need to have $1 available."
      exit 1
    fi
  done
}
assert_deps wasmer python3 pip git wasix-clang wasix-clang++

# Assert that WASIX_SYSROOT is set
if test -z "$WASIX_SYSROOT" ; then
    echo "WASIX_SYSROOT is not set. Please set it to the sysroot path (Something like /home/lennart/Documents/wasix-libc/sysroot)."
    exit 1
fi

# Prepare the package repo
git submodule update --init --recursive
cd crc32c
git clean -d -x -f
if compgen -G "../patches/*.patch" > /dev/null; then
    git am ../patches/*.patch
fi
cd "$WORKDIR"

# Optain python root
if [ ! -d python ]; then
    wasmer package download zebreus/python-ehpic -o python.webc
    wasmer package unpack python.webc --out-dir python
fi

# Create a venv for cross compilation based on the python root
python3 -m venv ./native-venv
source ./native-venv/bin/activate
pip install crossenv
python3 -m crossenv $(pwd)/python/tmp/wasix-install/cpython/bin/python3.wasm ./cross-venv --cc "wasix-clang" --cxx "wasix-clang"
source ./cross-venv/bin/activate
python3 -m pip install cython build

# Build the wheel
cd crc32c
python3 -m build --wheel

# Copy the wheel to the current directory
cp crc32c/dist/crc32c-*-wasix_wasm32.whl .