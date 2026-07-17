# 数值主表导入

`master_balance.tsv` 是唯一可编辑数值源。`generated/*.tres`、`combat_balance.tres`、`economy_balance.tres` 和 `run_pacing.tres` 均由导入器生成，不应手工修改。

生成数据：

```powershell
rtk powershell -NoProfile -File tools\godot_headless.ps1 --script res://tools/import_master_balance.gd
```

仅检查主表、分域 Resource 和 typed config 是否漂移：

```powershell
rtk powershell -NoProfile -File tools\godot_headless.ps1 --script res://tools/import_master_balance.gd --check
```

运行导入验收：

```powershell
rtk powershell -NoProfile -File tools\godot_headless.ps1 --scene res://scenes/tests/MasterBalanceImportCheck.tscn
```
