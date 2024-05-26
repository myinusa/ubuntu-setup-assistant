#!/bin/bash

# Introductory message
# echo -e "\033[1;45;37;1;4mStarting the post-ubuntu-setup script...\033[0m"
# echo -e "\033[1;45;37;1;4mThis script will check your Bash version, verify sudo access, update the package list, and install specified packages.\033[0m"

initial_message() {
   echo -e "\033[1;45;37;1;4mpost-ubuntu-setup.sh - a post-ubuntu-setup script for Ubuntu 20.04 LTS\033[0m"
}

system_info(){
   echo -e "system information: "
   echo -e "\tOS: $(uname)"
   echo -e "\tBash Version: $BASH_VERSION"
   echo -e "\tOS Version: $(uname -r)"
}

initial_message

# Check if Bash version is 4.0 or greater
if ((BASH_VERSINFO[0] < 4)); then
    echo -e "\033[1;31mError: This script requires Bash version 4.0 or greater. You are using version ${BASH_VERSION}.\033[0m"
    exit 1
# else
    # echo -e "\033[1;32mBash version ${BASH_VERSION} is sufficient to run this script.\033[0m"
fi

# Define package groups (categories)
package_groups_editor=("vim" "neovim")
package_groups_development=("git" "build-essential" "software-properties-common")
package_groups_system_monitoring=("wget" "htop")
# Add more categories and packages as needed.

# Function to display help message
show_help() {
echo -e "    \033[1;34mUsage: $0 [OPTION]... where OPTION is one of the following:\033[0m"

    # Function to print a few packages from a category
    print_packages() {
        local category=$1
        local packages_var="package_groups_${category}[@]"
        local packages=("${!packages_var}")
        echo -e "\t\033[1;32m-${category:0:1}, --${category}\033[0m Install packages from the '\033[1;36m${category}\033[0m' category (e.g., \033[1;33m${packages[*]}\033[0m)"
    }

    print_packages "editor"
    print_packages "development"
    print_packages "system_monitoring"

    echo -e "\t\033[1;32m-a, --all\033[0m For installing all packages use '-a, --all'"
}

# If no categories are specified, show available options and exit
show_no_categories_message() {
    echo -e "\033[1;31mNo categories specified. Available options are:\033[0m"
    show_help
    exit 1
}

# Parse command-line options using getopts
while getopts "aedsh" opt; do
    case $opt in
        a) all_packages=true ;;
        e) categories+=("editor") ;;
        d) categories+=("development") ;;
        s) categories+=("system_monitoring") ;;
        sy) system_info; exit 0 ;;
        h) show_help; exit 0 ;;
        \?) show_help >&2; exit 1 ;;
    esac
done

# If no categories are specified, show available options and exit
if [ -z "$all_packages" ] && [ ${#categories[@]} -eq 0 ]; then
    show_no_categories_message
fi

# Check if script is being executed with sudo
sudo_check() {
    if [ "$EUID" -ne 0 ]; then
        echo "Please run this script with sudo."
        exit 1
    fi
}

# Display distribution information.
display_distro_info() {
    lsb_release -a
}

# Check if the package manager is available.
check_package_manager() {
    if ! command -v apt-get &> /dev/null; then
        echo "apt-get package manager is not available."
        exit 1
    fi
}

# Prepare the system.
prepare_system() {
    apt-get update
}

# Function to install packages from a given category.
install_packages_from_category() {
    local category=$1
    local packages_var="package_groups_${category}[@]"
    local packages=("${!packages_var}")
    for pkg in "${packages[@]}"; do
        echo -e "\033[1;35mChecking availability of $pkg...\033[0m"
        if check_package_exists "$pkg"; then
            echo -e "\033[1;35mInstalling $pkg...\033[0m"
            if sudo apt-get install -y "$pkg"; then
                echo -e "\033[1;32mPackage $pkg installed successfully.\033[0m"
            else
                echo -e "\033[1;31mFailed to install package $pkg.\033[0m"
            fi
        fi
    done
}

# Install packages based on provided categories or all packages if '-all' is specified.
for cat in "${categories[@]}"; do
    install_packages_from_category "$cat