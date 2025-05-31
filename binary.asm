section .data
    prompt_msg db 'Enter a number: ', 0
    prompt_len equ $ - prompt_msg
    newline    db 10, '', 0
    binary_msg db 'Binary form: ', 0

section .bss
    input_buffer resb 12
    binary_output resb 33

section .text
    global _start

_start:
main_loop:
    ; Display prompt
    mov eax, 4          ; sys_write
    mov ebx, 1          ; stdout
    mov ecx, prompt_msg
    mov edx, prompt_len
    int 0x80

    ; Read input string and handle newline
    mov eax, 3          ; sys_read
    mov ebx, 0          ; stdin
    mov ecx, input_buffer
    mov edx, 11
    int 0x80

    ; Explicitly null-terminate at newline or end of buffer
    mov ecx, eax        ; Number of bytes read
    mov edi, input_buffer
check_bytes:
    cmp ecx, 0
    je null_terminate_end
    cmp byte [edi], 10  ; Check for newline
    je terminate_at_newline
    inc edi
    dec ecx
    jmp check_bytes

terminate_at_newline:
    mov byte [edi], 0
    jmp check_exit

null_terminate_end:
    cmp eax, 0
    je check_exit
    mov byte [input_buffer + eax - 1], 0

check_exit:
    ; Check for exit ('0') at the beginning of the buffer
    cmp byte [input_buffer], '0'
    je exit_program

    ; --- Decimal to Binary Conversion ---
    mov esi, input_buffer
    mov ebx, 0          ; Binary result
    mov ecx, 0          ; Negative flag

    ; Check sign
    cmp byte [esi], '-'
    jne check_plus_convert
    inc ecx
    inc esi
    jmp convert_digit

check_plus_convert:
    cmp byte [esi], '+'
    jne convert_digit
    inc esi

convert_digit:
    movzx eax, byte [esi]
    cmp al, '0'
    jl conversion_done
    cmp al, '9'
    jg conversion_done
    sub al, '0'         ; Convert ASCII to number

    push eax            ; Save the digit's value
    mov eax, ebx
    mov edx, 10
    mul edx             ; EAX = EBX * 10
    mov ebx, eax
    pop eax             ; Restore the digit
    add ebx, eax        ; EBX = (old EBX * 10) + current digit

    inc esi
    jmp convert_digit

conversion_done:
    cmp ecx, 1
    jne convert_to_binary
    neg ebx

convert_to_binary:
    mov edi, binary_output + 32
    mov byte [edi], 0

    mov ecx, 32
binary_conversion_loop:
    dec edi
    mov eax, ebx
    and eax, 1
    add al, '0'
    mov [edi], al
    shr ebx, 1
    loop binary_conversion_loop

    ; --- Display Binary Output ---
    mov eax, 4
    mov ebx, 1
    mov ecx, binary_msg
    mov edx, 13
    int 0x80

    mov eax, 4
    mov ebx, 1
    mov ecx, binary_output
    mov edx, 32
    int 0x80

    ; Display newline
    mov eax, 4
    mov ebx, 1
    mov ecx, newline
    mov edx, 1
    int 0x80

    jmp main_loop

exit_program:
    mov eax, 1
    xor ebx, ebx
    int 0x80