; TASK: Dynamic Memory Allocation and Array Operations
; IMPLEMENTED:
;   - 
; TODO (possible improvements):
;   - 

SYS_EXIT equ 60
SYS_READ equ 0
SYS_WRITE equ 1
SYS_BRK equ 12
STDIN equ 0
STDOUT equ 1

MAX_EXPERESSION_SIZE equ 100 ; 100 characters string is max
STACK_SIZE equ 256           ; 256 4-byte integers

ARR1_SIZE equ 7
ARR2_SIZE equ 5

section .data
    result_msg db "Result: "
    result_msg_len equ $ - result_msg

    arr1_msg db "Array 1: "
    arr1_msg_len equ $ - arr1_msg

    arr2_msg db "Array 2: "
    arr2_msg_len equ $ - arr2_msg

    common_msg db "Common elements: "
    common_msg_len equ $ - common_msg

    arr1_unique_msg db "Array 1 unique elements: "
    arr1_unique_msg_len equ $ - arr1_unique_msg

    arr2_unique_msg db "Array 2 unique elements: "
    arr2_unique_msg_len equ $ - arr2_unique_msg

    newline_ascii db 0xa                   ; newline character
    space_ascii db 0x20                    ; space character

    arr_1_values dq 56, 3, 6, 10, 7, 548, 800
    arr_2_values dq 35, 6, 19, 800, 7

section .bss
    ; reserve memory to store addresses of dynamically allocated memory blocks
    current_brk resq 1
    arr1_addr resq 1
    arr2_addr resq 1
    result_common_addr resq 1       ; common elemenets
    result_arr1_only_addr resq 1    ; elements unique for arr 1
    result_arr2_only_addr resq 1    ; elements unique for arr 2

    ; variables to track the size and status of memory blocks
    result_common_size resq 1
    result_arr1_only_size resq 1
    result_arr2_only_size resq 1

    itoa_result_buffer resb 20             ; buffer to store the number digits in string

section .text
    global _start

_start:
    mov rax, 0
    mov [current_brk], rax
    ; allocate arr1
    mov rbx, ARR1_SIZE * 8
    call alloc
    sub rax, rbx
    mov [arr1_addr], rax      ; move to the start of allocated block
    
    ; allocate arr2
    mov rbx, ARR2_SIZE * 8
    call alloc
    sub rax, rbx
    mov [arr2_addr], rax      ; move to the start of allocated block

    ; preallocate for common elements array (with the size of the smallest array)
    mov rbx, ARR2_SIZE * 8
    call alloc
    sub rax, rbx
    mov [result_common_addr], rax

    ; preallocate for unique elements in arr1
    mov rbx, ARR2_SIZE * 8
    call alloc
    sub rax, rbx
    mov [result_arr1_only_addr], rax

    ; preallocate for unique elements in arr1
    mov rbx, ARR2_SIZE * 8
    call alloc
    sub rax, rbx
    mov [result_arr2_only_addr], rax

    ; populate with numbers
    call populate_arr_1
    call populate_arr_2

    ; finc common elements
    call find_common

    ; unique elements of the arr1
    mov rcx, ARR1_SIZE              ; outer loop counter - smallest array size
    mov rsi, [arr1_addr]            ; pointer to the first arr
    mov rax, [result_arr1_only_addr]   ; pointer to common elements array
    mov rdi, [arr2_addr]        ; pointer to the second arr
    mov rbp, ARR2_SIZE          ; inner loop counter
    call find_unique
    mov [result_arr1_only_size], rdx

    ; unique elements of the arr2
    mov rcx, ARR2_SIZE              ; outer loop counter - smallest array size
    mov rsi, [arr2_addr]            ; pointer to the second arr
    mov rax, [result_arr2_only_addr]   ; pointer to common elements array
    mov rdi, [arr1_addr]        ; pointer to the first arr
    mov rbp, ARR1_SIZE          ; inner loop counter
    call find_unique
    mov [result_arr2_only_size], rdx

    ; ========== print results ==========
    ; array 1
    mov esi, arr1_msg
    mov edx, arr1_msg_len
    call print_string

    mov rbx, [arr1_addr]
    mov rax, ARR1_SIZE
    call print_array

    ; array 2
    mov esi, arr2_msg
    mov edx, arr2_msg_len
    call print_string

    mov rbx, [arr2_addr]
    mov rax, ARR2_SIZE
    call print_array

    ; common elements
    mov esi, common_msg
    mov edx, common_msg_len
    call print_string

    mov rbx, [result_common_addr]
    mov rax, [result_common_size]
    call print_array

    ; array 1 unique
    mov esi, arr1_unique_msg
    mov edx, arr1_unique_msg_len
    call print_string

    mov rbx, [result_arr1_only_addr]
    mov rax, [result_arr1_only_size]
    call print_array

    ; array 2 unique
    mov esi, arr2_unique_msg
    mov edx, arr2_unique_msg_len
    call print_string

    mov rbx, [result_arr2_only_addr]
    mov rax, [result_arr2_only_size]
    call print_array

    ; exit
    mov rax, SYS_EXIT                   ; sys_exit system call
    xor rdi, rdi                        ; exit status 0
    syscall

; ------------------ helpers --------------------
alloc:
    push rbx

    mov rax, SYS_BRK        ; sys_brk syscall
    mov rdi, 0  ; initial break point
    syscall

    mov rdi, rax            ; store the current break
    mov rsi, rbx            ; length of memory block
    mov rax, SYS_BRK        ; sys_brk syscall
    add rdi, rsi            ; new break point
    syscall

    mov [current_brk], rax
    pop rbx
ret

populate_arr_1:
    mov rcx, ARR1_SIZE
    mov rsi, arr_1_values
    mov rdi, [arr1_addr]
    .populate:
        mov rbx, [rsi]
        mov [rdi], rbx
        add rdi, 8
        add rsi, 8
        loop .populate
ret

populate_arr_2:
    mov rcx, ARR2_SIZE
    mov rsi, arr_2_values
    mov rdi, [arr2_addr]
    .populate:
        mov rbx, [rsi]
        mov [rdi], rbx
        add rdi, 8
        add rsi, 8
        loop .populate
ret

find_common:
    mov rcx, ARR2_SIZE              ; outer loop counter - smallest array size
    mov rsi, [arr2_addr]            ; pointer to the second arr
    mov rax, [result_common_addr]   ; pointer to common elements array
    mov rdx, 0                      ; amount of common elements
    .loop_arr2:
        cmp rcx, 0
        je .done
        mov rdi, [arr1_addr]        ; pointer to the first arr
        mov rbp, ARR1_SIZE          ; inner loop counter
        mov rbx, [rsi]              ; current check number from arr2
        add rsi, 8                  ; next element
        .loop_arr1:
            cmp rbp, 0
            je .next_number_iter

            cmp rbx, [rdi]
            je .found_common

            add rdi, 8              ; next element
            dec rbp
            jmp .loop_arr1

            .found_common:
                mov [rax], rbx
                add rax, 8
                inc rdx
            .next_number_iter:
                dec rcx
                jmp .loop_arr2      ; next number iteration
        jmp .loop_arr1
        dec rcx
    jmp .loop_arr2

    .done:
        mov [result_common_size], rdx
ret

find_unique:
    ; arguments:
    ; rcx - size of the array; counter of the outer loop
    ; rsi - pointer to the array
    ; rax - pointer to the result array
    ; rbp - size of the array for comparison; counter of the inner loop
    ; rdi - pointer to the array for comparison

    mov rdx, 0                      ; amount of common elements
    .loop_arr1:
        cmp rcx, 0
        je .done

        mov r8, rdi                 ; pointer to the second array
        mov r9, rbp                 ; inner loop counter
        mov rbx, [rsi]              ; current check number from the first array
        add rsi, 8                  ; next element
        .loop_arr2:
            cmp r9, 0
            je .found_unique

            cmp rbx, [r8]
            je .found_common
            add r8, 8               ; next element
            dec r9
            jmp .loop_arr2

            .found_common:
                dec rcx
                jmp .loop_arr1      ; next number iteration

        .found_unique:
            dec rcx
            mov [rax], rbx
            add rax, 8
            inc rdx
    jmp .loop_arr1

    .done:
ret

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

print_array:
    mov rcx, rax                        ; size of array for loop counter
    .loop_array:
        mov rax, [rbx]                  ; second number to rax
        call itoa
        call print_int

        ; print space
        mov rsi, space_ascii
        mov rdx, 1
        call print_string

        add rbx, 8                      ; move pointer to the next element
        loop .loop_array

    call print_newline
ret