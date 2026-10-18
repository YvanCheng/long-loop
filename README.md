# long-loop

把一个功能从产品规格做到测试通过的 PR。只有 `long-loop` 是可唤起的技能，角色写在 `roles/` 里。

## 安装

把 long-loop 安装到所选技能目录。

```bash
bash install.sh
bash install.sh --target <技能目录>
bash install.sh --target <技能目录> --link
bash install.sh --target <技能目录> --skip-deps
bash install.sh --target <技能目录> --uninstall
```

Windows：

```powershell
powershell -File install.ps1 -Target <技能目录>
```

在终端中直接运行时，脚本列出常见技能目录并等待选择。脚本化调用通过 `--target` 或 `-Target` 传入目录。

`--link` 以符号链接安装本仓库，未加该参数时复制文件。`--uninstall` 从该目录移除 `long-loop`，其余已安装技能保留。

所选目录若缺少闭环依赖，安装程序会一并装入：`grill-with-docs`、`grilling`、`domain-modeling`、`to-spec`、`to-tickets`、`implement`、`implement-spec`、`tdd`、`code-review`、`pr`、`ponytail`。本机已有的先复制，没有的再从上游仓库下载。页面相关技能在对应环节需要时安装。

许可证见 [LICENSE](LICENSE)。
