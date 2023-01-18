halt:
    cli
    hlt

;
; Print a string to the screen
; Params:
;   ds:si - points to string

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


