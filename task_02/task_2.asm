SYS_EXIT equ 1
SYS_READ equ 3
SYS_WRITE equ 4
STDIN equ 0
STDOUT equ 1

%define SYSCALL 0x80

section .data
    msg db 'Capgemini task 2', 0xa
    len equ $ - msg

section .bss
    reversed_msg resb len

section .text
    global _start

reverse_string:
    mov ecx, len

    mov esi, 0 ; reversed str counter
    mov edi, len - 1 ; init str counter

    reverse_loop:
    mov al, [msg + edi]
    add al, 'a'
    mov [reversed_msg + esi], al
    inc esi
    dec edi
    loop reverse_loop
ret

_start:
    mov eax, msg
    call reverse_string

    ; display result in console
    mov eax, SYS_WRITE      ; system call to write
    mov ebx, STDOUT         ; file descriptor
    mov ecx, reversed_msg            ; store result
    mov edx, len            ; length of the result
    int SYSCALL

    ; exit
    mov eax, SYS_EXIT
    int SYSCALL