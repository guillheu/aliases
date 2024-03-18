# The GitHub username to check against
GITHUB_USERNAME="guillheu"

# Directory where SSH keys are stored
SSH_DIR="$HOME/.ssh"

# Fetch public keys from GitHub for the specified user
GITHUB_KEYS=$(curl -s "https://github.com/$GITHUB_USERNAME.keys")

# Exit if unable to fetch keys from GitHub
if [ -z "$GITHUB_KEYS" ]; then
    echo "Could not fetch keys for user $GITHUB_USERNAME, or no keys exist."
    exit 2
fi

# Flag to indicate if a matching key is found
MATCH_FOUND=0

# Iterate over public keys in the SSH directory
for key in $SSH_DIR/*.pub; do
    # Read the contents of the public key
    CONTENT=$(cut -d ' ' -f 1,2 "$key")

    # Check if the current key exists in the GitHub keys
    if echo "$GITHUB_KEYS" | grep -q "$CONTENT"; then
        echo "Match found for key: $key"
        MATCH_FOUND=1
    fi
done

# If no matches were found, print a message
if [ $MATCH_FOUND -eq 0 ]; then
    echo "No matching keys found for GitHub user: $GITHUB_USERNAME"
fi
