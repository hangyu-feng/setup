# Git abbreviations (matching oh-my-zsh git plugin)
# Source: https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/git/git.plugin.zsh
#
# Aliases that need the current branch or main branch at runtime are
# implemented as functions in functions/*.fish instead of abbreviations.

# Add
abbr -a g     git
abbr -a ga    git add
abbr -a gaa   git add --all
abbr -a gapa  git add --patch
abbr -a gau   git add --update
abbr -a gav   git add --verbose

# Apply
abbr -a gap   git apply
abbr -a gapt  git apply --3way

# Bisect
abbr -a gbs   git bisect
abbr -a gbsb  git bisect bad
abbr -a gbsg  git bisect good
abbr -a gbsn  git bisect new
abbr -a gbso  git bisect old
abbr -a gbsr  git bisect reset
abbr -a gbss  git bisect start

# Blame
abbr -a gbl   git blame -w

# Branch
abbr -a gb    git branch
abbr -a gba   git branch --all
abbr -a gbd   git branch --delete
abbr -a gbD   git branch --delete --force
abbr -a gbm   git branch --move
abbr -a gbnm  git branch --no-merged
abbr -a gbr   git branch --remote
# ggsup is a function (needs runtime branch name)

# Checkout
abbr -a gco   git checkout
abbr -a gcor  git checkout --recurse-submodules
abbr -a gcb   git checkout -b
abbr -a gcB   git checkout -B
# gcm/gcd are functions (detect main/develop branch at runtime)

# Cherry-pick
abbr -a gcp   git cherry-pick
abbr -a gcpa  git cherry-pick --abort
abbr -a gcpc  git cherry-pick --continue

# Clean
abbr -a gclean git clean --interactive -d

# Clone
abbr -a gcl   git clone --recurse-submodules
abbr -a gclf  git clone --recursive --shallow-submodules --filter=blob:none --also-filter-submodules

# Commit
abbr -a gc    git commit --verbose
abbr -a gc!   git commit --verbose --amend
abbr -a gcn   git commit --verbose --no-edit
abbr -a gcn!  git commit --verbose --no-edit --amend
abbr -a gca   git commit --verbose --all
abbr -a gca!  git commit --verbose --all --amend
abbr -a gcan! git commit --verbose --all --no-edit --amend
abbr -a gcam  git commit --all --message
abbr -a gcas  git commit --all --signoff
abbr -a gcasm git commit --all --signoff --message
abbr -a gcmsg git commit --message
abbr -a gcsm  git commit --signoff --message
abbr -a gcs   git commit --gpg-sign
abbr -a gcss  git commit --gpg-sign --signoff
abbr -a gcssm git commit --gpg-sign --signoff --message
abbr -a gcf   git config --list
abbr -a gcfu  git commit --fixup

# Describe
abbr -a gdct  git describe --tags (git rev-list --tags --max-count=1)

# Diff
abbr -a gd    git diff
abbr -a gdca  git diff --cached
abbr -a gdcw  git diff --cached --word-diff
abbr -a gds   git diff --staged
abbr -a gdw   git diff --word-diff
abbr -a gdup  git diff @{upstream}
abbr -a gdt   git diff-tree --no-commit-id --name-only -r

# Fetch
abbr -a gf    git fetch
abbr -a gfa   git fetch --all --tags --prune --jobs=10
abbr -a gfo   git fetch origin

# Help
abbr -a ghh   git help

# Log
abbr -a glo   git log --oneline --decorate
abbr -a glog  git log --oneline --decorate --graph
abbr -a gloga git log --oneline --decorate --graph --all
abbr -a glg   git log --stat
abbr -a glgp  git log --stat --patch
abbr -a glgg  git log --graph
abbr -a glgga git log --graph --decorate --all
abbr -a glgm  git log --graph --max-count=10
abbr -a glol  git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset'
abbr -a glols git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset' --stat
abbr -a glola git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset' --all
abbr -a glod  git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ad) %C(bold blue)<%an>%Creset'
abbr -a glods git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ad) %C(bold blue)<%an>%Creset' --date=short

# Merge
abbr -a gm    git merge
abbr -a gma   git merge --abort
abbr -a gmc   git merge --continue
abbr -a gms   git merge --squash
abbr -a gmff  git merge --ff-only
# gmom/gmum are functions (detect main branch at runtime)
abbr -a gmtl  git mergetool --no-prompt
abbr -a gmtlvim git mergetool --no-prompt --tool=vimdiff

# Pull
abbr -a gl    git pull
abbr -a gpr   git pull --rebase
abbr -a gprv  git pull --rebase -v
abbr -a gpra  git pull --rebase --autostash
abbr -a gprav git pull --rebase --autostash -v
# gprom/gpromi/gprum/gprumi are functions (detect main branch at runtime)
# ggpull/gluc/glum are functions (need runtime branch name)

# Push
abbr -a gp    git push
abbr -a gpd   git push --dry-run
abbr -a gpf   git push --force-with-lease --force-if-includes
abbr -a gpf!  git push --force
abbr -a gpv   git push --verbose
abbr -a gpoat git push origin --all; and git push origin --tags
abbr -a gpod  git push origin --delete
# gpsup/gpsupf/ggpush/gpu are functions (need runtime branch name)

# Rebase
abbr -a grb   git rebase
abbr -a grba  git rebase --abort
abbr -a grbc  git rebase --continue
abbr -a grbi  git rebase --interactive
abbr -a grbo  git rebase --onto
abbr -a grbs  git rebase --skip
# grbd/grbm/grbom/grbum are functions (detect main/develop branch at runtime)

# Reflog
abbr -a grf   git reflog

# Remote
abbr -a gr    git remote
abbr -a grv   git remote --verbose
abbr -a gra   git remote add
abbr -a grrm  git remote remove
abbr -a grmv  git remote rename
abbr -a grset git remote set-url
abbr -a grup  git remote update

# Reset
abbr -a grh   git reset
abbr -a gru   git reset --
abbr -a grhh  git reset --hard
abbr -a grhk  git reset --keep
abbr -a grhs  git reset --soft
# groh is a function (needs runtime branch name)

# Restore
abbr -a grs   git restore
abbr -a grss  git restore --source
abbr -a grst  git restore --staged

# Revert
abbr -a grev  git revert
abbr -a greva git revert --abort
abbr -a grevc git revert --continue

# Remove
abbr -a grm   git rm
abbr -a grmc  git rm --cached

# Shortlog
abbr -a gcount git shortlog --summary --numbered

# Show
abbr -a gsh   git show
abbr -a gsps  git show --pretty=short --show-signature

# Stash
abbr -a gsta  git stash push
abbr -a gstaa git stash apply
abbr -a gstall git stash --all
abbr -a gstc  git stash clear
abbr -a gstd  git stash drop
abbr -a gstl  git stash list
abbr -a gstp  git stash pop
abbr -a gsts  git stash show --patch

# Status
abbr -a gst   git status
abbr -a gss   git status --short
abbr -a gsb   git status --short --branch

# Submodule
abbr -a gsi   git submodule init
abbr -a gsu   git submodule update

# Switch
abbr -a gsw   git switch
abbr -a gswc  git switch --create
# gswm/gswd are functions (detect main/develop branch at runtime)

# Tag
abbr -a gta   git tag --annotate
abbr -a gts   git tag --sign
abbr -a gtv   git tag --sort=-v:refname

# Worktree
abbr -a gwt   git worktree
abbr -a gwta  git worktree add
abbr -a gwtls git worktree list
abbr -a gwtmv git worktree move
abbr -a gwtrm git worktree remove
