#!/usr/bin/bash
set -euxo pipefail

GNU_PATH="/usr/lib/x86_64-linux-gnu"
WORKDIR="${WORKDIR:-"$HOME/work"}"
echo "Working dir: $WORKDIR"

# Install dependencies
apt-get update
apt-get install -y software-properties-common
apt-add-repository ppa:ev3dev/tools
apt-get install -y wget git build-essential ncurses-dev fakeroot bc u-boot-tools lzop flex bison libssl-dev gcc-arm-linux-gnueabihf gcc-arm-linux-gnueabi

wget https://releases.linaro.org/components/toolchain/binaries/6.4-2018.05/arm-linux-gnueabihf/gcc-linaro-6.4.1-2018.05-x86_64_arm-linux-gnueabihf.tar.xz
tar xf gcc-linaro-6.4.1-2018.05-x86_64_arm-linux-gnueabihf.tar.xz
mv gcc-linaro-6.4.1-2018.05-x86_64_arm-linux-gnueabihf "$GNU_PATH/gcc-linaro-arm-linux-gnueabihf-6.4"

# Fix error due to deprecated git:// protocol on GitHub
git config --global url."https://".insteadOf git://

# Create working directory
mkdir -p $WORKDIR
cd $WORKDIR

# Clone environment
git clone --depth 1 --recursive --branch ev3dev-stretch https://github.com/ev3dev/ev3dev-buildscripts.git
git clone --depth 1 --recursive --branch ev3dev-stretch https://github.com/ev3dev/ev3-kernel.git

# Update submodule
cd ev3-kernel/drivers/lego
git pull origin ev3dev-stretch
cd $WORKDIR

# Build the EV3 kernel
cd ev3dev-buildscripts
echo "export EV3DEV_MAKE_ARGS=-j$(nproc)" > local-env
./build-kernel
cd $WORKDIR

# Download Wi-Fi driver
git clone --depth 1 https://gitee.com/coolflyreg163/rtl8821cu.git
cd rtl8821cu

# Compile Wi-Fi driver
BIN_PATH="$GNU_PATH/gcc-linaro-arm-linux-gnueabihf-6.4/bin"
make ARCH=arm KVER=4.14 \
KSRC="$WORKDIR/ev3dev-buildscripts/build-area/linux-ev3dev-ev3-obj" \
CC="$BIN_PATH/arm-linux-gnueabihf-gcc" \
LD="$BIN_PATH/arm-linux-gnueabihf-ld"

