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
sed -i '$!{h;d;};x;s/}$/  nix.settings.experimental-features = [ "nix-command" "flakes" ];\n}/' "$NIXOS_CONFIG_FILE"

# Rebuilding the system from the new config
sudo nixos-rebuild switch

# Installing home-manager
nix-channel --add https://github.com/nix-community/home-manager/archive/$NIXOS_CHANNEL.tar.gz home-manager
nix-channel --update
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

# Check if a matching key file was found
if [ -n "$MATCHING_KEY_FILE" ]; then
    echo "Matching key file: $MATCHING_KEY_FILE"
else
    echo "No matching keys found for GitHub user: $GITHUB_USERNAME"
fi

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
