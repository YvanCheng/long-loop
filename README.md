# long-loop

把一个功能从产品规格做到测试通过的 PR。只有 `long-loop` 是可唤起的技能，角色写在 `roles/` 里。

## 安装

安装目录由你指定。脚本不默认写入 `~/.qoder/skills` 或其他代理目录。

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

不带目录时，脚本列出常见位置，等你选一个。非交互运行必须传入目录。

`--link` 把本仓库链进目标目录。省略时复制文件。`--uninstall` 只移除 `long-loop`，不移除已经装上的其他技能。

目标目录里缺少的必需技能会装进同一目录：`grill-with-docs`、`grilling`、`domain-modeling`、`to-spec`、`to-tickets`、`implement`、`implement-spec`、`tdd`、`code-review`、`pr`、`ponytail`。本机已有的先复制过去，没有的再从上游仓库下载。页面才用到的技能不在安装时装。

许可证见 [LICENSE](LICENSE)。
