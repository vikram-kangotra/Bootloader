org 0x7c00
bits 16

%define ENDL 0x0a, 0x0d

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

    mov [ebpb_physical_drive_number], dl

    mov ax, 1
    mov cl, 1
    mov bx, buffer
    call disk_read

    mov si, hello
    call puts

jmp halt

%include "utility.asm"
%include "disk.asm"

hello: db 'Hello, world!', ENDL, 0x00

times 510-($-$$) db 0
dw 0xaa55

buffer:
