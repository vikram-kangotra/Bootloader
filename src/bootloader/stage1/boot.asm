org 0x7c00
bits 16

; FAT12 header

jmp short start
nop

bpb_oem:                        db "MSWIN4.1"               ; Just because Microsoft recommends it
bpb_bytes_per_sector:           dw 512                      ; 512 bytes per sector
bpb_sectors_per_cluster:        db 1                        ; 1 sector per cluster
bpb_reserved_sectors:           dw 1                        ; 1 reserved sector
bpb_number_of_fats:             db 2                        ; 2 FATs
bpb_root_dir_entries:           dw 0xE0                     ; 224 root directory entries
bpb_total_sectors:              dw 0x0b40                   ; 2880 sectors
bpb_media_descriptor:           db 0xf0                     ; 3.5" 1.44MB floppy
bpb_sectors_per_fat:            dw 0x09                     ; 9 sectors per FAT
bpb_sectors_per_track:          dw 0x12                     ; 18 sectors per track
bpb_number_of_heads:            dw 0x02                     ; 2 heads
bpb_hidden_sectors:             dd 0                        ; 0 hidden sectors
bpb_large_sector_count:         dd 0                        ; 0 large sector count

; extended BIOS parameter block

ebpb_physical_drive_number:     db 0x00                     ; physical drive number
ebpb_current_head:              db 0x00                     ; current head
ebpb_extended_boot_signature:   db 0x29                     ; extended boot signature
ebpb_volume_id:                 dd 0x12345678               ; volume ID
ebpb_volume_label:              db "MIOSIS     "            ; volume label
ebpb_file_system_type:          db "FAT12   "               ; file system type

start:
    mov ax, 0
    mov ds, ax
    mov es, ax

    mov ss, ax
    mov sp, 0x7c00

    ; BIOS might start us at 7c00:0000 instead of 0000:7c00
    push es
    push word .after
    retf
.after:

    mov [ebpb_physical_drive_number], dl

    push es
    mov ah, 0x08
    int 0x13
    jc disk_error
    pop es

    and cl, 0x3f            ; remove top 2 bits
    xor ch, ch
    mov [bpb_sectors_per_track], cx

    inc dh
    mov [bpb_number_of_heads], dh

    ; compute LBA of root directory = reserved + fats * sectors_per_fat
    mov ax, [bpb_sectors_per_fat]
    mov bl, [bpb_number_of_fats]
    xor bh, bh
    mul bx,
    add ax, [bpb_reserved_sectors]
    push ax

    ; compute size of root directory = (32 * root_entries) / bytes_per_sector
    mov ax, [bpb_root_dir_entries]
    shl ax, 5
    xor dx, dx
    div word [bpb_bytes_per_sector]

    test dx, dx
    jz .root_dir_after
    inc ax

.root_dir_after:
    
    mov cl, al
    pop ax
    mov dl, [ebpb_physical_drive_number]
    mov bx, buffer
    call disk_read

    xor bx, bx
    mov di, buffer

.search_kernel:
    mov si, file_kernel_bin
    mov cx, 11
    push di

    repe cmpsb                      ; repe: repeats a string instruction
                                    ;   while the operands are equal or cx
                                    ;   reaches 0
                                    ; cmpsb: compares two bytes at si and di
    pop di
    je .found_kernel

    add di, 32
    inc bx
    cmp bx, [bpb_root_dir_entries]
    jl .search_kernel

    jmp kernel_not_found_error

.found_kernel:
    ; di should have the address to the entry
    mov ax, [di + 26]
    mov [kernel_cluster], ax

    ; load FAT from disk into memory
    mov ax, [bpb_reserved_sectors]
    mov bx, buffer
    mov cl, [bpb_sectors_per_fat]
    mov dl, [ebpb_physical_drive_number]
    call disk_read

    ; read kernel and process FAT chain
    mov bx, KERNEL_LOAD_SEGMENT
    mov es, bx
    mov bx, KERNEL_LOAD_OFFSET

.load_kernel_loop:
    ; read next cluster
    mov ax, [kernel_cluster]
    add ax, 31                      ; first cluster = (kernel_cluster - 2) * sectors_per_cluster + start_sector
                                    ; start_sector = reserved + fats + root directory size = 1 + 18 + 14 = 33
    mov cl, 1
    mov dl, [ebpb_physical_drive_number]
    call disk_read

    add bx, [bpb_bytes_per_sector]

    ; compute location of next cluster
    mov ax, [kernel_cluster]
    mov cx, 3
    mul cx
    mov cx, 2
    div cx

    mov si, buffer
    add si, ax
    mov ax, [ds:si]

    or dx, dx
    jz .even

.odd:
    shr ax, 4
    jmp .next_cluster_after

.even:
    and ax, 0x0fff

.next_cluster_after:
    cmp ax, 0x0ff8
    jae .read_finish

    mov [kernel_cluster], ax
    jmp .load_kernel_loop

.read_finish:
    mov dl, [ebpb_physical_drive_number]
    mov ax, KERNEL_LOAD_SEGMENT
    mov ds, ax
    mov es, ax

    jmp KERNEL_LOAD_SEGMENT:KERNEL_LOAD_OFFSET

    jmp wait_key_and_reboot

kernel_not_found_error:
    mov si, msg_kernel_not_found
    call puts
    jmp wait_key_and_reboot

%include "utility.asm"
%include "disk.asm"
%include "constants.asm"

kernel_cluster: dw 0

KERNEL_LOAD_SEGMENT     equ 0x2000
KERNEL_LOAD_OFFSET      equ 0

times 510-($-$$) db 0
dw 0xaa55

buffer:
