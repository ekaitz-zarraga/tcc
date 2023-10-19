guix build -L . -e '(begin (use-modules (guix commencement)) tcc-boot0)' --system=riscv64-linux --no-grafts -K
