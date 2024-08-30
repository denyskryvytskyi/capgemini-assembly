SYS_EXIT equ 1
SYS_READ equ 3
SYS_WRITE equ 4
STDIN equ 0
STDOUT equ 1

section .data
    prompt_choice db "Find (1) Maximum or (0) Minimum: ", 0
    prompt_choice_len equ $ - prompt_choice

    array_msg db "Array: "
    array_msg_len equ $ - array_msg

    result_msg db "Result: "
    result_msg_len equ $ - result_msg

    newline db 10                       ; newline character
    space_char db 32                    ; space character

    numbers dd 89, -10, 2, 789, -55, 130, -6, 3, 900, 78, 5, 5700
    numbers_len equ ($ - numbers) / 4 ; calculate the length of the array

section .bss
    input_buffer resb 4                 ; buffer to store input number
    result resb 4                       ; result number based on comparisons
    itoa_result_buffer resb 20               ; buffer to store the digits in string
    choice resd 1

section .text
    global _start

_start:
    ; print prompt to choose logic min/max
    mov esi, prompt_choice
    mov edx, prompt_choice_len
    call print_string
    call read_int
    mov [choice], eax

    ; check choice and make appropriate call
    mov edx, [choice]
    cmp edx, 0
    je .find_min
    cmp edx, 1
    je .find_max
    ; invalid choice
    jmp .exit

.find_min:
    call min
    jmp .print_result

.find_max:
    call max

.print_result:
    call print_array

    ; print result (min/max value)
    mov esi, result_msg
    mov edx, result_msg_len
    call print_string

    ; convert integer to string
    mov eax, [result]
    call itoa
    call print_int
    call print_newline

.exit:
    mov eax, 60                         ; sys_exit system call
    xor edi, edi                        ; exit status 0
    syscall

; ------------------ helpers --------------------
print_string:
    mov eax, SYS_EXIT
    mov edi, STDOUT
    syscall
ret

read_int:
    mov eax, 0                          ; sys_read
    mov edi, 0                          ; file descriptor (stdin)
    mov esi, input_buffer               ; buffer to store input
    mov edx, 4                          ; number of bytes to read
    syscall

    call atoi
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

; proc to find maximum value
max:
    xor eax, eax
    mov eax, [numbers]
    mov ecx, (numbers_len - 1) / 4          ; loop counter with skip of the first element

    cmp ecx, 0                              ; if array has less then 4 elements - skip unrolling
    je .process_remainder

    mov esi, numbers + 4                    ; current array pointer

    ; loop through the array and compare elements
.loop_array:
        mov ebx, [esi]
        cmp eax, ebx            ; set flag
        cmovl eax, ebx          ; move by flag

        mov ebx, [esi + 4]
        cmp eax, ebx
        cmovl eax, ebx

        mov ebx, [esi + 8]
        cmp eax, ebx
        cmovl eax, ebx

        mov ebx, [esi + 12]
        cmp eax, ebx
        cmovl eax, ebx

        add esi, 16             ; move pointer to the next group of four numbers
        loop .loop_array

.process_remainder:
    mov ecx, numbers_len - 1
    and ecx, 3  ; Get remainder when divided by 4
    jz .done

    .remainder_loop:
        mov ebx, [esi]
        cmp eax, ebx
        cmovl eax, ebx
        add esi, 4
    loop .remainder_loop

.done:
    mov [result], eax
ret

; proc to find minimum value
min:
    xor eax, eax
    mov eax, [numbers]
    mov ecx, (numbers_len - 1) / 4          ; loop counter with skip of the first element

    cmp ecx, 0                              ; if array has less then 4 elements - skip unrolling
    je .process_remainder

    mov esi, numbers + 4                    ; current array pointer

    ; loop through the array and compare elements
.loop_array:
        mov ebx, [esi]
        cmp eax, ebx            ; set flag
        cmovg eax, ebx          ; move by flag

        mov ebx, [esi + 4]
        cmp eax, ebx
        cmovg eax, ebx

        mov ebx, [esi + 8]
        cmp eax, ebx
        cmovg eax, ebx

        mov ebx, [esi + 12]
        cmp eax, ebx
        cmovg eax, ebx

        add esi, 16             ; move pointer to the next group of four numbers
        loop .loop_array

.process_remainder:
    mov ecx, numbers_len - 1
    and ecx, 3  ; Get remainder when divided by 4
    jz .done

    .remainder_loop:
        mov ebx, [esi]
        cmp eax, ebx
        cmovg eax, ebx
        add esi, 4
    loop .remainder_loop

.done:
    mov [result], eax
ret

; proc to convert number to string
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

print_newline:
    mov esi, newline                    ; address of newline character
    mov edx, 1                          ; length of 1 byte
    mov edi, STDOUT
    mov eax, SYS_EXIT
    syscall
ret

print_int:
    mov edx, itoa_result_buffer
    add edx, 20
    sub edx, edi                    ; edx now holds the string length

    mov esi, edi
    mov edi, STDOUT
    mov eax, SYS_EXIT
    syscall
ret

print_array:
    mov esi, array_msg
    mov edx, array_msg_len
    call print_string

    xor ecx, ecx
    mov ecx, numbers_len                ; size of array for loop counter
    mov ebp, 0                          ; current index of array

    .loop_array:
        push rcx                        ; save loop counter on stack
        mov eax, [numbers + ebp * 4]    ; second number to eax
        call itoa
        call print_int

        ; print space
        mov esi, space_char                    ; address of newline character
        mov edx, 1                             ; length of 1 byte
        mov edi, STDOUT
        mov eax, SYS_EXIT
        syscall

        inc ebp
        pop rcx                                ; get loop counter from stack

        loop .loop_array

    call print_newline
ret