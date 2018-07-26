# SVN to git migration tools

**I am not maintaining this code**. If you want to submit PRs or fork this code, feel free to do so. I will not implement feature requests.

This repo contains the tools for migrating any SVN repo to git (it was assumed GitHub, but any LFS-capable server will work).

The latest status of the code for incremental svn updates in git is in commit `Final attempt at updating git with new svn changes` (hash `83b6b8e14da3a9eea7b19d2c9512b7235662765d`).

## Usage

Run `update_all.sh` from a directory to contain the git repository.

**NOTE**: If `git svn init` fails due to a missing function in a shared object, run update_all.sh after entering the shell created by running `ssh-agent bash`

`update_all.sh` will always assume that it is re-exporting the repository from scratch. It was supposed to also support incremental updates in commit `83b6b8e14da3a9eea7b19d2c9512b7235662765d`.

## License

Public domain. This code is too small and too hacky to be worth being credited for.
