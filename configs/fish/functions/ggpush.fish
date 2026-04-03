function ggpush --description "git push origin <current branch>"
    git push origin (git branch --show-current)
end
