(load "guix.scm")

(define triplet "riscv64-linux-gnu")

(packages->manifest
  (let* ((binutils (cross-binutils triplet))
         (libc     (cross-libc     triplet)))
    (list tcc-mine
          binutils
          libc
          (list libc "static"))))
