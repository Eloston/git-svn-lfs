#!/bin/bash

set -eux

# Update (and also initialize) the git repo with major SVN branches

if [ ! -s '../authors.txt' ]; then
	svn log -q svn+ssh://YOUR_SVN_REPO_ROOT_HERE | awk -F '|' '/^r/ {sub("^ ", "", $2); sub(" $", "", $2); print $2" = "$2" <"$2">"}' | sort -u > ../authors.txt
fi

if [ ! -s '../authors.txt' ]; then
	echo 'ERROR: Failed to download authors.txt'
	exit 1
fi

INITIAL=0
if ! git config svn-remote.svn.fetch > /dev/null; then
	git svn init svn+ssh://YOUR_SVN_REPO_ROOT_HERE --no-minimize-url --prefix=svn/ --trunk=branches/branch_trunk
	INITIAL=1
fi
git config user.email 'user@company.com'
git config user.name Name
git config svn.brokenSymlinkWorkaround false
# Background garbage collection can break git-lfs-migrate which runs almost immediately after git-svn fetch.
git config --bool gc.autoDetach false
git lfs install

# We create a fake remote "svn" so we can track the branches created by git-svn in "refs/remotes/svn/"
# (Tracking doesn't change merging; just makes "git status" nice to use for each branch)
if ! git config remote.svn.url > /dev/null; then
	git remote add svn /dev/null
fi

# Fetch all SVN changes into refs/remotes/svn (on subsequent invocations, update the refs)
git config svn-remote.svn.branches 'branches/rel/{branch_1,branch_2,branch_3,branch_4,branch_5,branch_6,branch_7,branch_8}:refs/remotes/svn/*'
if [ $INITIAL ]; then
	git svn fetch -A ../authors.txt -r 98753:HEAD --log-window-size=5000 | tee ../migration.log
else
	git svn fetch -A ../authors.txt --log-window-size=5000 | tee ../migration.log
fi

TARGET_BR=master $(dirname $(readlink -f $0))/get_local_branch.sh branch_trunk
$(dirname $(readlink -f $0))/get_local_branch.sh branch_1
$(dirname $(readlink -f $0))/get_local_branch.sh branch_2
$(dirname $(readlink -f $0))/get_local_branch.sh branch_3
$(dirname $(readlink -f $0))/get_local_branch.sh branch_4
$(dirname $(readlink -f $0))/get_local_branch.sh branch_5
$(dirname $(readlink -f $0))/get_local_branch.sh branch_6
$(dirname $(readlink -f $0))/get_local_branch.sh branch_7
$(dirname $(readlink -f $0))/get_local_branch.sh branch_8

git lfs migrate import --include='*.gz,*.xz,*.rdf,*.db' --skip-fetch --everything

TARGET_BR=master $(dirname $(readlink -f $0))/process_lfs.sh branch_trunk
$(dirname $(readlink -f $0))/process_lfs.sh branch_1
$(dirname $(readlink -f $0))/process_lfs.sh branch_2
$(dirname $(readlink -f $0))/process_lfs.sh branch_3
$(dirname $(readlink -f $0))/process_lfs.sh branch_4
$(dirname $(readlink -f $0))/process_lfs.sh branch_5
$(dirname $(readlink -f $0))/process_lfs.sh branch_6
$(dirname $(readlink -f $0))/process_lfs.sh branch_7
$(dirname $(readlink -f $0))/process_lfs.sh branch_8

# Erase old pre-LFS tree, if present
git reflog expire --expire-unreachable=now --all
git gc --prune=now

# Use the .gitattributes generated here and checkin to SVN
#git lfs track '*.gz' '*.xz' '*.rdf' '*.db'
