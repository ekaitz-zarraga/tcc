#! /bin/sh
set -ex
rm -f *.o *.a *.E *.hex2 *.mesc-o *.i686-unknown-linux-gnu-o *.M1
rm -f 1 2 1.elf 2.elf

# trivial object
set +e
./tcc -c -I ../mes/mlibc/include ../mes/scaffold/main.c 2>/dev/null
./i686-unknown-linux-gnu-tcc -o main.i686-unknown-linux-gnu-o -c -I ../mes/mlibc/include ../mes/scaffold/main.c 2> 1
./tcc.mes -o main.mesc-o -c -I ../mes/mlibc/include ../mes/scaffold/main.c &> 2
diff -y 1 2

readelf -a main.i686-unknown-linux-gnu-o > 1.elf
readelf -a main.mesc-o > 2.elf
diff -y 1.elf 2.elf

# trivial bin
./tcc ../mes/scaffold/main.c
./i686-unknown-linux-gnu-tcc -o a.i686-unknown-linux-gnu-out -I ../mes/mlibc/include ../mes/scaffold/main.c 2> 1.a
./tcc.mes -o a.mes-out -I ../mes/mlibc/include ../mes/scaffold/main.c 2> 2.a
diff -y 1.a 2.a
