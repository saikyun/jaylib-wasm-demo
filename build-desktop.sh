#! /bin/sh

PRELOAD_DIR=cross
LIB_DIR=${PRELOAD_DIR}/jpm_tree/lib

# exit if some part fails
set -e

if [[ -z "${JAYLIB_WASM_DEMO_SKIP_DEPS}" ]]; then
    echo "[Preparing janet amalgamated bits]..."
    cd janet && \
        make clean && \
        make && \
        cd ..

    echo "[Preparing libraylib.a]..."
    cd freja-jaylib/raylib/src && \
        make clean && \
        make &&
        cd ../../..

    echo "[Preparing freja-jaylib.janet shim]..."
    mkdir -p ${LIB_DIR} && \
        janet make-freja-jaylib-janet-shim.janet \
              freja-jaylib/src ${LIB_DIR}/freja-jaylib.janet
fi

[ -e janet/build/c/janet.c ] || \
    (echo "janet/build/c/janet.c not found, please build" && exit 1)

[ -e freja-jaylib/raylib/libraylib.a ] || \
    (echo "freja-jaylib/raylib/libraylib.a not found, please build" && exit 1)

echo "[Compiling output]..."
gcc \
    -O0 -g3 \
    -Wall \
    -o cross/main \
    main.c \
    janet/build/c/janet.c \
    freja-jaylib/raylib/libraylib.a \
    -Ijanet/build \
    -Ifreja-jaylib/raylib/src \
    -lm -lpthread -ldl

