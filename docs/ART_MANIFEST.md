# 素材清单与导入分类（ART_MANIFEST）

> 2026-07-07 用 Godot 引擎实测 `assets/images/` 全库 496 张 PNG 的尺寸与导入设置生成。
> 用途：①导入压缩优化（阶段 0.2）的目录分类依据；②像素清除与素材替换（阶段 3）的对账表。
> 现状基线：**496 张全部 compress/mode=0（Lossless）**，除 explore 外基本无 mipmap。

## 目录分类表

| 目录 | 数量 | 最大边 | 风格判定 | 导入建议 | 备注 |
|---|---|---|---|---|---|
| boss | 16 | 1792 | 高清厚涂 | **VRAM+mipmap** | 含少量 boss HUD 贴图(hud_lifebar_frame/hud_score_panel) |
| enemy | 45 | 1024 | 高清厚涂 | **VRAM+mipmap** | designed_25 主体,运行时 `ENEMY_TEXTURE_PATHS` 引用 |
| divine_messenger | 18 | 1024 | 高清厚涂 | **VRAM+mipmap** | 体积最大目录(19.5MB) |
| paradise | 12 | 2048 | 高清厚涂 | **VRAM+mipmap** | 含 2048×1152 超大图 |
| warpedcore | 6 | 1254 | 高清厚涂 | **VRAM+mipmap** | |
| helleye / _admin / _sentry | 5/2/2 | 1024 | 高清厚涂 | **VRAM+mipmap** | 三目录各有重复 nebula_raw.png |
| turret | 24 | 1024 | 高清厚涂 | **VRAM+mipmap** | explore 防御炮塔 |
| powerup | 8 | 1024 | 高清厚涂 | **VRAM+mipmap** | |
| rewards | 8 | 1024 | 高清 | **VRAM+mipmap** | 与 explore/rewards 平行(待合并) |
| player | 4 | 1024 | 高清厚涂 | **VRAM+mipmap** | 排除任何 sheet |
| electric_isolation | 3 | 1024 | 高清 | **VRAM+mipmap** | |
| isolation_band | 18 | 3000 | 高清 | **VRAM+mipmap** | 与 isolation_band_tiles / explore/isolation_belt 三处平行(待合并) |
| isolation_band_tiles | 6 | 512 | tile | **VRAM+mipmap** | 平铺 tile,mipmap 有益 |
| background | 2 | 1080 | 深空背景 | **VRAM+mipmap** | deep_space,仅主菜单用 |
| equipment | 142 | 96 | 扁平图标 | **保持 Lossless** | 契约 `equipment/<id>.png`,勿动尺寸 |
| ui | 22 | 2560 | 混合 | **Lossless；参考大图移出** | reference_preview(1920×1088)移到 source_ai |
| fx | 41 | 3388 | 特效/spritesheet | **VRAM，不开 mipmap** | explosion(3388×2476,6帧)/debris 是逐帧 sheet,mipmap 会帧间渗色 |
| projectiles | 1 | 1280 | spritesheet | **VRAM，不开 mipmap** | bullet_04_sheet(hframes5×vframes4) |
| asteroid | 10 | 4096 | **像素风** | **待清除替换** | explore 陨石,顶层与 explore/asteroid 平行 |
| explore | 101 | 4096 | **混合(含像素)** | **待细分/替换** | 含 pixel_asteroids/pixel_starfield_tile 等像素素材 + 高清杂物 |

## 待清除的像素素材（阶段 3.1）
- `assets/images/asteroid/`（顶层，10 张，maxdim 4096）
- `assets/images/explore/` 下 `pixel_asteroids/`、`pixel_asteroid_5/`、`pixel_starfield_tile.png`
- `assets/source_ai/pixel_art/`（生成源，非运行时）

## 待移出运行目录的非游戏素材（阶段 0.3）
- `ui/main_menu/reference_preview.png`、`ui/loading_screen/reference_preview.png`（1920×1088 参考稿）
- 各目录 `_raw.png`（15 张，AI 出图中间产物；成品是对应 `_cutout.png`）
→ 移到 `assets/source_ai/`（不参与导入，减包体）

## 导入优化操作说明
MCP 脚本批量 reimport 在编辑器进度条机制下不可行（"Can't find file during reimport"）。**建议在 Godot 编辑器 FileSystem 面板操作**：选中上表"VRAM+mipmap"目录 → Import 面板设 Compress Mode=VRAM Compressed、Mipmaps=On → Reimport（有进度条，可即时预览色带）。厚涂能量光晕的平滑渐变是色带高风险处，重导入后重点看 Boss/扭曲星核的青紫光效。

## 运行时贴图引用契约（换素材前必读）
- **装备**：`EquipmentCatalog.gd:897` → `equipment/<id>.png`，同名替换即换皮。
- **DesignedEnemy 25 种**：`DesignedEnemy.gd:54-80` 硬编码 25 条含中文名+hash 路径（阶段 0.5 拟重构为 Catalog 字段）。
- **Boss/普通敌机/子弹/掉落**：写死在各 .tscn(ExtResource) 或 .gd(preload)，同名覆盖即换皮。
- **explore 杂物**：`ExploreRoom.gd:43` 扫目录随机取，增删文件即生效。

## 测试护栏
改素材路径/UI 后必跑：`EquipmentIconCheck`、`DesignedEnemyPlaceholderTextureCheck`、25 个 `EnemyTest_*`、`ui_copy_quality_check`、`RuntimeUiSmokeTest`。
