#!/bin/bash

KuboVersion=$1
GoVersion=$2

[ -z "$KuboVersion" ] && KuboVersion="latest"
[ -z "$GoVersion" ] && GoVersion="latest"

printf_style () {
    if [ "$2" == "info" ] ; then
        COLOR="96m";
    elif [ "$2" == "success" ] ; then
        COLOR="92m";
    elif [ "$2" == "warning" ] ; then
        COLOR="93m";
    elif [ "$2" == "danger" ] ; then
        COLOR="91m";
    else #default color
        COLOR="0m";
    fi

    STARTCOLOR="\e[$COLOR";
    ENDCOLOR="\e[0m";

    printf "$STARTCOLOR%b$ENDCOLOR" "$1";
}

# Check packages
printf_style "Checking packages...\n" "info"
missingPackage=false

git --version
if [ $? -ne 0 ]; then
	printf_style "missing package: git\n" "danger"
	missingPackage=true
fi

go version
if [ $? -ne 0 ]; then
	printf_style "missing package: go\n" "danger"
	missingPackage=true
fi

make --version | head -n1
if [ $? -ne 0 ]; then
	printf_style "missing package: make (base-devl)\n" "danger"
	missingPackage=true
fi

if $missingPackage ; then
	printf_style "\nExiting because of missing package.\n" "danger"
	exit
fi

# Preparation for Build
BUILDDIR="$(realpath $(dirname "$0"))/build"
mkdir -p $BUILDDIR
cd $BUILDDIR
rm -rf $BUILDDIR/kubo

printf_style "\nCloning IPFS Kubo\n" "info"
git clone https://github.com/ipfs/kubo
cd kubo
if [[ $KuboVersion != "latest" ]]; then
	KuboVersionHash=$(git describe --tags)
else
	KuboVersion=$(git describe --tags --abbrev=0)
	KuboVersionHash=$(git rev-list -n 1 $KuboVersion)
fi
printf_style "\nChecking out ${KuboVersion} (${KuboVersionHash})\n" "info"
git config advice.detachedHead false
git checkout ${KuboVersion} -f

if [ $? -ne 0 ]; then
	printf_style "Tag not found.\n" "danger"
	exit
fi

versionoverwrite=$(grep "${KuboVersion} " ../../../versions.txt | awk '{ print $2}')
if [ $versionoverwrite ]; then
	GoVersion=$versionoverwrite
fi

if [[ $GoVersion != "latest" ]]; then
	printf_style "Installing go version: ${GoVersion}\n" "warning"

	GOPATH=$(go env GOPATH)
	GOROOT=$(go env GOROOT)
	go install golang.org/dl/${GoVersion}@latest
	govers=$GOPATH/bin/$GoVersion
	$govers download
	GOVERSIONROOT=$($govers env GOROOT)
	GOVERSIONPATH=$($govers env GOPATH)

	cp $GOROOT/go.env $GOVERSIONROOT/go.env

	export GOROOT=$GOVERSIONROOT
	export GOPATH=$GOVERSIONPATH
else
	govers=$(which go)
fi

export GO111MODULE=on

printf_style "\nFetching go-ds-s3 plugin\n" "info"
$govers get github.com/ipfs/go-ds-s3/plugin@latest
echo -en "\ns3ds github.com/ipfs/go-ds-s3/plugin 0" >> plugin/loader/preload_list

if [[ $GoVersion != "latest" ]]; then
	sed -i "s\GOCC ?= go\GOCC ?= ${govers}\g" Rules.mk
fi
sed -Ei "s/const CurrentVersionNumber = \"(.*)\"/const CurrentVersionNumber = \"\1-s3\"/g" version.go

# Build

printf_style "\nBuilding...\n" "info"
make build
$govers mod tidy
make build

if [ $? -ne 0 ]; then
	printf_style "Build failed.\n" "danger"
	exit
fi

cd ..

rm -rf $BUILDDIR/release/ipfs
mkdir -p $BUILDDIR/release
cp $BUILDDIR/kubo/cmd/ipfs/ipfs $BUILDDIR/release/ipfs
printf_style "\nBuild to: $BUILDDIR/release/ipfs\n" "info"
$BUILDDIR/release/ipfs version
