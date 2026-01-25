
# Some other aliases
function scst { scoop update; scoop status }

function rename-ext {
  $ext = $args[0]
  $offset = $args[1]
  foreach ($file in (Get-ChildItem *.$ext)) {
    Rename-Item -Path $file -NewName $file.Name.SubString($offset)
  }
}

Set-Alias -Name vi -Value vim

Set-Alias -Name which -Value Get-Command

Set-Alias -Name python2 -Value "C:\Python27\python.exe"
Set-Alias -Name py2 -Value "C:\Python27\python.exe"

Set-Alias -Name emulator -Value "C:\Users\VailG\AppData\Local\Android\Sdk\emulator\emulator.exe"
Set-Alias -Name adb -Value "C:\Users\VailG\AppData\Local\Android\Sdk\platform-tools\adb.exe"
Set-Alias -Name mail -Value "Send-MailMessage"
Set-Alias -Name rcon -Value "C:\Users\VailG\rcon-0.10.3-win64\rcon.exe"
function defpy {
  if (Test-Path -Path ~/def_env) {
    ~/def_env/Scripts/activate.ps1
  }
}

function conda-activate($conda_env = "C:\Users\VailG\miniconda3") {
  pwsh -ExecutionPolicy ByPass -NoExit -Command "& 'C:\Users\VailG\miniconda3\shell\condabin\conda-hook.ps1' ; conda activate ${conda_env} ; Set-PoshPrompt pure "
}

function ffmpeg-download($url, $origin, $referer, $outpath) {
  $userAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:87.0) Gecko/20100101 Firefox/87.0"
  ffmpeg -user_agent $userAgent -headers "origin:${origin}" -headers "referer:${referer}" -protocol_whitelist file, http, https, tcp, tls, crypto -i $url -c copy $outpath
}

function networth($buyback) {
  ($buyback - 200) * 13
}

function nvenc() {
  foreach ($arg in $args) {
    foreach ($filename in $arg) {
      if (Test-Path $filename) {
        $file = (Get-Item $filename)
        $dirName = $file.DirectoryName
        $baseName = $file.BaseName
        $outpath = "${dirName}\nvenc-${baseName}.mp4"
        ffmpeg -i $filename -vcodec hevc_nvenc $outPath
      }
    }
  }
}

function leetcode() {
  # convert leetcode title to filename
  $trimmed = "$args".trim()
  $textinfo = (get-culture).textinfo
  $left = $trimmed.split(' ')
  $result = ""
  foreach ($word in $left) {
    $result += $textinfo.totitlecase($word)
  }
  $result = "./algorithms/${result}.py"

  code $result
  # set-clipboard -Value $result
  # return $result
}

function remove-duplicate() {
  ls * -recurse | get-filehash | group -property hash | where { $_.count -gt 1 } | % { $_.group | select -skip 1 } | del
}

function rgf() {
  rg --files | rg --smart-case ${args}
}

function sendkeys([int]${sleeptime} = 1, [string]${key} = ' ') {
  echo "Press Ctrl-c to stop"
  $wshell = New-Object -ComObject wscript.shell;
  while ($true) {
    # $wshell.AppActivate('title of the application window')
    Sleep ${sleeptime}
    $wshell.SendKeys(${key})
  }
}

function phone() {
  scrcpy --max-size 1200 -b 16M --turn-screen-off --stay-awake
}

function scribd() {
  foreach ($arg in $args) {
    echo "https://www.scribd.com/embeds/${arg}/content"
  }
}
function refresh-path {
  $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") +
    ";" +
    [System.Environment]::GetEnvironmentVariable("Path","User")
}
