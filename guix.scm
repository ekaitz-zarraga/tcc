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

(define %source-dir (dirname (current-filename)))

(define %git-commit
  (read-line
    (open-pipe "git show HEAD | head -1 | cut -d ' ' -f 2 "  OPEN_READ)))

(define (discard-git path stat)
  (let* ((start (1+ (string-length %source-dir)) )
         (end   (+ 4 start)))
  (not (false-if-exception (equal? ".git" (substring path start end))))))


(define libccross (cross-libc "riscv64-linux-gnu"))

(define-public tcc-mine-native
  (package
    (name "tcc")                                  ;aka. "tinycc"
    (version "0.9.27-HEAD")
    (source (local-file %source-dir
                        #:recursive? #t
                        #:select? discard-git))
    (build-system gnu-build-system)
    (native-inputs (list perl texinfo which))
    (arguments
      `(#:configure-flags (list (string-append "--elfinterp="
                                               (assoc-ref %build-inputs "libc")
                                               ,(glibc-dynamic-linker))
                                (string-append "--crtprefix="
                                               (assoc-ref %build-inputs "libc")
                                               "/lib")
                                (string-append "--sysincludepaths="
                                               (assoc-ref %build-inputs "libc")
                                               "/include:"
                                               (assoc-ref %build-inputs
                                                          "kernel-headers")
                                               "/include:{B}/include")
                                (string-append "--libpaths="
                                               (assoc-ref %build-inputs "libc")
                                               "/lib")
                                ,@(if (string-prefix? "armhf-linux"
                                                      (or (%current-target-system)
                                                          (%current-system)))
                                    `("--triplet=arm-linux-gnueabihf")
                                    '()))
        #:test-target "test"))
    (native-search-paths
      (list (search-path-specification
              (variable "CPATH")
              (files '("include")))
            (search-path-specification
              (variable "LIBRARY_PATH")
              (files '("lib" "lib64")))))

    (synopsis "Tiny and fast C compiler")
    (description
      "TCC, also referred to as \"TinyCC\", is a small and fast C compiler
      written in C.  It supports ANSI C with GNU and extensions and most of the C99
      standard.")
      (home-page "http://www.tinycc.org/")
      ;; An attempt to re-licence tcc under the Expat licence is underway but not
      ;; (if ever) complete.  See the RELICENSING file for more information.
      (license license:lgpl2.1+)))




(define-public tcc-mine
  (package
    (name "tcc")                                  ;aka. "tinycc"
    (version "0.9.27-HEAD")
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
                "--extra-cflags=-DHAVE_FLOAT=1 -DHAVE_BITFIELD=1 -DHAVE_LONG_LONG=1 -DHAVE_SETJMP=1")
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
                        (call-with-output-file "config-extra.mak"
                          (lambda (port)
                            (display
                              (string-append "CRT-riscv64 = " #$libccross "/lib") port)
                            (newline port)
                            (display
                              (string-append "LIB-riscv64 = " #$libccross "/lib") port)
                            (newline port)
                            (display
                              (string-append "INC-riscv64 = " #$libccross "/include" ":{B}/include") port)))))

                   ;(add-before 'install 'fail (lambda _ (error "Fail for debug")))

                   ;; Default `make install` phase does not install the cross compilers
                   ;; We have to do it by hand
                   (replace 'install
                     (lambda* (#:key inputs outputs #:allow-other-keys)
                              (install-file "riscv64-libtcc1.a"
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

    (synopsis "Tiny and fast C compiler")
    (description
     "TCC, also referred to as \"TinyCC\", is a small and fast C compiler
written in C.  It supports ANSI C with GNU and extensions and most of the C99
standard.")
    (home-page "http://www.tinycc.org/")
    ;; An attempt to re-licence tcc under the Expat licence is underway but not
    ;; (if ever) complete.  See the RELICENSING file for more information.
    (license license:lgpl2.1+)))

tcc-mine
