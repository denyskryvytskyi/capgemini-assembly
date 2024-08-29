SYS_EXIT equ 1
SYS_READ equ 3
SYS_WRITE equ 4
STDIN equ 0
STDOUT equ 1

MAX_NUMBERS equ 20

section .data
    array_msg db "Array: "
    array_msg_len equ $ - array_msg

    prompt_number db "Enter number: ", 0
    prompt_number_len equ $ - prompt_number

    result_msg db "Factorial: "
    result_msg_len equ $ - result_msg

    overflow_msg db "Overflow detected!", 0xa
    overflow_msg_len equ $ - overflow_msg

    newline db 10                       ; newline character
    space_char db 32                    ; space character

section .bss
    input_buffer resd 1                 ; buffer to store input number
    result resd 1                       ; factorial of number
    itoa_result_buffer resb 20          ; buffer to store the digits in string
    input_number resd 1

    ; for sequence
    numbers resb MAX_NUMBERS * 8                    ; 20 8-byte numbers

section .text
    global _start

_start:
    mov rsi, prompt_number
    mov rdx, prompt_number_len
    call print_string
    call read_int
    mov [input_number], rax

    ; calculate factorial
    mov rbx, [input_number] ; current processing number
    mov rax, 1

    ;call factorial_loop    ; loop version
    call factorial_recursed ; recusrion version
    jo .overflow_detected

    mov [result], rax

.print_result:
    ;call print_array

    ; print result (min/max value)
    mov rsi, result_msg
    mov rdx, result_msg_len
    call print_string

    ; convert integer to string
    mov rax, [result]
    call itoa
    call print_int
    call print_newline
    jmp .exit

.overflow_detected:
    mov rsi, overflow_msg
    mov rdx, overflow_msg_len
    call print_string

.exit:
    mov rax, 60                         ; sys_exit system call
    xor rdi, rdi                        ; exit status 0
    syscall

; ------------------ helpers --------------------
print_string:
    mov rax, SYS_EXIT
    mov rdi, STDOUT
    syscall
ret

read_int:
    mov rax, 0                          ; sys_read
    mov rdi, 0                          ; file descriptor (stdin)
    mov rsi, input_buffer               ; buffer to store input
    mov rdx, 4                          ; number of bytes to read
    syscall

    call atoi
ret

atoi:
    xor rax, rax                        ; initialize result
    xor rcx, rcx                        ; initialize sign flag (0 = positive)

    ; check for sign
    mov bl, [rsi]
    cmp bl, '-'
    jne .process_digits
    inc rsi                             ; move past the minus sign
    inc rcx                             ; set sign flag

.process_digits:
    xor rbx, rbx
    mov bl, [rsi]                       ; get the current character
    test bl, bl
    jz .done                            ; if null terminator, we're done

    sub bl, '0'                         ; convert ASCII to number
    cmp bl, 9
    ja .done                            ; if not a digit, we're done

    imul rax, 10                        ; multiply current result by 10
    add rax, rbx                        ; add the current digit

    inc rsi                             ; move to next character
    jmp .process_digits

.done:
    test rcx, rcx
    jz .exit
    neg rax                             ; negate if sign flag is set
.exit:
ret

; proc to convert number to string
itoa:
    mov rdi, itoa_result_buffer  ; point edi to the end of the buffer

    ; check if the number is negative
    xor rsi, rsi
    test rax, rax
    jns .process_digits
    inc rsi             ; set negative flag
    neg rax             ; make the number positive

.process_digits:
    add rdi, 19             ; fill it from right to left
    mov rcx, 10             ; divisor for extracting digits

    .convert_loop:
        xor rdx, rdx       ; clear edx for division
        div rcx            ; divide eax by 10, remainder in edx
        add dl, '0'        ; convert remainder to ASCII
        dec rdi            ; move buffer pointer left
        mov [rdi], dl      ; store the digit
        test rax, rax      ; check if quotient is zero
        jnz .convert_loop      ; if not, continue loop

    ; check if the negative flag is set
    test rsi, rsi
    jz .done
    dec rdi
    mov byte [rdi], '-' ; Add minus sign to the buffer

    .done:
ret

print_newline:
    mov rsi, newline                    ; address of newline character
    mov rdx, 1                          ; length of 1 byte
    mov rdi, STDOUT
    mov rax, SYS_EXIT
    syscall
ret

print_int:
    mov rdx, itoa_result_buffer
    add rdx, 20
    sub rdx, rdi                    ; edx now holds the string length

    mov rsi, rdi
    mov rdi, STDOUT
    mov rax, SYS_EXIT
    syscall
ret

print_array:
    mov rsi, array_msg
    mov rdx, array_msg_len
    call print_string

    xor rcx, rcx
    mov rcx, MAX_NUMBERS                ; size of array for loop counter
    mov rbp, 0                          ; current index of array

    .loop_array:
        push rcx                        ; save loop counter on stack
        mov rax, [numbers + rbp * 4]    ; second number to eax
        call itoa
        call print_int

        ; print space
        mov rsi, space_char                    ; address of newline character
        mov rdx, 1                             ; length of 1 byte
        mov rdi, STDOUT
        mov rax, SYS_EXIT
        syscall

        inc rbp
        pop rcx                                ; get loop counter from stack

        loop .loop_array

    call print_newline
ret

factorial_loop:
mov rcx, [input_number] ; loop counter
.loop_fact:
        cmp rbx, 1
        jle .done
        mul rbx
        jo .done
        dec rbx
        loop .loop_fact
.done:
ret

factorial_recursed:
    cmp rbx, 1
    jg .next_number
    ret
.next_number:
    mul rbx
    jo .overflow
    dec rbx
    call factorial_recursed
ret