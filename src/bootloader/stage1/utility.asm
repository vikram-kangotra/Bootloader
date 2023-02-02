wait_key_and_reboot:
    mov ah, 0
    int 16h
    jmp 0xffff:0x0000

halt:
    cli
    hlt

;
; Prints a string to the screen
; Params:
;  ds:si - string to print
;

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

;
; Converts an LBA address to a CHS address
; LBS = Logical Block Address
; CHS = Cylinder, Head, Sector
; Params:
;   - ax - LBA address
; Returns:
;   - cx [bits 0-5] - sector
;   - cx [bits 6-15] - cylinder
;   - dh - head
;

lba_to_chs:
    push ax
    push dx

    xor dx, dx
    div word [bpb_sectors_per_track]      ; ax = lba / sectors_per_track
                                          ; dx = lba % sectors_per_track
    inc dx                                ; sector = (lba % sectors_per_track) + 1 = sector
    mov cx, dx

    xor dx, dx
    div word [bpb_number_of_heads]                  ; ax = (lba / sectors_per_track) / heads = cylinder
                                          ; dx = (lba % (sectors_per_track) % heads = head
    mov dh, dl
    mov ch, al                            ; ch = cylinder (lowe 8 bits)
    shl ah, 6
    or cl, ah                             ; cl = cylinder (higher 2 bits) + sector (lower 6 bits)

    pop ax
    mov dl, al
    pop ax

    ret
