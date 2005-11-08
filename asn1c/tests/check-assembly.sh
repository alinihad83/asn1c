#!/bin/sh

#
# This script is designed to quickly create lots of files in underlying
# test-* directories, do lots of other magic stuff and exit cleanly.
#

if [ "x$1" = "x" ]; then
	echo "Usage: $0 <check-NN.c>"
	exit
fi

# Compute the .asn1 spec name by the given file name.
source=`echo "$1" | sed -e 's/.*\///'`
testno=`echo "$source" | cut -f2 -d'-' | cut -f1 -d'.'`

args=`echo "$source" | sed -e 's/\.c[c]*$//'`
testdir=test-${args}

OFS=$IFS
IFS="."
set $args
shift
IFS=$OFS
AFLAGS="$@"

touch ${testdir}-FAILED		# Create this file to ease post mortem analysis

if [ ! -d $testdir ]; then
	mkdir $testdir		|| exit $?
fi
cd $testdir			|| exit $?
rm -f ./$source 2>/dev/null
ln -fns ../$source		|| exit $?

asn_module=`echo ../../../tests/${testno}-*.asn1`

# Create a Makefile for the project.
cat > Makefile <<EOM
# This file is autogenerated by ../$0

COMMON_FLAGS= -I. -DEMIT_ASN_DEBUG
CFLAGS=\${COMMON_FLAGS} ${CFLAGS}
CXXFLAGS=\${COMMON_FLAGS} ${CXXFLAGS}

CC ?= ${CC}

all: check-executable
check-executable: compiled-module *.c*
	@rm -f *.core
	\$(CC) \$(CFLAGS) -o check-executable -lm *.c*

# Compile the corresponding .asn1 spec.
compiled-module: ${asn_module} ../../asn1c
	../../asn1c -S ../../../skeletons -Wdebug-compiler	\\
		${AFLAGS} ${asn_module}
	@touch compiled-module

check-succeeded: check-executable
	@rm -f check-succeeded
	./check-executable
	@touch check-succeeded

check: check-succeeded

clean:
	@rm -f *.o check-executable
EOM

# Perform building and checking
make check || exit $?

rm -f ../${testdir}-FAILED

exit 0
