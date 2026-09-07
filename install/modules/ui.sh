#!/usr/bin/env bash

RESET=$'\e[0m'
BOLD=$'\e[1m'
DIM=$'\e[2m'
C_BLUE=$'\e[34m'
C_CYAN=$'\e[36m'
C_GREEN=$'\e[32m'
C_YELLOW=$'\e[33m'
C_RED=$'\e[31m'
C_MAGENTA=$'\e[35m'

INSTALL_FULL_WALLPAPERS=true
SELECTED_COMPOSITORS=("hyprland")
IS_REINSTALL=false

OPT_SDDM=false
REPLACE_DM=false
SDDM_WAYLAND=false

USER_NAME="${USER:-$(whoami)}"
OS_NAME=$(grep '^PRETTY_NAME=' /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '"')
[[ -z "$OS_NAME" ]] && OS_NAME="$(t "installer.os.default_os")"
CPU_INFO=$(grep -m 1 'model name' /proc/cpuinfo 2>/dev/null | cut -d: -f2 | xargs)
[[ -z "$CPU_INFO" ]] && CPU_INFO="$(t "installer.os.unknown_cpu")"

GPU_RAW=$(lspci -nn 2>/dev/null | grep -iE 'vga|3d|display')
GPU_INFO=$(echo "$GPU_RAW" | cut -d: -f3 | sed -E 's/ \(rev [0-9a-f]+\)//g' | xargs)
[[ -z "$GPU_INFO" ]] && GPU_INFO="$(t "installer.os.unknown_gpu")"

cleanup_terminal() {
    printf "\e[?25h" 2>/dev/null || true
    stty echo icanon 2>/dev/null || true
}
trap cleanup_terminal EXIT INT TERM

read_key() {
    local key=""
    local rest=""
    IFS= read -rsn1 key 2>/dev/null
    if [[ "$key" == $'\x1b' ]]; then
        read -rsn2 -t 0.05 rest 2>/dev/null
        if [[ "$rest" == "[A" || "$rest" == "OA" ]]; then
            echo "UP"
            return
        elif [[ "$rest" == "[B" || "$rest" == "OB" ]]; then
            echo "DOWN"
            return
        elif [[ "$rest" == "[C" || "$rest" == "OC" ]]; then
            echo "RIGHT"
            return
        elif [[ "$rest" == "[D" || "$rest" == "OD" ]]; then
            echo "LEFT"
            return
        elif [[ "$rest" == *"["* ]]; then
            local trailing=""
            while read -rsn1 -t 0.05 trailing 2>/dev/null; do
                [[ -z "$trailing" ]] && break
            done
            echo "ESC"
            return
        elif [[ -z "$rest" ]]; then
            echo "ESC"
            return
        fi
        echo "ESC"
        return
    elif [[ -z "$key" || "$key" == $'\n' || "$key" == $'\r' ]]; then
        echo "ENTER"
        return
    elif [[ "$key" == " " ]]; then
        echo "SPACE"
        return
    fi
    echo "$key"
}



draw_banner() {
    clear
    printf "%s%s" "$BOLD" "$C_CYAN"
    printf "Kairo — Arch, composed.
"
    printf "%s\n" "$RESET"

    printf "Local checkout build. Upstream credits: see UPSTREAM.md\n"
    printf "\033[K%s $(t "installer.ui.user")%s %-25s | %s$(t "installer.ui.os")%s %s\n" "$BOLD" "$RESET" "$USER_NAME" "$BOLD" "$RESET" "$OS_NAME"
    printf "\033[K%s $(t "installer.ui.cpu")%s  %-25s | %s$(t "installer.ui.gpu")%s %s\n" "$BOLD" "$RESET" "$CPU_INFO" "$BOLD" "$RESET" "$GPU_INFO"
    printf "\033[K%s--------------------------------------------------------------------------------%s\n" "$C_BLUE" "$RESET"
    printf "\033[K%s $(t "installer.ui.target_version")%s %-10s (%-7s) | %s$(t "installer.ui.install_mode")%s %s\n" "$BOLD" "$RESET" "$TARGET_VERSION" "$TARGET_COMMIT" "$BOLD" "$RESET" "$INSTALL_STATE"
    printf "\033[K%s================================================================================%s\n\n" "$C_BLUE" "$RESET"
}

show_package_overview() {
    local target_list=("${REQUIRED_PKGS[@]}")
    for comp in "${SELECTED_COMPOSITORS[@]}"; do
        target_list+=("$comp")
    done
    if [ "$OPT_SDDM" = true ]; then
        target_list+=("sddm" "qt6-declarative" "qt6-svg")
    fi

    local missing_raw
    missing_raw=$(pacman -T "${target_list[@]}" 2>/dev/null || true)

    declare -A is_missing
    while IFS= read -r p; do
        [[ -n "$p" ]] && is_missing["$p"]=1
    done <<< "$missing_raw"

    local overview_items=()
    for pkg in "${target_list[@]}"; do
        if [[ -n "${is_missing[$pkg]}" ]]; then
            overview_items+=("$(t "installer.ui.package_missing" "pkg=$pkg")")
        else
            overview_items+=("$(t "installer.ui.package_installed" "pkg=$pkg")")
        fi
    done

    cleanup_terminal
    printf "%s\n" "${overview_items[@]}" | fzf \
        --ansi \
        --layout=reverse \
        --border=rounded \
        --margin=1,2 \
        --height=25 \
        --prompt="$(t "installer.ui.packages_prompt")" \
        --header="$(t "installer.ui.packages_header")" > /dev/null || true
    stty -echo icanon 2>/dev/null || true
    printf "\e[?25l"
}

toggle_hyprland_examples() {
    COPY_HYPRLAND=$([ "${COPY_HYPRLAND:-false}" = true ] && echo false || echo true)
}

manage_sddm_menu() {
    draw_banner
    stty -echo 2>/dev/null || true
    printf "\e[?25l"
    printf "%s%s$(t "installer.ui.sddm_title")%s\n\n" "$BOLD" "$C_CYAN" "$RESET"

    local current_dm=""
    local dms=("gdm" "gdm3" "lightdm" "sddm" "lxdm" "lxdm-gtk3" "ly")
    for dm in "${dms[@]}"; do
        if systemctl is-enabled "$dm.service" &>/dev/null || systemctl is-active "$dm.service" &>/dev/null; then
            current_dm="$dm"
            break
        fi
    done

    if [ -n "$current_dm" ]; then
        printf "$(t "installer.ui.sddm_detected_active" "dm=${BOLD}${C_YELLOW}%s${RESET}")\n\n" "$current_dm"
    else
        printf "%s\n\n" "$(t "installer.ui.sddm_detected_none")"
    fi

    local cursor=0
    local rendered_lines=0

    while true; do
        local S_SDDM="${DIM}[Disabled]${RESET}"
        local S_RDM="${DIM}[No]${RESET}"
        local S_WAY="${DIM}[X11/Default]${RESET}"

        [ "$OPT_SDDM" = true ] && S_SDDM="${C_GREEN}[Enabled]${RESET}"
        [ "$REPLACE_DM" = true ] && S_RDM="${C_GREEN}[Yes]${RESET}"
        [ "$SDDM_WAYLAND" = true ] && S_WAY="${C_GREEN}[Wayland]${RESET}"

        local items=()
        items+=("1. $(t "installer.ui.sddm_opt_install") $S_SDDM")
        if [ -n "$current_dm" ] && [ "$current_dm" != "sddm" ]; then
            items+=("2. $(t "installer.ui.sddm_opt_disable" "dm=$current_dm") $S_RDM")
        fi
        items+=("3. $(t "installer.ui.sddm_opt_wayland") $S_WAY")
        items+=("4. ${BOLD}${C_GREEN}$(t "installer.ui.done")${RESET}")

        if [ "$rendered_lines" -gt 0 ]; then
            printf "\033[%dA" "$rendered_lines"
        fi

        for i in "${!items[@]}"; do
            if [ "$i" -eq "$cursor" ]; then
                printf "\r\033[K%s%s ▸ %s%s\n" "$BOLD" "$C_CYAN" "$RESET" "${items[$i]}"
            else
                printf "\r\033[K    %s\n" "${items[$i]}"
            fi
        done
        rendered_lines=${#items[@]}

        local key
        key=$(read_key)

        case "$key" in
            UP|[kK])
                if [ "$cursor" -gt 0 ]; then
                    cursor=$(( cursor - 1 ))
                else
                    cursor=$(( ${#items[@]} - 1 ))
                fi
                ;;
            DOWN|[jJ])
                if [ "$cursor" -lt $(( ${#items[@]} - 1 )) ]; then
                    cursor=$(( cursor + 1 ))
                else
                    cursor=0
                fi
                ;;
            ENTER|SPACE)
                local selected_str="${items[$cursor]}"
                case "$selected_str" in
                    *"1."*)
                        OPT_SDDM=$([ "$OPT_SDDM" = true ] && echo false || echo true)
                        if [ "$OPT_SDDM" = true ] && [ -n "$current_dm" ] && [ "$current_dm" != "sddm" ]; then
                            REPLACE_DM=true
                        fi
                        ;;
                    *"2."*)
                        REPLACE_DM=$([ "$REPLACE_DM" = true ] && echo false || echo true)
                        ;;
                    *"3."*)
                        SDDM_WAYLAND=$([ "$SDDM_WAYLAND" = true ] && echo false || echo true)
                        ;;
                    *"4."*)
                        break
                        ;;
                esac
                ;;
            ESC|[qQ])
                break
                ;;
        esac
    done
}

run_installer_ui() {
    local cursor=0

    while true; do
        draw_banner
        stty -echo 2>/dev/null || true
        printf "\e[?25l"

        local rendered_lines=0

        while true; do
            local COMP_MENU_ITEM="Copy Hyprland examples [${COPY_HYPRLAND:-false}]"
            local S_SDDM="${DIM}[OFF]${RESET}"
            local S_WP="${DIM}[3 Random]${RESET}"

            [ "$OPT_SDDM" = true ] && S_SDDM="${C_GREEN}[ON]${RESET}"
            [ "$INSTALL_FULL_WALLPAPERS" = true ] && S_WP="${C_GREEN}[Full Pack]${RESET}"

            local items=()
            items+=("1. $(t "installer.ui.menu_overview" "count=${#REQUIRED_PKGS[@]}")")
            items+=("2. $COMP_MENU_ITEM")
            items+=("3. $(t "installer.ui.menu_sddm") $S_SDDM")
            items+=("4. $(t "installer.ui.menu_wallpapers") $S_WP")

            if [[ "$INSTALL_STATE" == "current" ]]; then
                items+=("5. ${BOLD}${C_GREEN}$(t "installer.ui.menu_update")${RESET}")
                items+=("6. ${BOLD}${C_YELLOW}$(t "installer.ui.menu_reinstall")${RESET}")
                items+=("7. ${DIM}$(t "installer.ui.menu_exit")${RESET}")
            else
                items+=("5. ${BOLD}${C_GREEN}$(t "installer.ui.menu_install")${RESET}")
                items+=("6. ${DIM}$(t "installer.ui.menu_exit")${RESET}")
            fi

            if [ "$rendered_lines" -gt 0 ]; then
                printf "\033[%dA" "$rendered_lines"
            fi

            for i in "${!items[@]}"; do
                if [ "$i" -eq "$cursor" ]; then
                    printf "\r\033[K%s%s ▸ %s%s\n" "$BOLD" "$C_CYAN" "$RESET" "${items[$i]}"
                else
                    printf "\r\033[K    %s\n" "${items[$i]}"
                fi
            done
            rendered_lines=${#items[@]}

            local key
            key=$(read_key)

            case "$key" in
                UP|[kK])
                    if [ "$cursor" -gt 0 ]; then
                        cursor=$(( cursor - 1 ))
                    else
                        cursor=$(( ${#items[@]} - 1 ))
                    fi
                    ;;
                DOWN|[jJ])
                    if [ "$cursor" -lt $(( ${#items[@]} - 1 )) ]; then
                        cursor=$(( cursor + 1 ))
                    else
                        cursor=0
                    fi
                    ;;
                "1")
                    show_package_overview
                    break
                    ;;
                "2")
                    toggle_hyprland_examples
                    break
                    ;;
                "3")
                    manage_sddm_menu
                    break
                    ;;
                "4")
                    INSTALL_FULL_WALLPAPERS=$([ "$INSTALL_FULL_WALLPAPERS" = true ] && echo false || echo true)
                    ;;
                "5")
                    IS_REINSTALL=false
                    cleanup_terminal
                    return 0
                    ;;
                "6")
                    if [[ "$INSTALL_STATE" == "current" ]]; then
                        IS_REINSTALL=true
                        cleanup_terminal
                        return 0
                    else
                        cleanup_terminal
                        clear
                        exit 0
                    fi
                    ;;
                "7")
                    if [[ "$INSTALL_STATE" == "current" ]]; then
                        cleanup_terminal
                        clear
                        exit 0
                    fi
                    ;;
                ESC|[qQ])
                    cleanup_terminal
                    clear
                    exit 0
                    ;;
                ENTER|SPACE)
                    local sel="${items[$cursor]}"
                    case "$sel" in
                        *"1."*)
                            show_package_overview
                            break
                            ;;
                        *"2."*)
                            toggle_hyprland_examples
                            break
                            ;;
                        *"3."*)
                            manage_sddm_menu
                            break
                            ;;
                        *"4."*)
                            INSTALL_FULL_WALLPAPERS=$([ "$INSTALL_FULL_WALLPAPERS" = true ] && echo false || echo true)
                            ;;
                        *"5."*)
                            IS_REINSTALL=false
                            cleanup_terminal
                            return 0
                            ;;
                        *"6."*)
                            if [[ "$INSTALL_STATE" == "current" ]]; then
                                IS_REINSTALL=true
                                cleanup_terminal
                                return 0
                            else
                                cleanup_terminal
                                clear
                                exit 0
                            fi
                            ;;
                        *"7."*)
                            if [[ "$INSTALL_STATE" == "current" ]]; then
                                cleanup_terminal
                                clear
                                exit 0
                            fi
                            ;;
                    esac
                    ;;
            esac
        done
    done
}

draw_completion_screen() {
    local target_ver="$1"
    local target_commit="$2"
    cleanup_terminal
    clear
    printf "%s%s" "$BOLD" "$C_GREEN"
    printf "Kairo — Arch, composed.
"
    printf "%s\n\n" "$RESET"
    printf "%s%s  %s%s\n\n" "$BOLD" "$C_CYAN" "$(t "installer.ui.tagline")" "$RESET"
    printf "%s%s================================================================================%s\n" "$BOLD" "$C_MAGENTA" "$RESET"
    printf "%s%s $(t "installer.ui.support_creator")%s\n" "$BOLD" "$C_YELLOW" "$RESET"
    printf " $(t "installer.ui.buy_coffee")\n"
    printf " Upstream credits: see UPSTREAM.md\n"
    printf "%s%s================================================================================%s\n\n" "$BOLD" "$C_MAGENTA" "$RESET"
    printf "%s%s%s\n" "$C_GREEN" "$(t "installer.ui.installed_success" "ver=$target_ver" "commit=$target_commit")" "$RESET"
    if [ ${#FAILED_PKGS[@]} -gt 0 ]; then
        printf "\n%s%s%s%s\n" "$BOLD" "$C_RED" "$(t "installer.ui.failed_packages")" "$RESET"
        for fp in "${FAILED_PKGS[@]}"; do
            printf "  - %s%s%s\n" "$C_YELLOW" "$fp" "$RESET"
        done
    fi
    printf "\n%s\n\n" "$(t "installer.ui.restart_prompt")"

    local restart_choice=""
    local prompt_msg
    prompt_msg="$(t "installer.ui.ask_reboot")"

    if [ -t 0 ]; then
        read -r -p "$prompt_msg" restart_choice
    elif [ -e /dev/tty ]; then
        read -r -p "$prompt_msg" restart_choice < /dev/tty
    fi

    if [[ "$restart_choice" =~ ^[Yy]$ ]]; then
        sudo reboot now
    fi
}
