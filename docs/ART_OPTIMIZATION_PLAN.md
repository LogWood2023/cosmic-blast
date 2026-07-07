# 画面·美术·动画·UI 大规模优化计划（高清定稿版）

> 基于 2026-07-07 对素材库、UI 体系、动画特效、视觉装配方式的四路全面审计。
> 2026-07-07 决策定稿：主风格 = **高清厚涂科幻**（保留存量主体），少数派像素素材清除。
> 本文档是执行蓝本。素材生成部分等绘图 API 开放后按第 5 节规格执行；阶段 0/1/2 的多数工作不依赖 API，已开工。

---

## 0. 已锁定的决策

1. **主风格 = 高清厚涂科幻**。存量高清库（5 套 Boss、25 敌人、142 装备图标、玩家、子弹等）是主体，予以保留统一；少数派像素素材（explore 陨石、星空 tile、像素杂物）清除并替换为高清。理由：存量主体已是此风格、质量最高，工作量最省，且匹配"二次元科幻悲壮"世界观。
2. **引入 CJK 字体**：思源黑体（OFL 可商用）作正文；标题可另选一款科技感中文字体（阶段 1 定）。
3. **VRAM 压缩**：实体大图上 VRAM + mipmap（省显存/包体），UI/图标保 Lossless。
4. **玩家机体倾斜/推进器帧动画**：做（阶段 3.5）。

---

## 1. 现状诊断（审计结论摘要）

### 1.1 素材库（assets/images/，496 张 PNG / 139MB）
- **≥3 种风格混用**：①高清厚涂 AI 渲染（boss、designed_25 敌人、divine_messenger 等，1024²+，**存量主体，保留**）；②像素风（explore 陨石、pixel_starfield_tile、source_ai/pixel_art，少数派，**清除**）；③扁平 UI 图标（equipment 96²）。
- **导入一刀切**：496 个 .import 全 Lossless、无 mipmap、无逐文件 filter；项目未设 default_texture_filter（默认 Linear）→ 现有像素素材被糊化（反正要清除，无碍）；大图无 mipmap 缩小时闪烁、显存高。
- **规格浪费**：64 张 >1MB；`fx/bomb_icon.png` 1024² 当图标；1024² 缩到 ~64px 显示（scale 0.0625=1/16）；`reference_preview.png` 等非游戏素材混在运行目录。
- **组织混乱**：37 个中文目录 + hash 文件名；asteroid/rewards/isolation_band 顶层与 explore/ 双份平行；`_raw`/`_cutout`/`props`/`final` 混放，部分 `props/` 被运行时直接引用（不能盲删）；`_tmp/Godot-MCP-Native/` 是无关第三方整仓。

### 1.2 UI 体系
- **无统一 Theme 资源、无字体文件**（中文靠引擎默认字体，发布风险）、无九宫格贴图。
- `CombatUiTheme.gd` 有设计好的 9 色板 + 样式工厂但**全项目只调 1 次**；实际 764 处 `theme_override_*` + 上千处手工复制 RGBA + 23 种字号各自为政。
- 布局以 anchors + Container 为主（较规范）；`CombatUiMotion.gd`（UI 动效）是唯一广泛复用层（18 脚本引用）——好底子。

### 1.3 动画与特效
- **零粒子、实体零帧动画、战斗场景无背景**（纯黑清屏）。全靠 Tween/`_process`/`_draw`。
- **打击反馈不足**：敌人受击仅 ±4px 抖动无闪白；Boss 受击零表现；无 hitstop、无统一震屏（3 套零散实现）、无全屏打击闪。
- 已有 11 个 canvas_item shader（描边/发光/全屏 glitch）；子弹/爆炸/碎片**无对象池**，每颗子弹独立 Area2D + `_process`。
- 护栏已有：GameManager 帧预算守卫 + 卡顿监控（stutter_log）；explore 巡逻敌有对象池（可复用模式）。

### 1.4 素材装配三路径（换皮影响面）
- **A 场景静态贴图**：玩家/9 普通敌机/子弹/掉落，写死 .tscn，统一 scale 0.0625。同名覆盖即换皮。
- **B 脚本 preload**：全部 Boss + FX，49 处散在 17 个 .gd。
- **C 表驱动/目录扫描**：DesignedEnemy 25 种路径硬编码 `DesignedEnemy.gd:54-80`（含中文名+hash，与 Catalog 靠索引隐式绑定）；装备图标契约 `EquipmentCatalog.gd:897`=`equipment/<id>.png`；explore 杂物 `ExploreRoom.gd:43` 扫目录随机取。
- **测试护栏**：~78 个无头 Check；`EquipmentIconCheck`（每装备 id 有同名 PNG）、`DesignedEnemyPlaceholderTextureCheck`、25 个 `EnemyTest_*`、`ui_copy_quality_check.gd`（UI 文案纯中文/无 ASCII/30 词黑名单）、`CommercialUiVerifier`/`RuntimeUiSmokeTest`。

---

## 2. 风格与技术基准（高清科幻）

### 2.1 主风格定义
**"高清厚涂科幻"**：深空冷色环境光 + 单侧强光源，边缘轮廓清晰，透明 cutout。三层规范：
| 层 | 风格 | 适用 |
|---|---|---|
| 游戏内实体 | 高清厚涂，深空冷色底 + 左上强光，透明 cutout | 机体/敌人/Boss/陨石/杂物/掉落 |
| 背景 | 深空星云，低饱和蓝紫黑，亮度低实体一档（保弹幕可读），多层视差 | 战斗/探索/菜单 |
| UI | 全息指挥舱风：深空蓝黑面板 + 青(主)/琥珀(强调)/红(危险)，沿用 CombatUiTheme 九色 + 斜切圆角；几何走 StyleBoxFlat，不烘焙文字 | 界面/HUD/图标 |

### 2.2 主色板（阶段 1 地基）
将 `CombatUiTheme.gd` 现有 9 色升为全项目权威色板，美术生成与 UI 重构都对齐：
COMMAND_CYAN #52e8ff / FURNACE_AMBER #ffb84d / DANGER_RED #ff4f6a / VOID_VIOLET #b78cff / ANOMALY_GREEN #65f0a3 / DEEP_PANEL #071018 / NEAR_BLACK #03070c / TEXT_MAIN #f8fbff / TEXT_MUTED #b7c4cf。战场敌我可读性：敌对偏红/紫、玩家/友方偏青、中立偏琥珀。

### 2.3 导入与渲染
- default_texture_filter 维持 **Linear**（高清主体适用，可安全全局设定）。
- 压缩分类（落实决策 3）：实体大图 → **VRAM + mipmap**；UI/图标 → **Lossless**；逐类抽查画质回归防色带。
- 大图开 mipmap（缩到 1/16 显示必需，消除缩小闪烁）。

### 2.4 缩放
沿用现有"大图缩小"装配（scale 反算/固定小 scale）；仅对纯图标类超大源图（如 bomb_icon 1024²）降采样到 256²。替换素材须保持相近高分辨率 + 透明 cutout + 视觉重心对齐（scale 反算，重心偏则游戏内歪）。

---

## 3. 阶段划分

### 阶段 0 —— 地基（多数不依赖 API，进行中）
| # | 任务 | 说明 |
|---|---|---|
| 0.1 | 渲染设置 | project.godot 补 `stretch/aspect`（keep）、显式设 default_texture_filter=Linear；实体大图导入预设改 VRAM+mipmap |
| 0.2 | 导入预设分类 | 实体大图 VRAM+mipmap；UI/图标 Lossless；逐类抽查回归 |
| 0.3 | 源图降采样 | 图标类超大源图降采样；参考稿/`_raw`/`reference_preview` 移出 assets/images 到 source_ai（不参与导入） |
| 0.4 | 目录规范化 | 统一 `assets/images/<域>/<主题>/` 英文命名；合并三处平行目录；消灭中文目录+hash。**同步改** `ENEMY_TEXTURE_PATHS`(25)、`ExploreRoom.gd`(杂物+5 陨石路径)、各 tscn ExtResource、Boss preload；跑全部 Check。**高风险，分域小批推进** |
| 0.5 | 消除隐式绑定 | DesignedEnemy 贴图路径从 `ENEMY_TEXTURE_PATHS` 索引绑定重构为 Catalog 显式字段（配合 0.4，换素材更安全） |
| 0.6 | 清死资产 | 删 `_tmp/Godot-MCP-Native/`、`ScrollingBackground.gd`（死代码）、grep 确认无引用的 props/ 中间产物；`stutter_log.txt` 入 .gitignore |
| 0.7 | 素材清单 | `docs/ART_MANIFEST.md`：每张运行时贴图 路径→用途→显示尺寸→风格标签→替换状态，作对账单 |

### 阶段 1 —— UI 统一（纯代码/资源，收益最大，可即刻开工）
| # | 任务 | 说明 |
|---|---|---|
| 1.1 | 引字体 | 思源黑体正文 + 标题字体，建 FontVariation 层级 |
| 1.2 | 统一 Theme 资源 | `assets/theme/main_theme.tres`：九色板 + 斜切圆角 StyleBoxFlat 为基准，定义 Button/Panel/Label/ProgressBar 默认样式 + variation；设为全局 theme |
| 1.3 | 字号/间距标尺 | 23 种字号收敛到 6–8 级；margin/圆角进 theme 常量 |
| 1.4 | 分批迁移 | PlayerStatusHUD/BossHUD → 世界地图弹窗族（HangarPopup 582 行重灾区）→ 主菜单/BossSelect/GameOver → explore 程序化 UI（`_draw` 改读色板）。每批删对应 override，跑 `ui_copy_quality_check`+`RuntimeUiSmokeTest`+`ui_popup_check` |

### 阶段 2 —— Game Feel（代码为主，可与阶段 1 并行）
| # | 任务 | 说明 |
|---|---|---|
| 2.1 | 统一受击反馈 | hit-flash shader（白闪 0.06s）挂 BaseEnemy/BossBase/Player；补 Boss 受击表现 |
| 2.2 | 统一屏幕反馈 | 收编 3 套 shake 为 CameraFeedback 单例（trauma 衰减）；补 hitstop（击杀/大伤 0.02–0.05s）；低血暗角 |
| 2.3 | 死亡/出场 | 敌人死亡=缩放+闪白+淡出序列；出场警告升级；Boss 出场演出 |
| 2.4 | 粒子落地 | GPUParticles2D：尾焰/爆炸增强/拾取流光/狂热光环；与帧预算守卫联动限额 |
| 2.5 | 战斗背景 | 纯黑升级为 2–3 层视差深空（远景星云 + 中景星点 shader + 近景尘埃粒子），压暗保弹幕可读；explore 同步。管线先行，贴图等阶段 3 |
| 2.6 | 性能护航 | 子弹/爆炸/碎片对象池（复用 explore 池）；子弹 `_process` group 扫描改缓存。**与 2.4 同批**，stutter_log 前后对比 |

### 阶段 3 —— 素材替换（依赖绘图 API，工作量已大幅收窄，分批）
每批：按第 5 节生成→抠图/降采样/命名入库→改路径/覆盖→更新 MANIFEST→跑相关 Check→游戏内截图验收。
| 批次 | 内容 | 数量级 | 装配 |
|---|---|---|---|
| 3.1 | 像素风出清：explore 陨石×5、pixel_starfield_tile、像素杂物 → 高清 | ~20 | 同名覆盖 + ExploreRoom 路径 |
| 3.2 | 背景套装：战斗/探索/主菜单/加载屏 视差层 + 星云 | ~15 | 阶段 2.5 新管线 |
| 3.3 | UI 图形：主菜单 keyart、弹窗横幅、图标族补齐、指南针/摇杆重绘 | ~30 | TextureRect 位，不烘焙文字 |
| 3.4 | 实体统一微调：普通敌机 9 种与 designed_25 风格对齐、掉落、炮塔 | ~40 | 同名覆盖为主 |
| 3.5 | 动画帧：玩家机体倾斜(左/中/右)+推进器帧、Boss 部件差分（决策 4） | 视需求 | 新增 SpriteFrames 装配 |

### 阶段 4 —— 验收
- ~78 个 Check 全过；关键场景前后截图对比；stutter_log 特效加量后 `single_frame_over_budget` 不高于基线；素材体积经压缩+降采样目标 ≤60MB。

---

## 4. 依赖与并行

```
阶段0（地基） ──→ 阶段3（素材替换，依赖绘图API + 0.4目录规范 + 0.7清单）
   │
   ├──→ 阶段1（UI统一，独立，可即刻开工）
   └──→ 阶段2（Game Feel，可与1并行；2.5背景管线先行，贴图等3.2）
```
**不依赖 API、可立即开工**：阶段 0（除 3 相关外）、整个阶段 1、阶段 2 代码部分。

---

## 5. 绘图 API 生成规格（一致性把关标准）

**统一 prompt 基底（实体类共用）**：
> 高清科幻厚涂渲染，深空冷色环境光 + 左上方单一强光源，边缘轮廓清晰，背景纯透明（cutout），无文字无水印，色调锚定：深空蓝黑底 #071018，能量色 #52e8ff(青)/#ffb84d(琥珀)/#ff4f6a(红,敌对)

**分类规格**：
| 类别 | 画布 | 入库尺寸 | 格式 | 命名 |
|---|---|---|---|---|
| 实体（敌机/Boss部件/陨石） | 1024² | 512²（显示 ≤128px 者 256²） | PNG cutout / VRAM+mipmap | `<domain>_<name>_<variant>.png` 全英文小写蛇形 |
| 装备/UI 图标 | 512² | 96²(装备)/128²(UI) | PNG / Lossless | 装备**必须 = 装备 id**（EquipmentCatalog 契约） |
| 背景层 | 2048×1152 | 1920×1080 或无缝 tile 1024² | PNG / VRAM+mipmap | `bg_<scene>_<layer>.png` |
| UI 横幅/keyart | 1920×1088 | 按位裁切 | PNG | **禁止画入任何文字**（人工铁律） |

**逐张入库检查清单**：
1. 风格：光源方向、色调锚点、厚涂质感与基准图（如 `01_巨构碎臂`）并排比对一致；
2. 技术：透明边无白边/杂色、居中、视觉重心与旧图一致（scale 反算，重心偏则歪）；
3. 命名/路径符合 0.4 规范，登记 MANIFEST；
4. 敌对偏红/紫、玩家/友方偏青、中立偏琥珀；
5. 每批先出 2–3 张样张定调、比对基准图，再批量。

---

## 6. 风险清单

| 风险 | 缓解 |
|---|---|
| 0.4 目录重命名波及 25 硬编码路径+49 preload+大量 tscn | 分域小批、每批全量 Check；先做 0.5 消除索引隐式绑定 |
| VRAM 压缩让厚涂图产生色带 | 逐类抽查；UI/图标保 Lossless；必要时 high_quality 压缩 |
| 特效加量卡顿回归 | 2.6 对象池与特效同批；帧预算守卫 + stutter_log 对比 |
| UI 重构触发文案质检（纯中文/占位词黑名单） | 迁移只动样式不动文案 |
| AI 生成风格漂移 | 固定 prompt 基底 + 基准图比对；每批先出样张定调 |

---

## 7. 决策状态

四项决策已锁定（第 0 节）。可立即开工（不等 API）：阶段 0（除素材替换相关）、整个阶段 1、阶段 2 代码部分。当前进度见 `docs/ART_MANIFEST.md` 与本文件顶部。
