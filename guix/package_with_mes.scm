(use-modules (ice-9 popen)
             (ice-9 rdelim)
             (guix packages)
             (guix utils)
             (guix gexp)
             (guix profiles)
             (guix download)
             (guix build-system gnu)
             ((guix licenses) #:prefix license:)
             (gnu packages c)
             (gnu packages guile)
             (gnu packages cross-base)
             (gnu packages base)
             (gnu packages linux)
             (gnu packages maths)
             (gnu packages perl)
             (gnu packages cross-base)
             (gnu packages bootstrap)
             (gnu packages texinfo))

(define %source-dir-this (dirname (dirname (current-filename))))

(define %git-commit
  (read-line
    (open-pipe "git show HEAD | head -1 | cut -d ' ' -f 2 "  OPEN_READ)))

(define (discard-git path stat)
  (let* ((start (1+ (string-length %source-dir-this)) )
         (end   (+ 4 start)))
  (not (false-if-exception (equal? ".git" (substring path start end))))))

;; From mes source
;; NOTE: It expects Mes to be in a folder adjacent to the tcc project folder
(define %source-dir-mes (string-append (dirname (dirname (dirname (current-filename)))) "/mes/guix.scm"))
(chdir (dirname %source-dir-mes))
(load %source-dir-mes)
(chdir %source-dir-this)

(package
  (name "tcc-MES")
  (version "0.0.1")
  (source (local-file %source-dir-this
            #:recursive? #t
            #:select? discard-git))
  (build-system gnu-build-system)
  (inputs '())
  (propagated-inputs '())
  (native-inputs (list mes.git mescc-tools nyacc guile-3.0))

  (arguments
   (list
    #:validate-runpath? #f
    #:phases
    #~(modify-phases %standard-phases
        ;(add-before 'configure 'fail (lambda _ (error ":)"))
        (add-before 'configure 'conftest
          (lambda* (#:key inputs outputs #:allow-other-keys)
              (substitute* "conftest.c"
                (("volatile") ""))))

        ;; Uses live-bootstrap as a reference
        ;; https://git.stikonas.eu/andrius/live-bootstrap/src/branch/mes-x86_64/sysa/tcc-0.9.26/tcc-0.9.26.kaem#L62
        ;; TODO: ADD THE CRTS properly
        (replace 'configure
          (lambda _
            (let ((target-system (or #$(%current-target-system)
                                     #$(%current-system))))
              ;; TODO: set other variables
              (setenv "MES"             "guile") ; This literally reduces build times x20
              (setenv "MES_STACK"       "15000000")
              (setenv "MES_ARENA"       "30000000")
              (setenv "MES_MAX_ARENA"   "30000000")
              (setenv "MES_LIB"         (string-append  #$mes.git "/lib"))
              (cond
                ((string-prefix? "x86_64-linux" target-system)
                 (begin
                   (display "Preparing for x86_64-linux...\n")
                   (setenv "MES_ARCH" "x86_64")
                   (setenv "TCC_TARGET_ARCH" "X86_64")
                   (setenv "MES_LIBC_SUFFIX" "gcc")))
                ((string-prefix? "aarch64-linux" target-system)
                 (begin
                   (display "Preparing for aarch64-linux...\n")
                   (error "Not supported")))
                ((string-prefix? "riscv64-linux" target-system)
                 (begin
                   (display "Preparing for riscv64-linux...\n")
                   (setenv "MES_ARCH" "riscv64")
                   (setenv "TCC_TARGET_ARCH" "RISCV64")
                   (setenv "MES_LIBC_SUFFIX" "tcc")))
                (else (error "NO architecture matched\n"))))))

        (replace 'build
          (lambda _
            (define-syntax invoke-and-show
              (syntax-rules (invoke-and-show)
                ((invoke-and-show expr ...)
                 (begin
                   (display (string-join (list "INVOKING: " expr ...) " ") (current-error-port))
                   (force-output (current-error-port))
                   (invoke expr ...)))))

            (invoke-and-show
              (string-append #$mes.git "/bin/mescc")
              "-S"
              "-o" "tcc.s"
              (string-append "-I" #$mes.git "/include")
              "-DBOOTSTRAP=1"
              "-DHAVE_LONG_LONG=1"
              "-I."
              (string-append "-DTCC_TARGET_" (getenv "TCC_TARGET_ARCH") "=1")
              "-Dinline="
              (string-append "-DCONFIG_TCC_CRTPREFIX=\"" #$mes.git "/lib\"")
              "-DCONFIG_TCC_ELFINTERP=\"/mes/loader\""
              (string-append "-DCONFIG_TCC_SYSINCLUDEPATHS=\"" #$mes.git "/include:/include\"")
              (string-append "-DTCC_LIBGCC=\"" #$mes.git "/lib/libc.a\"")
              "-DCONFIG_TCC_LIBTCC1_MES=0"
              "-DCONFIG_TCCBOOT=1"
              "-DCONFIG_TCC_STATIC=1"
              "-DCONFIG_USE_LIBGCC=1"
              "-DTCC_MES_LIBC=1"
              "-DTCC_VERSION=\"0.9.26\""
              "-DONE_SOURCE=1"
              "tcc.c")))

        (add-after 'build 'link
          (lambda _
            (invoke (string-append #$mes.git "/bin/mescc")
                    "--base-address" "0x08048000"
                    "-o" "mes-tcc"
                    (string-append "-L" #$mes.git "/lib")
                    "tcc.s"
                    "-lc+tcc")))

        ;; There's a better way to do this today but...
        (replace 'install
          (lambda* (#:key inputs outputs #:allow-other-keys)
            (chmod "mes-tcc" #o775)
            (install-file "mes-tcc"
                          (string-append (assoc-ref outputs "out") "/bin/"))))

        (replace 'check
          (lambda _
            (system* "./mes-tcc" "--help"))))))

  (native-search-paths
   (list (search-path-specification
          (variable "C_INCLUDE_PATH")
          (files '("include")))
         (search-path-specification
          (variable "LIBRARY_PATH")
          (files '("lib")))))
  (outputs (list "out" "debug"))
  (synopsis "Tiny and fast C compiler")
  (description
   "TCC, also referred to as \"TinyCC\", is a small and fast C compiler
written in C.  It supports ANSI C with GNU and extensions and most of the C99
standard.")
  (home-page "http://www.tinycc.org/")
  (license license:lgpl2.1+))
