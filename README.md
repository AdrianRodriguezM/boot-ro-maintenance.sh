# Secure Boot Maintenance Script

Bash script for Linux systems where `/boot` is mounted read-only as part of a hardening strategy.

It temporarily remounts `/boot` as read-write only for the duration of required maintenance tasks (kernel, initramfs and bootloader updates) and restores the original mount state on exit, including in error conditions.

---

## Rationale

`/boot` contains critical boot artifacts:

- kernel images
- initramfs
- bootloader configuration

Keeping `/boot` mounted read-only by default reduces the risk of persistence and accidental modification.  
This script enables controlled maintenance without leaving the partition writable outside scheduled operations.

---

## Behavior

Execution flow:

1. Verify root privileges
2. Detect current mount mode of `/boot`
3. Remount as RW only if required
4. Run maintenance tasks:
   - `apt-get update && apt-get upgrade`
   - `update-initramfs`
   - bootloader regeneration
5. Flush buffers (`sync`)
6. Restore original mount mode using `trap` cleanup logic

---

## Requirements

- Bash
- `findmnt`
- Debian/Ubuntu-based systems

Must be executed as root.

---

## Installation

```bash
sudo install -m 700 secure-boot-maintenance.sh /usr/local/sbin/secure-boot-maintenance
