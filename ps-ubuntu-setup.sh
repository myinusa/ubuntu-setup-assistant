#!/bin/bash

# Constants for color codes
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
PURPLE="\033[1;35m"
CYAN="\033[1;36m"
RESET="\033[0m"
BOLD="\033[1;45;37;1;4m"

# Initial message to display script information
initial_message() {
    echo -e "post-ubuntu-setup.sh - ${BOLD}A post-ubuntu-setup script for Ubuntu 20.04 and above ${RESET}"
    echo -e "Author\n"
}

# Display system information
system_info() {
    echo -e "${YELLOW}System Information:${RESET}"
    echo -e "\tOS: $(uname)"
    echo -e "\tBash Version: $BASH_VERSION"
    echo -e "\tOS Version: $(uname -r)"
}

# Define package groups (categories)
declare -A package_groups=(
    [editor]="vim neovim"
    [development]="git build-essential software-properties-common"
    [system_monitoring]="wget htop"
)

# Display category menu and handle user input
select_categories() {
    echo -e "${BLUE}Select categories to install (separated by spaces):${RESET}"
    local i=1
    local options=()
    local max_key_length=0

    trap 'echo -e "\n${RED}Exiting due to Ctrl+C${RESET}"; exit 1' SIGINT

    for key in "${!package_groups[@]}"; do
        max_key_length=$(( max_key_length > ${#key} ? max_key_length : ${#key} ))
    done

    local padded_heading_key=$(printf "%-${max_key_length}s" "Category")
    echo -e "${YELLOW}No.   ${GREEN}${padded_heading_key}   ${CYAN}Packages${RESET}"
    echo -e "${YELLOW}---  ${GREEN}$(printf '%*s' $max_key_length '----------------')  ${CYAN}----------------${RESET}"

    for key in "${!package_groups[@]}"; do
        options+=("$key")
        local padded_key=$(printf "%-${max_key_length}s" "$key")
        echo -e "${YELLOW}[$i]   ${GREEN}$padded_key   ${CYAN}${package_groups[$key]// /, }${RESET}"
        ((i++))
    done
    echo -e "${YELLOW}[$i]   Install All${RESET}"
    ((i++))
    echo -e "${YELLOW}[$i]   Exit${RESET}"

    read -p "Enter choices: " choices
    handle_choices choices options i
    trap - SIGINT
}

# Handle user choices for package installation
handle_choices() {
    local choices=$1
    local options=($2)
    local max_choice=$3
    local selected=()

    for choice in $choices; do
        if [[ $choice -eq $max_choice ]]; then
            echo "Exiting."
            exit 0
        elif [[ $choice -eq $max_choice-1 ]]; then
            echo "Installing all packages."
            install_all_packages
            return
        elif [[ $choice -gt 0 && $choice -le ${#options[@]} ]]; then
            selected+=("${options[$choice-1]}")
        else
            echo -e "${RED}Invalid option: $choice${RESET}"
        fi
    done
    echo -e "${GREEN}Selected categories: ${selected[@]}${RESET}"
    install_selected_packages selected
}

# Install all packages from all categories
install_all_packages() {
    for category in "${!package_groups[@]}"; do
        install_packages_from_category "$category"
    done
}

# Install selected packages from chosen categories
install_selected_packages() {
    local selected=($1)
    for category in "${selected[@]}"; do
        install_packages_from_category "$category"
    done
}

# Install packages from a given category
install_packages_from_category() {
    local category=$1
    local packages=(${package_groups[$category]})
    for pkg in "${packages[@]}"; do
        echo -e "${PURPLE}Checking availability of $pkg...${RESET}"
        if apt list --installed "$pkg" &> /dev/null; then
            echo -e "${GREEN}Package $pkg is already installed.${RESET}"
        else
            echo -e "${PURPLE}Installing $pkg...${RESET}"
            sudo apt-get install -y "$pkg"
        fi
    done
}

# Main function to control flow
main() {
    initial_message
    system_info
    select_categories
}

main