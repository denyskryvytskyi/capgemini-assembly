SYS_EXIT equ 1
SYS_READ equ 3
SYS_WRITE equ 4
STDIN equ 0
STDOUT equ 1

%define SYSCALL 0x80

section .data
    numA dd 153
    numB dd 30
    numC dd 740
    newline db 10           ; Newline character

section .bss
    result_buffer resb 20   ; Buffer to store the digits

section .text
    global _start

_start:
    mov eax, [numA]
    cmp eax, [numB]         ; compare first and second numbers
    jg check_third_number   ; if first number is greater then second - jump
    mov eax, [numB]

; compare check between 1st and 2nd number with 3rd number
check_third_number:
    cmp eax, [numC]
    jg convert_to_string    ; jump if greater then 3rd number
    mov eax, [numC]

; convert number to string
convert_to_string:
    mov edi, result_buffer  ; Point rdi to the end of the buffer
    add edi, 19             ; (we'll fill it from right to left)
    mov ecx, 10             ; Divisor for extracting digits
.convert_loop:
    xor edx, edx       ; Clear rdx for division
    div ecx            ; Divide rax by 10, remainder in rdx
    add dl, '0'        ; Convert remainder to ASCII
    dec edi            ; Move buffer pointer left
    mov [edi], dl      ; Store the digit
    test eax, eax      ; Check if quotient is zero
    jnz .convert_loop  ; If not, continue loop

    ; Calculate string length
    mov eax, result_buffer
    add eax, 20
    sub eax, edi       ; eax now holds the string length

    ; Print the number
    mov edx, eax       ; Length of the string to print
    mov esi, edi
    mov edi, STDOUT
    mov eax, SYS_EXIT
    syscall

    ; Print newline
    mov eax, SYS_EXIT
    mov edi, STDOUT
    mov esi, newline   ; Address of newline character
    mov edx, 1         ; Length of 1 byte
    syscall

    ; Exit program
    mov eax, 60        ; sys_exit system call
    xor edi, edi       ; Exit status 0
    syscall