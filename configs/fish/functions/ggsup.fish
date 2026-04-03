function ggsup --description "git branch --set-upstream-to=origin/<current branch>"
    git branch --set-upstream-to=origin/(git branch --show-current)
end
