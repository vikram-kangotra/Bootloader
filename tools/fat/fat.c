#include <stddef.h>
#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

typedef struct {
    uint8_t boot_jmp[3];
    uint8_t oem_identifier[8];
    uint16_t bytes_per_sector;
    uint8_t sectors_per_cluster;
    uint16_t reserved_sectors;
    uint8_t number_of_fats;
    uint16_t root_entries;
    uint16_t total_sectors;
    uint8_t media_descriptor;
    uint16_t sectors_per_fat;
    uint16_t sectors_per_track;
    uint16_t number_of_heads;
    uint32_t hidden_sectors;
    uint32_t large_sectors;

    uint8_t drive_number;
    uint8_t reserved;
    uint8_t boot_signature;
    uint32_t volume_id;
    uint8_t volume_label[11];
    uint8_t file_system_type[8];
} __attribute__((packed)) BootSector;

typedef struct {
    uint8_t name[11];
    uint8_t attributes;
    uint8_t reserved;
    uint8_t creation_time_tenths;
    uint16_t creation_time;
    uint16_t creation_date;
    uint16_t last_access_date;
    uint16_t first_cluster_high;
    uint16_t last_modification_time;
    uint16_t last_modification_date;
    uint16_t first_cluster_low;
    uint32_t size;
} __attribute__((packed)) DirectoryEntry;

uint32_t g_root_directory_end;

bool read_boot_sector(FILE* disk, BootSector* boot_sector) {
    return fread(boot_sector, sizeof(BootSector), 1, disk) > 0;
}

bool read_sectors(FILE* disk, uint32_t lba, uint32_t count, void* buffer, BootSector* boot_sector) {
    bool ok =true;
    ok = ok && (fseek(disk, lba * boot_sector->bytes_per_sector, SEEK_SET) == 0); 
    ok = ok && (fread(buffer, boot_sector->bytes_per_sector, count, disk) == count);
    return ok;
}

uint8_t* read_fat(FILE* disk, BootSector* boot_sector) {
    uint8_t* fat = (uint8_t*) malloc(boot_sector->sectors_per_fat * boot_sector->bytes_per_sector);
    if (!read_sectors(disk, boot_sector->reserved_sectors, boot_sector->sectors_per_fat, fat, boot_sector)) {
        free(fat);
        return NULL;
    }
    return fat;
}

DirectoryEntry* read_root_directory(FILE* disk, BootSector* boot_sector) {
    uint32_t lba = boot_sector->reserved_sectors + boot_sector->sectors_per_fat * boot_sector->number_of_fats;
    uint32_t size = sizeof(DirectoryEntry) * boot_sector->root_entries;
    uint32_t sectors = (size + boot_sector->bytes_per_sector - 1) / boot_sector->bytes_per_sector;
    g_root_directory_end = lba + sectors;

    DirectoryEntry* root_directory = (DirectoryEntry*) malloc(sectors * boot_sector->bytes_per_sector);
    if (!read_sectors(disk, lba, sectors, root_directory, boot_sector)) {
        free(root_directory);
        return NULL;
    }
    return root_directory;
}

DirectoryEntry* find_file(BootSector* boot_sector, DirectoryEntry* root_directory, const char* name) {
    for (uint32_t i = 0; i < boot_sector->root_entries; ++i) {
        if (memcmp(root_directory[i].name, name, 11) == 0) {
            return &root_directory[i];
        }
    }
    return NULL;
}

bool read_file(DirectoryEntry* file_entry, FILE* disk, uint8_t* buffer, BootSector* boot_sector, uint8_t* fat) {
    bool ok = true;
    uint16_t current_cluster = file_entry->first_cluster_low;

    do {
        uint32_t lba = g_root_directory_end + (current_cluster - 2) * boot_sector->sectors_per_cluster;
        ok = ok && read_sectors(disk, lba, boot_sector->sectors_per_cluster, buffer, boot_sector);
        buffer += boot_sector->sectors_per_cluster * boot_sector->bytes_per_sector;
        uint32_t fatIndex = current_cluster * 3 / 2;
        if (current_cluster % 2 == 0) {
            current_cluster = (*(uint16_t*)(fat + fatIndex)) & 0x0FFF;
        } else {
            current_cluster = (*(uint16_t*)(fat + fatIndex)) >> 4;
        }
    } while (ok && current_cluster < 0x0FF8);

    return ok;
}

int main(int argc, char** argv) {
    if (argc < 3) {
        printf("Syntax: %s <disk image> <file name>\n", argv[0]);
        return -1;
    }

    FILE* disk = fopen(argv[1], "rb");
    if (!disk) {
        printf("Failed to open disk image %s!\n", argv[1]);
        return -1;
    }

    BootSector boot_sector;

    if (!read_boot_sector(disk, &boot_sector)) {
        printf("Failed to read boot sector!\n");
        return -1;
    }

    uint8_t* fat = read_fat(disk, &boot_sector);
    if (!fat) {
        printf("Failed to read FAT!\n");
        return -3;
    }

    DirectoryEntry* root_directory = read_root_directory(disk, &boot_sector);
    if (!root_directory) {
        printf("Failed to read root directory!\n");
        free(fat);
        return -4;
    }

    DirectoryEntry* file = find_file(&boot_sector, root_directory, argv[2]);
    if (!file) {
        printf("File %s not found!\n", argv[2]);
        free(fat);
        free(root_directory);
        return -5;
    }

    uint8_t* buffer = (uint8_t*) malloc(file->size * boot_sector.bytes_per_sector);
    if (!read_file(file, disk, buffer, &boot_sector, fat)) {
        printf("Failed to read file!\n");
        free(fat);
        free(root_directory);
        free(buffer);
        return -6;
    }
    
    for (size_t i = 0; i < file->size; ++i) {
        if (isprint(buffer[i])) {
            fputc(buffer[i], stdout);
        } else {
            printf("<%02x>", buffer[i]);
        }
    }
    printf("\n");

    free(fat);
    free(root_directory);
    free(buffer);

    return 0;
}
