(use-modules (ice-9 popen)
             (ice-9 rdelim)
             (guix packages)
             (guix utils)
             (guix gexp)
             (guix profiles)
             (guix download)
             (guix build-system gnu)
             ((guix licenses) #:prefix license:)
             (gnu packages gcc)
             (gnu packages base)
             (gnu packages linux)
             (gnu packages maths)
             (gnu packages perl)
             (gnu packages cross-base)
             (gnu packages bootstrap)
             (gnu packages texinfo))

(define %source-dir (dirname (dirname (current-filename))))

(define %git-commit
  (read-line
    (open-pipe "git show HEAD | head -1 | cut -d ' ' -f 2 "  OPEN_READ)))

(define (discard-git path stat)
  (let* ((start (1+ (string-length %source-dir)) )
         (end   (+ 4 start)))
  (not (false-if-exception (equal? ".git" (substring path start end))))))

(define libccross (cross-libc "riscv64-linux-gnu"))
(define libccross-i386 (cross-libc "i686-linux-gnu"))

(define-public tcc-mine-riscv
  (package
    (name "tcc")                                  ;aka. "tinycc"
    (version "riscv-mes-HEAD")
    (source (local-file %source-dir
              #:recursive? #t
              #:select? discard-git))
    (build-system gnu-build-system)
    (native-inputs (list perl texinfo which))
    (arguments
      (list
        #:configure-flags
        #~(list "--enable-cross"
                "--disable-rpath"
                (string-append "--extra-cflags="
                               "-DHAVE_FLOAT=1 "
                               "-DHAVE_BITFIELD=1 "
                               "-DHAVE_LONG_LONG=1 "
                               "-DHAVE_SETJMP=1 "
                               "-DASM_DEBUG=1 "
                               "-DCONFIG_TCC_ELFINTERP=\\\\\"\\\"" #$libccross "/lib/ld-linux-riscv64-lp64d.so.1\\\\\"\\\""))
        #:tests? #f
        #:validate-runpath? #f
        #:phases #~(modify-phases %standard-phases
                   (replace 'build
                     (lambda _
                       (invoke "make" "cross-riscv64")))

                   ;; Cross compilers don't get the default config so we need to add custom
                   ;; configuration like explained in `make help`
                   (add-before 'configure 'configure-cross
                     (lambda _
                        (call-with-output-file "config-cross.mak"
                          (lambda (port)
                            (display
                              (string-append "CRT-riscv64 = " #$libccross "/lib") port)
                            (newline port)
                            (display
                              (string-append "LIB-riscv64 = " #$libccross "/lib") port)
                            (newline port)
                            (display
                              (string-append "INC-riscv64 = " #$libccross "/include" ":" #$output "/include") port)))))

                   ;; Use lib/lib-arm64.c. Needed for long-double support.
                   ;; - Later it'll try to link it (needed)
                   (add-before 'install 'build-libtcc1
                     (lambda* (#:key inputs outputs #:allow-other-keys)
                       (invoke "./riscv64-tcc" "-c" "lib/lib-arm64.c" "-o" "libtcc1.o")
                       (invoke "./riscv64-tcc" "-ar" "cr" "libtcc1-riscv64.a" "libtcc1.o")))

                   ;; Default `make install` phase does not install the cross compilers
                   ;; We have to do it by hand
                   (replace 'install
                     (lambda* (#:key inputs outputs #:allow-other-keys)
                              (install-file "libtcc1-riscv64.a"
                                            (string-append (assoc-ref outputs "out") "/lib/tcc"))
                              (install-file "riscv64-tcc"
                                            (string-append (assoc-ref outputs "out") "/bin"))
                              (copy-recursively "include"
                                            (string-append (assoc-ref outputs "out") "/include")))))))
    (native-search-paths
     (list (search-path-specification
            (variable "CPATH")
            (files '("include")))
           (search-path-specification
            (variable "LIBRARY_PATH")
            (files '("lib" "lib64")))))

    (outputs (list "out" "debug"))
    (synopsis "Tiny and fast C compiler")
    (description
     "TCC, also referred to as \"TinyCC\", is a small and fast C compiler
written in C.  It supports ANSI C with GNU and extensions and most of the C99
standard.")
    (home-page "http://www.tinycc.org/")
    ;; An attempt to re-licence tcc under the Expat licence is underway but not
    ;; (if ever) complete.  See the RELICENSING file for more information.
    (license license:lgpl2.1+)))


tcc-mine-riscv
