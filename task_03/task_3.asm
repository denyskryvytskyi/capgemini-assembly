SYS_EXIT equ 1
SYS_READ equ 3
SYS_WRITE equ 4
STDIN equ 0
STDOUT equ 1

%define SYSCALL 0x80

section .data
    numberA dd 15
    numberB dd 3
    numberC dd 74

section .bss
    result resb 4

section .text
    global _start

_start:
    mov eax, [numberA]
    cmp eax, [numberB]      ; compare first and second numbers
    jg check_third_number   ; if first number is greater then second - jump
    mov eax, [numberB]

; compare check between 1st and 2nd number with 3rd number
check_third_number:
    cmp eax, [numberC]
    jg _exit                ; jump if greater then 3rd number
    mov eax, [numberC]

_exit:
    mov [result], eax
    mov eax, SYS_EXIT
    int SYSCALL