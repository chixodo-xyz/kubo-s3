# Kubo-s3

This builds IPFS Kubo with S3 Datastore Implementation.

## Building

- Arch Linux: PKGBUILD and version.txt provides all required informationo for `makepkg` 
- Other Linux: Take a look at `misc/build.sh`

## Commit to AUR

Commiting to AUR can be done as following:

```bash
git -c init.defaultbranch=master clone ssh://aur@aur.archlinux.org/kubo-s3-git.git 
cd kubo-s3-git/
git config user.name [Public Name]
git config user.email [Public E-Mail]
#make required modifications
namcap PKGBUILD
makepkg
namcap kubo-s3-git-*.pkg.tar.xz
sudo pacman -U kubo-s3-git-*.pkg.tar.xz
#run tests
makepkg --printsrcinfo > .SRCINFO
#verify changes, f.E. using: git status ; git diff
git add PKGBUILD .SRCINFO .gitignore versions.txt
git commit -m "useful commit message"
git push
```

Further Information:

- https://wiki.archlinux.org/title/AUR_submission_guidelines
- https://wiki.archlinux.org/title/creating_packages


## Credits

- IPFS Kubo: https://github.com/ipfs/kubo
- S3 Datastore Implementation: https://github.com/ipfs/go-ds-s3/