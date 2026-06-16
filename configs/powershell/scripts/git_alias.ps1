# Here are some git aliases I borrowed from oh-my-zsh's git plugin:
# https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/git

set-alias -name g -value git

function current_branch { git rev-parse --abbrev-ref HEAD $args }
set-alias -name git_current_branch -value current_branch
function ga { git add $args }
function gaa { git add --all $args }
function gav { git add --verbose $args }
function gb { git branch $args }
function gc { git commit -v $args }
function gc! {  git commit --amend $args }
function gcam { git commit -a -m $args }
function gcb { git checkout -b $args }
function gcf { git config --list $args }
function gcm { git checkout master $args }
function gco { git checkout $args }
function gcp { git cherry-pick $args }
function gcpa {	git cherry-pick --abort $args }
function gcpc {	git cherry-pick --continue $args }
function gd { git diff $args }
function gf { git fetch $args }
function gfa { git fetch --all --prune $args }
function ggu { git pull --rebase origin $(current_branch) $args }
function gpsup { git push --set-upstream origin $(current_branch) $args }
function gpull { git pull $args }
function gm { git merge $args }
function gmom { git merge origin/master $args }
function gma { git merge --abort $args }
function gp { git push $args }
function grh { git reset $args }
function grhh { git reset --hard $args }
function grs { git restore $args }
function gst { git status $args }
function gstc { git stash clear $args }
function gstd { git stash drop $args }
function gstl { git stash list $args }
function gstp { git stash pop $args }
