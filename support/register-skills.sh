echo -e "Checking skills for registration...\n"

cd packages

for dir in *-skill; do
    if [[ -d $dir ]]; then
        cd "$dir"

        # Extract NAMESPACE from directory name
        IFS='-' read -ra ADDR <<<"$dir"
        if [ ${#ADDR[@]} -gt 1 ]; then
            NAMESPACE=${ADDR[1]}
        else
            echo "Invalid directory format for $dir" >&2
            cd ..
            continue
        fi

        # Check if .env file exists
        if [ -f .env ]; then
            # Check if SKILL_ID is defined in .env file
            if ! grep -q "^SKILL_ID=" .env; then
                spruce set.remote --remote=local
                spruce register --nameReadable="$NAMESPACE" --nameKebab="$NAMESPACE"
            fi
        else
            echo "$dir is missing a .env file!" >&2
            exit 1
        fi

        cd ..
    fi
done
