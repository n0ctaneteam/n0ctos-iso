#!/bin/bash
# =====================================================
# N0ctOS — welcome.sh
# pure bash + tput + toilet (pagga font)
# nav: arrow keys, vim j/k, number keys
# =====================================================

# ── colors ────────────────────────────────────────────
RESET="\e[0m"
BOLD="\e[1m"
DIM="\e[2m"

CYAN="\e[38;2;0;190;200m"
PURPLE="\e[38;2;180;0;255m"
BLUE="\e[38;2;30;120;255m"
BLUE_DIM="\e[38;2;20;60;120m"
WHITE="\e[38;2;220;230;255m"
GRAY="\e[38;2;160;180;200m"
SEL_FG="\e[38;2;0;220;220m"
SEL_BG="\e[48;2;10;10;40m"

# ── helpers ────────────────────────────────────────────

# center a plain string (no ansi codes)
print_centered() {
    local str="$1"
    local color="$2"
    local cols
    cols=$(tput cols)
    local len=${#str}
    local pad=$(( (cols - len) / 2 ))
    printf "%${pad}s"
    echo -en "${color}${str}${RESET}"
}

# center a line that may contain ansi/unicode (toilet output)
print_art_line_centered() {
    local line="$1"
    local cols
    cols=$(tput cols)
    # strip ansi escapes and non-printable chars to measure visible length
    local visible
    visible=$(printf '%s' "$line" \
        | sed 's/\x1b\[[0-9;]*m//g' \
        | sed 's/[^[:print:]]//g')
    local len=${#visible}
    local pad=$(( (cols - len) / 2 ))
    (( pad < 0 )) && pad=0
    printf "%${pad}s"
    echo -e "$line"
}

# ── terminal setup ─────────────────────────────────────
setup_term() {
    tput civis          # hide cursor
    tput clear
    tput rmam           # disable line wrap
    stty -echo          # hide keypresses
}

teardown_term() {
    tput cnorm          # restore cursor
    tput smam           # re-enable line wrap
    stty echo
    tput clear
}

# ── draw header ────────────────────────────────────────
# sets global MENU_START_ROW
MENU_START_ROW=3

draw_header() {
    local row=2

    # generate ascii art with pagga font
    local art
    art=$(toilet -f ansi-shadow "N0ctOS" 2>/dev/null \
          || toilet -f pagga "N0ctOS" 2>/dev/null \
          || echo "  N0ctOS")

    # print each line of art centered in cyan
    echo -en "${CYAN}"
    while IFS= read -r line; do
        # skip blank lines
        [[ -z "${line// }" ]] && { ((row++)); continue; }
        tput cup $row 0
        print_art_line_centered "$line"
        ((row++))
    done <<< "$art"
    echo -en "${RESET}"

    ((row++))

    # h2 — subtitle
    tput cup $row 0
    print_centered "Welcome to N0ctOS Installer !!" "${PURPLE}${BOLD}"
    echo ""
    ((row++))

    # h3 — tagline
    tput cup $row 0
    print_centered "[ minimal · fast · yours ]" "${BLUE}${DIM}"
    echo ""
    ((row += 2))

    # divider
    local cols
    cols=$(tput cols)
    tput cup $row 2
    echo -en "${BLUE_DIM}"
    printf '─%.0s' $(seq 1 $((cols - 4)))
    echo -en "${RESET}"
    ((row += 2))

    MENU_START_ROW=$row
}

# ── menu items ─────────────────────────────────────────
MENU_LABELS=(
    "Install N0ctOS"
    "WiFi Setup"
    "Open Terminal"
    "Keybindings"
    "System Info"
    "Reboot"
    "Shutdown"
)

MENU_DESCS=(
    "launch calamares installer"
    "connect to a network"
    "drop into a zsh shell"
    "show dwm key reference"
    "hardware overview"
    "restart the machine"
    "power off"
)

# ── draw menu ──────────────────────────────────────────
draw_menu() {
    local selected=$1
    local total=${#MENU_LABELS[@]}
    local cols
    cols=$(tput cols)
    local left=8

    for ((i=0; i<total; i++)); do
        local row=$(( MENU_START_ROW + i * 2 ))

        # clear the line
        tput cup $row 0
        printf "%${cols}s"

        tput cup $row $left

        if [[ $i -eq $selected ]]; then
            # pointer arrow
            tput cup $row $((left - 3))
            echo -en "${CYAN}${BOLD}▶ ${RESET}"
            tput cup $row $left
            echo -en "${SEL_BG}${SEL_FG}${BOLD} $((i+1)). ${MENU_LABELS[$i]} ${RESET}"
            echo -en "  ${GRAY}${DIM}${MENU_DESCS[$i]}${RESET}"
        else
            echo -en "  ${BLUE}$((i+1)).${RESET} ${WHITE}${MENU_LABELS[$i]}${RESET}"
            echo -en "  ${GRAY}${DIM}${MENU_DESCS[$i]}${RESET}"
        fi
    done

    # nav hint row
    local hint="[ ↑↓ / j k / 1-6 ]  navigate    [ Enter ]  select    [ q ]  quit"
    local hintrow=$(( MENU_START_ROW + total * 2 + 1 ))
    tput cup $hintrow 0
    printf "%${cols}s"
    tput cup $hintrow 0
    echo -en "${GRAY}${DIM}"
    print_centered "$hint" "${RESET}${CYAN}"
    echo -en "${RESET}"
}

# ── system info ────────────────────────────────────────
sysinfo() {
    teardown_term
    tput clear
    echo ""
    echo -e "${CYAN}${BOLD}  System Info${RESET}\n"
    echo -e "  ${BLUE}CPU   :${RESET} ${WHITE}$(grep 'model name' /proc/cpuinfo \
        | head -1 | cut -d: -f2 | xargs)${RESET}"
    echo -e "  ${BLUE}RAM   :${RESET} ${WHITE}$(free -h | awk '/Mem/{print $2}') total / \
$(free -h | awk '/Mem/{print $7}') available${RESET}"
    echo -e "  ${BLUE}Disk  :${RESET} ${WHITE}$(df -h / | awk 'NR==2{print $4}') free on /${RESET}"
    echo -e "  ${BLUE}Kernel:${RESET} ${WHITE}$(uname -r)${RESET}"
    echo -e "  ${BLUE}Arch  :${RESET} ${WHITE}$(uname -m)${RESET}"
    echo ""
    echo -en "${GRAY}${DIM}  press any key to return...${RESET}"
    read -rn1
    main
}

# ── dwm keybindings ────────────────────────────────────
dwm_keys() {
    teardown_term
    tput clear
    echo ""
    echo -e "${CYAN}${BOLD}  DWM Keybindings${RESET}\n"

    echo -e "  ${PURPLE}${BOLD}LAUNCHERS${RESET}"
    echo -e "  ${BLUE}Super + Return    ${RESET}${WHITE}terminal${RESET}"
    echo -e "  ${BLUE}Super + d         ${RESET}${WHITE}dmenu${RESET}"
    echo -e "  ${BLUE}Super + w         ${RESET}${WHITE}welcome TUI${RESET}"
    echo -e "  ${BLUE}Super + i         ${RESET}${WHITE}calamares${RESET}"
    echo ""
    echo -e "  ${PURPLE}${BOLD}FOCUS${RESET}"
    echo -e "  ${BLUE}Super + j/k / ↑↓ ${RESET}${WHITE}focus next / prev window${RESET}"
    echo ""
    echo -e "  ${PURPLE}${BOLD}MASTER${RESET}"
    echo -e "  ${BLUE}Super + h/l / ←→ ${RESET}${WHITE}shrink / grow master${RESET}"
    echo -e "  ${BLUE}Super + = / -     ${RESET}${WHITE}add / remove from master${RESET}"
    echo -e "  ${BLUE}Super + Shift+Ret ${RESET}${WHITE}swap focused to master${RESET}"
    echo ""
    echo -e "  ${PURPLE}${BOLD}LAYOUTS${RESET}"
    echo -e "  ${BLUE}Super + t         ${RESET}${WHITE}tiling${RESET}"
    echo -e "  ${BLUE}Super + m         ${RESET}${WHITE}monocle${RESET}"
    echo -e "  ${BLUE}Super + f         ${RESET}${WHITE}floating${RESET}"
    echo -e "  ${BLUE}Super + Shift+Spc ${RESET}${WHITE}toggle float focused${RESET}"
    echo ""
    echo -e "  ${PURPLE}${BOLD}TAGS${RESET}"
    echo -e "  ${BLUE}Super + 1-5       ${RESET}${WHITE}switch tag${RESET}"
    echo -e "  ${BLUE}Super + Shift+1-5 ${RESET}${WHITE}move window to tag${RESET}"
    echo ""
    echo -e "  ${PURPLE}${BOLD}MISC${RESET}"
    echo -e "  ${BLUE}Super + b         ${RESET}${WHITE}toggle bar${RESET}"
    echo -e "  ${BLUE}Super + Shift+c   ${RESET}${WHITE}close window${RESET}"
    echo -e "  ${BLUE}Super + Shift+q   ${RESET}${WHITE}quit dwm${RESET}"
    echo ""
    echo -en "${GRAY}${DIM}  press any key to return...${RESET}"
    read -rn1
    main
}

# ── calamares ────────────────────────────────────────────
launch_calamares() {
    # launch calamares silently in background on tag 2
    # dwm rule in config.h already places it on tag 2
    calamares > /dev/null 2>&1 &

    # re-render the full screen
    setup_term
    draw_header

    local cols
    cols=$(tput cols)
    local row=$MENU_START_ROW

    # status message
    local msg="Calamares Installer has been opened in Tag 2"
    tput cup $row 0
    print_centered "$msg" "${CYAN}${BOLD}"
    echo ""
    ((row += 2))

    # sub message
    local sub="Switch to Tag 2 to begin installation"
    tput cup $row 0
    print_centered "$sub" "${GRAY}${DIM}"
    echo ""
    ((row += 3))

    # button options
    local opts=("Switch to Tag 2" "Back to Menu")
    local sel=0
    local total=${#opts[@]}

    draw_calamares_btns() {
        for ((i=0; i<total; i++)); do
            local brow=$(( row + i * 2 ))
            tput cup $brow 0
            printf "%${cols}s"
            tput cup $brow 0
            if [[ $i -eq $sel ]]; then
                print_centered "▶  ${opts[$i]}  ◀" "${SEL_BG}${SEL_FG}${BOLD}"
            else
                print_centered "   ${opts[$i]}   " "${BLUE}"
            fi
        done

        # hint
        local hintrow=$(( $(tput lines) - 2 ))
        tput cup $hintrow 0
        printf "%${cols}s"
        tput cup $hintrow 0
        print_centered "${RESET}${CYAN}""[ ↑↓ / j k ]  navigate    [ Enter ]  select" 
    }

    draw_calamares_btns

    # button nav loop
    while true; do
        local key
        IFS= read -rsn1 key

        if [[ $key == $'\e' ]]; then
            local seq
            read -rsn2 -t 0.1 seq
            case $seq in
                '[A') key='k' ;;
                '[B') key='j' ;;
            esac
        fi

        case $key in
            k|K)
                ((sel--))
                ((sel < 0)) && sel=$((total - 1))
                draw_calamares_btns
                ;;
            j|J)
                ((sel++))
                ((sel >= total)) && sel=0
                draw_calamares_btns
                ;;
            '')
                case $sel in
                    0)
                        # switch dwm to tag 2 using xdotool
                        xdotool key super+2
                        ;;
                    1)
                        main
                        return
                        ;;
                esac
                ;;
            q|Q)
                main
                return
                ;;
        esac
    done
}

# ── wifi/imapala ────────────────────────────────────────────
wifi_setup() {
    teardown_term
    tput clear

    # launch impala — q exits it naturally
    # trap its exit and return to welcome TUI
    impala

    # once user hits q in impala, come back
    main
}

# ── actions ────────────────────────────────────────────
run_action() {
    local idx=$1
    case $idx in
        0)  launch_calamares ;;
        1)  wifi_setup ;;           # ← new
        2)  teardown_term; st -e zsh ; tput clear;sleep 0.3; main;;
        3)  dwm_keys ;;
        4)  sysinfo ;;
        5)  teardown_term; reboot ;;
        6)  teardown_term; poweroff ;;
    esac
}

# ── main loop ──────────────────────────────────────────
main() {
    local selected=0
    local total=${#MENU_LABELS[@]}

    setup_term
    draw_header
    draw_menu "$selected"

    while true; do
        local key
        IFS= read -rsn1 key

        # handle escape sequences (arrow keys)
        if [[ $key == $'\e' ]]; then
            local seq
            read -rsn2 -t 0.1 seq
            case $seq in
                '[A') key='k' ;;    # up arrow
                '[B') key='j' ;;    # down arrow
            esac
        fi

        case $key in
            k|K)
                ((selected--))
                ((selected < 0)) && selected=$((total - 1))
                draw_menu "$selected"
                ;;
            j|J)
                ((selected++))
                ((selected >= total)) && selected=0
                draw_menu "$selected"
                ;;
            [1-7])
                selected=$((key - 1))
                draw_menu "$selected"
                ;;
            '')
                run_action "$selected"
                return
                ;;
            q|Q)
                teardown_term
                exit 0
                ;;
        esac
    done
}

# ── entry ──────────────────────────────────────────────
trap 'teardown_term; exit' INT TERM
main