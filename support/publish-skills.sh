#!/bin/bash

echo -e "Publishing skills...\n"
cd packages

# namespaces of skills that cannot be installed
namespaces=("files" "images" "organization" "locations" "heartwood" "people" "roles" "skills" "permissions" "theatre" "marketplace" "rp")

publish_skill() {
	local dir="$1"
	(
		cd "$dir" || exit 0
		namespace=$(grep '"namespace"' package.json | awk -F: '{print $2}' | tr -d '," ')
		if [[ " ${namespaces[*]} " == *"$namespace"* ]]; then
			echo "Publishing $namespace and setting canBeInstalled to false"
			spruce publish --isInstallable false
		else
			echo "Publishing $namespace and setting canBeInstalled to true"
			spruce publish --isInstallable true
		fi
	) &
}

for dir in *-skill; do
	if [[ -d $dir ]]; then
		publish_skill "$dir"
	fi
done

wait
echo "All publish tasks complete."
