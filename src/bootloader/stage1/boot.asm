org 0x7c00
bits 16

%define ENDL 0x0a, 0x0d

mov si, hello
call puts

jmp halt

puts:
    push si
    push ax
    push bx

.loop:
    lodsb
    or al, al
    jz .done

    mov ah, 0x0e
    mov bh, 0x00
    int 0x10
    jmp .loop

.done:
    pop bx
    pop ax
    pop si
    ret

halt:
    cli
    hlt

hello: db 'Hello, world!', ENDL, 0x00

times 510-($-$$) db 0
dw 0xaa55
