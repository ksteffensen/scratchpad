#!/bin/bash

git for-each-ref --format="%(refname:short)" refs/remotes/ |
while read branch
do
    if [[ $branch == *tags/* ]] || [[ $branch == trunk ]] || [[ $branch == *master* ]] || [[ $branch == *HEAD* ]]
    then
        echo "SVN Tag Skipped: $branch"
    else
        branch_name=${branch##*remotes/}
        branch_name=${branch_name##*origin/}
        echo "Git Branch Checked Out: $branch as $branch_name"
        git checkout -b $branch_name $branch
    fi
done
git checkout master
