#! /bin/sh

MESCC=${MESCC-mescc}
MES_PREFIX=${MES_PREFIX-$(dirname $MESCC)/../share/mes}

tests="
t

01-return-0
02-return-1
03-call
04-call-0
05-call-1
06-call-!1
10-if-0
11-if-1
12-if-==
13-if-!=
14-if-goto
15-if-!f
16-if-t
20-while
21-char[]
22-while-char[]

30-strlen
31-eputs
32-compare
33-and-or
34-pre-post
35-compare-char

37-compare-assign

40-if-else
41-?
42-goto-label
43-for-do-while

45-void-call
50-assert
51-strcmp
52-itoa
53-strcpy






70-printf


73-union
74-multi-line-string
75-struct-union







7d-cast-char




7i-struct-struct



7m-struct-char-array-assign


"

broken="
00-exit-0
"

fail="
23-pointer
36-compare-arithmetic
38-compare-call
44-switch
54-argv
60-math
61-array
63-struct-cell
64-make-cell
65-read
71-struct-array
72-typedef-struct-def
76-pointer-arithmetic
77-pointer-assign
78-union-struct
79-int-array
7a-struct-char-array
7b-struct-int-array
7c-dynarray
7e-struct-array-access
7f-struct-pointer-arithmetic
7g-struct-byte-word-field
7h-struct-assign
7j-strtoull
7k-for-each-elem
7l-struct-any-size-array
7n-struct-struct-array
"

tests=$(echo "$tests$fail" | sort)

if [ ! -x ./i686-unknown-linux-gnu-tcc ]; then
    tests=$(echo "$tests" | grep -Ev "02-return-1|05-call-1")
fi

mkdir -p scaffold/tests

set +e
fail=0
total=0
for t in $tests; do
    sh test.sh "$t" &> "scaffold/tests/$t".log
    r=$?
    total=$((total+1))
    if [ $r = 0 ]; then
        echo $t: [OK]
    else
        echo $t: [FAIL]
        fail=$((fail+1))
    fi
done
if [ $fail != 0 ]; then
    echo FAILED: $fail/$total
    exit 1
else
    echo PASS: $total
fi
