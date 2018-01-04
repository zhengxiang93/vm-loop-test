#!/bin/bash

# Written to be called from migration-test.sh

PROGNAME=create-guest-kernel.sh
LINUXDIR=linux

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

if [[ -e Image ]]; then
	error_exit "Kernel image Image already exists."
fi

if [[ -d linux ]]; then
	echo "Linux directory already exists.  Skipping clone."
else
	git clone git://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git $LINUXDIR
fi

cd $LINUXDIR
VERSION=`git tag | grep '^v[0-9]\+\.[0-9]\+$' | sort --version-sort | tail -n 1`
echo "Building Linux $VERSION..."
git checkout $VERSION
make defconfig
make -j `nproc`
cp arch/arm64/boot/Image ../.
cd ..

echo "I have bulid you a brand new kernel $VERSION."
read -p "Would you like me to clean up after myself and remove the source dir? [y/N]" -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
	rm -rf $LINUXDIR
fi
