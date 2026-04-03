function gpsupf --description "git push --set-upstream origin <current branch> --force-with-lease"
    git push --set-upstream origin (git branch --show-current) --force-with-lease --force-if-includes
end
