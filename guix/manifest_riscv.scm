(load "package_riscv.scm")
(use-modules (gnu packages gdb))
(define triplet "riscv64-linux-gnu")

(packages->manifest
  (let* ((binutils (cross-binutils triplet))
         (libc     (cross-libc     triplet)))
    (list tcc-mine-riscv
          (list gcc "lib")
          binutils
          libc
          gdb
          (list libc "static"))))
