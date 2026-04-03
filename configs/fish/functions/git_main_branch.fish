function git_main_branch --description "Detect the main branch name (main or master)"
    for ref in refs/heads/main refs/heads/master refs/heads/mainline refs/heads/default refs/heads/stable refs/heads/develop
        if command git show-ref -q --verify $ref
            echo (string replace 'refs/heads/' '' $ref)
            return 0
        end
    end
    echo main
end
