if status is-interactive
    set -gx PATH (uv tool dir --bin) $PATH
    set -l ripgrep_config_dir (dirname (path resolve (status --current-filename)))
    set -gx RIPGREP_CONFIG_PATH (path normalize "$ripgrep_config_dir/../../ripgreprc")
end
