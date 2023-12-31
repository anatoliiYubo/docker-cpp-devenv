#!/usr/bin/env bash

# ______________________________________________________
# Container bootstrap script.
#
# @file     bootstrap.sh
# @author   Mustafa Kemal GILOR <mustafagilor@gmail.com>
# @date     10.05.2020
# 
# All rights reserved. Licensed under the MIT license. 
# See LICENSE in the project root for license information.
# 
# SPDX-License-Identifier:	MIT
# ______________________________________________________

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" 
done

SCRIPT_ROOT="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"

# Enable abort on error
set -e

readonly apt_command='apt-get'
readonly apt_args='-y install'
readonly pip_command='pip3'
readonly pip_args='install'

# Packages to be installed via apt
apt_package_list=(
    # Verify git, process tools, lsb-release (useful for CLI installs) installed
    git git-flow iproute2 procps lsb-release
    # Install GNU GCC Toolchain, version 10
    gcc-13 g++-13 gdb libstdc++-13-dev libc6-dev
    # Install LLVM Toolchain, version 10
    llvm-17 lldb-17 clang-17 clangd-16 libc++-15-dev
    # Install build generator & dependency resolution and build accelarator tools
    make ninja-build autoconf automake libtool m4 cmake ccache
    # Install python & pip
    python3 python3-pip
    # Install static analyzers, formatting, tidying,
    clang-format-15 clang-tidy-15 iwyu cppcheck
    # Debugging/tracing
    valgrind 
    # Install test framework & benchmark 
    libgtest-dev libgmock-dev libbenchmark-dev
    # Install code coverage
    lcov gcovr
    # Documentation & graphing
    doxygen doxygen-latex doxygen-doxyparse graphviz
    # User-specified packages
    ${apt_extra_package_list[@]}
)

# Packages to be installed via pip
pip_package_list=(
    conan
    # User-specified packages
    ${pip_extra_package_list[@]}
)

apt-get update && apt-get -y install --no-install-recommends apt-utils dialog 2>&1 \
&& 
# Install apt packages
$apt_command $apt_args ${apt_package_list[@]} \
&& 
# Install pip packages
( ( which $pip_command && $pip_command $pip_args ${pip_package_list[@]}) || true ) \
&& 
# Create a non-root user to use if preferred - see https://aka.ms/vscode-remote/containers/non-root-user.
groupadd --gid $USER_GID $USERNAME \
&& 
useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME \
&& 
# [Optional] Add sudo support for the non-root user
apt-get install -y sudo \
&& echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
&& chmod 0440 /etc/sudoers.d/$USERNAME \
&& 
# Clean up
apt-get autoremove -y \
&& apt-get clean -y \
&& rm -rf /var/lib/apt/lists/* 
