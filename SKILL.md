---
name: long-loop
description: 研发闭环。人唤起后，把一个功能从产品规格做到测试通过的 PR。
disable-model-invocation: true
---

# 研发闭环

人唤起本技能后，按下面的顺序做。角色文件在本技能目录的 `roles/` 下。用词以本目录的 `GLOSSARY.md` 为准。

## 安装

安装目录由人指定。`install.sh` 和 `install.ps1` 不默认写入任何代理的 skills 目录。

```bash
bash install.sh --target <技能目录>
bash install.sh --target <技能目录> --link
bash install.sh --target <技能目录> --uninstall
```

Windows 用 `powershell -File install.ps1 -Target <技能目录>`。省略 `--target` 时，脚本列出常见目录，等人选一个。

目标目录里缺少的必需技能会装进同一目录：`grill-with-docs`、`grilling`、`domain-modeling`、`to-spec`、`to-tickets`、`implement`、`implement-spec`、`tdd`、`code-review`、`pr`、`ponytail`。页面才用到的技能不在安装时装。

## 1. 读现状

在当前产品仓库里确定这一次的功能名，并找出已有产物。

1. 从人的需求里拟一个可做目录名的功能名。
2. 若 `.scratch/<功能>/sources.md` 已在，先读它。里面的路径就是产物位置。没有 `ui` 这一行时，仍按下面第 5 步判断要不要做界面设计。
3. 没有来源记录时，按默认位置找：
   - 产品规格：`.scratch/<功能>/spec.md`
   - 界面设计：`.scratch/<功能>/ui.md`
   - 技术设计：`.scratch/<功能>/design.md`
   - 票：`.scratch/<功能>/issues/`
   - 代码：仓库根
   - PR：当前分支上已有的 PR
4. 默认位置没有文件时，在仓库里找。只对上唯一一份，就把那份路径写进计划。对上零份或多份，路径留空。
5. 需求、已有产品规格或要改的代码涉及页面、界面或屏幕时，界面设计进入计划。否则界面设计标为跳过，路径留空。

完成：六份产物各自有路径，或明确留空。

## 2. 出计划

任何角色开工之前，把计划给人看。每一份产物标一个动作：

- **补齐**：还没有这份产物
- **跳过**：已有，且这次需求不动它
- **改造**：已有，且这次需求要改它

上游标成改造时，下游默认也是改造。人可以在计划里把某一段改成跳过。

计划写明功能名、每个角色的动作、每份产物的路径。人可以改功能名、动作和路径。

人确认后，把结果写入 `.scratch/<功能>/sources.md`：

```markdown
feature: <功能名>
spec: <路径>
ui: <路径或空>
design: <路径>
tickets: <路径>
code: <路径>
pr: <路径或空>
```

路径相对仓库根。确认过的空路径保持空。

完成：人确认了计划，`sources.md` 与确认结果一致。五份产物都是跳过时，告诉人没有要做的阶段，然后停。

## 3. 按阶段执行

跳过的角色不读角色文件。其余角色按这个顺序，一次一个：

1. 产品：`roles/product.md`
2. UI 设计师：`roles/ui-designer.md`
3. 架构师：`roles/architect.md`
4. 研发人员：`roles/developer.md`
5. 测试：`roles/test.md`

把功能名、该角色各份产物的动作和产物位置告诉角色，然后读取角色文件并做完它的工作流。角色文件里点名的技能，按名称读取并遵循。

完成：该角色的成功标准全部达到，或者关卡把它退回。

## 4. 关卡

下一个角色开工时先做检查。没通过就不进入它自己的交付。

- 架构师检查产品规格。规格自相矛盾时，停下来问人，不重开产品。这次有界面设计时，先确认它写得出页面；写不出就退回 UI 设计师。
- 研发人员检查技术设计和票。结构对不上时，退回架构师，不写代码。页面和界面设计对不上时，退回 UI 设计师，不写页面。
- 测试对照产品规格、技术设计和票检查 PR。这次有界面设计时，一并对照页面。实现没对上，退回研发人员。技术设计满足不了规格，或代码照设计做了但设计漏了规格，退回架构师。界面设计满足不了规格，退回 UI 设计师。

退回时，把这一条意见追加到被退回角色的记忆文件。文件不存在就创建。

- 产品：`.scratch/memory/product.md`
- UI 设计师：`.scratch/memory/ui-designer.md`
- 架构师：`.scratch/memory/architect.md`
- 研发人员：`.scratch/memory/developer.md`
- 测试：`.scratch/memory/test.md`

每一条写成一行：意见本身，加上「下次开工先对照它」。

同一次唤起里，同一条意见退回两次仍过不了关，把这两次意见给人看，停下来问人。测试通过，这次闭环结束。
