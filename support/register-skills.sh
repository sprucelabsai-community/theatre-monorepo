echo -e "Checking skills for registration...\n"

cd packages

for dir in *-skill; do
    if [[ -d $dir ]]; then
        cd "$dir"

        # Check if .env file exists
        if [ -f .env ]; then
            # Check if SKILL_ID is defined in .env file
            if ! grep -q "^SKILL_ID=" .env; then
                echo "$dir NEEDS REGISTER"
            fi
        else
            echo "$dir NEEDS REGISTER (No .env file found)"
        fi

        cd ..
    fi
done
