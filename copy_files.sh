#!/bin/bash

# List of files to exclude
exclude_files=(
    "Prompts/Prompt for \"End Date\" is greater than the \"Start Date\""
    "Prompts/Prompt: Discovery Pattern Designer Playbook"
)

# Copy files excluding the problematic ones
git ls-tree -r HEAD --name-only | while read -r file; do
    if [[ ! " ${exclude_files[@]} " =~ " ${file} " ]]; then
        mkdir -p "$(dirname "../SN-Snippets-VS-Code/${file}")"
        cp "${file}" "../SN-Snippets-VS-Code/${file}"
    fi
done