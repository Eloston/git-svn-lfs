#!/bin/bash

set -eux

# Update (and also initialize) the git repo with major SVN branches

if [ ! -f '../authors.txt' ]; then
	svn log -q svn+ssh://YOUR_SVN_REPO_ROOT_HERE | awk -F '|' '/^r/ {sub("^ ", "", $2); sub(" $", "", $2); print $2" = "$2" <"$2">"}' | sort -u > ../authors.txt
fi

if ! git config svn-remote.svn.fetch > /dev/null; then
	git svn init --no-minimize-url svn+ssh://YOUR_SVN_REPO_ROOT_HERE --prefix=svn/
fi
git config user.email 'user@company.com'
git config user.name Name
git config svn.brokenSymlinkWorkaround false
# Background garbage collection can break git-lfs-migrate which runs almost immediately after git-svn fetch.
git config --bool gc.autoDetach false
git lfs install
git lfs track '*.gz' '*.xz' '*.rdf'

# We create a fake remote "svn" so we can track the branches created by git-svn in "refs/remotes/svn/"
# (Tracking doesn't change merging; just makes "git status" nice to use for each branch)
if ! git config remote.svn.url > /dev/null; then
	git remote add svn /dev/null
fi

TARGET_BR=master $(dirname $(readlink -f $0))/update_branch.sh 'branch_trunk'
$(dirname $(readlink -f $0))/update_branch.sh 'branch_1'
$(dirname $(readlink -f $0))/update_branch.sh 'branch_2'
$(dirname $(readlink -f $0))/update_branch.sh 'branch_3'
$(dirname $(readlink -f $0))/update_branch.sh 'branch_4'
$(dirname $(readlink -f $0))/update_branch.sh 'branch_5'
$(dirname $(readlink -f $0))/update_branch.sh 'branch_6'
$(dirname $(readlink -f $0))/update_branch.sh 'branch_7'
