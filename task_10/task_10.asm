; TASK: Memory Segmentation by Accessing Data from Different Segments

SYS_EXIT equ 60
SYS_READ equ 0
SYS_WRITE equ 1
STDIN equ 0
STDOUT equ 1

SHIFT_BITS_AMOUNT equ 3

section .data
    data_str db 'Hello, Capgemini!', 0
    data_str_len equ $ - data_str

    str_msg db "Default string: "
    str_msg_len equ $ - str_msg

    encrypt_msg db "Encrypted: "
    encrypt_msg_len equ $ - encrypt_msg

    decrypt_msg db "Decrypted: "
    decrypt_msg_len equ $ - decrypt_msg

    newline_ascii db 0xa                   ; newline character
    space_ascii db 0x20                    ; space character

section .bss
    encrypted_data resb data_str_len
    decrypted_data resb data_str_len

section .text
    global _start

_start:
    lea rsi, [data_str]          ; SI points to data in the data segment
    lea rdi, [encrypted_data]    ; DI points to buffer in the bss segment
    mov dl, SHIFT_BITS_AMOUNT    ; load shift amount (1) into DL
    mov rcx, data_str_len        ; amount of bytes to encrypt
    call encrypt_data

    lea rsi, [encrypted_data]
    lea rdx, [decrypted_data]
    mov rcx, data_str_len
    call decrypt_data

    ; default data print
    mov esi, str_msg
    mov edx, str_msg_len
    call print_string

    mov esi, data_str
    mov edx, data_str_len
    call print_string
    call print_newline

    ; encrypt data print
    mov esi, encrypt_msg
    mov edx, encrypt_msg_len
    call print_string

    mov esi, encrypted_data
    mov edx, data_str_len
    call print_string
    call print_newline

    ; decrypt data print
    mov esi, decrypt_msg
    mov edx, decrypt_msg_len
    call print_string

    mov esi, decrypted_data
    mov edx, data_str_len
    call print_string
    call print_newline

    .exit:
        mov rax, SYS_EXIT                   ; sys_exit system call
        xor rdi, rdi                        ; exit status 0
        syscall

; ------------------ helpers --------------------
print_string:
    push rcx

    mov rax, SYS_WRITE
    mov rdi, STDOUT
    syscall

    pop rcx
ret

print_newline:
    push rcx

    mov rsi, newline_ascii      ; address of newline character
    mov rdx, 1                   ; length
    mov rdi, STDOUT
    mov rax, SYS_WRITE
    syscall

    pop rcx
ret

encrypt_data:
    .encrypt_loop:
        mov rax, [rsi]              ; receive first character of the string
        rol al, SHIFT_BITS_AMOUNT   ; rotate bits to the left shifting on n-bits
        mov [rdi], rax              ; move to destination
        inc rsi
        inc rdi
        loop .encrypt_loop
ret

decrypt_data:
    .decrypt_loop:
        mov rax, [rsi]              ; receive first character of the string
        ror al, SHIFT_BITS_AMOUNT   ; rotate bits to the right shifting on n-bits
        mov [rdi], rax              ; move to destination
        inc rsi
        inc rdi
        loop .decrypt_loop
ret