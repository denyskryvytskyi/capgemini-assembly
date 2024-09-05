; TASK: Find the Maximum Value from Three Integers
; IMPLEMETED:
;   - min and max procedures
;   - user input for numbers
;   - user input to select operation (min/max) 
;   - output of the result

SYS_READ equ 0
SYS_WRITE equ 1
SYS_EXIT equ 60
STDIN equ 0
STDOUT equ 1

NUMBERS_AMOUNT equ 3
MAX_INPUT_BUFFER_BYTES equ 16 ; max number of characters to read from input for one number

section .data
    prompt_values db "Enter number: ", 0
    prompt_values_len equ $ - prompt_values

    prompt_choice db "Find (1) Maximum or (0) Minimum: ", 0
    prompt_choice_len equ $ - prompt_choice

    newline db 10                       ; newline character

section .bss
    input_buffer resb MAX_INPUT_BUFFER_BYTES ; buffer to store input number
    result resb 4                            ; result number based on comparisons
    values resb 12                           ; buffer to store three 4-byte values
    result_buffer resb 20                    ; buffer to store the digits in string
    choice resd 1

section .text
    global _start

_start:
    xor ebp, ebp
    mov ebx, values                      ; point to the start of the values array
    .read_values:
        cmp ebp, NUMBERS_AMOUNT              ; compare counter with the number of values
        jge .choose_max_or_min               ; if we've read enough values, move on

        mov esi, prompt_values               ; prompt for each value
        mov edx, prompt_values_len
        call print_string

        call read_int                        ; read the value
        mov [values + ebp * 4], eax          ; store the value in the array
        inc ebp                              ; increment counter
        jmp .read_values                     ; repeat for the next value

    .choose_max_or_min:
        ; print prompt to choose logic min/max
        mov esi, prompt_choice
        mov edx, prompt_choice_len
        call print_string
        call read_int                        ; read the choice
        mov [choice], eax

        xor rax, rax
        mov eax, [values]
        mov [result], eax                   ; first number to result
        mov eax, [values + 4]               ; second number to eax

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
        ; convert integer to string
        mov eax, [result]
        call itoa

        ; calculate result number string length
        mov eax, result_buffer
        add eax, 20
        sub eax, edi                        ; eax now holds the string length

        ; print the number
        mov esi, edi
        mov edx, eax                        ; length of the string to print
        mov edi, STDOUT
        mov eax, SYS_WRITE
        syscall

        ; print newline
        mov esi, newline                    ; address of newline character
        mov edx, 1                          ; length of 1 byte
        mov edi, STDOUT
        mov eax, SYS_WRITE
        syscall

    .exit:
        mov eax, SYS_EXIT                   ; sys_exit system call
        xor edi, edi                        ; exit status 0
        syscall

; ------------------ helpers --------------------
print_string:
    mov eax, SYS_WRITE                  ; sys_write
    mov edi, STDOUT                     ; file descriptor (stdout)
    syscall
ret

read_int:
    mov eax, SYS_READ                   ; sys_read
    mov edi, STDIN                      ; file descriptor (stdin)
    mov esi, input_buffer               ; buffer to store input
    mov edx, MAX_INPUT_BUFFER_BYTES     ; number of bytes to read
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
    cmp [result], eax                   ; compare first and second numbers
    jg .check_third_number              ; if first number is greater then second - jump
    mov [result], eax

    ; compare check between 1st and 2nd number with 3rd number
    .check_third_number:
        mov eax, [values + 8]
        cmp [result], eax
        jg .exit                            ; jump if greater then 3rd number
        mov [result], eax
    .exit:
    ret

    ; proc to find minimum value
    min:
        cmp [result], eax                   ; compare first and second numbers
        jl .check_third_number              ; if first number is greater then second - jump
        mov [result], eax

    ; compare check between 1st and 2nd number with 3rd number
    .check_third_number:
        mov eax, [values + 8]
        cmp [result], eax
        jl .exit                           ; jump if greater then 3rd number
        mov [result], eax
    .exit:
ret

; proc to convert number to string
itoa:
    mov edi, result_buffer  ; point edi to the end of the buffer

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