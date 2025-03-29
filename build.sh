#!/bin/bash
# Install latest clang tooling
set -e -x -o pipefail

# Microchip Tools Require i386 Compatability as Dependency
dpkg --add-architecture i386 
apt-get update -yq 
apt-get install -yq --no-install-recommends build-essential bzip2 cpio curl unzip wget libc6:i386 libx11-6:i386 libxext6:i386 libstdc++6:i386 libexpat1:i386  libxext6 libxrender1 libxtst6 libgtk2.0-0 libxslt1.1 libncurses5-dev gcc python3 python3-pip python3.11-venv inetutils-ping openssh-client pkg-config dpkg-dev nano git sudo gnupg lsb-release software-properties-common procps libusb-1.0-0-dev

        
# Download and Install XC8 Compiler, Current Version
cd /tmp
wget https://ww1.microchip.com/downloads/aemDocuments/documents/DEV/ProductDocuments/SoftwareTools/xc8-v3.00-full-install-linux-x64-installer.run 
chmod a+x /tmp/xc8-v3.00-full-install-linux-x64-installer.run 
/tmp/xc8-v3.00-full-install-linux-x64-installer.run --mode unattended --unattendedmodeui none --netservername localhost --LicenseType FreeMode --prefix /opt/microchip/xc8 

wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add -
wget -O - https://apt.llvm.org/llvm.sh > /tmp/llvm.sh 
chmod +x /tmp/llvm.sh 

# FUCK YOU MCHP!!!!!!
tar -xf /opt/installer/MPLABX-*-linux-installer.tar
USER=root ./MPLABX-*-linux-installer.sh  --nox11 -- --unattendedmodeui none --mode unattended --installdir /opt/microchip/mplabx

/tmp/llvm.sh all

CLANGD_EXE=$(ls -1 /usr/bin/clangd-* | sort -hr | head -n1)
LLVM_VERSION=$(echo $CLANGD_EXE | cut -d- -f2)
apt-get install -y --no-install-recommends clang-format-$LLVM_VERSION
# Add in unversioned symlinks for clangd and clang-format
ln -sfv $CLANGD_EXE /usr/bin/clangd
ln -sfv /usr/bin/clang-format-$LLVM_VERSION /usr/bin/clang-format
ln -sfv /usr/bin/clang-format-diff-$LLVM_VERSION /usr/bin/clang-format-diff

# Install latest stable CMake 
CMAKE_VERSION=3.29.6
wget -O - https://github.com/Kitware/CMake/releases/download/v$CMAKE_VERSION/cmake-$CMAKE_VERSION-linux-x86_64.sh > /tmp/cmake_install.sh
/bin/bash /tmp/cmake_install.sh --skip-license  --prefix=/usr


# Bootstrap pipx with pipx
python3 -m venv /tmp/bootstrap_pipx
/tmp/bootstrap_pipx/bin/pip install pipx
PIPX_HOME=/opt/pipx PIPX_BIN_DIR=/usr/local/bin /tmp/bootstrap_pipx/bin/pipx install --global pipx
rm -rf /tmp/bootstrap_pipx

# install dpkgdeps
/home/crossbuilder/scripts/build_steps_amd64/125-dpkgdeps /home/crossbuilder/target

# Clean up
rm -rf /tmp/* 
apt-get clean 
apt-get autoremove -y 
rm -rf /var/lib/apt/lists/*
