#! /usr/bin/env bash

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
     riscv64*)
         cpu=riscv64
         tcc_cpu=riscv64
         triplet=riscv64-unknown-linux
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
MES_SOURCE=${MES_SOURCE-mes-source}
export MES_PREFIX
export MES_SOURCE

mkdir -p lib/tests
cp -r $MES_SOURCE/lib/tests lib

mes_tests="
lib/tests/scaffold/t.c
lib/tests/scaffold/01-return-0.c
lib/tests/scaffold/02-return-1.c
lib/tests/scaffold/03-call.c
lib/tests/scaffold/04-call-0.c
lib/tests/scaffold/05-call-1.c
lib/tests/scaffold/06-call-not-1.c
lib/tests/scaffold/06-not-call-1.c
lib/tests/scaffold/06-call-2.c
lib/tests/scaffold/06-call-string.c
lib/tests/scaffold/06-call-variable.c
lib/tests/scaffold/06-return-void.c
lib/tests/scaffold/07-include.c
lib/tests/scaffold/08-assign.c
lib/tests/scaffold/08-assign-negative.c
lib/tests/scaffold/08-assign-global.c
lib/tests/scaffold/10-if-0.c
lib/tests/scaffold/11-if-1.c
lib/tests/scaffold/12-if-eq.c
lib/tests/scaffold/13-if-neq.c
lib/tests/scaffold/14-if-goto.c
lib/tests/scaffold/15-if-not-f.c
lib/tests/scaffold/16-if-t.c
lib/tests/scaffold/17-compare-char.c
lib/tests/scaffold/17-compare-ge.c
lib/tests/scaffold/17-compare-gt.c
lib/tests/scaffold/17-compare-le.c
lib/tests/scaffold/17-compare-lt.c
lib/tests/scaffold/17-compare-unsigned-ge.c
lib/tests/scaffold/17-compare-unsigned-gt.c
lib/tests/scaffold/17-compare-unsigned-le.c
lib/tests/scaffold/17-compare-unsigned-lt.c
lib/tests/scaffold/17-compare-unsigned-char-le.c
lib/tests/scaffold/17-compare-unsigned-short-le.c
lib/tests/scaffold/17-compare-unsigned-long-le.c
lib/tests/scaffold/17-compare-and.c
lib/tests/scaffold/17-compare-or.c
lib/tests/scaffold/17-compare-and-or.c
lib/tests/scaffold/17-compare-assign.c
lib/tests/scaffold/17-compare-call.c
lib/tests/scaffold/18-assign-shadow.c
lib/tests/scaffold/20-while.c
lib/tests/scaffold/21-char-array-simple.c
lib/tests/scaffold/21-char-array.c
lib/tests/scaffold/22-while-char-array.c
lib/tests/scaffold/23-global-pointer-init-null.c
lib/tests/scaffold/23-global-pointer-init.c
lib/tests/scaffold/23-global-pointer-ref.c
lib/tests/scaffold/23-global-pointer-pointer-ref.c
lib/tests/scaffold/23-pointer-sub.c
lib/tests/scaffold/23-pointer.c
lib/tests/mes/30-oputs.c
lib/tests/mes/30-eputs.c
lib/tests/string/30-strlen.c
lib/tests/scaffold/30-exit-0.c
lib/tests/scaffold/30-exit-42.c
lib/tests/scaffold/32-call-wrap.c
lib/tests/scaffold/32-compare.c
lib/tests/scaffold/33-and-or.c
lib/tests/scaffold/34-pre-post.c
lib/tests/scaffold/35-compare-char.c
lib/tests/scaffold/36-compare-arithmetic.c
lib/tests/scaffold/36-compare-arithmetic-negative.c
lib/tests/scaffold/37-compare-assign.c
lib/tests/scaffold/38-compare-call-2.c
lib/tests/scaffold/38-compare-call-3.c
lib/tests/scaffold/38-compare-call.c
lib/tests/scaffold/40-if-else.c
lib/tests/scaffold/41-ternary.c
lib/tests/scaffold/42-goto-label.c
lib/tests/scaffold/43-for-do-while.c
lib/tests/scaffold/44-switch.c
lib/tests/scaffold/44-switch-fallthrough.c
lib/tests/scaffold/44-switch-body-fallthrough.c
lib/tests/scaffold/45-void-call.c
lib/tests/scaffold/46-function-static.c
lib/tests/scaffold/47-function-expression.c
lib/tests/scaffold/48-global-static.c
lib/tests/assert/50-assert.c
lib/tests/mes/50-itoa.c
lib/tests/posix/50-getenv.c
lib/tests/stdlib/50-malloc.c
lib/tests/string/50-strcmp.c
lib/tests/string/50-strcmp-itoa.c
lib/tests/string/50-strcpy.c
lib/tests/string/50-strncmp.c
lib/tests/posix/50-open-read.c
lib/tests/scaffold/51-pointer-sub.c
lib/tests/scaffold/54-argc.c
lib/tests/scaffold/54-argv.c
lib/tests/scaffold/55-char-array.c
lib/tests/scaffold/60-math.c
lib/tests/scaffold/60-math-itoa.c
lib/tests/scaffold/61-array.c
lib/tests/scaffold/62-array.c
lib/tests/scaffold/63-struct.c
lib/tests/scaffold/63-struct-pointer.c
lib/tests/scaffold/63-struct-local.c
lib/tests/scaffold/63-struct-function.c
lib/tests/scaffold/63-struct-assign.c
lib/tests/scaffold/63-struct-array.c
lib/tests/scaffold/63-struct-array-assign.c
lib/tests/scaffold/63-struct-array-compare.c
lib/tests/scaffold/63-struct-cell.c
lib/tests/scaffold/64-make-cell.c
lib/tests/scaffold/65-read.c
lib/tests/scaffold/66-local-char-array.c
"

tcc_tests="
lib/tests/scaffold/70-stdarg.c
lib/tests/stdio/70-printf-hello.c
lib/tests/stdio/70-printf-simple.c
lib/tests/stdio/70-printf.c
lib/tests/stdlib/70-strtoull.c
lib/tests/string/70-strchr.c
lib/tests/scaffold/71-struct-array.c
lib/tests/scaffold/72-typedef-struct-def.c
lib/tests/scaffold/72-typedef-struct-def-local.c
lib/tests/scaffold/73-union-hello.c
lib/tests/scaffold/73-union.c
lib/tests/scaffold/74-multi-line-string.c
lib/tests/scaffold/75-struct-union.c
lib/tests/scaffold/76-pointer-arithmetic-pp.c
lib/tests/scaffold/76-pointer-arithmetic.c
lib/tests/scaffold/77-pointer-assign.c
lib/tests/scaffold/78-union-struct.c
lib/tests/scaffold/79-int-array-simple.c
lib/tests/scaffold/79-int-array.c
lib/tests/scaffold/7a-struct-char-array.c
lib/tests/scaffold/7b-struct-int-array-hello.c
lib/tests/scaffold/7b-struct-int-array-pointer.c
lib/tests/scaffold/7b-struct-int-array.c
lib/tests/scaffold/7c-dynarray.c
lib/tests/scaffold/7d-cast-char.c
lib/tests/scaffold/7e-struct-array-access.c
lib/tests/scaffold/7f-struct-pointer-arithmetic.c
lib/tests/scaffold/7g-struct-byte-word-field.c
lib/tests/scaffold/7h-struct-assign.c
lib/tests/scaffold/7i-struct-struct-simple.c
lib/tests/scaffold/7i-struct-struct.c
lib/tests/scaffold/7k-empty-for.c
lib/tests/scaffold/7k-for-each-elem-simple.c
lib/tests/scaffold/7k-for-each-elem.c
lib/tests/scaffold/7l-struct-any-size-array-simple.c
lib/tests/scaffold/7l-struct-any-size-array.c
lib/tests/scaffold/7m-struct-char-array-assign.c
lib/tests/scaffold/7n-struct-struct-array.c
lib/tests/scaffold/7o-struct-pre-post-simple.c
lib/tests/scaffold/7o-struct-pre-post.c
lib/tests/scaffold/7p-struct-cast.c
lib/tests/scaffold/7q-bit-field-simple.c
lib/tests/scaffold/7q-bit-field.c
lib/tests/scaffold/7r-sign-extend.c
lib/tests/scaffold/7s-struct-short.c
lib/tests/scaffold/7s-unsigned-compare.c
lib/tests/scaffold/7t-function-destruct.c
lib/tests/scaffold/7u-double.c
lib/tests/scaffold/7u-long-long.c
lib/tests/scaffold/7u-ternary-expression.c
lib/tests/scaffold/7u-call-ternary.c
lib/tests/scaffold/7u-inc-byte-word.c
lib/tests/scaffold/7u-struct-func.c
lib/tests/scaffold/7u-struct-size10.c
lib/tests/scaffold/7u-vstack.c
lib/tests/scaffold/70-array-in-struct-init.c
lib/tests/scaffold/70-struct-short-enum-init.c
lib/tests/scaffold/70-struct-post.c
lib/tests/scaffold/70-extern.c
lib/tests/scaffold/70-ternary-arithmetic-argument.c
lib/tests/setjmp/80-setjmp.c
lib/tests/stdio/80-sscanf.c
lib/tests/stdlib/80-qsort.c
lib/tests/stdlib/80-qsort-dupes.c
lib/tests/string/80-strncpy.c
lib/tests/string/80-strrchr.c
lib/tests/scaffold/82-define.c
lib/tests/scaffold/83-heterogenoous-init.c
lib/tests/scaffold/84-struct-field-list.c
lib/tests/scaffold/85-sizeof.c
"

gnu_tests="
lib/tests/dirent/90-readdir.c
lib/tests/io/90-stat.c
lib/tests/mes/90-abtod.c
lib/tests/mes/90-dtoab.c
lib/tests/posix/90-execlp.c
lib/tests/posix/90-unsetenv.c
lib/tests/signal/90-signal.c
lib/tests/stdio/90-fopen.c
lib/tests/stdio/90-fopen-append.c
lib/tests/stdio/90-fread-fwrite.c
lib/tests/stdio/90-fseek.c
lib/tests/stdio/90-sprintf.c
lib/tests/stdlib/90-strtol.c
lib/tests/string/90-snprintf.c
lib/tests/string/90-strpbrk.c
lib/tests/string/90-strspn.c
lib/tests/scaffold/90-goto-var.c
lib/tests/scaffold/91-goto-array.c
lib/tests/scaffold/a0-call-trunc-char.c
lib/tests/scaffold/a0-call-trunc-short.c
lib/tests/scaffold/a0-call-trunc-int.c
lib/tests/scaffold/a0-math-divide-signed-negative.c
lib/tests/scaffold/a1-global-no-align.c
lib/tests/scaffold/a1-global-no-clobber.c
"

tests="$mes_tests$tcc_tests$gnu_tests"

broken="
lib/tests/scaffold/t.c
lib/tests/scaffold/70-ternary-arithmetic-argument.c
lib/tests/dirent/90-readdir.c
lib/tests/io/90-stat.c
lib/tests/stdio/90-fseek.c
"

if [ $TCC = ./tcc ]; then
    broken="$broken
lib/tests/scaffold/60-math.c
lib/tests/scaffold/7s-unsigned-compare.c
"
fi

if [ $tcc_cpu = "arm" ]; then
    broken="$broken
lib/tests/setjmp/80-setjmp.c
lib/tests/mes/90-abtod.c
lib/tests/signal/90-signal.c
"
fi

if [ ! -x $GCC_TCC ]; then
    broken="$broken
02-return-1
05-call-1
"
fi

if ! test -f lib/tests/scaffold/t.c; then
    tests=
    broken=
fi

expect=$(echo $broken | wc -w)
mkdir -p scaffold/tests

set +e
pass=0
fail=0
total=0
for t in $tests; do
    b=$(basename "$t" .c)
    sh test.sh "$t" &> "$t".log
    r=$?
    total=$((total+1))
    if [ $r = 0 ]; then
        echo $t: [OK]
        pass=$((pass+1))
    else
        echo $t: [FAIL]
        fail=$((fail+1))
    fi
done

tests="
tests/tests2/00_assignment.c
tests/tests2/01_comment.c
tests/tests2/02_printf.c
tests/tests2/03_struct.c
tests/tests2/04_for.c
tests/tests2/05_array.c
tests/tests2/06_case.c
tests/tests2/07_function.c
tests/tests2/08_while.c
tests/tests2/09_do_while.c

tests/tests2/10_pointer.c
tests/tests2/11_precedence.c
tests/tests2/12_hashdefine.c
tests/tests2/13_integer_literals.c
tests/tests2/14_if.c
tests/tests2/15_recursion.c
tests/tests2/16_nesting.c
tests/tests2/17_enum.c
tests/tests2/18_include.c
tests/tests2/19_pointer_arithmetic.c

tests/tests2/20_pointer_comparison.c
tests/tests2/21_char_array.c
tests/tests2/22_floating_point.c
tests/tests2/23_type_coercion.c
tests/tests2/24_math_library.c
tests/tests2/25_quicksort.c
tests/tests2/26_character_constants.c
tests/tests2/27_sizeof.c
tests/tests2/28_strings.c
tests/tests2/29_array_address.c

tests/tests2/30_hanoi.c
tests/tests2/31_args.c
tests/tests2/32_led.c
tests/tests2/33_ternary_op.c
tests/tests2/34_array_assignment.c
tests/tests2/35_sizeof.c
tests/tests2/36_array_initialisers.c
tests/tests2/37_sprintf.c
tests/tests2/38_multiple_array_index.c
tests/tests2/39_typedef.c

tests/tests2/40_stdio.c
tests/tests2/41_hashif.c
tests/tests2/42_function_pointer.c
tests/tests2/43_void_param.c
tests/tests2/44_scoped_declarations.c
tests/tests2/45_empty_for.c
tests/tests2/47_switch_return.c
tests/tests2/48_nested_break.c
tests/tests2/49_bracket_evaluation.c

tests/tests2/50_logical_second_arg.c
tests/tests2/51_static.c
tests/tests2/52_unnamed_enum.c
tests/tests2/54_goto.c
tests/tests2/55_lshift_type.c
"

broken="$broken
tests/tests2/22_floating_point.c
tests/tests2/23_type_coercion.c
tests/tests2/24_math_library.c
tests/tests2/34_array_assignment.c
tests/tests2/49_bracket_evaluation.c
tests/tests2/55_lshift_type.c
"

#tests/tests2/24_math_library.c         ; float, math
#tests/tests2/34_array_assignment.c     ; fails with GCC

expect=$(echo $broken | wc -w)
for t in $tests; do
    if [ ! -f "$t" ]; then
        echo ' [SKIP]'
        continue;
    fi
    b=$(basename "$t" .c)
    d=$(dirname "$t")
    sh test.sh "$t" &> "$d/$b".log
    r=$?
    total=$((total+1))
    if [ $r = 0 ]; then
        echo $t: [OK]
        pass=$((pass+1))
    else
        echo $t: [FAIL]
        fail=$((fail+1))
    fi
done
[ $expect != 0 ] && echo "expect: $expect"
[ $fail != 0 ] && echo "failed: $fail"
echo "passed: $pass"
[ $fail -lt $expect ] && echo "solved: $(($expect - $fail))"
echo "total:  $total"
if [ $fail != 0 -a $fail -gt $expect ]; then
    echo FAILED: $fail/$total
    exit 1
elif [ $fail != 0 ]; then
    echo PASS: $pass/$total
else
    echo PASS: $total
fi
