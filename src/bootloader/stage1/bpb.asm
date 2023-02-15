bpb_oem_name:               db "MSWIN4.1"
bpb_bytes_per_sector:       dw 512
bpb_sectors_per_cluster:    db 1
bpb_reserved_sectors:       dw 1
bpb_number_of_fats:         db 2
bpb_root_dir_entries:       dw 224
bpb_total_sectors:          dw 2880
bpb_media_descriptor:       db 0xf0
bpb_sectors_per_fat:        dw 9
bpb_sectors_per_track:      dw 18
bpb_number_of_heads:        dw 2
bpb_hidden_sectors:         dd 0
bpb_large_sectors:          dd 0

ebpb_drive_number:          db 0
ebpb_reserved:              db 0
ebpb_signature:             db 0x29
ebpb_serial_number:         dd 0x12345678
ebpb_volume_label:          db "MIOSIS     "
ebpb_file_system_type:      db "FAT12   "
