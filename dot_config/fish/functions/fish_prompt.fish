function fish_prompt --description 'Write out the prompt'
    # 1. Get last directory component
    set -l last_dir (basename "$PWD")

    # 2. Get git status (e.g., (main))
    set -l git_status (fish_vcs_prompt)

    # 3. Determine prompt symbol
    set -l prompt_symbol '#'
    if not test (id -u) -eq 0
        set prompt_symbol '$'
    end

    # 4. Print: last_dir git_status prompt_symbol
    echo -n -s $last_dir " " $git_status " " $prompt_symbol " "
end
