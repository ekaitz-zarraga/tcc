#! /bin/sh
set -ex

export PREFIX=usr
export HEX2=../mescc-tools/bin/hex2
export M1=../mescc-tools/bin/M1
export MESCC=../mes/guile/mescc.scm
export MES_PREFIX=../mes
export MES_SEED=../mes-seed

sh build.sh
sh check.sh
