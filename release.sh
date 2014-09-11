#!/bin/bash

# Script to make a dated release of the Media Capture and Streams spec.
# 
# Prerequisites: You must have a remote called "origin" that points to the
# github repo. You must have local branches called "master" and "gh-pages".
#
# Run this script to create a release when work has been done on the "master"
# branch and it's ahead of your local "gh-pages" branch (as well as
# "origin/master" and "origin/gh-pages").
#
# How to use:
#
# 1. Prepare the release (previous release date before the new one)
#    $ ./release.sh 20140817 20140909 prepare
#
# 2. Browse to the getusermedia.html source file and press Ctrl+Alt+Shift+s
#    to show the respec save dialog. Click the "Save as HTML" option and save
#    the resulting document at the location proposed this script.
#
# 3. Continue the release (change last script argument)
#    $ ./release.sh 20140817 20140909 continue
#
# 4. Take a look at the repo with, e.g., "gitk --all". The branches gh-pages
#    and master should be at the top of the tree along with a new tag. The
#    remote branches should be lagging behind.
#
# 5. Push the new release to github
#    $ ./release.sh 20140817 20140909 push
#
# Done.
#
# If you made a release, pushed it to the github repo and notice that you missed
# something that requires extra commits to fix. Then, after you fixed the issue
# and pushed the fixes, run this script with the "retag" option to move the
# release tag to point to the new top of the tree. Example:
# $ ./release.sh 20140817 20140909 retag
#

# Source and repository settings
REPO_NAME="mediacapture-main"
SRC_NAME="getusermedia.html"
CONFIG_NAME="getusermedia.js"

PREV_DATE=$1
NEW_DATE=$2
STAGE=$3

USAGE="\n\nUsage: $0 <prev-date> <new-date> prepare|continue|push|retag\n\
For example: $0 20140817 20140909 prepare"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TAG_NAME="v$NEW_DATE"

pushd $DIR > /dev/null

function quit {
  popd > /dev/null
  exit $1
}

function check {
  if [ $? != 0 ] ; then
    echo "* $1: Failed (!)"
    quit 1
  fi
  echo "* $1: Done"
}

if [ $# -lt 3 ] ; then
  echo -e "Too few arguments. $USAGE"
  quit 1
fi

BRANCH=$(git symbolic-ref --short HEAD)
if [ $BRANCH != "master" ] ; then
  echo "You should be on the (local) master branch to do a release (you are on $BRANCH)"
  quit 1
fi

case $STAGE in
  prepare)
    echo "*** Prepare ***"

    sed -i "s/prevED:.*$/prevED: \"http:\/\/w3c.github.io\/$REPO_NAME\/archives\/$PREV_DATE\/$SRC_NAME\",/" $CONFIG_NAME
    check "Update prevED field in respec config"

    mkdir -p archives/$NEW_DATE
    check "Create new archive dir"

    echo "Do the Ctrl+Alt+Shift+s thing in Rspec.js and save the generated version as: "
    echo "$DIR/archives/$NEW_DATE/$SRC_NAME"
    echo -e "\nWhen the generated version is saved, run:"
    echo "$0 $PREV_DATE $NEW_DATE continue"
    ;;

  continue)
    echo "*** Continue ***"

    if [ ! -f $DIR/archives/$NEW_DATE/$SRC_NAME ] ; then
      echo "Unable to find archives/$NEW_DATE/$SRC_NAME"
      echo "Please refer to the previous step (prepare)."
      exit 1
    fi

    cp -r images archives/$NEW_DATE/
    check "Copy image resources"

    git add archives/$NEW_DATE
    check "Add new archive directory"

    ln -s -f archives/$NEW_DATE/$SRC_NAME index.html
    check "Create index.html sym-link"

    git commit -am "Added dated version $TAG_NAME"
    check "Make commit"

    git tag -m "Editor's draft $NEW_DATE." $TAG_NAME
    check "Add tag"

    git rebase master gh-pages
    check "Rebase gh-pages on master"

    git checkout master
    check "Checkout master again (after rebase)"

    echo -e "\nPlease review the state of your repo. If everything looks OK, run:"
    echo "$0 $PREV_DATE $NEW_DATE push"
    ;;

  push)
    if [ ! -d $DIR/archives/$NEW_DATE ] ; then
      echo "Unable to find archives/$NEW_DATE"
      echo "Have you done the \"prepare\" and \"continue\" steps before \"push\"?"
      exit 1
    fi

    echo "*** Push ***"
    git push --dry-run origin master gh-pages :refs/tags/$TAG_NAME
    check "Push branches and tag"
    ;;

  retag)
    echo "*** Retag ***"
    git tag -d $TAG_NAME
    check "Remove local tag"

    git tag -m "Editor's draft $NEW_DATE." $TAG_NAME
    check "Add new tag at master's position"

    git push origin :refs/tags/$TAG_NAME
    check "Push new tag"
    ;;

  *)
    echo -e "Unknown option. $USAGE"
    quit 1
esac

echo "*** Done ***"

quit 0