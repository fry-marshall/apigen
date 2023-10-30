current_dir="$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )"

chmod +x "$current_dir/model.sh"
chmod +x "$current_dir/service.sh"
chmod +x "$current_dir/controller.sh"
chmod +x "$current_dir/route.sh"
chmod +x "$current_dir/config.sh"

source "$current_dir/model.sh"
source "$current_dir/service.sh"
source "$current_dir/controller.sh"
source "$current_dir/route.sh"
source "$current_dir/config.sh"
source "$current_dir/test.sh"

echo "Model generate succesfully :)"