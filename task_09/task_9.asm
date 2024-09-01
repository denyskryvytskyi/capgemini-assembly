; TASK: Simple Calculator
; IMPLEMENTED:
;   - addition, subtraction of signed integer values with overflow detection
;   - multiplication of signed integers
;   - division for unsigned integers with division by zero check
;   - prompts and results output
;   - repeat calculation by user choice
; TODO:
;   - multiplication for big range integers with format RDX:RDA
;   - division of signed integers with sign flag processing correctly
;   - float numbers support

SYS_EXIT equ 60
SYS_READ equ 0
SYS_WRITE equ 1
STDIN equ 0
STDOUT equ 1

BYTES_PER_NUMBER equ 8

section .data
    prompt_number db "Enter number: ", 0
    prompt_number_len equ $ - prompt_number

    prompt_operation db "Choose operation (+) addition, (-) subtraction, (*) multiplication, (/) division: ", 0
    prompt_operation_len equ $ - prompt_operation

    result_msg db "Result: "
    result_msg_len equ $ - result_msg

    repeat_msg db "Do you want another calculation (1) Yes, (0) No: "
    repeat_msg_len equ $ - repeat_msg

    wrong_op_msg db "Wrong operation input. Try again."
    wrong_op_msg_len equ $ - wrong_op_msg

    div_by_zero_msg db "Division by zero. Try again."
    div_by_zero_msg_len equ $ - div_by_zero_msg

    overflow_msg db "Overflow. Try again."
    overflow_msg_len equ $ - overflow_msg

    newline_ascii db 0xa                   ; newline character
    space_ascii db 0x20                    ; space character

section .bss
    itoa_result_buffer resb 20              ; buffer to store the number digits in string
    input_buffer resb 20                    ; 20 1-byte characters
    num_1 resb BYTES_PER_NUMBER             ; buffer to store input number
    num_2 resb BYTES_PER_NUMBER             ; buffer to store input number
    op_result resb 16
    input_op resb 2

section .text
    global _start

_start:
    ; read first number
    mov esi, prompt_number
    mov edx, prompt_number_len
    call print_string
    call read_int
    mov [num_1], rax

    ; read second number
    mov esi, prompt_number
    mov edx, prompt_number_len
    call print_string
    call read_int
    mov [num_2], rax

    ; read operation
    mov esi, prompt_operation
    mov edx, prompt_operation_len
    call print_string
    mov eax, SYS_READ
    mov edi, STDIN
    mov esi, input_op               ; buffer to store input
    mov edx, 2                          ; number of bytes to read
    syscall

    mov rax, [num_1]

    mov bl, [input_op]
    cmp bl, 0x2b ; +
    je .add
    cmp bl, 0x2d ; -
    je .sub
    cmp bl, 0x2a ; *
    je .mul
    cmp bl, 0x2f ; /
    je .div

    jmp .wrong_op_input

    .add:
        add rax, [num_2]
        jo .overflow
        mov [op_result], rax
        jmp .print_result
    
    .sub:
        sub rax, [num_2]
        jo .overflow
        mov [op_result], rax
        jmp .print_result
    .mul:
        xor rdx, rdx        ; rest rdx to 0
        mov rbx, [num_2]
        imul rbx
        jo .overflow
        mov [op_result], rax
        jmp .print_result
    .div:
        mov rbx, [num_2]
        cmp rbx, 0
        je .div_by_zero
        cqo                 ; sign-extend rax into rdx:rax
        idiv rbx
        mov [op_result], rax

    .print_result:
        mov esi, result_msg
        mov edx, result_msg_len
        call print_string
        mov rax, [op_result]
        call itoa
        call print_int
        call print_newline

        ; repeat
        mov esi, repeat_msg
        mov edx, repeat_msg_len
        call print_string
        call read_int
        cmp eax, 1
        je _start
        jmp .exit

    .wrong_op_input:
        mov esi, wrong_op_msg
        mov edx, wrong_op_msg_len
        call print_string
        call print_newline
        jmp _start
        ;jmp .exit

    .div_by_zero:
        mov esi, div_by_zero_msg
        mov edx, div_by_zero_msg_len
        call print_string
        call print_newline
        jmp _start

    .overflow:
        mov esi, overflow_msg
        mov edx, overflow_msg_len
        call print_string
        call print_newline
        jmp _start

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

read_int:
    push rcx

    mov eax, SYS_READ                   ; sys_read
    mov edi, STDIN                      ; file descriptor (stdin)
    mov esi, input_buffer               ; buffer to store input
    mov edx, 20                         ; number of bytes to read
    syscall

    call atoi

    pop rcx
ret

atoi:
    xor eax, eax                        ; initialize result
    xor ecx, ecx                        ; initialize sign flag (0 = positive)

    ; check for sign
    mov bl, [esi]
    cmp bl, '-'
    jne .process_digits
    inc esi                             ; move past the minus sign
    inc ecx                             ; set sign flag

    .process_digits:
        xor ebx, ebx
        mov bl, [esi]                       ; get the current character
        test bl, bl
        jz .done                            ; if null terminator, we're done

        sub bl, '0'                         ; convert ASCII to number
        cmp bl, 9
        ja .done                            ; if not a digit, we're done

        imul eax, 10                        ; multiply current result by 10
        add eax, ebx                        ; add the current digit

        inc esi                             ; move to next character
        jmp .process_digits

    .done:
        test ecx, ecx
        jz .exit
        neg eax                             ; negate if sign flag is set
    .exit:
ret

itoa:
    push rcx
    push rbx

    mov edi, itoa_result_buffer  ; point edi to the end of the buffer

    ; check if the number is negative
    xor esi, esi
    test eax, eax
    jns .process_digits
    inc esi             ; set negative flag
    neg eax             ; make the number positive

    .process_digits:
        add edi, 19             ; fill it from right to left
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
    pop rbx
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

print_int:
    push rcx

    mov rdx, itoa_result_buffer
    add rdx, 20
    sub rdx, rdi                 ; rdx now holds the string length

    mov rsi, rdi
    mov rdi, STDOUT
    mov rax, SYS_WRITE
    syscall

    pop rcx
ret
