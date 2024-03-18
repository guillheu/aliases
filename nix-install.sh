# Exit on any error
set -e

# Vars

# The GitHub username to check against
GITHUB_USERNAME="guillheu"

# Directory where SSH keys are stored
SSH_DIR="$HOME/.ssh"

# NixOS default configuration file (to inject initial flakes config)
NIXOS_CONFIG_FILE="/etc/nixos/configuration.nix"

# NixOS hardware configuration file
NIXOS_HARDWARE_CONFIG_FILE="/etc/nixos/hardware-configuration.nix"

# NixConfigs git repo directory
NIX_CONFIGS_REPO_PATH="/etc/NixConfigs"

# Assumed NixOS channel
NIXOS_CHANNEL="release-23.11"

# Name of the nix system (used in nixos-rebuild switch --flake .#<system_name>
NIX_SYSTEM="TerraNix"

# Checking vars with the user
echo "The script will proceed with the following variables:"
echo "GITHUB_USERNAME = $GITHUB_USERNAME"
echo "SSH_DIR = $SSH_DIR"
echo "NIXOS_CONFIG_FILE = $NIXOS_CONFIG_FILE"
echo "NIXOS_HARDWARE_CONFIG_FILE = $NIXOS_HARDWARE_CONFIG_FILE"
echo "NIXOS_CHANNEL = $NIXOS_CHANNEL"
echo "NIX_CONFIGS_REPO_PATH = $NIX_CONFIGS_REPO_PATH"
echo "USER = $USER"
echo "NIX_SYSTEM = $NIX_SYSTEM"

# Prompt the user to decide whether to continue
while true; do
    read -p "Do you wish to continue with these variables? (y/n) " yn
    case $yn in
        [Yy]* ) break;;  # Continue with the script
        [Nn]* ) echo "Exiting script."; exit;;  # Exit the script
        * ) echo "Please answer yes or no.";;  # Prompt the user again in case of invalid input
    esac
done

echo ""
echo "####################################################"
echo "################# Enabling flakes ##################"
echo "################ And home-manager ##################"
echo "####################################################"
echo ""

# Adding `nix.settings.experimental-features = [ "nix-command" "flakes" ];` to the NixOS config
# sudo sed -i '$!{h;d;};x;s/}$/  nix.settings.experimental-features = [ "nix-command" "flakes" ];\n}/' "$NIXOS_CONFIG_FILE"

# Create a temporary file
TMP_FILE=$(mktemp)

# Capture everything except the last line of the original file
head -n -1 "$NIXOS_CONFIG_FILE" > "$TMP_FILE"

# Add the new content before the last line (replacing the last '}')
echo '  nix.settings.experimental-features = [ "nix-command" "flakes" ];' >> "$TMP_FILE"

# Add the last line (the closing '}')
tail -n 1 "$NIXOS_CONFIG_FILE" | grep '}' >> "$TMP_FILE" || echo "}" >> "$TMP_FILE"

# Use sudo to overwrite the original file with the temporary file
sudo cp "$TMP_FILE" "$NIXOS_CONFIG_FILE"

# Remove the temporary file
rm "$TMP_FILE"



# Adding git to system packages
sudo sed -i 's/  #  wget\n  ];/  #  wget\n    git\n    qrencode\n  ];/g' "$NIXOS_CONFIG_FILE"

# Rebuilding the system from the new config
sudo nixos-rebuild switch

# Installing home-manager
nix-channel --add https://github.com/nix-community/home-manager/archive/$NIXOS_CHANNEL.tar.gz home-manager
nix-channel --update
export NIX_PATH=$NIX_PATH:$HOME/.nix-defexpr/channels
nix-shell '<home-manager>' -A install

echo ""
echo "####################################################"
echo "######## Checking if user has an SSH key ###########"
echo "###### With permissions for the private repo #######"
echo "####################################################"
echo ""

# Fetch public keys from GitHub for the specified user
GITHUB_KEYS=$(curl -s "https://github.com/$GITHUB_USERNAME.keys")

# Exit if unable to fetch keys from GitHub
if [ -z "$GITHUB_KEYS" ]; then
    echo "Could not fetch keys for user $GITHUB_USERNAME, or no keys exist."
    exit 2
fi

# Flag to indicate if a matching key is found
MATCHING_KEY_FILE=""

# Create SSH key if none exist, then wait for user to import it onto github
PUB_FILES=$(ls $SSH_DIR/*.pub 2> /dev/null | wc -l)

if [ "$PUB_FILES" != "0" ]; then
    echo "SSH public key(s) found in $SSH_DIR."
else
    echo "No SSH public keys found in $SSH_DIR. Generating a new SSH key..."

    # Generate a new SSH key
    ssh-keygen -t ed25519

    echo "A new SSH key has been generated."
    echo "Scan this code to copy the new SSH key to your phone's clipboard"
    qrencode -t ANSI < ~/.ssh/*.pub
fi

while [ -z "$MATCHING_KEY_FILE" ]
do
  echo "Ensure a local SSH key has read priviledges for $GITHUB_USERNAME's repositories"
  read -r
  # Iterate over public keys in the SSH directory
  for key in $SSH_DIR/*.pub; do
      # Read the contents of the public key
      CONTENT=$(cut -d ' ' -f 1,2 "$key")

      # Check if the current key exists in the GitHub keys
      if echo "$GITHUB_KEYS" | grep -q "$CONTENT"; then
          MATCHING_KEY_FILE="$key"
          break
      fi
  done
done

echo ""
echo "####################################################"
echo "########### Cloning NixConfigs git repo ############"
echo "########## And handling user permissions ###########"
echo "####################################################"
echo ""

# Creating /etc/NixConfigs directory as root and making NIX_USERNAME the owner
sudo mkdir $NIX_CONFIGS_REPO_PATH
chown $USER $NIX_CONFIGS_REPO_PATH
chgrp users $NIX_CONFIGS_REPO_PATH

# Clone the repository using the specified SSH key and username
GIT_SSH_COMMAND="ssh -i $MATCHING_KEY_FILE -o IdentitiesOnly=yes" git clone git@github.com:$GITHUB_USERNAME/NixConfigs $NIX_CONFIGS_REPO_PATH




echo ""
echo "####################################################"
echo "####### Handling hardware configuration file #######"
echo "####################################################"
echo ""




# Path to the existing hardware-configuration.nix in the Git repo
REPO_HW_CONFIG_FILE="$NIX_CONFIGS_REPO_PATH/systems/$NIX_SYSTEM/hardware-configuration.nix"

# Check if the target file exists
if [ ! -f "$REPO_HW_CONFIG_FILE" ]; then
  echo "The target hardware-configuration.nix file does not exist: $REPO_HW_CONFIG_FILE"
  exit 1
fi

# Ask the user if they want to replace the existing hardware-configuration.nix file
while true; do
    read -p "Do you wish to use the new local auto-generated hardware-configuration.nix file? (y/n) " yn
    case $yn in
        [Yy]* )
          # User chose to use the new file, overwrite the existing one
          cp "$NIXOS_HARDWARE_CONFIG_FILE" "$REPO_HW_CONFIG_FILE"
          echo "The hardware-configuration.nix file has been updated with the new local version."
          break
          ;;
        [Nn]* )
          # User chose to keep the existing file
          echo "Keeping the existing hardware-configuration.nix file."
          break
          ;;
        * ) echo "Please answer yes (y) or no (n).";;
    esac
done
