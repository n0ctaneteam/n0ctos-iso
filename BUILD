#!/usr/bin/env bash
# ─────────────────────────────────────────────
#  build-archiso.sh — N0CTOS Archiso Builder
#  UWSM/Hyprland — notify-send + QEMU launch
# ─────────────────────────────────────────────

set -euo pipefail

# ── Paths ────────────────────────────────────
PROFILE_DIR="./"
WORK_DIR="./work"
OUT_DIR="./out"

# ── QEMU Config Array ────────────────────────
QEMU_FLAGS=(
    -enable-kvm
    -machine  type=q35,accel=kvm
    -cpu      host
    -m        2G
    -smp      2
    -vga      virtio
    -display  sdl,gl=on
    -boot     d
    -cdrom    ""                          # filled at runtime
    -netdev   user,id=net0
    -device   virtio-net-pci,netdev=net0
    -audiodev pipewire,id=audio0
    -device   ich9-intel-hda
    -device   hda-output,audiodev=audio0
)

# ── Helpers ──────────────────────────────────
notify() {
    local urgency="${1}"; local summary="${2}"; local body="${3}"
    notify-send \
        --urgency="${urgency}" \
        --icon=system-run \
        --app-name="N0CTOS Builder" \
        "${summary}" "${body}"
}

print_banner() {
  clear
    echo ""
    echo "  ███╗   ██╗ ██████╗  ██████╗████████╗ ██████╗ ███████╗"
    echo "  ████╗  ██║██╔═══██╗██╔════╝╚══██╔══╝██╔═══██╗██╔════╝"
    echo "  ██╔██╗ ██║██║   ██║██║        ██║   ██║   ██║███████╗"
    echo "  ██║╚██╗██║██║   ██║██║        ██║   ██║   ██║╚════██║"
    echo "  ██║ ╚████║╚██████╔╝╚██████╗   ██║   ╚██████╔╝███████║"
    echo "  ╚═╝  ╚═══╝ ╚═════╝  ╚═════╝   ╚═╝    ╚═════╝ ╚══════╝"
    echo "            Archiso Builder — UWSM/Hyprland"
    echo ""
}

# ── Step 1: Cache sudo password ───────────────
cache_sudo() {
    echo "🔐 Enter your sudo password to cache it for the build:"
    # -S reads from stdin, -v validates/refreshes timestamp
    sudo -v
    # Keep sudo alive in background for the duration of the script
    ( while true; do sudo -n true; sleep 50; done ) &
    SUDO_KEEPER_PID=$!
    trap 'kill "${SUDO_KEEPER_PID}" 2>/dev/null' EXIT
    echo "✔  Sudo cached — keeper PID: ${SUDO_KEEPER_PID}"
    echo ""
}

# ── Step 2: Clean old work dir ────────────────
clean_workdir() {
    if [[ -d "${WORK_DIR}" ]]; then
        echo "🧹 Cleaning stale work directory..."
        sudo rm -rf ${WORK_DIR}"
    fi
    mkdir -p "${WORK_DIR}" "${OUT_DIR}"
}

# ── Step 3: Build ─────────────────────────────
build_iso() {
    notify "normal" "N0CTOS Build Started" \
        "Building Arch ISO from releng profile…"

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  🚀 Build started at $(date '+%H:%M:%S')"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    sudo mkarchiso -v \
        -w "${WORK_DIR}" \
        -o "${OUT_DIR}" \
        "${PROFILE_DIR}"
}

# ── Step 4: Locate the built ISO ──────────────
find_iso() {
    ISO_PATH="$(ls -t "${OUT_DIR}"/*.iso 2>/dev/null | head -n1)"
    if [[ -z "${ISO_PATH}" ]]; then
        echo "❌  No ISO found in ${OUT_DIR}"
        notify "critical" "N0CTOS Build Failed" "No ISO was produced. Check the build log."
        exit 1
    fi
    echo "📀 ISO ready: ${ISO_PATH}"
}

# ── Step 5: Ask for QEMU ─────────────────────
ask_qemu() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  🖥  Launch ISO in QEMU VM?"
    echo "  Press [y] Yes  /  [n] No"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Notification with actions (requires a notification daemon that supports actions)
    notify "normal" "N0CTOS — Launch QEMU?" \
        "ISO built: $(basename "${ISO_PATH}")\nRun QEMU VM? Answer in terminal."

    read -rp "  → Your choice [y/N]: " QEMU_CHOICE
    echo ""
}

# ── Step 6: Launch QEMU ───────────────────────
launch_qemu() {
    # Inject the real ISO path into the flags array
    # Find the -cdrom flag and set the next element
    for i in "${!QEMU_FLAGS[@]}"; do
        if [[ "${QEMU_FLAGS[$i]}" == "" ]]; then
            QEMU_FLAGS[$i]="${ISO_PATH}"
            break
        fi
    done

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  🖥  Launching QEMU with flags:"
    printf '     %s\n' "${QEMU_FLAGS[@]}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    notify "low" "N0CTOS — QEMU Starting" \
        "Launching VM with $(basename "${ISO_PATH}")"

    qemu-system-x86_64 "${QEMU_FLAGS[@]}"
}

# ─────────────────────────────────────────────
#  MAIN
# ─────────────────────────────────────────────
print_banner
cache_sudo
clean_workdir
build_iso
find_iso

# Build success notification
notify "normal" "✅ N0CTOS Build Complete" \
    "ISO ready: $(basename "${ISO_PATH}")"
echo ""
echo "  ✅ Build finished at $(date '+%H:%M:%S')"
echo "  📀 Output: ${ISO_PATH}"
echo ""

ask_qemu

case "${QEMU_CHOICE,,}" in
    y|yes)
        launch_qemu
        ;;
    *)
        echo "  Skipping QEMU. ISO is at:"
        echo "  ${ISO_PATH}"
        notify "low" "N0CTOS — Done" "QEMU skipped. ISO at: ${ISO_PATH}"
        ;;
esac