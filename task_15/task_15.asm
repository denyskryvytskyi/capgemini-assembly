; TASK: Simple File Encryption/Decryption Program

SYS_READ equ 0  ; read from file/console
SYS_WRITE equ 1 ; write to file/console
SYS_OPEN equ 2  ; open file
SYS_CLOSE equ 3  ; close file
SYS_EXIT equ 60 

STDIN equ 0
STDOUT equ 1

D_ASCII equ 0x44
E_ASCII equ 0x45

ERROR_FILE_NOT_FOUND equ -2

section .data
    operation_msg db "Choose operation (E)ncrypt, (D)ecrypt: "
    operation_msg_len equ $ - operation_msg

    input_file_path_msg db "Input file path: "
    input_file_path_msg_len equ $ - input_file_path_msg

    output_file_path_msg db "Output file path: "
    output_file_path_msg_len equ $ - output_file_path_msg

    key_msg db "Enter encryption key: "
    key_msg_len equ $ - key_msg

    result_msg db "Operation succeed: "
    result_msg_len equ $ - result_msg

    error_file_msg db "Error: file not found"
    error_file_msg_len equ $ - error_file_msg

    error_op_msg db "Error: wrong operation input. Try again."
    error_op_msg_len equ $ - error_op_msg

    newline_ascii db 0xa                   ; newline character
    space_ascii db 0x20                    ; space character

    test_ifile db "input.txt", 0
    test_ifile_len equ $ - test_ifile

    test_ofile db "output.txt", 0
    test_ofile_len equ $ - test_ofile

section .bss
    input_file_name_buffer resb 256
    output_file_name_buffer resb 256
    key_buffer resb 256
    operation resb 2
    file_content_buffer resb 1024
    key_size resb 8

section .text
    global _start

_start:
    ; print prompt
    mov esi, operation_msg
    mov edx, operation_msg_len
    call print_string

    ; read operation 
    mov esi, operation     ; buffer to store input
    mov edx, 2             ; number of bytes to read: letter + newline
    call read_string

    ; depending on operation prompt input/output file and key
    mov al, byte [operation]
    cmp al, E_ASCII
    je .encrypt_decrypt
    cmp al, D_ASCII
    je .encrypt_decrypt
    ; wrong operation
    mov esi, error_op_msg
    mov edx, error_op_msg_len
    call print_string
    call print_newline
    jmp _start

    .encrypt_decrypt:
        call prepare_data

        mov rdi, file_content_buffer     ; pointer to content buffer
        mov rsi, key_buffer              ; pointer to key buffer
        call encrypt_decrypt

        call write_to_output
        jmp .exit

    .error_file_not_found:
        mov esi, error_file_msg
        mov edx, error_file_msg_len
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
    mov rdx, 1                  ; length
    mov rdi, STDOUT
    mov rax, SYS_WRITE
    syscall

    pop rcx
ret

read_string:
    mov eax, SYS_READ                  ; sys_read
    mov edi, STDIN                     ; file descriptor (stdin)
    syscall                            ; return: rax contains number of bytes
ret

prepare_data:
    ; prompt for input file path
    mov rsi, input_file_path_msg
    mov rdx, input_file_path_msg_len
    call print_string
    mov rsi, input_file_name_buffer                 ; buffer to store input file path
    mov rdx, 256                                    ; number of bytes to read
    call read_string
    mov byte [input_file_name_buffer + rax - 1], 0  ; null terminator

    ; prompt for output file path
    mov rsi, output_file_path_msg
    mov rdx, output_file_path_msg_len
    call print_string
    mov rsi, output_file_name_buffer                ; buffer to store output file path
    mov rdx, 256                                    ; number of bytes to read
    call read_string
    mov byte [output_file_name_buffer + rax - 1], 0 ; null terminator

    ; prompt for key
    mov rsi, key_msg
    mov rdx, key_msg_len
    call print_string
    mov rsi, key_buffer                ; buffer to store output file path
    mov rdx, 256                       ; number of bytes to read
    call read_string
    mov byte [key_buffer + rax - 1], 0 ; null terminator
    mov [key_size], al

    ; open input file
    mov rax, SYS_OPEN
    mov rdi, input_file_name_buffer
    xor rsi, rsi                        ; read-only
    xor rdx, rdx                        ; no flags
    syscall                             ; return: rax contains file desriptor
    mov rdi, rax                        ; save file descriptor

    ; check errors
    cmp rax, ERROR_FILE_NOT_FOUND
    je _start.error_file_not_found

    ; get input file content
    mov rax, SYS_READ
    mov rsi, file_content_buffer
    mov rdx, 1024
    syscall                             ; return: rax contains number of reading bytes
    mov rbx, rax

    ; close input file
    mov rax, SYS_CLOSE
    mov rdi, rdi                        ; use saved file descriptor
    syscall
ret

encrypt_decrypt:
    ; arguments:
    ; rbx - size of string to process
    push rbx                     ; save rbx

    mov rcx, rbx                 ; loop counter
    xor rax, rax
    xor rdx, rdx
    xor rbx, rbx
    xor rbp, rbp                 ; index of current iterated byte
    mov rdx, [key_size]         ; length of key
    sub rdx, 1

    .process_loop:
        cmp rcx, rbp
        je .done
        ; XOR each byte with the key
        mov al, [rdi]                   ; load byte from read_buffer
        mov bl, [rsi]                   ; load byte from key_buffer
        xor al, bl                      ; XOR operation
        mov [rdi], al                   ; store result back in read_buffer
        inc rbp                         ; increase index
        cmp rbp, rdx                    ; check key buffer index
        jge .reset_key
        inc rsi
        inc rdi
        jmp .process_loop               ; repeat for next byte
        .reset_key:
            mov rsi, key_buffer
            inc rdi
        jmp .process_loop               ; repeat for next byte

    .done:
        pop rbx
ret

write_to_output:
    ; open output file
    xor rdi,rdi
    mov rax, SYS_OPEN
    mov rdi, output_file_name_buffer
    mov rsi, 0x201                      ; O_WRONLY | O_TRUNC
    xor rdx, rdx                        ; no flags
    syscall
    mov rdi, rax                        ; save file descriptor

    ; check errors
    cmp rax, ERROR_FILE_NOT_FOUND
    je _start.error_file_not_found

    ; write to output file
    mov rax, SYS_WRITE
    mov rsi, file_content_buffer
    mov rdx, rbx
    syscall

    ; close output file
    mov rax, SYS_CLOSE
    mov rdi, rdi ; use saved file descriptor
    syscall

ret