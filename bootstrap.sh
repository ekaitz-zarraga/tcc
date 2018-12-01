#! /bin/sh
set -e

if [ "$V" = 1 -o "$V" = 2 ]; then
    set -x
fi

prefix=${prefix-/usr/local}
MES_PREFIX=${MES_PREFIX-mes}
MES_SEED=${MES_SEED-../mes-seed}
interpreter=${interpreter-interpreter}

cp $MES_SEED/linux/x86-mes-gcc/crt1.o crt1.o
cp $MES_SEED/linux/x86-mes-gcc/crti.o crti.o
cp $MES_SEED/linux/x86-mes-gcc/crtn.o crtn.o

mescc=$(command -v mescc)

sh $mescc --help

[ "$V" = 1 ] && echo "sh $mescc -S ... tcc.c"
sh $mescc\
   -v\
   -S\
   -o tcc.S\
   -D ONE_SOURCE=1\
   -I .\
   -I $MES_PREFIX/lib\
   -I $MES_PREFIX/include\
   -D inline=\
   -D CONFIG_TCCDIR=\"$prefix/lib/tcc\"\
   -D CONFIG_TCC_CRTPREFIX=\"$prefix/lib:"{B}"/lib:.\"\
   -D CONFIG_TCC_ELFINTERP=\"$interpreter\"\
   -D CONFIG_TCC_LIBPATHS=\"$prefix/lib:"{B}"/lib:.\"\
   -D CONFIG_TCC_SYSINCLUDEPATHS=\"$MES_PREFIX/include:$prefix/include:"{B}"/include\"\
   -D TCC_LIBGCC=\"$prefix/lib/libc.a\"\
   -D BOOTSTRAP=1\
   -D CONFIG_TCCBOOT=1\
   -D CONFIG_TCC_STATIC=1\
   -D CONFIG_USE_LIBGCC=1\
   -D TCC_MES_LIBC=1\
   -D TCC_TARGET_I386=1\
   tcc.c

sh $mescc -v -g -o mes-tcc -L $MES_SEED -l c+tcc tcc.S $MES_SEED/x86-$MES_PREFIX/libc+tcc.o

rm -f libc.a
cp -f $MES_SEED/x86-mes-gcc/libc+gnu.o .
./mes-tcc -ar rc libc.a libc+gnu.o

rm -f libtcc1.a
cp -f $MES_SEED/x86-mes-gcc/libtcc1.o .
./mes-tcc -ar rc libtcc1.a libtcc1.o

if [ "$(basename $SHELL)" = gash ]; then
    echo "bootstrap.sh: run boot.sh sequence manually"
else
    TCC=./mes-tcc sh boot.sh
    TCC=./boot0-tcc sh boot.sh
    TCC=./boot1-tcc sh boot.sh
    TCC=./boot2-tcc sh boot.sh
    TCC=./boot3-tcc sh boot.sh
    cmp boot3-tcc boot4-tcc
    cp -f boot4-tcc tcc
    echo "bootstrap.sh: done"
fi
