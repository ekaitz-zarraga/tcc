#! /bin/sh

set -e

export V
if test "$V" = 1 -o "$V" = 2; then
    set -x
fi

arch=$(uname -m)
case $arch in
    aarch*)
         cpu=arm
         tcc_cpu=arm
         triplet=arm-linux-gnueabihf
         cross_prefix=${triplet}-
         ;;
     arm*|aarch*)
         cpu=arm
         tcc_cpu=arm
         triplet=arm-unknown-linux-gnueabihf
         cross_prefix=${triplet}-
         ;;
     *)
         cpu=x86
         tcc_cpu=i386
         triplet=i686-unknown-linux-gnu
         cross_prefix=${triplet}-
         ;;
esac
export cpu
export cross_prefix
export tcc_cpu
export triplet

GCC_TCC=${GCC_TCC-./${cross_prefix}tcc}
TCC=${TCC-./tcc}
MES_PREFIX=${MES_PREFIX-mes}
OBJDUMP=${OBJDUMP-objdump}
DIFF=${DIFF-diff}

unset C_INCLUDE_PATH LIBRARY_PATH

if test "$tcc_cpu" = i386; then
    libtcc1=-ltcc1
elif test "$tcc_cpu" = arm; then
    libtcc1='-lc -ltcc1 -ltcc1-mes'
    libtcc1=
elif test "$tcc_cpu" = x86_64; then
    libtcc1=-ltcc1
else
    echo "cpu not supported: $mes_cpu"
fi

timeout=${timeout-timeout 5}
if ! $timeout echo; then
    timeout=
fi

t=${1-lib/tests/scaffold/t.c}
b=$(dirname "$t")/$(basename "$t" .c)
co="$b"-$triplet-tcc
mo="$b"-tcc-mes

o="$co"

rm -f 1 1.s 1.link
rm -f 2 2.s 2.link
rm -f "$co" "$co".1
rm -f "$mo" "$mo".1

r=0
if [ -x $GCC_TCC ]; then
    $GCC_TCC                                    \
        -c                                      \
        -g                                      \
        -nostdlib                               \
        -I $MES_PREFIX/include                  \
        -I $MES_PREFIX/scaffold/tinycc          \
        -o "$o".o                               \
        "$t"                                    \
        2> 1
    $GCC_TCC                                    \
        -g                                      \
        -L .                                    \
        -o "$o"                                 \
        "$o".o                                  \
        -lc                                     \
        $libtcc1                                \
        2> 1.link
    set +e
    d=$(dirname "$t")
    d=$(dirname "$d")
    if [ "$d" = lib/tests ]; then
        $timeout "$o" -s --long file0 file1 > "$o".1   
    else
        $timeout "$o" arg1 arg2 arg3 arg4 arg5 > "$o".1
    fi
    m=$?
    set -e
    [ -f "$b".exit ] && r=$(cat "$b".exit)
    [ $m = $r ]
    if [ -f "$b".expect ]; then
        $DIFF -ub "$b".expect "$o".1;
    fi
fi

o="$b"-tcc-mes
$TCC                                            \
    -c                                          \
    -g                                          \
    -nostdlib                                   \
    -I $MES_PREFIX/include                      \
    -I $MES_PREFIX/scaffold/tinycc              \
    -o "$o".o                                   \
    "$t"                                        \
    2> 2
$TCC                                            \
    -g                                          \
    -L .                                        \
    -o "$o"                                     \
    "$o".o                                      \
    -lc                                         \
    $libtcc1                                    \
    2> 2.link

set +e
d=$(dirname "$t")
d=$(dirname "$d")
if [ "$d" = lib/tests ]; then
    $timeout "$o" -s --long file0 file1 > "$o".1   
else
    $timeout "$o" arg1 arg2 arg3 arg4 arg5 > "$o".1
fi
m=$?

set -e
[ $m = $r ]
[ -f "$b".exit ] && r=$(cat "$b".exit)
if [ -f "$b".expect ]; then
    $DIFF -ub "$b".expect "$co".1;
    $DIFF -ub "$co".1 "$mo".1;
fi
