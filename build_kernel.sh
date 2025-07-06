#!/bin/bash

# Proton Clang path
export PATH=$HOME/proton-clang/bin:$PATH

# Toolchain and build settings
export ARCH=arm64
export SUBARCH=arm64
export CC=clang
export CROSS_COMPILE=aarch64-linux-gnu-
export CROSS_COMPILE_COMPAT=arm-linux-gnueabi-
export ANDROID_MAJOR_VERSION=r

# Optional flags
export KCFLAGS=-w
export CONFIG_SECTION_MISMATCH_WARN_ONLY=y

# Output folder
OUT_DIR=out

# Defconfig
DEFCONFIG=a22x_defconfig

# Start build
make O=$OUT_DIR $DEFCONFIG
make -j$(nproc) O=$OUT_DIR

# Copy final kernel image
cp $OUT_DIR/arch/arm64/boot/Image arch/arm64/boot/Image