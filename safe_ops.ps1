<# ============================
  safe_ops.ps1  v1.0
  スマホ(iOSショートカット)→SSH→PCで安全にファイル操作するための最小コア

  対応アクション:
    - mkdir   : ディレクトリ作成
    - create  : 空ファイル作成（既存なら何もしない）
    - delete  : 削除（ファイル/ディレクトリ）
    - write   : 上書き or 追記（本文は stdin で受け取る）

  使い方例:
    # 1) ディレクトリ作成
    powershell -File "C:\code_drop\safe_ops.ps1" mkdir "notes"

    # 2) 空ファイル作成
    powershell -File "C:\code_drop\safe_ops.ps1" create "notes\test.txt"

    # 3) 上書き（stdinで本文を渡す）
    "Hello" | powershell -File "C:\code_drop\safe_ops.ps1" write "notes\test.txt" overwrite

    # 4) 追記
    " World" | powershell -File "C:\code_drop\safe_ops.ps1" write "notes\test.txt" append

    # 5) 削除
    powershell -File "C:\code_drop\safe_ops.ps1" delete "notes\test.txt"
================================ #>

param(
  [Parameter(Mandatory=$true)][ValidateSet('mkdir','create','delete','write')] [string]$Action,
  [string]$Path = "",
  # write のみ: overwrite / append
  [ValidateSet('overwrite','append')] [string]$Mode = "overwrite",
  # 上書き時の自動バックアップを有効化（.bak_YYYYMMDD-HHMMSS で保存）
  [switch]$Backup,
  # ドライラン（実際には書き込まない／削除しない）
  [switch]$DryRun,
  # ログ出力先（例: C:\code_drop\ops.log）…指定時のみ追記
  [string]$LogFile
)

# ===== 設定(要変更) =====
# この配下だけ操作を許可する（絶対パス）
$Root = "C:\Users\YOUR_NAME\Projects"
# 許可する拡張子（書き込み/作成時のみ適用・空拡張子は非許可）
$AllowedExts = @(
  ".ts",".tsx",".js",".jsx",".py",".json",".md",".txt",
  ".ps1",".psm1",".css",".html",".yml",".yaml",".toml",".ini",".sh"
)
# ========================

# ---- 共通ユーティリティ ----
function Write-Log([string]$msg) {
  $line = "[{0}] {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $msg
  if ($LogFile) { Add-Content -Path $LogFile -Value $line -Encoding UTF8 }
  Write-Output $line
}
function Fail([string]$msg) { Write-Error $msg; exit 2 }

function Get-FullPathSafe([string]$RelPath) {
  if ([string]::IsNullOrWhiteSpace($RelPath)) { return $null }
  $rootFull = [System.IO.Path]::GetFullPath($Root)
  $cand     = Join-Path $rootFull $RelPath
  $full     = [System.IO.Path]::GetFullPath($cand)

  if (-not $full.StartsWith($rootFull, [System.StringComparison]::OrdinalIgnoreCase)) {
    Fail "invalid path (escape detected): $RelPath"
  }
  return $full
}

function Ensure-AllowedExt([string]$FullPath) {
  $ext = [System.IO.Path]::GetExtension($FullPath)
  if ([string]::IsNullOrWhiteSpace($ext)) {
    Fail "extension not allowed (empty): $FullPath"
  }
  if ($AllowedExts -notcontains $ext.ToLowerInvariant()) {
    Fail "extension not allowed: $ext"
  }
}

# ---- 前提チェック ----
if (-not (Test-Path -LiteralPath $Root)) { Fail "Root does not exist: $Root" }

# 標準入力の文字化け対策（UTF-8想定）
[Console]::InputEncoding  = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$Target = $null
if ($Path) { $Target = Get-FullPathSafe -RelPath $Path }

# ---- アクション実装 ----
switch ($Action) {

  'mkdir' {
    if (-not $Target) { Fail "Path required" }
    if ($DryRun) { Write-Log "[dry-run] mkdir $Target"; break }
    New-Item -ItemType Directory -Force -Path $Target | Out-Null
    Write-Log "dir made: $Target"
  }

  'create' {
    if (-not $Target) { Fail "Path required" }
    Ensure-AllowedExt $Target
    if ($DryRun) { Write-Log "[dry-run] create $Target"; break }
    $parent = Split-Path $Target -Parent
    if ($parent) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
    if (-not (Test-Path -LiteralPath $Target)) {
      New-Item -ItemType File -Force -Path $Target | Out-Null
    }
    Write-Log "created: $Target"
  }

  'delete' {
    if (-not $Target) { Fail "Path required" }
    if ($DryRun) { Write-Log "[dry-run] delete $Target"; break }
    if (Test-Path -LiteralPath $Target) {
      # ディレクトリは再帰削除。ゴミ箱送りにしたい場合は別実装に差し替え
      if ((Get-Item -LiteralPath $Target).PSIsContainer) {
        Remove-Item -LiteralPath $Target -Recurse -Force
      } else {
        Remove-Item -LiteralPath $Target -Force
      }
      Write-Log "deleted: $Target"
    } else {
      Write-Log "not found: $Target"
    }
  }

  'write' {
    if (-not $Target) { Fail "Path required" }
    Ensure-AllowedExt $Target

    # 本文を stdin から取得
    $stdin = [Console]::In.ReadToEnd()

    if ($DryRun) {
      Write-Log "[dry-run] write $Target ($Mode), length=$($stdin.Length)"
      break
    }

    $parent = Split-Path $Target -Parent
    if ($parent) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }

    if ($Mode -eq 'append') {
      # 追記（無ければ作成）
      if (-not (Test-Path -LiteralPath $Target)) {
        New-Item -ItemType File -Force -Path $Target | Out-Null
      }
      Add-Content -LiteralPath $Target -Value $stdin -Encoding UTF8
      Write-Log "appended: $Target (len=$($stdin.Length))"
    }
    else {
      # 上書き: バックアップ
      if ($Backup -and (Test-Path -LiteralPath $Target)) {
        $stamp = (Get-Date -Format "yyyyMMdd-HHmmss")
        $bak   = "$Target.bak_$stamp"
        Copy-Item -LiteralPath $Target -Destination $bak -Force
        Write-Log "backup: $bak"
      }
      Set-Content -LiteralPath $Target -Value $stdin -Encoding UTF8
      Write-Log "wrote: $Target (len=$($stdin.Length))"
    }
  }

  default {
    Fail "unsupported action: $Action"
  }
}
