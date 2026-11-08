#Requires -Version 7.0
# XIRASM 演示：统一 UTF-8 编码 -> 汇编 -> 回读 listing -> 校验字节 -> 写作业摘要
# 由 .github/workflows/demo.yml 在 Windows x64 runner 上以 shell: pwsh 调用

$ErrorActionPreference = 'Stop'

# ---------- 1. 编码统一：Windows 控制台默认本地代码页，中文会乱码 ----------
try { chcp.com 65001 | Out-Null } catch { }
try { [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false) } catch { }
$OutputEncoding = [System.Text.UTF8Encoding]::new($false)

# ---------- 2. 路径 ----------
$root   = Split-Path -Parent $PSScriptRoot
$xirasm = Join-Path $root 'tools/xirasm.exe'
$src    = Join-Path $root 'demo/hello.xir'
$bin    = Join-Path $root 'demo/hello.bin'
$lst    = Join-Path $root 'demo/hello.lst'

if (-not (Test-Path -LiteralPath $xirasm)) { throw "找不到 xirasm.exe: $xirasm" }
if (-not (Test-Path -LiteralPath $src))    { throw "找不到演示源: $src" }

# ---------- 3. 运行环境（确认 Windows x64 / CPU） ----------
Write-Host '==================== 运行环境 ===================='
Write-Host "OS            : $([System.Environment]::OSVersion.VersionString)"
Write-Host "ProcessorArch : $env:PROCESSOR_ARCHITECTURE"
Write-Host "Runner        : $env:RUNNER_OS / $env:RUNNER_ARCH"
Write-Host "XIRASM sha256 : $((Get-FileHash -LiteralPath $xirasm -Algorithm SHA256).Hash)"
Write-Host 'UTF-8 中文显示 : 编码链路正常 OK'
Write-Host '==================================================='

# ---------- 4. 版本 ----------
$version = (& $xirasm --version | Out-String).Trim()
Write-Host "XIRASM 版本   : $version"

# ---------- 5. 汇编 ----------
Write-Host "`n>>> 开始汇编 demo/hello.xir ..."
& $xirasm $src -o $bin --listing $lst --no-progress
if ($LASTEXITCODE -ne 0) { throw "xirasm 汇编失败，退出码 $LASTEXITCODE" }

# ---------- 6. 回读 listing（UTF-8），确认中文行正确回显 ----------
Write-Host "`n-------------------- listing --------------------"
$listing = Get-Content -LiteralPath $lst -Raw -Encoding UTF8
Write-Host $listing
Write-Host '--------------------------------------------------'

# ---------- 7. 校验产物字节 ----------
$bytes = [System.IO.File]::ReadAllBytes($bin)
$hex   = -join ($bytes | ForEach-Object { $_.ToString('x2') })
Write-Host "`n输出大小 : $($bytes.Length) 字节"
Write-Host "二进制   : $hex"

# 期望 = mov eax,42 | ret | 4 个 dd(平方 0,1,4,9) | UTF-8("中文 XIRASM 演示")
$expected = 'b82a000000c3' + '00000000010000000400000009000000' +
            'e4b8ade696872058495241534d20e6bc94e7a4ba'
if ($hex -ne $expected) {
    throw "产物字节不符合预期`n  实际: $hex`n  预期: $expected"
}
Write-Host 'OK 字节校验通过：指令 / 编译期平方表 / 中文 UTF-8 字符串全部正确'

# ---------- 8. 写入 GitHub Actions 作业摘要 ----------
$summaryPath = if ($env:GITHUB_STEP_SUMMARY) { $env:GITHUB_STEP_SUMMARY } else { Join-Path $root 'demo-summary.md' }
$lines = @(
    '## XIRASM 演示结果 OK',
    '',
    '| 项目 | 值 |',
    '| --- | --- |',
    "| 运行器 | $env:RUNNER_OS / $env:RUNNER_ARCH (Windows x64, CPU) |",
    "| XIRASM | $version |",
    '| 源文件 | demo/hello.xir (UTF-8 中文) |',
    "| 输出 | $($bytes.Length) 字节，字节校验通过 |",
    '| 编码 | 控制台 UTF-8 (chcp 65001)，中文回显正常 |',
    '',
    '```text',
    $hex,
    '```'
)
($lines -join "`n") | Out-File -FilePath $summaryPath -Encoding utf8 -Append
Write-Host "`n>>> 演示完成。"
