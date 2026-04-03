function groh --description "git reset --hard to origin/<current branch>"
    git reset origin/(git branch --show-current) --hard
end
