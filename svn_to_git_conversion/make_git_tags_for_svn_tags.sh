#!/bin/bash

# Change TAG_TEST to false in order to convert all tags
TAG_TEST=true
#TAG_TEST=false

git for-each-ref --format="%(refname)" refs/remotes/tags/ |
while read tag
do
    # If TAG_TEST is set to true, modify the tests in the second group to meet your 
    # specific needs
    if ( ! $TAG_TEST ) || ( [[ $tag == */2.* ]] || [[ $tag == */3.* ]] && [[ $tag != *rev* ]] )
    then
        echo "Git Tag Created: $tag"
        GIT_COMMITTER_DATE="$(git log -1 --pretty=format:"%ad" "$tag")" \
        GIT_COMMITTER_EMAIL="$(git log -1 --pretty=format:"%ce" "$tag")" \
        GIT_COMMITTER_NAME="$(git log -1 --pretty=format:"%cn" "$tag")" \
        git tag -m "$(git for-each-ref --format="%(contents)" "$tag")" \
            ${tag#refs/remotes/tags/} "$tag"
    else
        echo "SVN Tag skipped: $tag"
    fi
done
