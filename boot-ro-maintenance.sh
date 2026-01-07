#!/usr/bin/env bash
# secure-boot-maintenance.sh
# Safely remounts /boot as RW only for maintenance operations and restores original state

set -Eeuo pipefail

BOOT_MOUNT="/boot"
LOG_TAG="secure-boot-maint"

log() {
    logger -t "$LOG_TAG" "$*"
    echo "[*] $*"
}

die() {
    log "ERROR: $*"
    exit 1
}

require_root() {
    if [[ $EUID -ne 0 ]]; then
        die "This script must be run as root"
    fi
}

get_mount_opts() {
    findmnt -no OPTIONS --target "$BOOT_MOUNT" || return 1
}

is_boot_ro() {
    get_mount_opts | grep -qw ro
}

remount_boot_rw() {
    log "Remounting $BOOT_MOUNT as read-write"
    mount -o remount,rw "$BOOT_MOUNT" || die "Failed to remount $BOOT_MOUNT as RW"
}

remount_boot_ro() {
    log "Restoring $BOOT_MOUNT to read-only"
    mount -o remount,ro "$BOOT_MOUNT" || die "Failed to remount $BOOT_MOUNT as RO"
}

run_maintenance() {
    log "Running system maintenance tasks"

    if command -v apt-get >/dev/null 2>&1; then
        apt-get update
        apt-get -y upgrade
    fi

    if command -v update-initramfs >/dev/null 2>&1; then
        update-initramfs -u -k all
    fi

    if command -v update-grub >/dev/null 2>&1; then
        update-grub
    fi

    log "Maintenance tasks completed"
}

cleanup() {
    if [[ "$ORIGINAL_BOOT_STATE" == "ro" ]]; then
        remount_boot_ro || log "WARNING: Failed to restore /boot to RO"
    fi
}

main() {
    require_root

    if ! mountpoint -q "$BOOT_MOUNT"; then
        die "$BOOT_MOUNT is not a mount point"
    fi

    if is_boot_ro; then
        ORIGINAL_BOOT_STATE="ro"
        log "$BOOT_MOUNT is currently read-only"
        remount_boot_rw
    else
        ORIGINAL_BOOT_STATE="rw"
        log "$BOOT_MOUNT is already read-write"
    fi

    trap cleanup EXIT

    run_maintenance

    sync
    log "Disk buffers flushed"
}

main "$@"
