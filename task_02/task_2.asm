; TASK: Reverse a String

SYS_EXIT equ 1
SYS_WRITE equ 4
STDOUT equ 1
SYS_CALL equ 0x80
ASCII_A equ 'a'
ASCII_Z equ 'z'

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
    int SYS_CALL

    ; exit
    mov eax, SYS_EXIT
    int SYS_CALL

to_uppercase:
    mov ecx, len - 1
    mov esi, msg                  ; character counter

    uppercase_loop:
        mov al, [esi]     ; get next character

        cmp al, ASCII_A         ; compare with ASCII 'a'
        jl next_char
        cmp al, ASCII_Z         ; compare with ASCII 'z'
        jg next_char

        sub al, 32              ; get uppercase ASCII character
        mov [esi], al

        next_char:
            inc esi
    loop uppercase_loop
ret

reverse_string:
    mov ecx, len - 1

    mov esi, msg                 ; init string pointer
    mov edi, reversed_msg        ; reversed string pointer
    add edi, ecx                 ; mov pointer to the last character
    sub edi, 1                   ; -1 byte back from new line character

    reverse_loop:
        mov al, [esi]
        mov [edi], al
        inc esi
        dec edi
    loop reverse_loop

    mov byte [reversed_msg + len - 1], 0xa ; add new line character
ret