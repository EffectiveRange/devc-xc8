#!/bin/bash
# Install latest clang tooling
set -e -x -o pipefail


# Microchip Tools Require i386 Compatability as Dependency
dpkg --add-architecture i386 
apt_update -yq 
apt_install -yq --no-install-recommends build-essential bzip2 cpio curl unzip wget libc6:i386 libx11-6:i386 libxext6:i386 libstdc++6:i386 libexpat1:i386  libxext6 libxrender1 libxtst6 libgtk2.0-0 libxslt1.1 libncurses5-dev gcc python3 python3-pip python3.11-venv inetutils-ping openssh-client pkg-config dpkg-dev nano git sudo gnupg lsb-release software-properties-common procps libusb-1.0-0-dev file less gdb

# add ER repo
wget -qO- https://raw.githubusercontent.com/EffectiveRange/infrastructure-configuration/refs/heads/main/aptrepo/apt-server/add_repo.sh | bash

# install packaging tools
. /etc/os-release && \
if [ "${PACKAGING_TOOLS_VER}" = "latest" ]; then \
    apt_install -y --no-install-recommends packaging-tools; \
else \
    wget -O /tmp/packaging-tools.deb \
    "https://github.com/EffectiveRange/packaging-tools/releases/download/${PACKAGING_TOOLS_VER}/${VERSION_CODENAME}_packaging-tools_${PACKAGING_TOOLS_VER#v}-1_all.deb" && \
    apt_install -y --no-install-recommends /tmp/packaging-tools.deb && \
    rm -f /tmp/packaging-tools.deb; \
fi


XC8_VERSION=3.10
        
# Download and Install XC8 Compiler, Current Version
cd /tmp
wget https://ww1.microchip.com/downloads/aemDocuments/documents/DEV/ProductDocuments/SoftwareTools/xc8-v$XC8_VERSION-full-install-linux-x64-installer.run 
chmod a+x /tmp/xc8-v$XC8_VERSION-full-install-linux-x64-installer.run 
/tmp/xc8-v$XC8_VERSION-full-install-linux-x64-installer.run --mode unattended --unattendedmodeui none --netservername localhost --LicenseType FreeMode --prefix /opt/microchip/xc8 

rm -vf /tmp/xc8-v$XC8_VERSION-full-install-linux-x64-installer.run

wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add -
wget -O - https://apt.llvm.org/llvm.sh > /tmp/llvm.sh 
chmod +x /tmp/llvm.sh 

# FUCK YOU MCHP!!!!!!
tar -xf /opt/installer/MPLABX-*-linux-installer.tar
USER=root ./MPLABX-*-linux-installer.sh  --nox11 -- --unattendedmodeui none --mode unattended --installdir /opt/microchip/mplabx

/bin/bash /opt/microchip/mplabx/mplab_platform/bin/packmanagercli.sh  --update-packs

# free up space
rm -vf /opt/installer/MPLABX-*-linux-installer.tar

/tmp/llvm.sh all

CLANGD_EXE=$(ls -1 /usr/bin/clangd-* | sort -hr | head -n1)
LLVM_VERSION=$(echo $CLANGD_EXE | cut -d- -f2)
apt_install -y --no-install-recommends clang-format-$LLVM_VERSION
# Add in unversioned symlinks for clangd and clang-format
ln -sfv $CLANGD_EXE /usr/bin/clangd
ln -sfv /usr/bin/clang-format-$LLVM_VERSION /usr/bin/clang-format
ln -sfv /usr/bin/clang-format-diff-$LLVM_VERSION /usr/bin/clang-format-diff

# Install latest stable CMake but remove the installed one first
apt remove -y cmake || true
CMAKE_VERSION=3.29.6
# Install latest stable CMake 
wget -O - https://github.com/Kitware/CMake/releases/download/v$CMAKE_VERSION/cmake-$CMAKE_VERSION-linux-x86_64.sh > /tmp/cmake_install.sh
/bin/bash /tmp/cmake_install.sh --skip-license  --prefix=/usr

mkdir -p /tmp/fake-cmake

cd /tmp/fake-cmake

cat << EOF > /tmp/fake-cmake/fake-cmake
Section: misc
Priority: optional
Standards-Version: 4.6.0

Package: fake-cmake
Version: 100:1.0
Provides: cmake
Conflicts: cmake
Replaces: cmake
Description: Dummy package to satisfy cmake dependency (custom cmake installed from source)
 This package does not contain cmake; it only exists so that apt
 considers the cmake dependency satisfied. Real cmake is installed
 under /usr/local from source.
EOF

equivs-build fake-cmake

dpkg -i fake-cmake_*.deb

# Bootstrap pipx with pipx
python3 -m venv /tmp/bootstrap_pipx
/tmp/bootstrap_pipx/bin/pip install pipx
PIPX_HOME=/opt/pipx PIPX_BIN_DIR=/usr/local/bin /tmp/bootstrap_pipx/bin/pipx install --global pipx
rm -rf /tmp/bootstrap_pipx

# install dpkgdeps
/home/crossbuilder/scripts/build_steps_amd64/125-dpkgdeps /home/crossbuilder/target

# install coverage tools
pipx install --global gcovr
pipx install --global markdownify 

# Clean up
rm -rf /tmp/* 
apt-get clean 
apt-get autoremove -y 
rm -rf /var/lib/apt/lists/*
