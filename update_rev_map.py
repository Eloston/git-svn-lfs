#!/usr/bin/env python36
# -*- coding: UTF-8 -*-

"""
Script to update the SHA-1 hash inside git-svn rev_map files for Company's git_repo repository.

rev_map format: https://github.com/git/git/blob/v2.18.0/perl/Git/SVN.pm#L2184
"""

# error for reference:
# + git svn fetch -A ../authors.txt --log-window-size=5000 branch_trunk
# fatal: Invalid revision range SHA1_HASH_HERE..refs/remotes/svn/branch_trunk
# rev-list --pretty=raw --reverse SHA1_HASH_HERE..refs/remotes/svn/branch_trunk --: command returned error: 128

import argparse
import random
import re
import string
import struct
import subprocess
from pathlib import Path

_REVMAP_STRUCT = struct.Struct('>I20s')
_SHA1_REGEX = re.compile(r'([a-f0-9]){40}')
_GIT_SVN_ID_REGEX = re.compile(
    r'git-svn-id: svn\+ssh://YOUR_SVN_REPO_ROOT_HERE/branches/(.+?)@([0-9]+?) ([a-z0-9]{8}-(?:[a-z0-9]{4}-){3}[a-z0-9]{12})')

def get_stdout(*args):
    """Runs the subprocess and returns the stdout as a string"""
    result = subprocess.run(args, stdout=subprocess.PIPE, universal_newlines=True)
    result.check_returncode()
    return result.stdout

def find_revmap_by_branch(branch_name):
    """
    Returns a pathlib.Path to the rev_map file
    """
    revmap_dir = Path('.git/svn/refs/remotes/svn/', branch_name)
    revmap_iter = iter(revmap_dir.glob('.rev_map.*'))
    try:
        revmap_file = next(revmap_iter)
    except StopIteration:
        raise FileNotFoundError('No revmap files found for %s' % branch_name)
    try:
        next(revmap_iter)
        raise ValueError('Found more than one revmap file')
    except StopIteration:
        pass
    return revmap_file

def parse_revmap(revmap_path):
    """
    Parse rev_map into a list of tuples, where each tuple contains the revision
        and the string hash
    """
    padding_commit = '0'*40
    entries = list(map(
        lambda x: (x[0], x[1].hex()),
        _REVMAP_STRUCT.iter_unpack(revmap_path.read_bytes())
    ))
    last_revision = 0
    for revision, commit_hash in entries:
        if revision > last_revision:
            last_revision = revision
        elif commit_hash == padding_commit:
            raise NotImplementedError(
                'Padding entries are not implemented. Entries: %s' % entries)
        else:
            raise ValueError(
                'Revision "%s" in revmap found after lower revision "%s"' % (
                    revision, last_revision))
    return entries

def parse_git(commit_hash, expected_branch, expected_uuid):
    """
    Returns a tuple containing the revision number and corresponding hash for
    the entire branch given by commit_hash. Uses "git log" to get the info.
    The list

    Aborts if expected_branch and expected_uuid don't match the git log.
    """
    magic_prefix = '__svngitupdater_{}_'.format(random.choice(string.ascii_letters))

    entries = list()

    # Either a SHA-1 hash hex string, or None to indicate we are searching for it
    current_hash = None

    raw_log = get_stdout('git', 'log', '--pretty={}%H%n%B'.format(magic_prefix), commit_hash)
    for line in raw_log.splitlines():
        line = line.strip()
        if not line:
            continue # Ignore blank lines
        elif line.startswith(magic_prefix):
            if current_hash:
                raise ValueError('Could not find git-svn-id line for hash: {}'.format(current_hash))
            else:
                current_hash = line.replace(magic_prefix, '')
                if not _SHA1_REGEX.fullmatch(current_hash):
                    raise ValueError(
                        'Expected SHA-1 hash after magic prefix, got: {}'.format(current_hash))
        elif current_hash:
            match = _GIT_SVN_ID_REGEX.fullmatch(line)
            if match:
                branch_name, revision, branch_uuid = match.groups()
                revision = int(revision)
                if branch_name != expected_branch:
                    raise ValueError(
                        'Branch name "{}" does not match expected "{}"'.format(
                            branch_name, expected_branch))
                if branch_uuid != expected_uuid:
                    raise ValueError(
                        'UUID "{}" does not match expected "{}"'.format(branch_uuid, expected_uuid))
                if entries and revision >= entries[-1][0]:
                    raise ValueError(
                        ('Revision {} for hash {} should be lower than '
                         'revision {} for hash {}').format(
                             revision, current_hash, *entries[-1]))
                entries.append((revision, current_hash))
                current_hash = None
        else:
            raise ValueError(
                ('git log parser has no current_hash and '
                 'did not find magic prefix for line "{}"').format(line))
    if not entries:
        raise ValueError('Could not find any entries from git log. Content: {}'.format(raw_log))
    entries.reverse()
    return entries

def verify_revmap_git_consistency(revmap_entries, git_entries):
    """
    Validate that the sequence of revisions in the revmap and git are the same.
    """
    git_entry_iter = iter(git_entries)
    for revmap_rev, _ in revmap_entries:
        try:
            git_rev, git_hash = next(git_entry_iter)
        except StopIteration:
            raise ValueError(
                'Fewer git entries than revmap entries. Stopped at revision {}'.format(revmap_rev))
        if revmap_rev != git_rev:
            raise ValueError(
                ('Revision ordering inconsistent: revmap revision {} does not '
                 'match revision {} for git commit {}').format(
                     revmap_rev, git_rev, git_hash))

def main():
    """CLI entrypoint"""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('branch', help='The git-svn branch name for the corresponding revmap that will be modified')
    parser.add_argument('new_hash', help='The commit hash of the new post-LFS branch to use')
    args = parser.parse_args()

    revmap_path = find_revmap_by_branch(args.branch)

    revmap_entries = parse_revmap(revmap_path)
    git_entries = parse_git(args.new_hash, args.branch, revmap_path.suffix[1:])

    verify_revmap_git_consistency(revmap_entries, git_entries)

    # Make backup of revmap file if it is not empty
    if revmap_path.stat().st_size:
        revmap_path.with_name('revmap_backup{}'.format(revmap_path.suffix)).write_bytes(
            revmap_path.read_bytes())

    # Write new revmap
    with revmap_path.open('wb') as revmap_file:
        for revision, commit_hex in git_entries:
            revmap_file.write(_REVMAP_STRUCT.pack(revision, bytes.fromhex(commit_hex)))

    print('Successfully updated revmap with commit {}'.format(args.new_hash))
    return 0

if __name__ == '__main__':
    exit(main())
