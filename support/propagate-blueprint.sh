# Parse the --configStrategy argument
ENV_STRATEGY=""
for arg in "$@"; do
    case $arg in
    --configStrategy=*)
        ENV_STRATEGY="${arg#*=}"
        ;;
    esac
done

REPO_PATH=$1
DIR_NAME=$(basename "$REPO_PATH")

# Pull env
ENV=$(node support/blueprint.js $2 env)

# Skip if .env if exists
case $ENV_STRATEGY in
skip)
    echo "Skipping due to 'skip' strategy in $DIR_NAME."
    exit 0
    ;;
replace)
    if [ -f "$REPO_PATH/.env" ]; then
        echo "Deleting .env due to 'replace' strategy in $DIR_NAME."
        rm "$REPO_PATH/.env"
    else
        echo ".env file not found, nothing to delete."
    fi
    ;;
*)
    # Other strategies can be handled here in the future
    ;;
esac

## drop in ENV logic here
SKILL_NAMESPACE=$(jq -r '.["skill"].namespace' $REPO_PATH/package.json)

cd $REPO_PATH

touch .env

# Ensure .env ends with a newline before appending
# This prevents new entries from concatenating onto the last line
if [ -s .env ] && [ "$(tail -c 1 .env | wc -l)" -eq 0 ]; then
    echo >> .env
fi

# Loop to set the environment variables
for key in $(jq -r 'keys[]' <<<"$ENV"); do
    if [[ "$key" == "universal" ]]; then
        len=$(jq -r ".\"$key\" | length" <<<"$ENV")
        for i in $(seq 0 $(($len - 1))); do
            pair=$(jq -r ".\"$key\"[$i] | to_entries[0] | \"\(.key)=\(.value | tostring | @json)\"" <<<"$ENV")
            echo "$pair" >>.env
        done
    fi
done

for key in $(jq -r 'keys[]' <<<"$ENV"); do
    if [[ "$key" == "$SKILL_NAMESPACE" ]]; then
        len=$(jq -r ".\"$key\" | length" <<<"$ENV")
        for i in $(seq 0 $(($len - 1))); do
            pair=$(jq -r ".\"$key\"[$i] | to_entries[0] | \"\(.key)=\(.value | tostring | @json)\"" <<<"$ENV")
            if [[ "$OSTYPE" == "darwin"* ]]; then
                # macOS requires an empty string after -i
                sed -i '' "/^$(echo $pair | cut -d= -f1)/d" .env
            else
                # Linux and other UNIX-like systems do not require the empty string
                sed -i "/^$(echo $pair | cut -d= -f1)/d" .env
            fi
            echo "$pair" >>.env
        done
    fi
done

# Define arrays for keys and values
keys=("namespace")
values=("$SKILL_NAMESPACE")

# Loop through the array and apply replacements
for i in "${!keys[@]}"; do
    key="${keys[$i]}"
    value="${values[$i]}"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS requires an empty string after -i
        sed -i '' "s/{{${key}}}/${value}/g" .env
    else
        # Linux and other UNIX-like systems do not require the empty string
        sed -i "s/{{${key}}}/${value}/g" .env
    fi
done

# Deduplicate .env entries, preserving comments and blank lines, keeping only the last value for each key
awk '
    /^[[:space:]]*#/ || /^[[:space:]]*$/ { print; next }
    /^[A-Za-z_][A-Za-z0-9_]*=/ {
        key = $1
        sub(/=.*/, "", key)
        last[key] = NR
        line[NR] = $0
        key_for_line[NR] = key
        next
    }
    { print }
    END {
        for (i=1; i<=NR; i++) {
            if (line[i] != "" && last[key_for_line[i]] == i) print line[i]
        }
    }
' .env >.env.cleaned && mv .env.cleaned .env

