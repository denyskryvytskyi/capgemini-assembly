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

    result_loop_msg db "Factorial (loop): "
    result_loop_msg_len equ $ - result_loop_msg

    result_recursion_msg db "Factorial (recursion): "
    result_recursion_msg_len equ $ - result_recursion_msg

    overflow_msg db "Overflow detected!", 0xa
    overflow_msg_len equ $ - overflow_msg

    negative_msg db "Negative number!", 0xa
    negative_msg_len equ $ - negative_msg

    newline db 10                       ; newline character
    space_char db 32                    ; space character

section .bss
    input_buffer resd MAX_NUMBERS       ; buffer to store input number
    result_loop resb 8                  ; factorial of number calculated by loop
    result_recursed resb 8              ; factorial of number calculated by recursion
    itoa_result_buffer resb 20          ; buffer to store the digits in string
    input_number resb 8

    ; for sequence
    input_array_size resb 4             ; size of input array
    numbers resb MAX_NUMBERS * 8        ; 20 8-byte numbers
    numbers_result_loop resb MAX_NUMBERS * 8                  ; factorial of number calculated by loop
    numbers_result_recursed resb MAX_NUMBERS * 8              ; factorial of number calculated by recursion

section .text
    global _start

_start:
    mov rsi, prompt_number
    mov rdx, prompt_number_len
    call print_string

    ; now we need read a sequence of integers
    call read_int_sequence

    ; calculate factorial with loop
    mov ecx, [input_array_size]                 ; size of array is loop counter
    mov rsi, numbers                            ; pointer to number array
    mov rdi, numbers_result_loop                ; pointer to factorial array

    .loop_array_l:
        mov rbx, [rsi]
        mov rax, 1
        call factorial_loop
        jo .overflow_detected
        mov [rdi], rax
        ; move pointers to the next elements
        add rsi, 8
        add rdi, 8
        loop .loop_array_l

    ; calculate factorial with recursion
    mov ecx, [input_array_size]                 ; size of array is loop counter
    mov rsi, numbers                            ; pointer to number array
    mov rdi, numbers_result_recursed            ; pointer to factorial array

    .loop_array_r:
        mov rbx, [rsi]
        mov rax, 1
        call factorial_recursed
        jo .overflow_detected
        mov [rdi], rax
        ; move pointers to the next elements
        add rsi, 8
        add rdi, 8
        loop .loop_array_r

.print_result:
    ; print loop factorial
    mov rsi, result_loop_msg
    mov rdx, result_loop_msg_len
    call print_string
    ; print array of results
    mov rbx, numbers_result_loop ; set pointer
    call print_array

    ; print recursion factorial
    mov rsi, result_recursion_msg
    mov rdx, result_recursion_msg_len
    call print_string
    ; print array of results
    mov rbx, numbers_result_recursed ; set pointer
    call print_array
    jmp .exit

.overflow_detected:
    mov rsi, overflow_msg
    mov rdx, overflow_msg_len
    call print_string
    jmp .exit

.negative:
    mov rsi, negative_msg
    mov rdx, negative_msg_len
    call print_string

.exit:
    mov rax, 60                         ; sys_exit system call
    xor rdi, rdi                        ; exit status 0
    syscall

; ------------------ helpers --------------------
print_string:
    push rcx
    mov rax, SYS_EXIT
    mov rdi, STDOUT
    syscall
    pop rcx
ret

read_int_sequence:
    mov rax, 0                          ; sys_read
    mov rdi, 0                          ; file descriptor (stdin)
    mov rsi, input_buffer               ; buffer to store input
    mov rdx, 160                        ; number of bytes to read
    syscall

    mov bl, [rsi]
    mov ebp, numbers                    ; pointer to array
    mov edi, [input_array_size]
.seq_to_i:                              ; do while not null terminator
    call atoi
    inc edi
    test bl, bl
    jz .done                            ; if null terminator
    cmp bl, 32
    jne .done                           ; if space delimiter
    inc rsi
    add ebp, 8                          ; move pointer to the next element
    jmp .seq_to_i

.done:
    mov [input_array_size], edi
ret

atoi:
    xor rax, rax                        ; initialize result

.process_digits:
    xor rbx, rbx
    mov bl, [rsi]                       ; get the current character
    test bl, bl
    jz .done                            ; if null terminator, we're done

    cmp bl, '-'
    je _start.negative

    cmp bl, [space_char]
    je .done

    sub bl, '0'                         ; convert ASCII to number
    cmp bl, 9
    ja .done                            ; if not a digit, we're done

    imul rax, 10                        ; multiply current result by 10
    add rax, rbx                        ; add the current digit

    inc rsi                             ; move to next character
    jmp .process_digits

.done:
    mov [ebp], rax
ret

; proc to convert number to string
itoa:
    push rcx

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
        div rcx            ; divide rax by 10, remainder in edx
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
    pop rcx
ret

print_newline:
    mov rsi, newline                    ; address of newline character
    mov rdx, 1                          ; length of 1 byte
    mov rdi, STDOUT
    mov rax, SYS_EXIT
    syscall
ret

print_int:
    push rcx

    mov rdx, itoa_result_buffer
    add rdx, 20
    sub rdx, rdi                    ; edx now holds the string length

    mov rsi, rdi
    mov rdi, STDOUT
    mov rax, SYS_EXIT
    syscall

    pop rcx
ret

print_array:
    mov ecx, [input_array_size]                ; size of array for loop counter
    .loop_array:
        ;push rcx                        ; save loop counter on stack
        mov rax, [rbx]                  ; second number to rax
        call itoa
        call print_int

        ; print space
        mov rsi, space_char
        mov rdx, 1
        call print_string

        add rbx, 8                      ; move pointer to the next element
        ;pop rcx                         ; get loop counter from stack

        loop .loop_array

    call print_newline
ret

factorial_loop:
push rcx
push rsi
push rdi
mov rcx, [input_number] ; loop counter
.loop_fact:
    cmp rbx, 1
    jle .done
    mul rbx
    jo .done
    dec rbx
    loop .loop_fact
.done:
pop rdi
pop rsi
pop rcx
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
.overflow:
ret