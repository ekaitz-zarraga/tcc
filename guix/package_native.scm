(use-modules (ice-9 popen)
             (ice-9 rdelim)
             (guix packages)
             (guix utils)
             (guix build utils)
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

(define-public tcc-native
  (package
    (name "tcc")                                  ;aka. "tinycc"
    (version "riscv-mes-HEAD")
    (source (local-file %source-dir
              #:recursive? #t
              #:select? discard-git))
    (build-system gnu-build-system)
    (arguments
      (list
        #:tests? #f
        #:phases
        #~(modify-phases %standard-phases
           (delete 'configure)
           (replace 'build
             (lambda* (#:key inputs outputs #:allow-other-keys)
               (let ((libc (assoc-ref %build-inputs "libc"))
                     (out  (assoc-ref outputs "out")))
                 (invoke "gcc"
                       "-g"
                       "-static"
                       "-o" "tcc"
                       "-DONE_SOURCE=1"
                       "-DHAVE_FLOAT=1 "
                       "-DHAVE_BITFIELD=1 "
                       "-DHAVE_LONG_LONG=1 "
                       "-DHAVE_SETJMP=1 "
                       "-DASM_DEBUG=1 "
                       #$(cond
                           ((target-x86-64?) "-DTCC_TARGET_X86_64=1")
                           ((target-x86-32?) "-DTCC_TARGET_I386=1")
                           ((target-riscv64?) "-DTCC_TARGET_RISCV64=1"))
                       (string-append "-DCONFIG_TCC_ELFINTERP=\"" libc #$(glibc-dynamic-linker) "\"")
                       "-D inline="
                       (string-append "-DCONFIG_TCCDIR=\"" out "/lib/tcc\"")
                       (string-append "-DCONFIG_TCC_CRTPREFIX=\"" libc "/lib:" out "/lib\"")
                       (string-append "-DCONFIG_TCC_LIBPATHS=\"" libc "/lib:" out "/lib\"")
                       (string-append "-DCONFIG_TCC_SYSINCLUDEPATHS=\"" out "/include:" libc "/include\"")
                       "-D CONFIG_TCCBOOT=1"
                       "-D CONFIG_TCC_STATIC=1"
                       "tcc.c"))))

           ;; Use lib/lib-arm64.c. Needed for long-double support.
           ;; - Later it'll try to link it (needed)
           (add-before 'install 'build-libtcc1
             (lambda* (#:key inputs outputs #:allow-other-keys)
               (cond
                 (#$(target-riscv64?)
                  (invoke "./tcc" "-c" "lib/lib-arm64.c" "-o" "libtcc1.o"))
                 (#$(target-x86?)
                  (call-with-output-file "libtcc1.c"
                                         (lambda (p) (display "" p)))
                  (invoke "./tcc" "-c" "libtcc1.c" "-o" "libtcc1.o")))
               (invoke "./tcc" "-ar" "cr" "libtcc1.a" "libtcc1.o")))

           ;; Default `make install` phase does not install the cross compilers
           ;; We have to do it by hand
           (replace 'install
             (lambda* (#:key inputs outputs #:allow-other-keys)
                      (install-file "libtcc1.a"
                                    (string-append (assoc-ref outputs "out") "/lib/tcc"))
                      (install-file "tcc"
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

    #;(outputs (list "out" "debug"))
    (synopsis "Tiny and fast C compiler")
    (description
     "TCC, also referred to as \"TinyCC\", is a small and fast C compiler
written in C.  It supports ANSI C with GNU and extensions and most of the C99
standard.")
    (home-page "http://www.tinycc.org/")
    ;; An attempt to re-licence tcc under the Expat licence is underway but not
    ;; (if ever) complete.  See the RELICENSING file for more information.
    (license license:lgpl2.1+)))


tcc-native
