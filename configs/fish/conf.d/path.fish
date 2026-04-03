if status is-interactive
    export PATH="$(uv tool dir --bin):$PATH"
    export RIPGREP_CONFIG_PATH=$HOME/codes/setup/configs/ripgreprc
end
