# XIRASM 汇编演示（GitHub Actions）

用 GitHub Actions 演示 [XIRASM 0.3.5](https://github.com/xir-kuku/XirAsm) 在
**Windows x64 / CPU** 运行器上汇编一段含中文的汇编源码，并验证编码链路与产物字节。

## 目标

- 在 CI 里跑通 `xirasm.exe`，证明汇编器可用；
- 演示「编码」：源码 UTF-8（无 BOM）→ 控制台 UTF-8（chcp 65001）→ listing 中文回显
  → 二进制里写入 UTF-8 字节，全链路不乱码；
- 演示汇编期语言：编译期函数/循环生成平方表，输出里只留数据；
- 产物（`hello.bin` / `hello.lst` / 作业摘要）可查看、可下载。

## 运行器（暂定）

`runs-on: windows-2022`（GitHub 托管的 Windows x64、**仅 CPU**）。
GitHub 没有官方的「Windows 11」托管镜像，故先暂定用 Windows Server 2022；
后续如需真机 Win11，可改为自托管：`runs-on: [self-hosted, windows, x64]`，
并在 `scripts/run-demo.ps1` 里把 `tools/xirasm.exe` 换成本机路径
`D:\develops\xirasm-0.3.5-windows-x86_64\xirasm.exe`。

`tools/xirasm.exe` 固定为 0.3.5（Windows x86-64），随仓库入库，
CI 不依赖外网下载，保证演示可复现；许可证见 [LICENSE](LICENSE)（Apache-2.0）。

## 编码约定

| 项 | 约定 |
| --- | --- |
| 文本文件 | UTF-8 **无 BOM**，LF 换行 |
| 换行/二进制保护 | `.gitattributes`：`eol=lf`，`*.exe`/`*.bin` 按二进制 |
| Windows 控制台 | `chcp 65001` + `[Console]::OutputEncoding = UTF8` |
| 源码 | `demo/hello.xir` 含中文注释与中文字符串字面量 |

> 本机 `core.autocrlf=true`，`.gitattributes` 确保 `.xir`/`.yml`/`.ps1`
> 一律以 LF/UTF-8 入库，且 exe 不被改写出错。

## 触发方式

`push` 到 `main`、`pull_request`、或手动 `workflow_dispatch`。

## 查看日志

```bash
gh run list --repo edidada/test_asm_xirasm
gh run watch                                    # 实时跟随最新一次运行
gh run view <run-id> --log                     # 完整日志
gh run view <run-id> --log | grep -E "版本|listing|字节|编码"
```

## 本地复现

```powershell
pwsh ./scripts/run-demo.ps1
```

脚本会打印运行环境、版本、listing、二进制十六进制，并断言 42 字节产物正确，
同时写出 `demo-summary.md`（CI 中则写到 `$GITHUB_STEP_SUMMARY` 作业摘要）。
