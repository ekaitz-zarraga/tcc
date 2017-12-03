#! /bin/sh
set -ex

export PREFIX=usr
export HEX2=../mescc-tools/bin/hex2
export M1=../mescc-tools/bin/M1
export BLOOD_ELF=../mescc-tools/bin/blood-elf
export MESCC=../mes/guile/mescc.scm
export MES_PREFIX=../mes
export TINYCC_SEED=${TINYCC_SEED-../tinycc-seed}

./test.sh ${1-t}
