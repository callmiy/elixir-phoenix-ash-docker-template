#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
  echo -e "${GREEN}$1${NC}"
}

print_warning() {
  echo -e "${YELLOW}$1${NC}"
}

print_error() {
  echo -e "${RED}$1${NC}"
}

# Function to validate app name (lowercase, alphanumeric with underscores)
validate_app_name() {
  local name=$1
  if [[ $name =~ ^[a-z][a-z0-9_]*$ ]]; then
    return 0
  else
    return 1
  fi
}

# Function to validate module name (CamelCase, starts with capital)
validate_module_name() {
  local name=$1
  if [[ $name =~ ^[A-Z][a-zA-Z0-9]*$ ]]; then
    return 0
  else
    return 1
  fi
}

# Function to convert snake_case to CamelCase
snake_to_camel() {
  local input=$1
  echo "$input" | awk -F_ '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)}1' OFS=""
}

# Function to convert snake_case to kebab-case
snake_to_kebab() {
  local input=$1
  echo "${input//_/-}"
}

# Main script
print_info "=== Phoenix/Ash Project Bootstrap Script ==="
echo ""

# Check if we're in the right directory
if [[ ! -f "mix.exs" ]] || [[ ! -d "lib/my_app" ]]; then
  print_error "Error: This script must be run from the project root directory"
  print_error "Please ensure you're in the directory containing mix.exs and lib/my_app"
  exit 1
fi

# Get app name
while true; do
  read -rp "Enter app name (e.g., my_app): " app_name
  if [[ -z "$app_name" ]]; then
    print_error "App name cannot be empty"
    continue
  fi
  if validate_app_name "$app_name"; then
    break
  else
    print_error "Invalid app name. Must be lowercase, start with a letter, and contain only letters, numbers, and underscores"
  fi
done

# Get module name (optional)
read -rp "Enter module name (optional, press Enter to derive from app name): " module_name
if [[ -z "$module_name" ]]; then
  module_name=$(snake_to_camel "$app_name")
  print_info "Module name derived: $module_name"
else
  if ! validate_module_name "$module_name"; then
    print_error "Invalid module name. Must be CamelCase and start with a capital letter"
    exit 1
  fi
fi

# Derive kebab-case name
kebab_name=$(snake_to_kebab "$app_name")

# Generate new timestamp for log labels
new_timestamp=$(date +%s)

# Show what will be replaced
echo ""
print_info "The following replacements will be made:"
echo "  my_app    → $app_name"
echo "  MyApp     → $module_name"
echo "  my-app    → $kebab_name"
echo "  :my_app   → :$app_name"
echo "  1753272418 → $new_timestamp (log label timestamp)"
echo ""

# Confirm before proceeding
read -rp "Do you want to proceed? (y/N): " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
  print_warning "Bootstrap cancelled"
  exit 0
fi

# Create a marker file to track if bootstrap has been run
if [[ -f ".bootstrapped" ]]; then
  print_warning "Warning: It appears bootstrap has already been run on this project."
  read -rp "Do you want to continue anyway? (y/N): " force_confirm
  if [[ ! "$force_confirm" =~ ^[Yy]$ ]]; then
    print_warning "Bootstrap cancelled"
    exit 0
  fi
fi

print_info "Starting bootstrap process..."

# Function to perform replacements in a file
replace_in_file() {
  local file=$1
  local temp_file="${file}.tmp"

  # Skip binary files
  if ! file "$file" | grep -q "text"; then
    return
  fi

  # Perform replacements
  if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS sed
    sed -E \
      -e "s/my_app/${app_name}/g" \
      -e "s/MyApp/${module_name}/g" \
      -e "s/my-app/${kebab_name}/g" \
      -e "s/:my_app/:${app_name}/g" \
      -e "s/1753272418/${new_timestamp}/g" \
      "$file" >"$temp_file"
  else
    # GNU sed
    sed -E \
      -e "s/my_app/${app_name}/g" \
      -e "s/MyApp/${module_name}/g" \
      -e "s/my-app/${kebab_name}/g" \
      -e "s/:my_app/:${app_name}/g" \
      -e "s/1753272418/${new_timestamp}/g" \
      "$file" >"$temp_file"
  fi

  # Only replace if changes were made
  if ! cmp -s "$file" "$temp_file"; then
    mv "$temp_file" "$file"
    echo "  Updated: $file"
  else
    rm "$temp_file"
  fi
}

# Find and replace in all text files
print_info "Replacing in file contents..."
find . -type f \
  -not -path "./.git/*" \
  -not -path "./_build/*" \
  -not -path "./deps/*" \
  -not -path "./.elixir_ls/*" \
  -not -path "./node_modules/*" \
  -not -path "./priv/static/assets/*" \
  -not -name "*.beam" \
  -not -name "*.ez" \
  -not -name "bootstrap.sh" \
  -not -name ".bootstrapped" \
  -print0 | while IFS= read -r -d '' file; do
  replace_in_file "$file"
done

# Rename directories
print_info "Renaming directories..."
if [[ -d "lib/my_app_web" ]]; then
  mv "lib/my_app_web" "lib/${app_name}_web"
  echo "  Renamed: lib/my_app_web → lib/${app_name}_web"
fi

if [[ -d "lib/my_app" ]]; then
  mv "lib/my_app" "lib/${app_name}"
  echo "  Renamed: lib/my_app → lib/${app_name}"
fi

if [[ -d "test/my_app_web" ]]; then
  mv "test/my_app_web" "test/${app_name}_web"
  echo "  Renamed: test/my_app_web → test/${app_name}_web"
fi

if [[ -d "test/my_app" ]]; then
  mv "test/my_app" "test/${app_name}"
  echo "  Renamed: test/my_app → test/${app_name}"
fi

# Rename files containing my_app in the name
print_info "Renaming files..."
find . -type f -name "*my_app*" \
  -not -path "./.git/*" \
  -not -path "./_build/*" \
  -not -path "./deps/*" \
  -not -path "./.elixir_ls/*" \
  -print0 | while IFS= read -r -d '' file; do
  dir=$(dirname "$file")
  base=$(basename "$file")
  new_base="${base//my_app/${app_name}}"
  if [[ "$base" != "$new_base" ]]; then
    mv "$file" "$dir/$new_base"
    echo "  Renamed: $file → $dir/$new_base"
  fi
done

# Clean up template-specific files
print_info "Cleaning up template-specific files..."
files_to_remove=(
  mix.lock
  generator.sh
  .claude.ebnis.chat.md
  .git/
)

for item in "${files_to_remove[@]}"; do
  if [[ -e "$item" ]]; then
    rm -rf "$item"
    echo "  Removed: $item"
  fi
done

# Remove the .claude.ebnis.chat.md line from .gitignore
if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS sed

  # User may have gsed in path
  if ! sed -i '' '/^!\.claude\.ebnis\.chat\.md$/d' .gitignore; then
    sed -i '/^!\.claude\.ebnis\.chat\.md$/d' .gitignore || :
  fi
else
  # GNU sed
  sed -i '/^!\.claude\.ebnis\.chat\.md$/d' .gitignore || :
fi
echo "  Updated: .gitignore (removed .claude.ebnis.chat.md exception)"

# Create marker file
echo "$app_name" >.bootstrapped

# Ask if user wants to fetch dependencies and compile
fetched_deps=
echo ""
read -rp "Would you like to fetch dependencies and compile the project now? (y/N): " fetch_deps
if [[ "$fetch_deps" =~ ^[Yy]$ ]]; then
  print_info "Fetching dependencies and compiling..."

  if mix "do" deps.get + compile; then
    fetched_deps=1
  fi
fi

cp .mcp.template.json .mcp.json
cp compose.template.yaml compose.yaml

# Initialize git
git init || :

print_info ""
print_info "Bootstrap complete! 🎉"
print_info ""
print_info "Next steps:"
print_info "1. Review the changes made to your project"
print_info "2. Setup MCP configuration - see README.md"
print_info "3. Setup compose.yaml - see README.md"
print_info "4. Update any additional project-specific references if needed"

if [ -z "$fetched_deps" ]; then
  print_info "5. To fetch dependencies and compile later, run:"
  print_info "   mix do deps.get + compile"
fi

print_info ""
print_info "Your project is now configured as:"
print_info "  App name: $app_name"
print_info "  Module name: $module_name"
print_info ""
