#!/bin/bash

set -eux

# Handles LFS on local and remote branches

# NOTE: This script will not resolve any discrepancies between the local git repo and the one on GitHub.

export TARGET_BR=${TARGET_BR:-$1}

git checkout $TARGET_BR

# Update pseudo "svn" remote so git-svn will use it for updates
git update-ref refs/remotes/svn/$1 $(git show-ref -s refs/heads/$TARGET_BR)

# Update internal state of git-svn due to history rewriting by git-lfs
$(dirname $(readlink -f $0))/update_rev_map.py $1 "$(git show-ref -s refs/heads/$TARGET_BR)"
git diff --exit-code # Make sure working tree is clean, otherwise LFS could be broken
git diff --cached --exit-code # Make sure index is good, otherwise we would be copying a bad index into git-svn
mv .git/svn/refs/remotes/svn/$1/index .git/svn/refs/remotes/svn/$1/index_backup
cp .git/index .git/svn/refs/remotes/svn/$1/index
