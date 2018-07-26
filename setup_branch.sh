#!/bin/bash

set -eux

git config svn-remote.$1.url svn+ssh://YOUR_SVN_REPO_ROOT_HERE/branches/$1
git config svn-remote.$1.fetch ":refs/remotes/svn/$1"
git svn fetch -A ../authors.txt --log-window-size=5000 $1
git checkout --track svn/$1
git lfs install
git lfs track '*.gz' '*.xz' '*.rdf'
# NOTE: git-lfs doesn't want to write back to anything under refs/remotes, and won't do anything without --include-ref
git lfs migrate import --include='*.gz,*.xz,*.rdf' --skip-fetch --include-ref=refs/heads/$1
git update-ref refs/remotes/svn/$1 $(git show-ref -s refs/heads/$1)
git reflog expire --expire-unreachable=now --all
git gc --prune=now
git branch -D master || true
$(dirname $(readlink -f $0))/update_rev_map.py $1 "$(git show-ref -s refs/heads/$1)"
git diff --exit-code # Make sure working tree is clean, otherwise LFS could be broken
git diff --cached --exit-code # Make sure index is good, otherwise we would be copying a bad index into git-svn
mv .git/svn/refs/remotes/svn/$1/index .git/svn/refs/remotes/svn/$1/index_backup
cp .git/index .git/svn/refs/remotes/svn/$1/index
