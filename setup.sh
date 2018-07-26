#!/bin/bash

set -eux

svn log -q svn+ssh://YOUR_SVN_REPO_ROOT_HERE | awk -F '|' '/^r/ {sub("^ ", "", $2); sub(" $", "", $2); print $2" = "$2" <"$2">"}' | sort -u > ../authors.txt

git svn init --no-minimize-url svn+ssh://YOUR_SVN_REPO_ROOT_HERE --prefix=svn/
git config user.email 'user@company.com'
git config user.name Name
git config svn.brokenSymlinkWorkaround false
# Background garbage collection can break git-lfs-migrate which runs almost immediately after git-svn fetch.
git config --bool gc.autoDetach false
git lfs install
git lfs track '*.gz' '*.xz' '*.rdf'

# We create a fake remote "svn" so we can track the branches created by git-svn in "refs/remotes/svn/"
# (Tracking doesn't change merging; just makes "git status" nice to use for each branch)
git remote add svn /dev/null

$(dirname $(readlink -f $0))/setup_branch.sh 'branch_1'
$(dirname $(readlink -f $0))/setup_branch.sh 'branch_2'
$(dirname $(readlink -f $0))/setup_branch.sh 'branch_3'
$(dirname $(readlink -f $0))/setup_branch.sh 'branch_4'
$(dirname $(readlink -f $0))/setup_branch.sh 'branch_trunk'
$(dirname $(readlink -f $0))/setup_branch.sh 'branch_5'
$(dirname $(readlink -f $0))/setup_branch.sh 'branch_6'
$(dirname $(readlink -f $0))/setup_branch.sh 'branch_7'

git checkout -b master svn/branch_trunk
git branch -d branch_trunk
