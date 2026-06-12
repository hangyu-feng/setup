if status is-interactive
    export PATH="$(uv tool dir --bin):$PATH"
    set -l ripgrep_config_dir (dirname (status --current-filename))
    set -gx RIPGREP_CONFIG_PATH (path normalize "$ripgrep_config_dir/../../ripgreprc")
end
