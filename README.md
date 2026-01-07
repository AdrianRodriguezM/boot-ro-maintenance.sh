# BOOT-RO-MAINTENANCE.SH

Root-level maintenance script for hardened Linux systems where `/boot` is mounted read-only by default.

The script temporarily remounts `/boot` as read-write only for the duration of required maintenance tasks (kernel, initramfs and bootloader updates) and restores the original mount state on exit, including in error conditions.

---

## Purpose

On hardened systems, `/boot` contains critical boot components:

- kernel images
- initramfs
- bootloader configuration

Keeping `/boot` mounted read-only reduces persistence risks and prevents accidental modification.  
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
   - bootloader regeneration (GRUB / systemd-boot hooks)
5. Flush disk buffers (`sync`)
6. Restore original mount mode using `trap` cleanup logic

The script guarantees that `/boot` is not left writable after execution.

---

## Requirements

- Bash
- `findmnt`
- Debian/Ubuntu-based systems

Must be executed as root.

---

## Installation

```bash
sudo install -m 700 boot-ro-maintenance.sh /usr/local/sbin/boot-ro-maintenance
