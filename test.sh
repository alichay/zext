#!/bin/sh

testlist=`find tests -name '*.odin' | tr '\n' ' '`
testlist="${testlist//tests\//}"
testlist="${testlist//.odin/}"


if [ $# -eq 0 ]; then
	echo "Please specify a test to run."
	echo "Valid tests: ${testlist}"
	exit 1
fi

exepath="tests/$1"
srcpath="$exepath.odin"

if [ ! -e "$srcpath" ]; then
	echo "Test \"$1\" does not exist!"
	echo "Valid tests: ${testlist}"
	exit 2
fi

echo "Running test: $srcpath"
echo "------------------"
echo "Building"
../Odin/odin build "$srcpath" -collection=zext=lib
echo "Running"
$exepath
rm $exepath
echo "Done"