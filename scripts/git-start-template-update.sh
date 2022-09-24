#!/bin/bash

REPO_CONFIG_FILE=".repo.config"
DEFAULT_TEMPLATE_REMOTE_NAME="template"
DEFAULT_TEMPLATE_REMOTE_BRANCH="main"
DEFAULT_LOCAL_STAGING_BRANCH="chore/template-update"
default_merge_branch=$(git branch --show-current)

template_remote_name=${1:-$DEFAULT_TEMPLATE_REMOTE_NAME}
template_remote_branch=${2:-$DEFAULT_TEMPLATE_REMOTE_BRANCH}
local_staging_branch=${3:-$DEFAULT_LOCAL_STAGING_BRANCH}
merge_branch=${4:-$default_merge_branch}

template_ref="$template_remote_name/$template_remote_branch"

if [ "$1" == "--help" ] || [ "$1" == "-h" ];
then
  cat << EOF
Git template update
template-update.sh [...params]

Params in order (all optional):
  <template_remote_name>    Remote repository that hosts the template.
                            Default: $DEFAULT_TEMPLATE_REMOTE_NAME
  <template_remote_branch>  Remote branch that shall be used as the template
                            Default: $DEFAULT_TEMPLATE_REMOTE_BRANCH
  <local_staging_branch>    Local branch to be created for the template update
                            Default: $DEFAULT_LOCAL_STAGING_BRANCH
  <merge_branch>            The branch on which the changes shall be staged. 
                            Default: the current branch from which the script 
                            is called, currently: $default_merge_branch

This script uses '$template_ref' to create a new local branch named
'$local_staging_branch'. Script will terminate when it merges
all template changes on top of local branch '$merge_branch'.

EOF
  exit 0
fi

if [[ "$(git remote)" != *"$template_remote_name"* ]];
then
  echo "Error: Remote '$template_remote_name' not found among remotes."
  exit 1
fi

if [[ $(git branch) == *"$local_staging_branch"* ]];
then
  cat << EOF
Error: There is already a branch named '$local_staging_branch'. Either provide 
a different local branch name or delete the existing branch.
EOF
  exit 2
fi

if [[ $(git branch) != *"$merge_branch"* ]];
then
  cat << EOF
Error: There is no '$merge_branch' branch to merge upon. Please provide a branch that
already exists.
EOF
  exit 3
fi

echo "Template changes will be merged onto the branch '$merge_branch'"

git checkout -b $local_staging_branch
git fetch template

# Rewrites the last template update
if [ ! -f .repo.config ];
then
  touch $REPO_CONFIG_FILE
fi
sed -i '/TEMPLATE_LAST_UPDATE/d' $REPO_CONFIG_FILE 
current_epoch=$(date +%s)
echo "TEMPLATE_LAST_UPDATE=$current_epoch" >> $REPO_CONFIG_FILE
# --

git merge \
  --squash \
  --allow-unrelated-histories \
  --strategy-option theirs \
  $template_ref
git reset --mixed $merge_branch
