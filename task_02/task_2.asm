SYS_EXIT equ 1
SYS_READ equ 3
SYS_WRITE equ 4
STDIN equ 0
STDOUT equ 1
ASCII_A equ 'a'
%define SYSCALL 0x80

section .data
    msg db 'Capgemini task 2', 0xa
    len equ $ - msg

section .bss
    reversed_msg resb len+1

section .text
    global _start

_start:
    mov eax, msg
    call to_uppercase
    call reverse_string

    ; print result in console
    mov eax, SYS_WRITE      ; system call to write
    mov ebx, STDOUT         ; file descriptor
    mov ecx, reversed_msg   ; store result
    mov edx, len            ; length of the result
    int SYSCALL

    ; exit
    mov eax, SYS_EXIT
    int SYSCALL

to_uppercase:
    mov ecx, len - 1
    mov esi, 0              ; character counter

    uppercase_loop:
        mov al, [msg + esi] ; get next character

        cmp al, 'a'         ; compare with ASCII 'a'
        jl next_char
        cmp al, 'z'         ; compare with ASCII 'z'
        jg next_char

        sub al, 32          ; get uppercase ASCII character
        mov [msg + esi], al

        next_char:
        inc esi
    loop uppercase_loop
ret

reverse_string:
    mov ecx, len

    mov esi, 0              ; reversed str counter sta
    mov edi, len - 2        ; init str counter, -2 because we need to skip new line character

    reverse_loop:
        mov al, [msg + edi]
        mov [reversed_msg + esi], al
        inc esi
        dec edi
    loop reverse_loop

    mov byte [reversed_msg + len - 1], 0xa ; add new line character
ret