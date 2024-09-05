; TASK: Add Three Integers

SYS_EXIT equ 1
SYS_CALL equ 0x80

section .data
    numA dw 105
    numB dw 137
    numC dw 54

section .bss
    result resb 2

section .text
    global _start

_start:
    ; calculate sum
    mov ax, [numA]
    add ax, [numB]
    add ax, [numC]

    mov [result], ax

    ; exit
    mov ax, SYS_EXIT
    int SYS_CALL