#
# Copyright (c) Authors: http://www.armbian.com/authors, info@armbian.com
#
# This file is licensed under the terms of the GNU General Public
# License version 2. This program is licensed "as is" without any
# warranty of any kind, whether express or implied.
#


# @description Configure system settings.
#
# @exitcode 0  If successful.
#
# @stdout Function to display the menu and get the user's choice
get_choice() {
    local options=("$@")
    local choice

    if [[ $DISPLAY ]] && command -v zenity >/dev/null 2>&1; then
        choice=$(zenity --list --title="Functions" --column="Function" --column="Description" "${options[@]}")
    elif command -v whiptail >/dev/null 2>&1; then
        choice=$(whiptail --title "Functions" --menu "Choose a function:" 15 60 4 "${options[@]}" 3>&1 1>&2 2>&3)
    elif command -v dialog >/dev/null 2>&1; then
        choice=$(dialog --title "Functions" --menu "Choose a function:" 15 60 4 "${options[@]}" 3>&1 1>&2 2>&3)
    else
        read -r -p "Choose a function:" choice
    fi

    echo "$choice"
}

# Get the directory of the script
directory="$(dirname "${BASH_SOURCE[0]}")"

# Get a list of functions and their descriptions, excluding files starting with 'about_'
declare -A function_descriptions

for func_file in "$directory"/*.sh; do
    func_name=$(basename "$func_file" .sh)
    if [[ $func_name != about_* ]]; then
        description=$(grep "^# @description" "$func_file" | sed 's/^# @description //')
        echo "Function: $func_name, Description: $description"  # Add this line for debugging
        function_descriptions["$func_name"]=$description
    fi
done


# Create an options array for the menu
options=()
for func in "${!function_descriptions[@]}"; do
    options+=("$func" "${function_descriptions[$func]}")
done

# Call the function to display the menu and get the user's choice
choice=$(get_choice "${options[@]}")

if [ -n "$choice" ]; then
    echo "You chose category: $choice"

    # Extract the function name from the metadata block
    function_name=$(grep -oP '(?<=function\s)\w+::\w+' "$directory/$choice.sh")

    if [ -n "$function_name" ]; then
        echo "You chose file: $choice.sh"

        # Source the file to make the function available
        source "$directory/$choice.sh"

        # Call the function
        "$function_name"
    else
        echo "$function_name not found in metadata."
    fi
else
    echo "No choice was made."
fi

