SYS_EXIT equ 60
SYS_READ equ 0
SYS_WRITE equ 1
STDIN equ 0
STDOUT equ 1

ARR_SIZE equ 12
BYTES_PER_NUMBER equ 4

section .data
    prompt_number db "Choose sorting order: (1) ascending, (0)(descending): ", 0
    prompt_number_len equ $ - prompt_number

    arr_msg db "Array (init): "
    arr_msg_len equ $ - arr_msg

    arr_msg_sorted db "Array (sorted): "
    arr_msg_sorted_len equ $ - arr_msg

    newline_ascii db 0xa                   ; newline character
    space_ascii db 0x20                    ; space character

    arr dd 34, -20, 0, 5, 53, 523, 8563, 2, -100, 34, 56, -765 ; 12 4-byte numbers

section .bss
    itoa_result_buffer resb 20                          ; buffer to store the number digits in string
    arr_sorted resb ARR_SIZE * BYTES_PER_NUMBER                        ; 12 4-byte numbers
    input_buffer resb 4                 ; buffer to store input number
    choice resb 1

section .text
    global _start

_start:
    ; print start prompt
    mov rsi, prompt_number
    mov rdx, prompt_number_len
    call print_string
    call read_int
    mov [choice], eax

    mov ecx, ARR_SIZE * BYTES_PER_NUMBER                   ; Load the length of the array into ecx
    mov esi, arr             ; Load the address of source_array into esi (source index)
    mov edi, arr_sorted   ; Load the address of destination_array into edi (destination index)
    rep movsb                 ; Copy ecx bytes from source_array to destination_array
    call bubble_sort

    .print_result:
        mov ebx, arr_sorted
        call print_array

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
    mov rsi, newline_ascii      ; address of newline character
    mov rdx, 1                  ; length
    mov rdi, STDOUT
    mov rax, SYS_WRITE
    syscall
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

print_array:
    mov ecx, ARR_SIZE         ; size of array for loop counter
    .loop_array:
        mov eax, [ebx]                  ; next number
        call itoa
        call print_int

        ; print space
        mov esi, space_ascii
        mov edx, 1
        call print_string

        add ebx, BYTES_PER_NUMBER                      ; move pointer to the next element
        loop .loop_array

    call print_newline
ret

bubble_sort:
    ; we need two loops, two counters for them and movemenet based on comparison
    mov ecx, ARR_SIZE       ; counter for the outer loop
    mov edi, [choice]
    .outer_loop:
        mov esi, arr_sorted     ; reset pointer to the array
        xor ebp, ebp            ; counter for the inner loop
        .inner_loop:
            mov eax, [esi]
            mov edx, [esi + BYTES_PER_NUMBER]

            ; choose comparison based on flag
            cmp edi, 0
            je .descending_compare

            ; ascending comparison
            cmp eax, edx                 ; compare
            jle .next_inner_iter         ; next iteration if not greater
            jmp .swap

            .descending_compare:
            cmp eax, edx                 ; compare
            jge .next_inner_iter         ; next iteration if not greater

            .swap:
                mov ebx, eax            ; temp
                mov [esi], edx
                mov [esi + BYTES_PER_NUMBER], ebx
            .next_inner_iter:
                inc ebp
                cmp ebp, ARR_SIZE - 1
                je .next_outer_iter
                add esi, BYTES_PER_NUMBER
        jmp .inner_loop
    .next_outer_iter:
    loop .outer_loop
ret