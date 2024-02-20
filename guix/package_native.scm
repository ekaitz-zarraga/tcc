(use-modules ((guix licenses) #:prefix license:)
             (srfi srfi-1)
             (ice-9 popen)
             (ice-9 rdelim)
             (ice-9 vlist)
             (ice-9 match)
             (guix gexp)
             (guix utils)
             (guix packages)
             (guix git-download)
             (guix build-system gnu)
             (guix store)
             (gnu packages)
             (gnu packages perl)
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


(define-public tcc
  (package
    (name "tcc")                                ;aka. "tinycc"
    (version "HEAD")
    (source (local-file %source-dir-this
                        #:recursive? #t
                        #:select? discard-git))
    (build-system gnu-build-system)
    (native-inputs (list perl texinfo))
    (arguments
      (list
        #:configure-flags #~(list
                             (string-append "--prefix=" #$output)
                             (string-append "--elfinterp="
                                            (assoc-ref %build-inputs
                                                       "libc")
                                            #$(glibc-dynamic-linker))
                             (string-append "--crtprefix="
                                            (assoc-ref %build-inputs
                                                       "libc") "/lib")
                             (string-append "--sysincludepaths="
                                            (assoc-ref %build-inputs
                                                       "libc") "/include:"
                                            (assoc-ref %build-inputs
                                                       "kernel-headers")
                                            "/include:{B}/include")
                             (string-append "--libpaths="
                                            (assoc-ref %build-inputs
                                                       "libc") "/lib:{B}")
                             #$@(if (string-prefix? "armhf-linux"
                                                   (or (%current-target-system)
                                                       (%current-system)))
                                 `("--triplet=arm-linux-gnueabihf")
                                 '()))
        #:make-flags '(list "CFLAGS=-g")
        #:test-target "test"
        #:tests? #f
        #:strip-binaries? #f))
    (native-search-paths
      (list (search-path-specification
              (variable "CPATH")
              (files '("include")))
            (search-path-specification
              (variable "LIBRARY_PATH")
              (files '("lib" "lib64")))))
    ;; Fails to build on MIPS: "Unsupported CPU"
    (supported-systems (delete "mips64el-linux" %supported-systems))
    (synopsis "Tiny and fast C compiler")
    (description
      "TCC, also referred to as \"TinyCC\", is a small and fast C compiler
      written in C.  It supports ANSI C with GNU and extensions and most of the
      C99 standard.")
      (home-page "http://www.tinycc.org/")
      ;; An attempt to re-licence tcc under the Expat licence is underway but not
      ;; (if ever) complete.  See the RELICENSING file for more information.
      (license license:lgpl2.1+)))

tcc
