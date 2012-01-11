#!/bin/bash
#
# Converts svn tags to git tags after using git svn to clone an svn repo
# into a git repo
#
# Credit to Jon Maddox 
# http://www.jonmaddox.com/2008/03/05/cleanly-migrate-your-subversion-repository-to-a-git-repository/ 
# and Thomas Rast 
# http://thomasrast.ch/git/git-svn-conversion.html
#

SVN_ROOT=svn://localhost/

SVN_DIR=directory-of-interest
#SVN_DIR=another-directory-that-we-also-want-to-clone

SVN_USERNAME=replace_with_valid_svn_username

# Change CONVERT_SVN_TAGS_TO_GIT_TAGS to false to skip tag conversion
CONVERT_SVN_TAGS_TO_GIT_TAGS=true
#CONVERT_SVN_TAGS_TO_GIT_TAGS=false

# Change DELETE_SPECIFIC_TAGS to false to skip tag deletion
DELETE_SPECIFIC_TAGS=true
#DELETE_SPECIFIC_TAGS=false

# If DELETE_SPECIFIC_TAGS is true, then the following list of specific tags will be deleted.
TAGS_TO_DELETE="bad_tag_1 bad_tag_2"

# Change CHECKOUT_REMOTE_BRANCHES to true in order to preserve remote branches
CHECKOUT_BRANCHES=false
#CHECKOUT_BRANCHES=true

# Create a temporary git repo to hold the first step of the conversion from SVN
cd /root/
mkdir $SVN_DIR-tmp.git/
cd $SVN_DIR-tmp.git
git svn init $SVN_ROOT/$SVN_DIR/ --stdlayout --no-metadata --username $SVN_USERNAME
git config svn.authorsfile ~/svnusers.txt
git svn fetch --username $SVN_USERNAME

# Removes empty commits (from svn copy, etc.)
git filter-branch --prune-empty --tag-name-filter cat -- --all

if $CONVERT_SVN_TAGS_TO_GIT_TAGS
then
    ~/make_git_tags_for_svn_tags.sh
fi

if $DELETE_SPECIFIC_TAGS
then
    git tag -d $TAGS_TO_DELETE
fi

if $CHECKOUT_BRANCHES
then
    ~/checkout_remote_git_branches.sh
fi

# Create a "clean" clone of the temporary repo (to clear out the SVN cruft)
cd /root/
mkdir $SVN_DIR.git
git clone --no-hardlinks /root/$SVN_DIR-tmp.git/ $SVN_DIR.git/
cd $SVN_DIR.git
if $CHECKOUT_BRANCHES
then
    ~/checkout_remote_git_branches.sh
fi
