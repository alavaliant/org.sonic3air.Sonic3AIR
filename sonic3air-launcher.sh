#!/bin/bash
set -euo pipefail;

function detect_user_data_dir () {
    if [ -n "${XDG_DATA_HOME+set}" ]; then 
        user_data_dir="${XDG_DATA_HOME}"
        return 0
    fi
    if [ -n "${HOME+set}" ]; then 
        user_data_dir="${HOME}"
        return 0
    fi
    return 1
}

function install_game () {
    # Source, Destination, Silent
    local game_checksum="fa52ac946dfd576538d00aa858b790b9d81a1217e25aa5193693a4e57f4f89d9"
    local error_title="Invalid file"
    local error_text="Checksum doesn't match, please select another file."
    echo "${game_checksum} $1" | sha256sum --check --status
    if [ $? -eq 1 ]; then
        echo "Checksum mismatch."
        if [ "$2" -eq 1 ]; then
            return 1
        else
            zenity --error --width 200 --height 100 --title="${error_title}" --text="${error_text}"
            return 1
        fi
    fi
    mkdir --parents "${install_dir}"
    cp "$1" "${install_dir}${install_file}"
    return $?
}

function detect_game () {
    local not_found_title="Game file not found"
    local not_found_text="To play Sonic 3: A.I.R, you need Sonic 3 &amp; Knuckles from the SEGA Mega Drive &amp; Genesis Classics collection installed on Steam.\n\nPlease install it and restart the game.\n\nIf your Steam install is in an unusual place, please locate the game's ROM file manually.\n\nManually set game location?"
    local select_title="Select your Sonic 3 & Knuckles file"
    local user_path=""
    local possible_paths=(
    "${HOME}/.local/share/Steam/steamapps/common/Sega Classics/uncompressed ROMs/Sonic_Knuckles_wSonic3.bin"
    "${HOME}/.steam/steam/steamapps/common/Sega Classics/uncompressed ROMs/Sonic_Knuckles_wSonic3.bin"
    "${HOME}/.steam/root/steamapps/common/Sega Classics/uncompressed ROMs/Sonic_Knuckles_wSonic3.bin"
    "${HOME}/.steam/debian-installation/steamapps/common/Sega Classics/uncompressed ROMs/Sonic_Knuckles_wSonic3.bin"
    "${HOME}/Steam/steamapps/common/Sega Classics/uncompressed ROMs/Sonic_Knuckles_wSonic3.bin"
    "${HOME}/.var/app/com.valvesoftware.Steam/.local/share/Steam/steamapps/common/Sega Classics/uncompressed ROMs/Sonic_Knuckles_wSonic3.bin"
    )
    for p in "${possible_paths[@]}"; do
        echo "Checking: ${p}"
        if [ -f "${p}" ]; then
            if install_game "${p}" 0; then
                echo "Found! Game installed."
                return 0
            fi
        fi
    done
    zenity --question --width 600 --height 300 --title="${not_found_title}" --text="${not_found_text}"
    if [ $? -eq 1 ]; then
        echo "User refused to select a file, quitting."
        return 1
    fi
    while true
    do
        user_path=$(zenity --file-selection --title="${select_title}")
        if [ $? -eq 1 ]; then
            echo "User cancelled file selection, quitting."
            return 1
        fi
        if install_game "${user_path}" 0; then
            echo "Game installed."
            return 0
        fi
    done
}

if detect_user_data_dir; then
    # File paths to check
    install_dir="${user_data_dir}/Sonic3AIR"
    install_file="/Sonic_Knuckles_wSonic3.bin"
    eggman_icon="/app/bin/icons/eggman-symbolic.svg"
    # Discord RPC
    for i in {0..9}; do
        test -S "$XDG_RUNTIME_DIR"/"discord-ipc-$i" || ln -sf {app/com.discordapp.Discord,"$XDG_RUNTIME_DIR"}/"discord-ipc-$i";
    done
    echo "Checking if the game is installed at: ${install_dir}${install_file}"
    if [ ! -f "${install_dir}${install_file}" ]; then
        echo "Game is not installed, starting detection..."
        if detect_game; then
            /app/bin/sonic3air_linux "$@"
        fi
    else
        echo "Game is installed, launching..."
        /app/bin/sonic3air_linux "$@"
    fi
else
    error_msg="Unable to detect your userdata directory, check your environment variables (\$HOME or \${XDG_DATA_HOME})."
    echo "${error_msg}"
    zenity --error --width 300 --height 100 --title="" --text="${error_msg}"
fi