; TASK: Evaluate an Arithmetical Expression Using Stack Operations
; IMPLEMENTED:
;   - complex multidigit multinumber (32-bit integer) expression evaluation
;   - negative numbers processing
;   - syntax errors handling
;   - overflow handling
; TODO (possible improvements):
;   - multiplication and division operations
;   - brackets and operations priorities

SYS_EXIT equ 60
SYS_READ equ 0
SYS_WRITE equ 1
STDIN equ 0
STDOUT equ 1

MAX_EXPERESSION_SIZE equ 100 ; 100 characters string is max
STACK_SIZE equ 256           ; 256 4-byte integers

SYS_ERROR_CODE equ 1
OVERFLOW_ERROR_CODE equ 2

section .data
    prompt_msg db "Enter expression: "
    prompt_msg_len equ $ - prompt_msg

    result_msg db "Result: "
    result_msg_len equ $ - result_msg
    
    syntax_error_msg db "Syntax Error.", 0xa
    syntax_error_msg_len equ $ - syntax_error_msg

    overflow_error_msg db "Overlow.", 0xa
    overflow_error_msg_len equ $ - overflow_error_msg

    newline_ascii db 0xa                   ; newline character

section .bss
    input_buffer resb MAX_EXPERESSION_SIZE
    stack resd STACK_SIZE
    stack_top resb 4
    last_op resb 1   ; last parsed operation

    result resb 4    ; result of calculation
    itoa_result_buffer resb 20             ; buffer to store the number digits in string

section .text
    global _start

_start:
    ; print prompt
    mov esi, prompt_msg
    mov edx, prompt_msg_len
    call print_string

    ; expression processing
    call evaluate_expression

    cmp eax, SYS_ERROR_CODE
    je .syntax_error
    cmp eax, OVERFLOW_ERROR_CODE
    je .overflow_error

    ; print result
    mov esi, result_msg
    mov edx, result_msg_len
    call print_string

    mov rax, [result]
    call itoa
    call print_int
    call print_newline
    jmp .exit

    .syntax_error:
        mov esi, syntax_error_msg
        mov edx, syntax_error_msg_len
        call print_string
        jmp .exit

    .overflow_error:
        mov esi, overflow_error_msg
        mov edx, overflow_error_msg_len
        call print_string

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

evaluate_expression:
    mov rax, SYS_READ
    mov rdi, STDIN
    mov rsi, input_buffer               ; buffer to store input
    mov rdx, MAX_EXPERESSION_SIZE       ; number of bytes to read
    syscall

    ; iterate string by character
    ; try to parse integer
    ; - if sign and empty stack then parse another number
    ; - if any othe character - error
    ; - if after sign no number - error
    ; - if number and sign - parse another number
    mov ecx, 100        ; iterate trough 100 character
    .loop_expr:
        mov bl, [rsi]                   ; next character
        test bl, bl
        jz .done                        ; if null terminator
        ; TODO: may be add newline character check
        cmp bl, 0xa
        je .done
        cmp bl, '-'
        je .operator_found
        cmp bl, '+'
        je .operator_found
        cmp bl, '0'
        jl .syntax_error
        cmp bl, '9'
        jg .syntax_error

        call read_number
        cmp eax, OVERFLOW_ERROR_CODE
        je .overflow

        ; check if we had operator
        mov bl, [last_op]
        cmp bl, '+'
        je .add
        cmp bl, '-'
        je .sub

        ; if not - check size of stack, it it has more than 1 number -> syntax error
        mov ebx, [stack_top]
        cmp ebx, 2
        je .syntax_error
        loop .loop_expr

        .operator_found:
            mov [last_op], bl           ; cache operator
            inc rsi                     ; next character
            loop .loop_expr
        .add:
            call add
            loop .loop_expr
        .sub:
            call sub

        loop .loop_expr

    .done:
        ; check if we have unused operator
        mov bl, [last_op]
        cmp bl, 0
        jne .syntax_error
        call stack_pop
        mov [result], edi
    ret

    .syntax_error:
        mov eax, SYS_ERROR_CODE          ; error code

    .overflow:
ret

read_number:
    ; process first digit
    xor edi, edi
    sub bl, '0'                    ; convert ASCII to number
    add edi, ebx                   ; add the current digit

    ; check another digits
    .loop_read_num:
        inc esi
        mov bl, [esi]              ; get the next character
        cmp bl, '0'
        jl .check_negative
        cmp bl, '9'
        jg .check_negative

        sub bl, '0'                    ; convert ASCII to number

        imul edi, 10               ; multiply current result by 10
        jo .overflow
        add edi, ebx               ; add the current digit
        jo .overflow
        jmp .loop_read_num

    .check_negative:
        ; now we check stack size and last parsed operator to check if the number is negative
        mov ebx, [stack_top]
        cmp ebx, 1
        je .done
        mov bl, [last_op]
        cmp bl, '-'
        mov byte [last_op], 0
        jne .done
        neg edi
        jo .overflow

    .done:
        call stack_push            ; push parsed number on stack
        ret

    .overflow:
        mov eax, OVERFLOW_ERROR_CODE
ret

add:
    xor edi, edi
    xor eax, eax
    call stack_pop
    mov ebx, edi
    call stack_pop
    add edi, ebx
    jo .overflow
    call stack_push
    mov byte [last_op], 0               ; reset op cache
    ret
    .overflow:
        mov eax, OVERFLOW_ERROR_CODE    ; error code
ret

sub:
    xor edi, edi
    xor eax, eax
    call stack_pop
    mov ebx, edi
    call stack_pop
    sub edi, ebx
    jo .overflow
    call stack_push
    mov byte [last_op], 0               ; reset op cache
    ret
    .overflow:
        mov eax, OVERFLOW_ERROR_CODE    ; error code
ret

itoa:
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

; ------------------ Stack operations ------------------
stack_push:
    push rax

    mov eax, [stack_top]                  ; get current top index
    mov [stack + eax * 4], edi      ; push the value onto the stack
    inc dword [stack_top]                       ; increment top index

    pop rax
ret

stack_pop:
    push rax

    dec dword [stack_top]                       ; decrement top index
    mov eax, [stack_top]                  ; get updated top index
    mov edi, [stack + eax * 4]      ; pop the value from the stack into EDI

    pop rax
ret

stack_top_value:
    mov eax, [stack_top]                  ; get top index
    dec eax                         ; move to the last element
    mov edi, [stack + eax * 4]      ; get the top value
ret