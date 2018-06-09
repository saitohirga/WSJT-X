Boost "vendor" repo for K1JT projects
=====================================

This repository contains a subset of the Boost project with libraries
needed by K1JT project s such as WSJT-X. It contains two branches,
upstream and master. To upgrade the content do the following:

```bash
git checkout upstream
rm -r *
# use the bcp tool to populate with the new Boost libraries
git commit -a -m "Updated Boost v1.63 libraries including ..."
git tag boost_1_63
git push origin
git checkout master
git merge upstream
git push origin
```

The resulting master branch is now ready to be git-subtree merged into
any projects that need these libraries.