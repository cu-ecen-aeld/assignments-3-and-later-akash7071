#!/bin/sh

filesdir=$1
writestr=$2

filedir=$(dirname "$filesdir")
filename=$(basename "$filesdir")

if ! [ $# -gt 1 ]
then 
	echo "Not enough parameters"
	exit 1
fi

mkdir -p "${filedir}"


touch "${filesdir}" && echo "${writestr}" >> "$filesdir"