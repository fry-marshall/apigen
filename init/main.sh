current_dir="$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )"

chmod +x "$current_dir/init-folders.sh"
chmod +x "$current_dir/init-files/root-files.sh"
chmod +x "$current_dir/init-files/src-files.sh"

source "$current_dir/init-folders.sh"
source "$current_dir/init-files/root-files.sh"
source "$current_dir/init-files/src-files.sh"