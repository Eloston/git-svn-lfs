# SVN to git migration tools

This repo contains the tools for migrating Company SVN repos to git and GitHub.

## First time migration

Run `setup.sh` from a directory to contain the git repository.

**NOTE**: If `git svn init` fails due to a missing function in a shared object, run setup.sh after entering the shell created by running `ssh-agent bash`

## Associate with GitHub

First, add a remote for GitHub:

```sh
git remote add github git@github.com:company/git_repo.git
```

Then, temporarily change user.name and user.email to the proper settings for your GitHub account so git will properly authenticate during pushing.

Finally, push to GitHub:

```sh
git push github --all
```

## Update GitHub with new SVN changes

To update a branch like `branch_8`, run the following from inside the git repo used for SVN migration:

```sh
update_branch.sh branch_8
```

To update the branch `master` (currently `branch_trunk` in SVN), use the following commands instead:

```sh
TARGET_BR=master update_branch.sh branch_trunk
```

Finally, push all updated branches and tags to GitHub:

```sh
git push --all github
```
