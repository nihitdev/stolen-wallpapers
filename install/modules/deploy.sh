#!/usr/bin/env bash

EXTRA_CONFIGS=()

render_wallpaper_progress() {
    local current="$1"
    local total="$2"
    local label="${3:-Installing wallpapers}"
    local bar_width=30
    local percent=0
    if [ "$total" -gt 0 ]; then
        percent=$(( current * 100 / total ))
    fi
    local filled=0
    if [ "$total" -gt 0 ]; then
        filled=$(( current * bar_width / total ))
    fi
    local empty=$(( bar_width - filled ))
    local bar_fill=""
    local bar_empty=""
    if [ "$filled" -gt 0 ]; then
        bar_fill=$(printf "%*s" "$filled" "" | tr ' ' '=')
    fi
    if [ "$empty" -gt 0 ]; then
        bar_empty=$(printf "%*s" "$empty" "" | tr ' ' ' ')
    fi
    printf "\r\e[36m[ INFO ]\e[0m %s \e[32m[%s%s]\e[0m %3d%% (%d/%d)" "$label" "$bar_fill" "$bar_empty" "$percent" "$current" "$total"
}

get_wallpaper_dir() {
    local user_pics=""
    if [ -f "$HOME/.config/user-dirs.dirs" ]; then
        user_pics=$(grep '^XDG_PICTURES_DIR' "$HOME/.config/user-dirs.dirs" 2>/dev/null | cut -d= -f2 | tr -d '"' | sed "s|\$HOME|$HOME|g")
    fi
    if [[ -z "$user_pics" || "$user_pics" == "$HOME" ]]; then
        if command -v xdg-user-dir &>/dev/null; then
            user_pics="$(xdg-user-dir PICTURES 2>/dev/null || true)"
        fi
    fi
    if [[ -z "$user_pics" || "$user_pics" == "$HOME" ]]; then
        user_pics="$HOME/Pictures"
    fi
    user_pics="${user_pics%/}"
    echo "$user_pics/Wallpapers"
}

install_wallpapers() {
    local full_pack="${1:-true}"
    local wallpaper_dir
    wallpaper_dir=$(get_wallpaper_dir)
    local wallpaper_repo="https://github.com/nihitdev/kairo-wallpapers.git"
    local clone_dir="${XDG_CACHE_HOME:-"$HOME/.cache"}/kairo-wallpapers"

    mkdir -p "$wallpaper_dir"

    local sync_success=false
    if [ -d "$clone_dir/.git" ]; then
        if git -C "$clone_dir" fetch --depth 1 origin 2>/dev/null; then
            if git -C "$clone_dir" reset --hard FETCH_HEAD 2>/dev/null || \
               git -C "$clone_dir" reset --hard origin/HEAD 2>/dev/null || \
               git -C "$clone_dir" reset --hard origin/main 2>/dev/null || \
               git -C "$clone_dir" reset --hard origin/master 2>/dev/null; then
                sync_success=true
            fi
        fi
    fi

    if [ "$sync_success" != true ]; then
        rm -rf "$clone_dir"
        echo -e "\n\e[36m[ INFO ]\e[0m Cloning wallpapers repository..."
        git clone --depth 1 "$wallpaper_repo" "$clone_dir" 2>/dev/null || true
    fi

    local src_dir="$clone_dir"
    if [ -d "$clone_dir/images" ]; then
        src_dir="$clone_dir/images"
    fi

    if [ ! -d "$src_dir" ]; then
        return 0
    fi

    if [ "$full_pack" = true ]; then
        local files=()
        while IFS= read -r f; do
            [[ -n "$f" ]] && files+=("$f")
        done < <(find "$src_dir" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.webp" \) 2>/dev/null)

        local total=${#files[@]}
        local count=0

        if [ "$total" -gt 0 ]; then
            for file in "${files[@]}"; do
                cp "$file" "$wallpaper_dir/" 2>/dev/null || true
                count=$((count + 1))
                render_wallpaper_progress "$count" "$total" "Installing wallpapers"
            done
            echo ""
        else
            find "$src_dir" -type f ! -name "README.md" ! -name "LICENSE" ! -path "*/.git/*" -exec cp {} "$wallpaper_dir/" \; 2>/dev/null || true
        fi
    else
        if [ -z "$(ls -A "$wallpaper_dir" 2>/dev/null | grep -iE '\.(jpg|jpeg|png|gif|webp)$')" ]; then
            local random_pics=()
            while IFS= read -r pic; do
                [[ -n "$pic" ]] && random_pics+=("$pic")
            done < <(find "$src_dir" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.webp" \) 2>/dev/null | shuf -n 3)

            local total=${#random_pics[@]}
            local count=0

            if [ "$total" -gt 0 ]; then
                for pic in "${random_pics[@]}"; do
                    cp "$pic" "$wallpaper_dir/" 2>/dev/null || true
                    count=$((count + 1))
                    render_wallpaper_progress "$count" "$total" "Installing wallpapers"
                done
                echo ""
            fi
        fi
    fi
}

setup_sddm() {
    local project_root="$1"
    if [ "$OPT_SDDM" != true ]; then
        return 0
    fi

    local init_sys="generic"
    if declare -f detect_init_system >/dev/null; then
        init_sys=$(detect_init_system)
    fi

    echo -e "\n\e[36m[ INFO ]\e[0m $(t "installer.deploy.configuring_sddm")"

    if [ "$REPLACE_DM" = true ]; then
        local dms=("gdm" "gdm3" "lightdm" "lxdm" "lxdm-gtk3" "ly" "greetd" "emptty")
        for dm in "${dms[@]}"; do
            if declare -f disable_system_service >/dev/null; then
                disable_system_service "$dm" "$init_sys"
            fi
            if command -v pacman &>/dev/null; then
                if pacman -Qq "$dm" &>/dev/null; then
                    echo "  $(t "installer.deploy.disabling_dm" "dm=$dm")"
                    sudo pacman -Rns --noconfirm "$dm" >/dev/null 2>&1 || true
                fi
            fi
        done
    fi

    sudo rm -rf /usr/share/sddm/themes/matugen-minimal
    sudo rm -rf /usr/share/sddm/themes/material-you
    sudo rm -f /etc/sddm.conf.d/*matugen*.conf
    sudo rm -f /etc/sddm.conf.d/*material-you*.conf
    sudo rm -f /etc/sddm.conf

    local sddm_theme_src="$project_root/config/sddm/themes/material-you"
    local sddm_theme_dest="/usr/share/sddm/themes/material-you"

    if [ -d "$sddm_theme_src" ]; then
        sudo mkdir -p "$sddm_theme_dest"
        sudo cp -r "$sddm_theme_src/." "$sddm_theme_dest/"
        sudo chmod -R 755 "$sddm_theme_dest"
        if [ -d "$sddm_theme_src/font" ]; then
            sudo mkdir -p /usr/share/fonts/TTF
            sudo cp -r "$sddm_theme_src/font/"*.ttf /usr/share/fonts/TTF/ 2>/dev/null || true
            fc-cache -f /usr/share/fonts >/dev/null 2>&1 || true
        fi
    fi

    sudo mkdir -p /etc/sddm.conf.d

    if [ "$SDDM_WAYLAND" = true ]; then
        cat <<EOF | sudo tee /etc/sddm.conf.d/10-material-you.conf > /dev/null
[Theme]
Current=material-you
ThemeDir=/usr/share/sddm/themes

[General]
DisplayServer=wayland
GreeterEnvironment=QT_WAYLAND_DISABLE_WINDOWDECORATION=1
InputMethod=
EOF
    else
        cat <<EOF | sudo tee /etc/sddm.conf.d/10-material-you.conf > /dev/null
[Theme]
Current=material-you
ThemeDir=/usr/share/sddm/themes

[General]
InputMethod=
EOF
    fi

    if declare -f enable_system_service >/dev/null; then
        enable_system_service "sddm" "$init_sys"
    else
        case "$init_sys" in
            systemd)
                sudo systemctl enable --now sddm.service 2>/dev/null || sudo systemctl enable -f sddm.service 2>/dev/null || sudo systemctl enable sddm 2>/dev/null || true
                ;;
            openrc)
                sudo rc-update add sddm default 2>/dev/null || true
                sudo rc-service sddm start 2>/dev/null || true
                ;;
            dinit)
                sudo dinitctl enable sddm 2>/dev/null || sudo dinitctl start sddm 2>/dev/null || true
                ;;
            runit)
                if [ -d "/etc/sv/sddm" ]; then
                    sudo ln -sf "/etc/sv/sddm" /var/service/ 2>/dev/null || true
                fi
                ;;
            s6)
                sudo s6-rc-bundle-update -b add default sddm 2>/dev/null || true
                ;;
            *)
                sudo systemctl enable sddm.service -f 2>/dev/null || true
                ;;
        esac
    fi

    echo -e "  \e[32m$(t "installer.deploy.sddm_success")\e[0m"
}

deploy_package() {
    local repo_root="$1"
    local target_base="${XDG_DATA_HOME:-$HOME/.local/share}/kairo"
    local bin_dir="${KAIRO_BIN_DIR:-$HOME/.local/bin}"
    local config_base="${XDG_CONFIG_HOME:-$HOME/.config}"
    local staged

    # Stage a complete copy before replacing the installed shell.
    mkdir -p "$(dirname "$target_base")" "$bin_dir"
    staged=$(mktemp -d "${target_base}.install.XXXXXX") || return 1
    if ! cp -a "$repo_root/bin" "$repo_root/src" "$repo_root/config" "$repo_root/compositors" "$staged/"; then
        rm -rf "$staged"
        return 1
    fi
    cp "$repo_root/version.txt" "$staged/src/version.txt"
    cp "$repo_root/LICENSE.md" "$repo_root/UPSTREAM.md" "$repo_root/CHANGELOG.md" "$repo_root/README.md" "$staged/src/"
    cp "$repo_root/install/uninstall.sh" "$staged/uninstall.sh"
    chmod +x "$staged/bin/kairo" "$staged/bin/kairod" "$staged/uninstall.sh"
    find "$staged/src" -type f \( -name '*.sh' -o -name '*.py' \) -exec chmod +x {} +
    # A marker distinguishes our managed installation from arbitrary user data.
    printf 'Kairo managed installation\n' > "$staged/.kairo-install"
    if [ -e "$target_base" ] && [ ! -f "$target_base/.kairo-install" ] && [ ! -f "$target_base/bin/kairod" ]; then
        echo "Kairo: refusing to replace an unmanaged directory: $target_base" >&2
        rm -rf "$staged"
        return 1
    fi
    for name in kairo kairod; do
        if [ -e "$bin_dir/$name" ] || [ -L "$bin_dir/$name" ]; then
            if [ ! -L "$bin_dir/$name" ] || [ "$(readlink "$bin_dir/$name")" != "$target_base/bin/$name" ]; then
                echo "Kairo: launcher already exists outside this installation: $bin_dir/$name" >&2
                rm -rf "$staged"
                return 1
            fi
        fi
    done
    rm -rf "$target_base"
    mv "$staged" "$target_base"
    for name in kairo kairod; do
        ln -sf "$target_base/bin/$name" "$bin_dir/$name"
    done

    local data_base="${XDG_DATA_HOME:-$HOME/.local/share}"
    mkdir -p "$data_base/applications" "$data_base/icons/hicolor/scalable/apps"
    ln -sf "$target_base/src/assets/applications/kairo.desktop" "$data_base/applications/kairo.desktop"
    ln -sf "$target_base/src/assets/kairo-logo.svg" "$data_base/icons/hicolor/scalable/apps/kairo.svg"

    # Optional example integration; never prune unrelated user configuration.
    if [ "${COPY_HYPRLAND:-false}" = true ]; then
        local dest="$config_base/hypr"
        if [ -d "$dest" ]; then
            local backup="$config_base/hypr_backup/backup_$(date +%Y%m%d_%H%M%S)"
            mkdir -p "$backup"
            cp -a "$dest/." "$backup/"
        fi
        mkdir -p "$dest"
        cp -a "$repo_root/compositors/hyprland/." "$dest/"
    fi
}
