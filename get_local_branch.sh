#!/bin/bash

set -eux

# Checks out and update local branch with new SVN changes from pseudo "svn" remote

export TARGET_BR=${TARGET_BR:-$1}

git update-ref refs/heads/$TARGET_BR $(git show-ref -s refs/remotes/svn/$1)
if git rev-parse --verify $TARGET_BR; then
	git checkout $TARGET_BR
else
	git checkout -b $TARGET_BR --track svn/$1
fi
