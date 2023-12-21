#!/usr/bin/env bash

screen_name="skills"

# Quit any existing screens with the same name
screen -S "${screen_name}" -X quit

# Create a new screen session and run the skills
screen -d -m -S "${screen_name}" bash

packages_dir="$(pwd)/packages"
boot_command="$(pwd)/support/boot-skill.sh"

echo "Booting Mercury..."
screen -S "${screen_name}" -p 0 -X screen -t "mercury" bash -c "cd ${packages_dir}/spruce-mercury-api && ${boot_command}; bash"

sleep 5

echo "Booting skills..."

cd packages

for skill_dir in *-skill; do
    skill_name="$(echo ${skill_dir} | cut -d '-' -f 2)"
    echo "Booting ${skill_name}"
    screen -S "${screen_name}" -p 0 -X screen -t "${skill_name}" bash -c "cd ${packages_dir}/${skill_dir} && ${boot_command}; bash"
done
