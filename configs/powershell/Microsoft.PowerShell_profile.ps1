# To use this profile, dot source it in $profile like this:
# . ~/setup/configs/powershell/Microsoft.PowerShell_profile.ps1

# Import-Module posh-git
# Import-Module oh-my-posh

# see https://ohmyposh.dev/

# oh-my-posh init pwsh --config "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/hotstick.minimal.omp.json" | Invoke-Expression

# oh-my-posh init pwsh --config "https://github.com/JanDeDobbeleer/oh-my-posh/raw/main/themes/material.omp.json" | Invoke-Expression

# oh-my-posh init pwsh --config "https://github.com/JanDeDobbeleer/oh-my-posh/raw/main/themes/huvix.omp.json" | Invoke-Expression
# oh-my-posh init pwsh --config "https://github.com/JanDeDobbeleer/oh-my-posh/raw/main/themes/robbyrussell.omp.json" | Invoke-Expression



# Set-PoshPrompt -Theme robbyrussel
# oh-my-posh init pwsh --config ~/setup/configs/powershell/themes/diu.omp.json | Invoke-Expression
# Set-PoshPrompt -Theme ~/setup/configs/powershell/themes/diu.omp.json  # More themes at https://github.com/JanDeDobbeleer/oh-my-posh#themes

Set-PSReadLineOption -Colors @{
  Parameter = 'Cyan'  # parameters were unreadable for Nord colorscheme
  Operator = 'Cyan'
}
Set-PSReadLineOption -PredictionSource History


. "${PSScriptRoot}/scripts/environment_variables.ps1"

. "${PSScriptRoot}/scripts/git_alias.ps1"

. "${PSScriptRoot}/scripts/aliases.ps1"

. "${PSScriptRoot}/scripts/red_dead_online.ps1"

if ((Get-Location).Provider.Name -eq 'FileSystem' -and (Get-Location).Path -eq (Resolve-Path -LiteralPath $HOME).Path) {
  defpy
}
