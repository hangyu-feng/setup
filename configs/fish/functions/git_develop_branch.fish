function git_develop_branch --description "Detect the develop branch name (develop or dev)"
    for ref in refs/heads/develop refs/heads/dev refs/heads/devel refs/heads/development
        if command git show-ref -q --verify $ref
            echo (string replace 'refs/heads/' '' $ref)
            return 0
        end
    end
    echo develop
end
