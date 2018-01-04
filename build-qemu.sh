#!/bin/bash

# Written to be called from migration-test.sh

PROGNAME=build-qemu.sh
QEMUDIR=qemu

function error_exit
{
	#	----------------------------------------------------------------
	#	Function for exit due to fatal program error
	#		Accepts 1 argument:
	#			string containing descriptive error message
	#	----------------------------------------------------------------

	echo "${PROGNAME}: ${1:-"Unknown Error"}" 1>&2
		exit 2
}

declare -a tools=("git" "gcc")
for tool in "${tools[@]}"
do
	if ! tool_loc="$(type -p "$tool")" || [ -z "$tool_loc" ]; then
		  error_exit "$tool is required, please install, aborting"
	fi
done

if [[ -e qemu-system-aarch64 ]]; then
	error_exit "qemu binary already exists."
fi

if [[ -d $QEMUDIR ]]; then
	echo "QEMU source directory already exists.  Skipping clone."
else
	git clone git://git.qemu.org/qemu.git $QEMUDIR
fi

pushd $QEMUDIR
VERSION=`git tag | grep '^v[0-9]\+\.[0-9]\+\.[0-9]\+$' | sort | tail -n 1`
echo "Building QEMU $VERSION..."
git checkout $VERSION
git submodule update --init dtc
mkdir -p build
pushd build
../configure --target-list=aarch64-softmmu
make -j `nproc`
popd
popd
cp $QEMUDIR/build/aarch64-softmmu/qemu-system-aarch64 .

echo "I have bulid you a brand new QEMU $VERSION for you."
read -p "Would you like me to clean up after myself and remove the source dir? [y/N]" -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
	rm -rf $QEMUDIR
fi
