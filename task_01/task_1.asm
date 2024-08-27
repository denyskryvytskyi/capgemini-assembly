SYS_EXIT equ 1
SYS_READ equ 3
SYS_WRITE equ 4
STDIN equ 0
STDOUT equ 1

section .data
    numberA db 1
    numberB db 3
    numberC db 5

section .bss
    result resb 2

section .text
    global _start

sum:
    mov eax, [numberA]
    add eax, [numberB]
    add eax, [numberC]
    ret

_start:
    call sum

    ; convert decimal to ASCII
    add eax, '0'
    mov [result], al

    ; null-terminate the string
    mov byte [result + 1], 0 

    ; display result in console
    mov eax, SYS_WRITE  ; system call to write
    mov ebx, STDOUT     ; file descriptor
    mov ecx, result     ; store result
    mov edx, 2          ; length of the result
    int 0x80            ; interrupt

    ; exit
    mov eax, SYS_EXIT
    int 0x80            ; interrupt

