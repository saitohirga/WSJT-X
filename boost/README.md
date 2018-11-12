Boost "vendor" repo for K1JT projects
=====================================

This repository contains a subset of the Boost project with libraries
needed by K1JT project s such as WSJT-X. It contains two branches,
upstream and master. To upgrade the content do the following:

```bash
git checkout upstream
rm -r *
# use the bcp tool to populate with the new Boost libraries
# use git add to stage any new files and directories
git commit -a -m "Updated Boost v1.63 libraries including ..."
git tag boost_1_63
git push origin
git checkout master
git merge upstream
git push origin
```

The resulting master branch is now ready to be git-subtree merged into
any projects that need these libraries.

This is imported here using git-subtree
---------------------------------------

To update this tree when the upstream Boost libraries are updated use
git-subtree-pull to import the changes like this:

```bash
git remote add  -f boost git@bitbucket.org:g4wjs/boost.git # for convienence
git subtree pull --prefix boost boost master --squash
```