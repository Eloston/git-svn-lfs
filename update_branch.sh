#!/bin/bash

set -eux

# NOTE: This script will not resolve any discrepancies between the local git repo and the one on GitHub.

export TARGET_BR=${TARGET_BR:-$1}

# Update pseudo "svn" remote with new SVN changes
git svn fetch -A ../authors.txt --log-window-size=5000 $1

# Update local branch with new SVN changes from pseudo "svn" remote
git checkout $TARGET_BR
git merge --ff-only svn/$1

git lfs track '*.gz' '*.xz' '*.rdf'
# NOTE: git-lfs doesn't want to write back to anything under refs/remotes, and won't do anything without --include-ref
# So, we update the local branch under refs/heads and update the ref under refs/remotes so git-svn can use it
git lfs migrate import --include='*.gz,*.xz,*.rdf' --skip-fetch --include-ref=refs/heads/$TARGET_BR

# Update pseudo "svn" remote so git-svn will use it for updates
git update-ref refs/remotes/svn/$1 $(git show-ref -s refs/heads/$TARGET_BR)

# Erase old pre-LFS tree, if present
git reflog expire --expire-unreachable=now --all
git gc --prune=now

# Update internal state of git-svn due to history rewriting by git-lfs
$(dirname $(readlink -f $0))/update_rev_map.py $1 "$(git show-ref -s refs/heads/$TARGET_BR)"
git diff --exit-code # Make sure working tree is clean, otherwise LFS could be broken
git diff --cached --exit-code # Make sure index is good, otherwise we would be copying a bad index into git-svn
mv .git/svn/refs/remotes/svn/$1/index .git/svn/refs/remotes/svn/$1/index_backup
cp .git/index .git/svn/refs/remotes/svn/$1/index
