. /opt/homebrew/opt/asdf/libexec/asdf.sh
# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="agnoster"

# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
    dotenv
    git
    node
    npm
    gcloud
    aliases
    docker
    encode64
    helm
    kubectl
    kubectx
    nvm
    postgres
    react-native
    redis-cli
)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# alias function and commands
# get the top ten commands
alias topten="history | commands | sort -rn | head"
alias python="python3.10"
alias pip="pip3.10"

# delete all the runs for the repo
alias gh_delete_runs='gh run list --json databaseId -q ".[].databaseId" | xargs -I {} gh run delete {}'
alias del_runs='for run_id in $(gh run list --json databaseId -q ".[].databaseId"); do echo "Deleting run ID: $run_id"; gh run delete $run_id; done'
alias del_pycache='find . | grep -E "(__pycache__|\.pyc$)" | xargs rm -rf'
# alias gh_delete_runs='while gh run list | jq -e 'length > 0' > /dev/null; do gh run list --json databaseId -q ".[].databaseId" | xargs -I {} gh run delete {}; done'


# tree git logs
alias gitlog='git log --graph --oneline'

# Check the command history
function commands() {
  awk '{a[$2]++}END{for(i in a){print a[i] " " i}}'
}

# Check the status of a specific port
function check_port() {
    lsof -i -P | grep LISTEN | grep :$PORT
}

# To check all the listening port of the system
function listening() {
    if [ $# -eq 0 ]; then
        sudo lsof -iTCP -sTCP:LISTEN -n -P
    elif [ $# -eq 1 ]; then
        sudo lsof -iTCP -sTCP:LISTEN -n -P | grep -i --color $1
    else
        echo "Usage: listening [pattern]"
    fi
}

# Deploy the tag in github
function deploy() {
  local remote="origin"  # Specify your Git remote here
  local branch="main"   # Specify the default branch here
  local dry_run=false   # Set to true to perform a dry run (no actions taken)

  # Check if an environment name is provided as an argument
  if [ $# -ne 1 ]; then
    echo "Usage: $0 <env_name>"
    exit 1
  fi

  local env_name=$1
  local timestamp=$(date +%Y%m%d%H%M%S)
  local tag="deploy.${env_name}.${timestamp}"

  # Safety check: Confirm the environment is valid
  case "$env_name" in
    "develop" | "staging" | "prod")
      ;;
    *)
      echo "Invalid environment name. Supported environments: prod, develop, stage"
      return 1
      ;;
  esac

  # Safety check: Confirm the branch exists
  local branch_exists=$(git ls-remote --exit-code --heads $remote $branch; echo $?)

  if [ $branch_exists -ne 0 ]; then
    echo "Branch '$branch' does not exist in the remote '$remote'. Deployment aborted."
    return 1
  fi

  if [ "$dry_run" = true ]; then
    echo "Dry run mode enabled. No changes will be made."
    echo "Would have created tag: $tag"
  else
    # Create the deployment tag
    if [ "$env_name" = "prod" ]; then
      read -p "WARNING: You are about to forcefully update the 'prod' tag. Continue? (y/n): " confirm
      if [ "$confirm" != "y" ]; then
        echo "Deployment aborted."
        return 1
      fi
      tag="deploy.${env_name}"
      git tag -f $tag
      git push -f $remote $tag
      echo "Created and forcefully pushed the tag: $tag"
    else
      git tag $tag
      git push $remote $tag
      echo "Generated deployment tag: $tag"
    fi
  fi
}

# function to create a dev branch
function create-dev-branch() {
  # Check if the current branch is the develop or main branch
  current_branch=$(git rev-parse --abbrev-ref HEAD)
  
  if [ "$current_branch" === "develop" ] || [ "$current_branch" === "main" ]; then
    echo "Error: Cannot perform merge from develop or main branch"
    return 1
  fi

  # Fetch the latest changes from the remote repository
  git fetch origin

  # Switch to the develop branch
  git checkout develop
  git pull origin develop

  # Create a new branch with dev/{branch_name_timestamp}
  timestamp=$(date +%s)
  new_branch="dev/${current_branch}_${timestamp}"
  git checkout -b "$new_branch"

  # Merge the feature branch into develop
  git merge "$current_branch" # merge commit

  # Push the changes to the remote repository
  git push origin "$new_branch"

  # Switch back to the original feature branch
  git checkout "$current_branch"

  echo "Merge and branch creation successful. Switched back to $current_branch."
}

# function to change the previous author with the new author
function change_git_author() {
  OLD_EMAIL="$1"
  CORRECT_NAME="$2"
  CORRECT_EMAIL="$3"

  git filter-branch --env-filter '
  if [ "$GIT_COMMITTER_EMAIL" = "$OLD_EMAIL" ]
  then
      export GIT_COMMITTER_NAME="$CORRECT_NAME"
      export GIT_COMMITTER_EMAIL="$CORRECT_EMAIL"
  fi
  if [ "$GIT_AUTHOR_EMAIL" = "$OLD_EMAIL" ]
  then
      export GIT_AUTHOR_NAME="$CORRECT_NAME"
      export GIT_AUTHOR_EMAIL="$CORRECT_EMAIL"
  fi
  ' --tag-name-filter cat -- --branches --tags
}

# function to delete all the branch
function delete_all_branch() {
  git for-each-ref --format '%(refname:short)' refs/heads | grep -v "master\|main" | xargs git branch -D
}

export PATH="/opt/homebrew/opt/curl/bin:$PATH"

# bun completions
[ -s "/Users/bhargavdadi/.bun/_bun" ] && source "/Users/bhargavdadi/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
# Add Visual Studio Code (code)
export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
export PATH="/opt/homebrew/opt/node@18/bin:$PATH"

# pnpm
export PNPM_HOME="/Users/bhargavdadi/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
export PATH="/opt/homebrew/opt/postgresql@14/bin:$PATH"

# Function to delete git tags with a given prefix (local and/or remote)
function del_tags() { 
    local delete_local=true 
    local delete_remote=true 
    local prefix=""  

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
        --local)
            delete_remote=false
            shift
            ;;
        --remote)
            delete_local=false
            shift
            ;;
        *)
            prefix=$1
            shift
            ;;
        esac
    done

    # Check if prefix is provided
    if [ -z "$prefix" ]; then
        echo "Usage: del_tags [--local|--remote] <prefix>"
        echo "Options:"
        echo "  --local   Delete only local tags"
        echo "  --remote  Delete only remote tags"
        echo "Example: del_tags --local deploy."
        return 1
    fi

    # Check if we're in a git repository
    if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
        echo "Error: Not in a git repository"
        return 1
    fi

    # Check if origin remote exists when dealing with remote tags
    if $delete_remote; then
        if ! git remote get-url origin > /dev/null 2>&1; then
            echo "Error: No 'origin' remote found"
            return 1
        fi
    fi

    echo "Finding tags with prefix: $prefix"
    local local_count=0
    local remote_count=0

    # Get and count local tags if needed
    if $delete_local; then
        local local_tags=$(git tag -l "${prefix}*")
        local_count=$(echo "$local_tags" | grep -c "^" || echo "0")
        echo "Found $local_count local tag(s)"
    fi

    # Get and count remote tags if needed
    if $delete_remote; then
        local remote_tags=$(git ls-remote --tags origin "refs/tags/${prefix}*" | cut -f2)
        remote_count=$(echo "$remote_tags" | grep -c "^" || echo "0")
        echo "Found $remote_count remote tag(s)"
    fi

    # If no tags found, exit
    if [ $local_count -eq 0 ] && [ $remote_count -eq 0 ]; then
        echo "No tags found matching prefix: $prefix"
        return 0
    fi

    # Confirm deletion (shell-agnostic input)
    echo -n "Do you want to proceed with deletion? (y/n): "
    read confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo "Operation cancelled"
        return 0
    fi

    # Delete local tags if requested
    if $delete_local && [ $local_count -gt 0 ]; then
        echo "Deleting $local_count local tag(s)..."
        echo "$local_tags" | xargs -n 1 git tag -d
    fi

    # Delete remote tags if requested
    if $delete_remote && [ $remote_count -gt 0 ]; then
        echo "Deleting $remote_count remote tag(s)..."
        echo "$remote_tags" | sed 's#refs/tags/##' | xargs -n 1 -I {} git push origin --delete {}
    fi

    echo "Successfully completed tag deletion operation"
}

# Print system resources summary
function print_system() {
    printf "=== SYSTEM RESOURCES SUMMARY ===\n\n" && \
    top -l 1 -n 0 -S && \
    printf "\n=== DISK USAGE ===\n" && \
    df -h && \
    printf "\n=== MEMORY DETAILS ===\n" && \
    vm_stat
}


# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/bhargavdadi/.cache/lm-studio/bin"

# Added by Windsurf
export PATH="/Users/bhargavdadi/.codeium/windsurf/bin:$PATH"

# place this after nvm initialization!
autoload -U add-zsh-hook

load-nvmrc() {
  local nvmrc_path
  nvmrc_path="$(nvm_find_nvmrc)"

  if [ -n "$nvmrc_path" ]; then
    local nvmrc_node_version
    nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")

    if [ "$nvmrc_node_version" = "N/A" ]; then
      nvm install
    elif [ "$nvmrc_node_version" != "$(nvm version)" ]; then
      nvm use
    fi
  elif [ -n "$(PWD=$OLDPWD nvm_find_nvmrc)" ] && [ "$(nvm version)" != "$(nvm version default)" ]; then
    echo "Reverting to nvm default version"
    nvm use default
  fi
}

add-zsh-hook chpwd load-nvmrc
load-nvmrc

export NPM_AUTH_TOKEN=""
export PATH="/opt/homebrew/opt/go@1.21/bin:$PATH"
