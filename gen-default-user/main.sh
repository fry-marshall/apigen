current_dir="$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )"

chmod +x "$current_dir/gen-models.sh"
chmod +x "$current_dir/gen-services.sh"
chmod +x "$current_dir/gen-controllers.sh"
chmod +x "$current_dir/gen-routes.sh"
chmod +x "$current_dir/gen-tests.sh"

source "$current_dir/gen-models.sh"
source "$current_dir/gen-services.sh"
source "$current_dir/gen-controllers.sh"
source "$current_dir/gen-routes.sh"
source "$current_dir/gen-tests.sh"