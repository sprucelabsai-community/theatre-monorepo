echo -e "Publishing skills...\n"

cd packages

namespaces=("appointments" "developer" "esm" "feedback" "forms" "groups" "invite" "lbb" "profile" "reminders" "shifts" "skills" "theme" "waivers")

for dir in *-skill; do
    if [[ -d $dir ]]; then
        cd "$dir"
        namespace=$(grep '"namespace"' package.json | awk -F: '{print $2}' | tr -d '," ')
        if [[ " ${namespaces[*]} " == *"$namespace"* ]]; then
            mongosh mercury --eval "db.skills.updateMany({slug: '$namespace'}, { \$set: {isPublished: true, canBeInstalled: true}})" >/dev/null
        else
            mongosh mercury --eval "db.skills.updateMany({slug: '$namespace'}, { \$set: {isPublished: true, canBeInstalled: false}})" >/dev/null
        fi
        cd ..
    fi
done
