#!/bin/bash

set -eux

# Push changes to GitHub

if ! git config remote.github.url > /dev/null; then
	git remote add github git@github.com:company/git_repo.git
fi
git config user.name Name
git config user.email user@company.com
git push --all github
