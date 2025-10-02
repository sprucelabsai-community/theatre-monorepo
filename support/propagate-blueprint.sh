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
		echo ".env file not found in $DIR_NAME, creating new one."
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
	echo >>.env
fi

# Loop to set the environment variables
for key in $(jq -r 'keys[]' <<<"$ENV"); do
	if [[ "$key" == "universal" ]]; then
		len=$(jq -r ".\"$key\" | length" <<<"$ENV")
		for i in $(seq 0 $(($len - 1))); do
			pair=$(jq -r ".\"$key\"[$i] | to_entries[0] | \"\(.key)=\(.value | tostring | @json)\"" <<<"$ENV")
			printf '%b\n' "$pair" >>.env
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
			printf '%b\n' "$pair" >>.env
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

# Deduplicate .env entries while retaining multi-line values and comments.
# Each assignment block (key line plus any continuation lines until the next key/comment/blank) is buffered
# so we can keep only the last occurrence for each key without mangling private keys or other multi-line secrets.
awk '
    function flush_comment_block() {
        if (comment_buf != "") {
            printf "%s", comment_buf
            comment_buf = ""
        }
    }

    function flush_assignment(key) {
        if (key == "") {
            return
        }
        last_block[key] = block_index
        blocks[block_index] = block_buf
        keys_for_block[block_index] = key
        block_buf = ""
    }

    function flush_pending() {
        flush_assignment(current_key)
        current_key = ""
    }

    /^[[:space:]]*$/ {
        flush_pending()
        flush_comment_block()
        print
        next
    }

    /^[[:space:]]*#/ {
        flush_pending()
        comment_buf = comment_buf $0 "\n"
        next
    }

    /^[A-Za-z_][A-Za-z0-9_]*=/ {
        flush_pending()
        flush_comment_block()
        ++block_index
        current_key = $1
        sub(/=.*/, "", current_key)
        block_buf = $0 "\n"
        next
    }

    {
        if (current_key != "") {
            block_buf = block_buf $0 "\n"
        } else {
            printf "%s\n", $0
        }
    }

    END {
        flush_pending()
        flush_comment_block()
        for (i = 1; i <= block_index; ++i) {
            key = keys_for_block[i]
            if (last_block[key] == i) {
                printf "%s", blocks[i]
            }
        }
    }
' .env >.env.cleaned && mv .env.cleaned .env
