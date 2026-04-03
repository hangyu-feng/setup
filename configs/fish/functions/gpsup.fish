function gpsup --description "git push --set-upstream origin <current branch>"
    git push --set-upstream origin (git branch --show-current)
end
