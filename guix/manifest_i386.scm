(load "package_i386.scm")
(use-modules (gnu packages gdb))
(define triplet "i686-linux-gnu")

(packages->manifest
  (let* ((binutils (cross-binutils triplet))
         (libc     (cross-libc     triplet)))
    (list tcc-mine-i386
          (list gcc "lib")
          binutils
          libc
          gdb
          (list libc "static"))))
