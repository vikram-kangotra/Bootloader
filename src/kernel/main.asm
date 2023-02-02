mov si, hello
call puts

cli
hlt

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

hello: db "Hello World from Kernel", 0x0a, 0x0d, 0
