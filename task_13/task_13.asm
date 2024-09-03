; TASK: Create and Use Macros for Common Arithmetic Operations

SYS_EXIT equ 60
SYS_READ equ 0
SYS_WRITE equ 1
STDIN equ 0
STDOUT equ 1

%macro ADD 2
    mov rax, %1
    add rax, %2
%endmacro

%macro SUB 2
    mov rax, %1
    sub rax, %2
%endmacro

%macro MUL 2
    mov rax, %1
    mov rbx, %2
    mul rbx
%endmacro

%macro DIV 2
    mov rax, %1
    mov rbx, %2
    cqo
    div rbx
%endmacro

section .data
    num_1_msg db "Number 1: "
    num_1_msg_len equ $ - num_1_msg

    num_2_msg db "Number 2: "
    num_2_msg_len equ $ - num_2_msg

    result_add_msg db "Addition: "
    result_add_msg_len equ $ - result_add_msg

    result_sub_msg db "Subtraction: "
    result_sub_msg_len equ $ - result_sub_msg

    result_mul_msg db "Multiplication: "
    result_mul_msg_len equ $ - result_mul_msg

    result_div_msg db "Division: "
    result_div_msg_len equ $ - result_div_msg

    newline_ascii db 0xa                   ; newline character
    space_ascii db 0x20                    ; space character

    num_1 dq 340
    num_2 dq 58

section .bss
    result resb 2
    itoa_result_buffer resb 4

section .text
    global _start

_start:
    ; print numbers
    mov esi, num_1_msg
    mov edx, num_1_msg_len
    call print_string
    mov rax, [num_1]
    call itoa
    call print_int
    call print_newline

    mov esi, num_2_msg
    mov edx, num_2_msg_len
    call print_string
    mov rax, [num_2]
    call itoa
    call print_int
    call print_newline

    ; addition
    mov esi, result_add_msg
    mov edx, result_add_msg_len
    call print_string

    ADD [num_1], [num_2]
    call itoa
    call print_int
    call print_newline

    ; subtraction
    mov esi, result_sub_msg
    mov edx, result_sub_msg_len
    call print_string

    SUB [num_1], [num_2]
    call itoa
    call print_int
    call print_newline

    ; multiplicaton
    mov esi, result_mul_msg
    mov edx, result_mul_msg_len
    call print_string

    MUL [num_1], [num_2]
    call itoa
    call print_int
    call print_newline

    ; division
    mov esi, result_div_msg
    mov edx, result_div_msg_len
    call print_string

    DIV [num_1], [num_2]
    call itoa
    call print_int
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

itoa:
    push rcx

    mov edi, itoa_result_buffer  ; point edi to the end of the buffer

    ; check if the number is negative
    xor esi, esi
    test eax, eax
    jns .process_digits
    inc esi             ; set negative flag
    neg eax             ; make the number positive

    .process_digits:
        add edi, 3              ; fill it from right to left
        mov ecx, 10             ; divisor for extracting digits

        .convert_loop:
            xor edx, edx       ; clear edx for division
            div ecx            ; divide eax by 10, remainder in edx
            add dl, '0'        ; convert remainder to ASCII
            dec edi            ; move buffer pointer left
            mov [edi], dl      ; store the digit
            test eax, eax      ; check if quotient is zero
            jnz .convert_loop      ; if not, continue loop

        ; check if the negative flag is set
        test esi, esi
        jz .done
        dec edi
        mov byte [edi], '-' ; Add minus sign to the buffer

    .done:
    pop rcx
ret

print_int:
    push rcx

    mov rdx, itoa_result_buffer
    add rdx, 4
    sub rdx, rdi                 ; rdx now holds the string length

    mov rsi, rdi
    mov rdi, STDOUT
    mov rax, SYS_WRITE
    syscall

    pop rcx
ret