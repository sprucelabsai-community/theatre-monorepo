#!/bin/bash

echo -e "Publishing skills...\n"
cd packages

# namespaces of skills that cannot be installed
namespaces=("feed" "files" "images" "organization" "locations" "heartwood" "people" "roles" "skills" "permissions" "theatre" "marketplace" "rp")

for dir in *-skill; do
	if [[ -d $dir ]]; then
		cd "$dir"
		namespace=$(grep '"namespace"' package.json | awk -F: '{print $2}' | tr -d '," ')
		if [[ " ${namespaces[*]} " == *"$namespace"* ]]; then
			echo "Publishing $namespace and setting canBeInstalled to false"
			spruce publish --isInstallable false
		else
			echo "Publishing $namespace and setting canBeInstalled to true"
			spruce publish --isInstallable true
		fi
		cd ..
	fi
done
