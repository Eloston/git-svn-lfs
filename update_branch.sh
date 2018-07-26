#!/bin/bash

set -eux

# NOTE: This script will not resolve any discrepancies between the local git repo and the one on GitHub.

export TARGET_BR=${TARGET_BR:-$1}

git svn fetch -A ../authors.txt --log-window-size=5000 $1
git checkout $TARGET_BR
git lfs track '*.gz' '*.xz' '*.rdf'
# NOTE: git-lfs doesn't want to write back to anything under refs/remotes, and won't do anything without --include-ref
git lfs migrate import --include='*.gz,*.xz,*.rdf' --skip-fetch --include-ref=refs/heads/$1
git update-ref refs/remotes/svn/$1 $(git show-ref -s refs/heads/$1)
git reflog expire --expire-unreachable=now --all
git gc --prune=now
$(dirname $(readlink -f $0))/update_rev_map.py $1 "$(git show-ref -s refs/heads/$TARGET_BR)"