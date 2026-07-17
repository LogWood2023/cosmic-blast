extends Node
## Manages one formal roguelite run: world map, economy, equipment, and crisis bosses.

const EquipmentCatalogScript := preload("res://scripts/core/EquipmentCatalog.gd")
const DesignedEnemyCatalog := preload("res://scripts/entities/designed_enemies/DesignedEnemyCatalog.gd")
const RunContentContextScript := preload("res://scripts/core/run_content/RunContentContext.gd")
const RunContentFacadeScript := preload("res://scripts/core/run_content/RunContentFacade.gd")
const RunMutationSetScript := preload("res://scripts/core/run_content/RunMutationSet.gd")
const BalanceTelemetryScript := preload("res://scripts/core/BalanceTelemetry.gd")
const AdvancedCrisisResolverScript := preload("res://scripts/core/AdvancedCrisisResolver.gd")
const BalanceServiceScript := preload("res://scripts/core/BalanceService.gd")

const WORLD_MAP_SCENE: String = "res://scenes/app/WorldMap.tscn"
const EXPLORE_ROOM_SCENE: String = "res://scenes/gameplay/explore/ExploreRoom.tscn"
const GAME_OVER_SCENE: String = "res://scenes/app/gameover.tscn"

const NODE_BASE: String = "base"
const NODE_BATTLE: String = "battle"
const NODE_EVENT: String = "event"
const NODE_REWARD: String = "reward"
const NODE_SPECIAL: String = "special"

var CRISIS_THRESHOLDS: Array[int] = [5, 12, 21]
const BOSS_ALERT_PREVIEWS: Dictionary = {
	"res://scenes/gameplay/boss/BossBattle_Frontier.tscn": {"name": "星海前锋", "forecast_text": "首领预报：前锋舰队已完成坐标校准，正在评估方舟的征服价值。"},
	"res://scenes/gameplay/boss/BossBattle_PeachBlossom.tscn": {"name": "桃源乡", "forecast_text": "首领预报：乐园协议正在抹除航图中的不稳定变量。"},
	"res://scenes/gameplay/boss/BossBattle_Source.tscn": {"name": "异变源石", "forecast_text": "首领预报：星核燃料形态失控，正在向核心区扩散。"},
	"res://scenes/gameplay/boss/BossBattle_Sentry.tscn": {"name": "前哨战", "forecast_text": "首领预报：外层侦测人格已锁定方舟核心信号。"},
	"res://scenes/gameplay/boss/BossBattle_ImitationAngel.tscn": {"name": "仿造天使", "forecast_text": "首领预报：工业化救赎单元正在接近核心航道。"},
	"res://scenes/gameplay/boss/BossBattle_Heavy.tscn": {"name": "星尘重兵", "forecast_text": "首领预报：重装封锁线已展开，正在封锁核心航道。"},
	"res://scenes/gameplay/boss/BossBattle_Utopia.tscn": {"name": "乌托邦", "forecast_text": "首领预报：合规裁决开始执行，异常航线将被逐项修剪。"},
	"res://scenes/gameplay/boss/BossBattle_Spore.tscn": {"name": "诡异菌孢", "forecast_text": "首领预报：失控繁殖体已污染撤离扇区。"},
	"res://scenes/gameplay/boss/BossBattle_Admin.tscn": {"name": "防火墙", "forecast_text": "首领预报：隔离系统判定方舟为感染源，封锁即将收紧。"},
	"res://scenes/gameplay/boss/BossBattle_HolyBloodBrokenSword.tscn": {"name": "圣血断剑", "forecast_text": "首领预报：残存审判协议要求以失血偿还越界。"},
	"res://scenes/gameplay/boss/BossBattle_Nebula.tscn": {"name": "星云巨构", "forecast_text": "首领预报：巨构行军核心已进入碾压航线。"},
	"res://scenes/gameplay/boss/BossBattle_Eden.tscn": {"name": "伊甸园", "forecast_text": "首领预报：完美容器正在覆写自由变量。"},
	"res://scenes/gameplay/boss/BossBattle_Anti.tscn": {"name": "反物质核", "forecast_text": "首领预报：反物质反应即将重写当前星域。"},
	"res://scenes/gameplay/boss/BossBattle_Gate.tscn": {"name": "典狱长", "forecast_text": "首领预报：深层判决人格宣告方舟不得离开。"},
	"res://scenes/gameplay/boss/BossBattle_CrystalMother.tscn": {"name": "水晶圣母", "forecast_text": "首领预报：封存协议已启动，心智样本正在冻结。"},
}
# 危机播报文案（对应 docs/lore/02）：引导之声 + 天穹协议双视角。
# 每次危机 +1 抽一条 TICK；将触阈值时（4/11/20）改抽 APPROACH；触到 5/12/21 锁定时用 LOCK。
const CRISIS_TICK_BROADCASTS: Array[String] = [
	"节点已并入观测。危机关注度上升。",
	"又一片被封存的空间变回了现实。协议注意到了。",
	"校准完成。星域记住了你走过的地方——协议也是。",
	"危机等级 +1。你越清晰，就越像协议眼里的一个错误。",
	"一处封存被打开。判决序列前移一位。",
]
const CRISIS_APPROACH_BROADCASTS: Array[String] = [
	"探测到否决前兆。再校准一片空间，中心节点将被锁定。",
	"协议的注意力正在收拢。下一次探索之前，确认你已准备好回家迎战。",
]
const CRISIS_LOCK_BROADCASTS: Dictionary = {
	5: "【危机警报 · 等级 5】\n中心节点已被锁定，所有航道暂停响应。\n一具危机执行体正朝方舟核心接近——它不是来清除你，是来确认你。\n引导之声：回来。这一次，让它看清你不是噪声。\n天穹协议：归档为可成长异常，调派第一席执行确认。",
	12: "【危机警报 · 等级 12】\n中心节点二次锁定。这一次不是确认，是压制。\n协议研究过你怎么飞、怎么选、怎么活下来——派来的东西，是照着你的弱点造的。\n引导之声：你把太多东西变回了现实，协议开始害怕。\n天穹协议：剥夺，比清除更彻底。",
	21: "【危机警报 · 等级 21】\n中心节点最终锁定，星域停止了对你的一切让步。\n派来的是一份判决——协议为无法归类的变量保留的那一条。\n引导之声：这是这条回声能抵达的最远处。飞过去，或者把记忆留给下一个。\n天穹协议：五席之力都无法容纳它，执行最终否决。",
}
const SAVE_PATH := "user://run_save.dat"
const SAVE_VERSION := 3
const CENTER_ID: int = 0
const MAP_CENTER: Vector2 = Vector2(700.0, 590.0)
const FAMILY_BIASES: Array[String] = [
	"colossus",
	"paradise",
	"warped",
	"hell_eye",
	"divine",
]
const ORE_SOURCE_BIAS_PROFILES: Array[Dictionary] = [
	{
		"id": "star_marrow",
		"name": "星髓矿脉",
		"label": "星髓",
		"hint": "常规矿源，收益稳定，可作为任何装配的补给底盘。",
		"weight": 2.6,
		"room_effect": {"reward_mineral_mult": 0.04, "clutter_count": 4},
		"room_effect_text": "星髓矿脉铺开稳定碎矿，回收点更多，收益略微上扬。",
	},
	{
		"id": "gleam_crystal",
		"name": "辉晶簇",
		"label": "辉晶",
		"hint": "明亮晶簇更容易结成富矿，常在奖励航线里囤积更多星髓矿。",
		"weight": 3.2,
		"room_effect": {"reward_mineral_mult": 0.08, "chest_crystal_count": 3},
		"room_effect_text": "辉晶簇会把矿光聚成明亮目标，矿脉数量和单次收益同时抬高。",
	},
	{
		"id": "rift_cluster",
		"name": "裂隙晶簇",
		"label": "裂晶",
		"hint": "裂隙晶簇会碎成更多可回收颗粒，清理越彻底收益越亮。",
		"weight": 3.0,
		"room_effect": {"clutter_count": 10, "max_patrol_enemy_count": 1, "enemy_spawn_interval": -4.0},
		"room_effect_text": "裂隙晶簇把碎矿洒满残区，也会引来更快的巡逻回声。",
	},
	{
		"id": "deep_core",
		"name": "深层矿核",
		"label": "核髓",
		"hint": "深层矿核数量少但单点价值很高，值得为它多承担一点风险。",
		"weight": 3.8,
		"room_effect": {"reward_mineral_mult": 0.22, "chest_crystal_count": -2, "trap_count": 3, "max_patrol_enemy_count": 2, "enemy_spawn_interval": -6.0},
		"room_effect_text": "深层矿核压低矿点数量，却让每块矿都更值钱；防线和巡逻也会靠近。",
	},
]
const EXPLORE_FAMILY_WEIGHT_BOOST: float = 2.4
const BEACON_ECHO_EQUIPMENT_BONUS: float = 0.08
const BEACON_ECHO_REWARD_BONUS: float = 0.10
const REWARD_CACHE_ROUTE_EQUIPMENT_BONUS: float = 0.06
const REWARD_CACHE_ROUTE_REWARD_BONUS: float = 0.06
const BOSS_AFTERSHOCK_ROUTE_COUNT: int = 3
const BOSS_AFTERSHOCK_EQUIPMENT_BONUS: float = 0.07
const BOSS_AFTERSHOCK_REWARD_BONUS: float = 0.08
const ACTIVE_RUN_CONDITION_COUNT: int = 2
const RUN_CONDITION_PROFILES: Array[Dictionary] = [
	{
		"id": "ore_tide",
		"title": "星髓潮汐",
		"category": "矿潮",
		"description": "矿尘顺着航线涨落，矿脉更亮，敌群也会循着光靠近。",
		"effects_text": "矿物倍率提高，巡逻压力小幅上升。",
		"reward_mult_bonus": 0.14,
		"equipment_chance_bonus": 0.02,
		"room_config": {"reward_mineral_mult": 1.12, "max_patrol_enemy_count": 10},
	},
	{
		"id": "blackbox_rain",
		"title": "黑匣雨",
		"category": "遗物",
		"description": "碎裂记录器像雨点一样落进残区，装备信号更密，陷阱也更难完全避开。",
		"effects_text": "装备出现率提高，陷阱密度上升。",
		"reward_mult_bonus": 0.04,
		"equipment_chance_bonus": 0.08,
		"room_config": {"trap_count": 10, "chest_crystal_count": 14},
	},
	{
		"id": "quiet_watch",
		"title": "静默值守",
		"category": "静默",
		"description": "巡逻链路短暂熄火，资源点更容易清理，但高价值信号也被压低。",
		"effects_text": "巡逻压力降低，装备出现率略降。",
		"reward_mult_bonus": 0.06,
		"equipment_chance_bonus": -0.03,
		"room_config": {"enemy_spawn_interval": 64.0, "max_patrol_enemy_count": 6},
	},
	{
		"id": "redline_alarm",
		"title": "红线警报",
		"category": "危机",
		"description": "地狱之眼的红线扫过航图，交火会更频繁，回收队却能趁乱拿到更多残片。",
		"effects_text": "敌压上升，矿物倍率提高。",
		"reward_mult_bonus": 0.12,
		"equipment_chance_bonus": 0.01,
		"room_config": {"enemy_spawn_interval": 26.0, "max_patrol_enemy_count": 13, "clutter_count": 52},
	},
	{
		"id": "seraph_drift",
		"title": "圣羽漂移",
		"category": "护航",
		"description": "失联僚机残片沿外层环绕，神使接口更活跃，宝箱缓存也更完整。",
		"effects_text": "装备出现率提高，宝箱密度上升。",
		"reward_mult_bonus": 0.08,
		"equipment_chance_bonus": 0.05,
		"room_config": {"chest_crystal_count": 18, "clutter_count": 46},
	},
	{
		"id": "gravity_surge",
		"title": "引力涌浪",
		"category": "空间",
		"description": "扭曲潮汐推挤所有残片，矿体更集中，机动空间被压缩。",
		"effects_text": "矿脉变多，障碍和陷阱同步增加。",
		"reward_mult_bonus": 0.10,
		"equipment_chance_bonus": 0.02,
		"room_config": {"large_space_rock_count": 18, "trap_count": 9, "chest_crystal_count": 16},
	},
	{
		"id": "paradise_crossfire",
		"title": "天堂交叉火线",
		"category": "火线",
		"description": "天堂号残留火控仍在铺线，敌群更密，弹药缓存也更容易被翻出来。",
		"effects_text": "战斗节奏加快，装备出现率提高。",
		"reward_mult_bonus": 0.05,
		"equipment_chance_bonus": 0.06,
		"room_config": {"enemy_spawn_interval": 28.0, "max_patrol_enemy_count": 12, "chest_crystal_count": 15},
	},
	{
		"id": "colossus_debris",
		"title": "巨构残骸带",
		"category": "残骸",
		"description": "巨型装甲块挤满航道，碎矿丰厚，撤离线路会被迫绕开厚重阴影。",
		"effects_text": "矿物倍率提高，障碍密度上升。",
		"reward_mult_bonus": 0.16,
		"equipment_chance_bonus": 0.0,
		"room_config": {"large_space_rock_count": 20, "clutter_count": 58, "reward_mineral_mult": 1.10},
	},
]
const NODE_INTEL_PROFILES: Array[Dictionary] = [
	{
		"id": "ore_bloom",
		"title": "矿脉丰化",
		"description": "晶体矿脉密度异常升高，资源回收价值更高。",
		"room_config": {
			"large_space_rock_count": 9,
			"trap_count": 5,
			"chest_crystal_count": 16,
			"clutter_count": 30,
			"enemy_spawn_interval": 38.0,
			"max_patrol_enemy_count": 8,
		},
	},
	{
		"id": "wreck_field",
		"title": "残骸带",
		"description": "密集杂物和废弃装甲漂浮在航道中，碎矿信号沿着残骸缝隙闪烁。",
		"room_config": {
			"large_space_rock_count": 7,
			"trap_count": 4,
			"chest_crystal_count": 8,
			"clutter_count": 54,
			"enemy_spawn_interval": 34.0,
			"max_patrol_enemy_count": 9,
		},
	},
	{
		"id": "mineweb",
		"title": "雷网封锁",
		"description": "自动炮塔和电弧隔离带仍在工作，撤离路线更危险。",
		"room_config": {
			"large_space_rock_count": 8,
			"trap_count": 14,
			"chest_crystal_count": 10,
			"clutter_count": 34,
			"enemy_spawn_interval": 32.0,
			"max_patrol_enemy_count": 10,
		},
	},
	{
		"id": "quiet_cache",
		"title": "静默缓存",
		"description": "巡逻信号稀薄，缓存更完整，但空间障碍压缩了可机动区域。",
		"room_config": {
			"large_space_rock_count": 14,
			"trap_count": 3,
			"chest_crystal_count": 13,
			"clutter_count": 26,
			"enemy_spawn_interval": 72.0,
			"max_patrol_enemy_count": 5,
		},
	},
	{
		"id": "hunt_signal",
		"title": "猎杀信号",
		"description": "敌方巡逻链路异常活跃，火力接触会一波接着一波压上来。",
		"room_config": {
			"large_space_rock_count": 6,
			"trap_count": 7,
			"chest_crystal_count": 9,
			"clutter_count": 32,
			"enemy_spawn_interval": 22.0,
			"max_patrol_enemy_count": 13,
		},
	},
	{
		"id": "salvage_lane",
		"title": "回收航道",
		"description": "矿物、残骸和敌方游击队混在同一条航道，收益与风险都更均衡。",
		"room_config": {
			"large_space_rock_count": 10,
			"trap_count": 8,
			"chest_crystal_count": 12,
			"clutter_count": 42,
			"enemy_spawn_interval": 40.0,
			"max_patrol_enemy_count": 9,
		},
	},
	{
		"id": "radiation_sleet",
		"title": "辉尘雨区",
		"description": "细碎辉尘像雨一样扫过残片外壳，矿脉裸露，感应器却会不断误报。",
		"room_config": {
			"large_space_rock_count": 12,
			"trap_count": 6,
			"chest_crystal_count": 15,
			"clutter_count": 38,
			"enemy_spawn_interval": 44.0,
			"max_patrol_enemy_count": 8,
		},
	},
	{
		"id": "broken_gate",
		"title": "断门回廊",
		"description": "折断的舱门沿航线排开，狭窄缺口里藏着宝箱，也藏着伏击角度。",
		"room_config": {
			"large_space_rock_count": 13,
			"trap_count": 9,
			"chest_crystal_count": 11,
			"clutter_count": 44,
			"enemy_spawn_interval": 36.0,
			"max_patrol_enemy_count": 10,
		},
	},
	{
		"id": "choir_static",
		"title": "圣歌静噪",
		"description": "远处仍有断续圣歌回响，巡逻较少，但每一次接敌都会带来更密集的火线。",
		"room_config": {
			"large_space_rock_count": 8,
			"trap_count": 4,
			"chest_crystal_count": 14,
			"clutter_count": 28,
			"enemy_spawn_interval": 62.0,
			"max_patrol_enemy_count": 7,
		},
	},
	{
		"id": "gravity_tide",
		"title": "引力潮汐",
		"description": "空间潮汐把碎石和晶簇推向同一侧，弹道与冲锋路线都需要重新估算。",
		"room_config": {
			"large_space_rock_count": 16,
			"trap_count": 5,
			"chest_crystal_count": 13,
			"clutter_count": 36,
			"enemy_spawn_interval": 42.0,
			"max_patrol_enemy_count": 9,
		},
	},
	{
		"id": "red_eye_drift",
		"title": "赤眼漂流",
		"description": "暗红观测线在残片间游移，资源并不稀少，只是每一步都像被提前看见。",
		"room_config": {
			"large_space_rock_count": 7,
			"trap_count": 11,
			"chest_crystal_count": 12,
			"clutter_count": 40,
			"enemy_spawn_interval": 30.0,
			"max_patrol_enemy_count": 12,
		},
	},
	{
		"id": "drone_graveyard",
		"title": "僚机坟场",
		"description": "失联僚机在这里静静漂浮，完整零件很多，唤醒信号也更容易惊动守卫。",
		"room_config": {
			"large_space_rock_count": 9,
			"trap_count": 7,
			"chest_crystal_count": 15,
			"clutter_count": 50,
			"enemy_spawn_interval": 34.0,
			"max_patrol_enemy_count": 11,
		},
	},
]
const NODE_MODIFIER_PROFILES: Array[Dictionary] = [
	{
		"id": "rich_ore_wake",
		"title": "富矿尾迹",
		"description": "晶脉被拖成明亮尾迹，重型矿体更多，但航路会更拥挤。",
		"tags": ["矿脉", "障碍"],
		"room_config": {
			"large_space_rock_count": 18,
			"chest_crystal_count": 17,
			"clutter_count": 44,
			"reward_mineral_mult": 1.18,
		},
	},
	{
		"id": "scrap_storm",
		"title": "碎骸风暴",
		"description": "轻型残骸在气流里翻滚，碎矿很多，视野和走位都更杂乱。",
		"tags": ["杂物", "碎矿"],
		"room_config": {
			"clutter_count": 64,
			"trap_count": 6,
			"reward_mineral_mult": 1.08,
		},
	},
	{
		"id": "silent_corridor",
		"title": "静默回廊",
		"description": "巡逻信号被厚重残墙吞掉，交火较少，资源点更集中。",
		"tags": ["静默", "缓存"],
		"room_config": {
			"enemy_spawn_interval": 76.0,
			"max_patrol_enemy_count": 5,
			"chest_crystal_count": 16,
			"trap_count": 3,
		},
	},
	{
		"id": "alarm_lattice",
		"title": "警戒格栅",
		"description": "旧式防卫格栅仍在跳电，炮塔与电弧会把撤离路线切得更碎。",
		"tags": ["陷阱", "高危"],
		"room_config": {
			"trap_count": 16,
			"enemy_spawn_interval": 30.0,
			"max_patrol_enemy_count": 12,
		},
	},
	{
		"id": "hunter_crossfire",
		"title": "猎队交叉火线",
		"description": "敌方猎队沿多条航线交错巡游，资源完整，但停留越久越危险。",
		"tags": ["巡逻", "伏击"],
		"room_config": {
			"enemy_spawn_interval": 24.0,
			"max_patrol_enemy_count": 15,
			"patrol_path_min_count": 4,
			"patrol_path_max_count": 6,
		},
	},
	{
		"id": "gravity_shear",
		"title": "剪切引力",
		"description": "不稳定引力把晶簇推向航道边缘，矿物更密，陷阱读数也更混乱。",
		"tags": ["引力", "矿簇"],
		"room_config": {
			"large_space_rock_count": 20,
			"chest_crystal_count": 18,
			"trap_count": 9,
		},
	},
	{
		"id": "ark_echo_cache",
		"title": "方舟回声缓存",
		"description": "方舟旧信标仍在低声回响，装备信号更清晰，守卫也会被同步唤醒。",
		"tags": ["装备", "回声"],
		"reward_mult_bonus": 0.12,
		"equipment_chance_bonus": 0.08,
		"room_config": {
			"chest_crystal_count": 15,
			"enemy_spawn_interval": 34.0,
			"max_patrol_enemy_count": 10,
		},
	},
	{
		"id": "bleeding_relay",
		"title": "赤色中继",
		"description": "赤红中继反复扫描机体热源，敌群反应更快，矿脉也被照得无处藏身。",
		"tags": ["赤眼", "压迫"],
		"room_config": {
			"large_space_rock_count": 12,
			"chest_crystal_count": 14,
			"enemy_spawn_interval": 20.0,
			"max_patrol_enemy_count": 16,
		},
	},
	{
		"id": "mirror_debris_field",
		"title": "镜面残骸场",
		"description": "巨构外壳碎片像暗镜一样排列，冲锋路线清晰，撞击后的回声也更沉。",
		"tags": ["冲锋", "重甲"],
		"room_config": {
			"large_space_rock_count": 17,
			"clutter_count": 40,
			"trap_count": 7,
			"max_patrol_enemy_count": 11,
		},
	},
	{
		"id": "radiant_crosswind",
		"title": "辉光横风",
		"description": "天堂号的残火沿横向航线吹过，弹药缓存更多，巡逻火线也更密。",
		"tags": ["火力", "弹仓"],
		"room_config": {
			"chest_crystal_count": 16,
			"enemy_spawn_interval": 26.0,
			"max_patrol_enemy_count": 14,
			"reward_mineral_mult": 1.1,
		},
	},
	{
		"id": "dark_tide_pocket",
		"title": "暗潮口袋",
		"description": "潮汐把小型残件卷进同一片空域，目标更集中，陷阱读数却变得迟钝。",
		"tags": ["引力", "聚群"],
		"room_config": {
			"large_space_rock_count": 15,
			"clutter_count": 56,
			"trap_count": 8,
			"enemy_spawn_interval": 32.0,
		},
	},
	{
		"id": "fever_static_band",
		"title": "热病静电带",
		"description": "地狱之眼留下的热噪声绕着船壳发亮，收益不低，交火升温也更快。",
		"tags": ["狂热", "高温"],
		"room_config": {
			"trap_count": 12,
			"chest_crystal_count": 15,
			"enemy_spawn_interval": 24.0,
			"reward_mineral_mult": 1.12,
		},
	},
	{
		"id": "choir_drone_grave",
		"title": "圣歌机群墓",
		"description": "失联僚机仍按旧节拍闪灯，零件完整，守卫信号也会被一起叫醒。",
		"tags": ["僚机", "零件"],
		"room_config": {
			"clutter_count": 62,
			"chest_crystal_count": 17,
			"enemy_spawn_interval": 28.0,
			"max_patrol_enemy_count": 13,
		},
	},
	{
		"id": "colossus_reflection_spine",
		"title": "巨构反射脊",
		"description": "弧形装甲脊排成连续折面，矿石卡在背光处，重甲巡逻也更难甩开。",
		"tags": ["折返", "装甲"],
		"room_config": {
			"large_space_rock_count": 19,
			"clutter_count": 38,
			"trap_count": 10,
			"max_patrol_enemy_count": 14,
			"reward_mineral_mult": 1.09,
		},
	},
	{
		"id": "paradise_cinder_lane",
		"title": "余烬弹道带",
		"description": "天堂号残火沿旧弹道缓慢漂移，晶簇被照亮，巡逻火力也更容易连成线。",
		"tags": ["余烬", "连射"],
		"room_config": {
			"chest_crystal_count": 18,
			"enemy_spawn_interval": 22.0,
			"max_patrol_enemy_count": 15,
			"trap_count": 9,
			"reward_mineral_mult": 1.11,
		},
	},
	{
		"id": "warped_tide_eye",
		"title": "潮眼聚域",
		"description": "扭曲潮眼把残骸拖向同一片暗区，矿物密度上升，敌群也会更快合拢。",
		"tags": ["潮眼", "合拢"],
		"room_config": {
			"large_space_rock_count": 16,
			"clutter_count": 60,
			"enemy_spawn_interval": 23.0,
			"max_patrol_enemy_count": 16,
			"patrol_path_min_count": 4,
		},
	},
	{
		"id": "divine_relay_hymn",
		"title": "圣律中继",
		"description": "神使中继仍在广播短促圣律，僚机残件更完整，巡逻队会按节拍增援。",
		"tags": ["圣律", "增援"],
		"room_config": {
			"clutter_count": 66,
			"chest_crystal_count": 16,
			"enemy_spawn_interval": 21.0,
			"max_patrol_enemy_count": 17,
			"patrol_path_max_count": 7,
		},
	},
]
const NODE_OPPORTUNITY_PROFILES: Array[Dictionary] = [
	{
		"id": "cold_vault_ore",
		"title": "冷舱丰矿",
		"description": "冻结货舱还锁着整排矿脉，破开外壳会惊动残留守卫。",
		"effects_text": "矿脉增多，巡逻上限提高。",
		"tags": ["富矿", "守卫"],
		"reward_mult_bonus": 0.10,
		"equipment_chance_bonus": 0.0,
		"room_effect": {"chest_crystal_count": 4, "max_patrol_enemy_count": 2},
	},
	{
		"id": "old_beacon_shortcut",
		"title": "旧航标捷径",
		"description": "一枚旧航标仍在指向撤离侧翼，回收队能更早找到干净退路。",
		"effects_text": "巡逻间隔放缓，矿物倍率略降。",
		"tags": ["捷径", "低压"],
		"reward_mult_bonus": -0.04,
		"equipment_chance_bonus": 0.0,
		"room_effect": {"enemy_spawn_interval": 10.0, "max_patrol_enemy_count": -2, "reward_mineral_mult": -0.04},
	},
	{
		"id": "blueprint_echo",
		"title": "蓝图回声",
		"description": "装备残片在静电里反复闪烁，值得冒险多翻几只货柜。",
		"effects_text": "装备出现率提高，陷阱密度上升。",
		"tags": ["蓝图", "陷阱"],
		"reward_mult_bonus": 0.0,
		"equipment_chance_bonus": 0.06,
		"room_effect": {"trap_count": 3, "chest_crystal_count": 2},
	},
	{
		"id": "scrap_river",
		"title": "碎矿河",
		"description": "碎矿沿着残骸缝隙缓慢流动，杂物堆里能筛出不少星髓。",
		"effects_text": "杂物与矿物倍率提高。",
		"tags": ["杂物", "碎矿"],
		"reward_mult_bonus": 0.06,
		"equipment_chance_bonus": 0.0,
		"room_effect": {"clutter_count": 12, "reward_mineral_mult": 0.06},
	},
	{
		"id": "quiet_salvage_hour",
		"title": "静默回收窗",
		"description": "敌方监听短暂失焦，矿点不算富，却能让回收队从容拆解。",
		"effects_text": "陷阱和巡逻压力下降。",
		"tags": ["静默", "稳妥"],
		"reward_mult_bonus": 0.02,
		"equipment_chance_bonus": -0.01,
		"room_effect": {"trap_count": -2, "enemy_spawn_interval": 8.0, "max_patrol_enemy_count": -1},
	},
	{
		"id": "red_cache_pulse",
		"title": "赤缓存脉冲",
		"description": "高热缓存把矿尘照得通红，收益明亮，交火也会更快升温。",
		"effects_text": "矿物与装备信号提高，敌方响应加快。",
		"tags": ["高热", "高收"],
		"reward_mult_bonus": 0.08,
		"equipment_chance_bonus": 0.03,
		"room_effect": {"reward_mineral_mult": 0.08, "enemy_spawn_interval": -5.0, "max_patrol_enemy_count": 1},
	},
	{
		"id": "drone_courier_wreck",
		"title": "僚机货梭残骸",
		"description": "护航货梭断在矿带边缘，零件完整，矿箱也还没散尽。",
		"effects_text": "装备出现率与杂物数量提高。",
		"tags": ["僚机", "货梭"],
		"reward_mult_bonus": 0.04,
		"equipment_chance_bonus": 0.04,
		"room_effect": {"clutter_count": 10, "chest_crystal_count": 1},
	},
	{
		"id": "gravity_pocket_lode",
		"title": "引力袋矿",
		"description": "小型引力袋把矿块攒成暗色团簇，路径拥挤，但回收价值很高。",
		"effects_text": "矿物倍率和障碍密度提高。",
		"tags": ["引力", "厚矿"],
		"reward_mult_bonus": 0.12,
		"equipment_chance_bonus": 0.01,
		"room_effect": {"large_space_rock_count": 4, "reward_mineral_mult": 0.10, "trap_count": 1},
	},
]
const SPECIAL_BONUS_PROFILES: Array[Dictionary] = [
	{
		"bonus_id": "vector_supply_beacon",
		"name": "航路补给信标",
		"bonus_name": "矢量补给协议",
		"bonus_description": "接入后，移动效率小幅提高，矿物回收收益提升。",
		"family_bias": "general",
		"offset": Vector2(0.0, 104.0),
	},
	{
		"bonus_id": "colossus_charge_beacon",
		"name": "巨构冲锋信标",
		"bonus_name": "冲刺碰撞协议",
		"bonus_description": "接入后，右键冲锋距离、速度、撞击威力与余震范围提升。",
		"family_bias": "colossus",
		"offset": Vector2(0.0, -98.0),
	},
	{
		"bonus_id": "paradise_fire_beacon",
		"name": "天堂火力信标",
		"bonus_name": "覆盖火力协议",
		"bonus_description": "接入后，主武器额外增加弹幕覆盖，弹体碎裂后继续压制战场。",
		"family_bias": "paradise",
		"offset": Vector2(82.0, -70.0),
	},
	{
		"bonus_id": "warped_gravity_beacon",
		"name": "星核引力信标",
		"bonus_name": "弱引力校准",
		"bonus_description": "接入后，子弹获得轻度追踪与引力牵引参数，便于边移动边聚敌输出。",
		"family_bias": "warped",
		"offset": Vector2(96.0, 32.0),
	},
	{
		"bonus_id": "hell_eye_frenzy_beacon",
		"name": "地狱狂热信标",
		"bonus_name": "狂热灌注协议",
		"bonus_description": "接入后，狂热积累速度提高，狂热期攻防收益更明显。",
		"family_bias": "hell_eye",
		"offset": Vector2(-92.0, 36.0),
	},
	{
		"bonus_id": "divine_drone_beacon",
		"name": "神使僚机信标",
		"bonus_name": "僚机挂载协议",
		"bonus_description": "接入后，整局获得额外僚机挂载位，僚机射速与火力同步提升。",
		"family_bias": "divine",
		"offset": Vector2(-84.0, -72.0),
	},
	{
		"bonus_id": "ark_guard_beacon",
		"name": "方舟护盾信标",
		"bonus_name": "核心护盾协议",
		"bonus_description": "护盾信标并入核心后，常态伤害被方舟外壳悄然削弱。",
		"family_bias": "general",
		"offset": Vector2(0.0, -132.0),
	},
	{
		"bonus_id": "colossus_mirror_ram_beacon",
		"name": "镜甲冲锋信标",
		"bonus_name": "镜甲折返协议",
		"bonus_description": "接入后，冲锋余震范围扩大，折返后的撞击会留下更沉的回响。",
		"family_bias": "colossus",
		"offset": Vector2(126.0, -18.0),
	},
	{
		"bonus_id": "paradise_skyline_beacon",
		"name": "天幕弹链信标",
		"bonus_name": "天幕齐射协议",
		"bonus_description": "接入后，弹幕覆盖继续外扩，分裂弹在远处也能维持压制。",
		"family_bias": "paradise",
		"offset": Vector2(116.0, 86.0),
	},
	{
		"bonus_id": "warped_tide_beacon",
		"name": "潮汐透镜信标",
		"bonus_name": "暗潮牵引协议",
		"bonus_description": "接入后，弹道牵引半径扩大，碎群会被更稳定地拖向火线。",
		"family_bias": "warped",
		"offset": Vector2(-124.0, 84.0),
	},
	{
		"bonus_id": "hell_eye_redline_beacon",
		"name": "赤线虹膜信标",
		"bonus_name": "赤线狂热协议",
		"bonus_description": "接入后，狂热来得更快，爆发期火力更亮，护盾也更硬。",
		"family_bias": "hell_eye",
		"offset": Vector2(-126.0, -18.0),
	},
	{
		"bonus_id": "divine_seraph_beacon",
		"name": "圣羽机库信标",
		"bonus_name": "圣羽护航协议",
		"bonus_description": "接入后，僚机群补上第二层护航，友军火线变得更密。",
		"family_bias": "divine",
		"offset": Vector2(0.0, 142.0),
	},
]
const TIER_REWARD_MULTS: Array[float] = [1.0, 1.25, 1.55]
var TIER_EQUIPMENT_DROP_CHANCES: Array[float] = [0.28, 0.36, 0.48]
var MAX_READABLE_EQUIPMENT_DROP_CHANCE: float = 0.85
const TIER_RISK_LEVELS: Array[int] = [1, 3, 5]
var SHOP_OFFER_COUNT: int = 12
var SHOP_REROLL_BASE_COST: int = 18
var SHOP_REROLL_COST_STEP: int = 10
var SHOP_REROLL_REPEAT_STEP: int = 14
const SHOP_FOCUS_MIN_OFFERS: int = 7
const SHOP_ORE_SOURCE_MIN_OFFERS: int = 3
const REWARD_CACHE_MINERAL_MULT_BONUS: float = 0.18
const REWARD_CACHE_MINERAL_CHEST_BONUS: int = 3
const REWARD_CACHE_EQUIPMENT_BONUS: float = 0.18
const REWARD_CACHE_FAMILY_EQUIPMENT_BONUS: float = 0.10
const REWARD_CACHE_FAMILY_MINERAL_BONUS: float = 0.08
const REWARD_CACHE_CHOICE_PROFILES: Array[Dictionary] = [
	{
		"cache_type": "minerals",
		"title": "星髓回收箱",
		"description": "优先标定矿脉与宝箱，撤离时带回更厚的星髓矿。",
		"preview": "星髓收益提高，矿脉与宝箱密度小幅上升。",
		"shop_focus": false,
	},
	{
		"cache_type": "equipment",
		"title": "封存蓝图箱",
		"description": "把扫描带宽让给装备残片，更容易从货柜里检出蓝图。",
		"preview": "装备蓝图检出提高，掉落仍参考当前缓存倾向。",
		"shop_focus": false,
	},
	{
		"cache_type": "family",
		"title": "同家族装备箱",
		"description": "锁定当前家族回响，装备、敌群信号和商店商品都会向这条航路靠拢。",
		"preview": "更容易获得同一家族装备，并获得少量星髓矿与商品偏好。",
		"shop_focus": true,
	},
	{
		"cache_type": "shop",
		"title": "采购校准箱",
		"description": "方舟把缓存坐标同步给商店终端，下一批商品会沿当前家族倾向刷新。",
		"preview": "立即调整商店商品，装备出现率小幅提高。",
		"shop_focus": true,
	},
]
const ROUTE_DIRECTIVE_COUNT: int = 3
# 航路悬赏只会从各 Boss 家族的精英敌人中抽取目标。
const ROUTE_DIRECTIVE_ELITE_BEHAVIORS: Array[int] = [3, 4, 8, 9, 13, 14, 18, 19, 23, 24]
const ROUTE_DIRECTIVE_MINERAL_REWARD_MIN: int = 240
const ROUTE_DIRECTIVE_MINERAL_REWARD_MAX: int = 360
const ROUTE_DIRECTIVE_PROFILES: Array[Dictionary] = [
	{
		"id": "clear_forward_lane",
		"title": "清扫前哨航线",
		"description": "方舟需要一段稳定前路，让回收队敢把信标继续往外推。",
		"goal_type": "complete_nodes",
		"required": 3,
		"reward": {"minerals": 36},
		"reward_text": "星髓矿 +36",
	},
	{
		"id": "secure_battle_line",
		"title": "压制作战残片",
		"description": "敌方巡逻链路仍在扩散，先敲掉几处火力节点，航图会安静许多。",
		"goal_type": "complete_type",
		"target": NODE_BATTLE,
		"required": 2,
		"reward": {"minerals": 42, "equipment_chance_bonus": 0.04},
		"reward_text": "星髓矿 +42，装备出现率提高",
	},
	{
		"id": "open_reward_cache",
		"title": "回收奖励缓存",
		"description": "方舟捕获到高亮货柜回声，打通这些缓存能快速抬高本局储备。",
		"goal_type": "complete_type",
		"target": NODE_REWARD,
		"required": 1,
		"reward": {"minerals": 48},
		"reward_text": "星髓矿 +48",
	},
	{
		"id": "decode_event_signal",
		"title": "解码异常信号",
		"description": "旧航标仍在低声重复，处理它们能让方舟拿到更多局内情报。",
		"goal_type": "complete_type",
		"target": NODE_EVENT,
		"required": 1,
		"reward": {"compute": 1},
		"reward_text": "装配容量 +1",
	},
	{
		"id": "wake_beacon_protocol",
		"title": "唤醒增益信标",
		"description": "远处协议灯还没有熄灭，接入任意信标都能让本局航线的战术路数更加自成一体。",
		"goal_type": "activate_special",
		"required": 1,
		"reward": {"minerals": 30, "compute": 1},
		"reward_text": "星髓矿 +30，装配容量 +1",
	},
	{
		"id": "trace_colossus_route",
		"title": "追踪巨构回响",
		"description": "厚重撞角信号沿航线敲击舱壁，清理星间巨构航线能让冲锋打法更快成形。",
		"goal_type": "complete_family",
		"target": "colossus",
		"required": 2,
		"reward": {"minerals": 34, "equipment_family": "colossus"},
		"reward_text": "星髓矿 +34，星间巨构蓝图",
	},
	{
		"id": "trace_paradise_route",
		"title": "点亮天堂火线",
		"description": "明亮弹链在远处排成弧线，清理天堂号航线会把火力覆盖推向成型。",
		"goal_type": "complete_family",
		"target": "paradise",
		"required": 2,
		"reward": {"minerals": 34, "equipment_family": "paradise"},
		"reward_text": "星髓矿 +34，天堂号蓝图",
	},
	{
		"id": "trace_warped_route",
		"title": "收束扭曲潮汐",
		"description": "扭曲星核的引力读数忽明忽暗；清理同一家族航线能让追踪火力更早成形。",
		"goal_type": "complete_family",
		"target": "warped",
		"required": 2,
		"reward": {"minerals": 34, "equipment_family": "warped"},
		"reward_text": "星髓矿 +34，扭曲星核蓝图",
	},
	{
		"id": "trace_hell_eye_route",
		"title": "压住赤红热线",
		"description": "地狱之眼的热值沿航线攀升；清理同一家族节点能让武器过载更早积累。",
		"goal_type": "complete_family",
		"target": "hell_eye",
		"required": 2,
		"reward": {"minerals": 34, "equipment_family": "hell_eye"},
		"reward_text": "星髓矿 +34，地狱之眼蓝图",
	},
	{
		"id": "trace_divine_route",
		"title": "回收圣羽航标",
		"description": "神明使者的僚机接口仍在回应；清理同一家族航线能让护航系统更快接入。",
		"goal_type": "complete_family",
		"target": "divine",
		"required": 2,
		"reward": {"minerals": 34, "equipment_family": "divine"},
		"reward_text": "星髓矿 +34，神明使者蓝图",
	},
	{
		"id": "align_paradise_shop",
		"title": "点亮天堂货栈",
		"description": "明亮弹链沿着补给轨道展开，方舟会让下一批商品更偏向火力覆盖装备。",
		"goal_type": "complete_type",
		"target": NODE_BATTLE,
		"required": 1,
		"reward": {"minerals": 28, "shop_focus_family": "paradise", "shop_focus_text": "天堂号商品偏好"},
		"reward_text": "星髓矿 +28，天堂号商品偏好",
	},
	{
		"id": "lock_warped_vendor",
		"title": "锁住星核观测窗",
		"description": "扭曲读数被压进采购天线，下一次商品更容易出现追踪与引力装备。",
		"goal_type": "complete_family",
		"target": "warped",
		"required": 1,
		"reward": {"minerals": 26, "shop_focus_family": "warped", "shop_focus_text": "扭曲星核商品偏好"},
		"reward_text": "星髓矿 +26，扭曲星核商品偏好",
	},
	{
		"id": "seal_hell_eye_redline",
		"title": "封存赤红热线",
		"description": "地狱之眼的高温回路短暂稳定，方舟会让过载相关装备更容易出现。",
		"goal_type": "complete_nodes",
		"required": 4,
		"reward": {"compute": 1, "shop_focus_family": "hell_eye", "shop_focus_text": "地狱之眼商品偏好"},
		"reward_text": "装配容量 +1，地狱之眼商品偏好",
	},
	{
		"id": "open_divine_relay_crate",
		"title": "开启圣翼转运箱",
		"description": "一枚护航转运箱落进近地轨道，清出奖励缓存后，僚机蓝图会随补给一并入库。",
		"goal_type": "complete_type",
		"target": NODE_REWARD,
		"required": 1,
		"reward": {"minerals": 22, "equipment_family": "divine", "shop_focus_family": "divine", "shop_focus_text": "神明使者商品偏好"},
		"reward_text": "星髓矿 +22，获得神明使者装备并提高商品偏好",
	},
	{
		"id": "chart_star_marrow_lane",
		"title": "稳住星髓矿脉",
		"description": "方舟需要一段稳定矿线校准采购端口，完成星髓矿脉航线后，商店会优先标记基础补给。",
		"goal_type": "complete_ore_source",
		"target": "star_marrow",
		"required": 1,
		"reward": {"minerals": 36, "shop_focus_ore_source": "star_marrow", "shop_focus_text": "星髓采购校准"},
		"reward_text": "星髓矿 +36，星髓采购校准",
	},
	{
		"id": "chart_gleam_crystal_lane",
		"title": "采亮辉晶航线",
		"description": "辉晶簇的回收读数足够明亮，清出一处辉晶矿线后，方舟会把采购清单调向高亮晶体补给。",
		"goal_type": "complete_ore_source",
		"target": "gleam_crystal",
		"required": 1,
		"reward": {"minerals": 40, "shop_focus_ore_source": "gleam_crystal", "shop_focus_text": "辉晶采购校准"},
		"reward_text": "星髓矿 +40，辉晶采购校准",
	},
	{
		"id": "chart_rift_cluster_lane",
		"title": "缝合裂隙晶簇",
		"description": "裂隙晶簇会把回收队的航标切成碎光，完成对应矿线后，商店会记录这类分裂矿源。",
		"goal_type": "complete_ore_source",
		"target": "rift_cluster",
		"required": 1,
		"reward": {"minerals": 42, "shop_focus_ore_source": "rift_cluster", "shop_focus_text": "裂晶采购校准"},
		"reward_text": "星髓矿 +42，裂晶采购校准",
	},
	{
		"id": "chart_deep_core_lane",
		"title": "启封深层矿核",
		"description": "深层矿核数量稀少但信号厚重，拿下一处矿核航线后，方舟会把重型矿源写进采购参数。",
		"goal_type": "complete_ore_source",
		"target": "deep_core",
		"required": 1,
		"reward": {"minerals": 46, "shop_focus_ore_source": "deep_core", "shop_focus_text": "核髓采购校准"},
		"reward_text": "星髓矿 +46，核髓采购校准",
	},
]
const MAP_RING_COUNTS: Array[int] = [5, 8, 11]
# Keep the formal world map wide enough for its route graph.  The previous
# radii made the map look cramped once the special beacon nodes were added.
const MAP_RING_RADII: Array[float] = [260.0, 470.0, 680.0]
const MAP_SPIDER_INITIAL_NODE_COUNT_MIN: int = 3
const MAP_SPIDER_INITIAL_NODE_COUNT_MAX: int = 5
const MAP_SPIDER_LAYER_COUNT: int = 4
const MAP_SPIDER_MAIN_NODE_COUNT_MIN: int = 45
const MAP_SPIDER_MAIN_NODE_COUNT_MAX: int = 55
const MAP_SPIDER_PATH_COUNT: int = 4
const MAP_REWARD_PATH_COUNT: int = 2
const MAP_BEACON_PATH_COUNT: int = 2
const MAP_SPIDER_LATERAL_DEPTH_COUNT: int = 3
const MAP_SPIDER_MIN_RADIUS: float = 250.0
const MAP_SPIDER_RADIUS_STEP: float = 150.0
const MAP_SPIDER_RADIUS_JITTER: float = 16.0
const MAP_SPIDER_MAX_PATH_BEND: float = deg_to_rad(12.0)
const MAP_SPIDER_NODE_ANGLE_JITTER: float = deg_to_rad(3.0)
const MAP_SPIDER_GAP_JITTER: float = deg_to_rad(10.0)
const MAP_LONG_LINK_LENGTH: float = 270.0
const MAP_BRIDGE_NEIGHBOR_DISTANCE: float = 240.0
const MAP_NODE_MIN_DISTANCE: float = 118.0
const MAP_WEB_ROOT_MAX_DEGREE: int = MAP_SPIDER_INITIAL_NODE_COUNT_MAX
const MAP_WEB_NODE_MAX_DEGREE: int = 3
const MAP_WEB_TERMINAL_MAX_DEGREE: int = 2
const MAP_WEB_RELAY_MAX_DEGREE: int = 3
const MAP_WEB_BRIDGE_MAX_DEGREE: int = 4
const MAP_WEB_NEAREST_CANDIDATE_COUNT: int = 4
const MAP_WEB_MIN_LOCAL_LINK_LENGTH: float = 132.0
const MAP_WEB_MAX_LOCAL_LINK_LENGTH: float = 260.0
const MAP_WEB_MIN_LINK_ANGLE: float = deg_to_rad(30.0)
const MAP_POSITION_SEARCH_STEP: float = 28.0
const MAP_POSITION_SEARCH_RINGS: int = 12
const MAP_POSITION_SEARCH_SAMPLES: int = 24
const MAP_BATTLE_NODE_COUNT: int = 30
const MAP_EVENT_NODE_COUNT: int = 12
const MAP_REWARD_NODE_COUNT: int = 6
const BATTLE_NODE_PROFILES: Array[Dictionary] = [
	{
		"id": "patrol_vanguard",
		"title": "巡逻前锋",
		"description": "敌方前锋舰队维持中等巡逻密度，航道里仍留有可回收残件。",
		"threat": 2,
		"room_config": {
			"large_space_rock_count": 7,
			"trap_count": 5,
			"chest_crystal_count": 9,
			"clutter_count": 36,
			"enemy_spawn_interval": 34.0,
			"max_patrol_enemy_count": 9,
			"family_bias": "paradise",
			"family_weight_boost": 2.8,
			"patrol_path_min_count": 2,
			"patrol_path_max_count": 4,
			"elite_replacement_min": 1,
			"elite_replacement_max": 2,
		},
	},
	{
		"id": "turret_nest",
		"title": "炮塔巢区",
		"description": "自动炮塔与障碍物结成固定火力网，冲刺角度会决定能否穿过去。",
		"threat": 3,
		"room_config": {
			"large_space_rock_count": 11,
			"trap_count": 8,
			"chest_crystal_count": 8,
			"clutter_count": 28,
			"enemy_spawn_interval": 48.0,
			"max_patrol_enemy_count": 7,
			"family_bias": "colossus",
			"family_weight_boost": 3.0,
			"patrol_path_min_count": 2,
			"patrol_path_max_count": 3,
			"elite_replacement_min": 1,
			"elite_replacement_max": 3,
		},
	},
	{
		"id": "mine_web",
		"title": "雷网封锁",
		"description": "陷阱密集铺开，敌机正把航线压向更危险的雷网边缘。",
		"threat": 4,
		"room_config": {
			"large_space_rock_count": 8,
			"trap_count": 15,
			"chest_crystal_count": 10,
			"clutter_count": 34,
			"enemy_spawn_interval": 38.0,
			"max_patrol_enemy_count": 9,
			"family_bias": "warped",
			"family_weight_boost": 3.4,
			"patrol_path_min_count": 3,
			"patrol_path_max_count": 4,
			"elite_replacement_min": 1,
			"elite_replacement_max": 2,
		},
	},
	{
		"id": "elite_escort",
		"title": "精英护航",
		"description": "巡逻数量并不夸张，但精锐护航节点会把单点火力逼到极限。",
		"threat": 5,
		"room_config": {
			"large_space_rock_count": 6,
			"trap_count": 6,
			"chest_crystal_count": 11,
			"clutter_count": 30,
			"enemy_spawn_interval": 28.0,
			"max_patrol_enemy_count": 12,
			"family_bias": "hell_eye",
			"family_weight_boost": 3.8,
			"patrol_path_min_count": 2,
			"patrol_path_max_count": 4,
			"elite_replacement_min": 2,
			"elite_replacement_max": 4,
		},
	},
	{
		"id": "ambush_salvage",
		"title": "伏击回收带",
		"description": "回收物富集在伏击带中央，高爆发火力才能抢在包围闭合前兑现收益。",
		"threat": 4,
		"room_config": {
			"large_space_rock_count": 9,
			"trap_count": 7,
			"chest_crystal_count": 14,
			"clutter_count": 52,
			"enemy_spawn_interval": 24.0,
			"max_patrol_enemy_count": 13,
			"family_bias": "paradise",
			"family_weight_boost": 3.6,
			"patrol_path_min_count": 3,
			"patrol_path_max_count": 5,
			"elite_replacement_min": 1,
			"elite_replacement_max": 3,
		},
	},
	{
		"id": "hunter_chain",
		"title": "猎杀链路",
		"description": "敌方信号链路持续亮起，追击压力会沿着整条航道蔓延。",
		"threat": 5,
		"room_config": {
			"large_space_rock_count": 5,
			"trap_count": 9,
			"chest_crystal_count": 8,
			"clutter_count": 32,
			"enemy_spawn_interval": 20.0,
			"max_patrol_enemy_count": 15,
			"family_bias": "divine",
			"family_weight_boost": 4.0,
			"patrol_path_min_count": 4,
			"patrol_path_max_count": 6,
			"elite_replacement_min": 2,
			"elite_replacement_max": 5,
		},
	},
	{
		"id": "ramming_corridor",
		"title": "撞角回廊",
		"description": "巨构残骸把航道挤成直线，重甲单位会沿着缺口一轮轮压上来。",
		"threat": 4,
		"room_config": {
			"large_space_rock_count": 13,
			"trap_count": 6,
			"chest_crystal_count": 10,
			"clutter_count": 32,
			"enemy_spawn_interval": 30.0,
			"max_patrol_enemy_count": 11,
			"family_bias": "colossus",
			"family_weight_boost": 4.2,
			"patrol_path_min_count": 2,
			"patrol_path_max_count": 5,
			"elite_replacement_min": 2,
			"elite_replacement_max": 4,
		},
	},
	{
		"id": "lattice_barrage",
		"title": "格栅弹幕",
		"description": "天堂号残留火控把碎片间隙编成格栅，任何停顿都会被交叉火力盖住。",
		"threat": 5,
		"room_config": {
			"large_space_rock_count": 7,
			"trap_count": 8,
			"chest_crystal_count": 9,
			"clutter_count": 30,
			"enemy_spawn_interval": 24.0,
			"max_patrol_enemy_count": 14,
			"family_bias": "paradise",
			"family_weight_boost": 4.4,
			"patrol_path_min_count": 3,
			"patrol_path_max_count": 6,
			"elite_replacement_min": 1,
			"elite_replacement_max": 4,
		},
	},
	{
		"id": "lens_maze",
		"title": "折镜迷宫",
		"description": "扭曲透镜散落在航路两侧，敌人会借偏折弹道逼迫你不断换位。",
		"threat": 4,
		"room_config": {
			"large_space_rock_count": 10,
			"trap_count": 10,
			"chest_crystal_count": 12,
			"clutter_count": 34,
			"enemy_spawn_interval": 32.0,
			"max_patrol_enemy_count": 10,
			"family_bias": "warped",
			"family_weight_boost": 4.1,
			"patrol_path_min_count": 3,
			"patrol_path_max_count": 5,
			"elite_replacement_min": 2,
			"elite_replacement_max": 3,
		},
	},
	{
		"id": "bloodline_watch",
		"title": "血线凝视",
		"description": "地狱之眼的残线拖过战场，巡逻机不多，却会把伤害窗口拉得很长。",
		"threat": 5,
		"room_config": {
			"large_space_rock_count": 6,
			"trap_count": 12,
			"chest_crystal_count": 9,
			"clutter_count": 31,
			"enemy_spawn_interval": 26.0,
			"max_patrol_enemy_count": 12,
			"family_bias": "hell_eye",
			"family_weight_boost": 4.5,
			"patrol_path_min_count": 2,
			"patrol_path_max_count": 5,
			"elite_replacement_min": 2,
			"elite_replacement_max": 5,
		},
	},
	{
		"id": "seraph_net",
		"title": "圣羽围网",
		"description": "神使信标把巡逻单位串成围网，僚机残骸会在火线中不断改变落点。",
		"threat": 5,
		"room_config": {
			"large_space_rock_count": 8,
			"trap_count": 8,
			"chest_crystal_count": 11,
			"clutter_count": 46,
			"enemy_spawn_interval": 22.0,
			"max_patrol_enemy_count": 15,
			"family_bias": "divine",
			"family_weight_boost": 4.6,
			"patrol_path_min_count": 4,
			"patrol_path_max_count": 6,
			"elite_replacement_min": 2,
			"elite_replacement_max": 5,
		},
	},
	{
		"id": "impact_breach",
		"title": "破阵撞线",
		"description": "巨构护甲片排成窄门，敌方重兵会守住撞线后的反弹角度。",
		"threat": 5,
		"room_config": {
			"large_space_rock_count": 16,
			"trap_count": 7,
			"chest_crystal_count": 10,
			"clutter_count": 36,
			"enemy_spawn_interval": 26.0,
			"max_patrol_enemy_count": 13,
			"family_bias": "colossus",
			"family_weight_boost": 4.8,
			"patrol_path_min_count": 3,
			"patrol_path_max_count": 5,
			"elite_replacement_min": 3,
			"elite_replacement_max": 5,
		},
	},
	{
		"id": "fever_pulse_field",
		"title": "热脉潮场",
		"description": "赤色脉冲在残骸间起伏，敌群会用短促接敌逼你频繁交换伤害。",
		"threat": 4,
		"room_config": {
			"large_space_rock_count": 7,
			"trap_count": 13,
			"chest_crystal_count": 11,
			"clutter_count": 42,
			"enemy_spawn_interval": 22.0,
			"max_patrol_enemy_count": 14,
			"family_bias": "hell_eye",
			"family_weight_boost": 4.7,
			"patrol_path_min_count": 3,
			"patrol_path_max_count": 5,
			"elite_replacement_min": 2,
			"elite_replacement_max": 5,
		},
	},
	{
		"id": "choir_intercept",
		"title": "圣歌截击",
		"description": "多层僚机信号交替点亮，巡逻队会分批切入，把撤离路线拆成数段。",
		"threat": 4,
		"room_config": {
			"large_space_rock_count": 8,
			"trap_count": 9,
			"chest_crystal_count": 12,
			"clutter_count": 50,
			"enemy_spawn_interval": 24.0,
			"max_patrol_enemy_count": 16,
			"family_bias": "divine",
			"family_weight_boost": 4.9,
			"patrol_path_min_count": 4,
			"patrol_path_max_count": 7,
			"elite_replacement_min": 2,
			"elite_replacement_max": 5,
		},
	},
	{
		"id": "mixed_salvo",
		"title": "混编齐射",
		"description": "多家族信号彼此缠绕，敌人构成不稳定，但每轮接敌都会更难预判。",
		"threat": 4,
		"room_config": {
			"large_space_rock_count": 9,
			"trap_count": 9,
			"chest_crystal_count": 10,
			"clutter_count": 38,
			"enemy_spawn_interval": 28.0,
			"max_patrol_enemy_count": 13,
			"family_bias": "warped",
			"family_weight_boost": 2.5,
			"patrol_path_min_count": 3,
			"patrol_path_max_count": 6,
			"elite_replacement_min": 1,
			"elite_replacement_max": 5,
		},
	},
]
const REWARD_NODE_PROFILES: Array[Dictionary] = [
	{
		"id": "ore_vault",
		"title": "星髓矿库",
		"description": "矿脉在舱壁后成片发光，巡逻信号反而稀薄。",
		"reward_mult_bonus": 0.32,
		"equipment_chance_bonus": 0.02,
		"cache_family_bias": "general",
		"room_config": {
			"large_space_rock_count": 14,
			"trap_count": 3,
			"chest_crystal_count": 18,
			"clutter_count": 42,
			"enemy_spawn_interval": 78.0,
			"max_patrol_enemy_count": 5,
			"reward_mineral_mult": 1.35,
		},
	},
	{
		"id": "sealed_armory",
		"title": "封存军械库",
		"description": "装备蓝图概率更高，但自动防卫设施仍在运行。",
		"reward_mult_bonus": 0.16,
		"equipment_chance_bonus": 0.24,
		"cache_family_bias": "paradise",
		"room_config": {
			"large_space_rock_count": 8,
			"trap_count": 9,
			"chest_crystal_count": 15,
			"clutter_count": 34,
			"enemy_spawn_interval": 54.0,
			"max_patrol_enemy_count": 7,
			"reward_mineral_mult": 1.16,
		},
	},
	{
		"id": "silent_cache",
		"title": "静默补给舱",
		"description": "补给完整且干扰较弱，是相对稳定的恢复型奖励节点。",
		"reward_mult_bonus": 0.22,
		"equipment_chance_bonus": 0.08,
		"cache_family_bias": "divine",
		"room_config": {
			"large_space_rock_count": 11,
			"trap_count": 2,
			"chest_crystal_count": 14,
			"clutter_count": 30,
			"enemy_spawn_interval": 90.0,
			"max_patrol_enemy_count": 4,
			"reward_mineral_mult": 1.22,
		},
	},
	{
		"id": "hazard_cache",
		"title": "高危收益缓存",
		"description": "缓存价值高，但陷阱和巡逻密度明显升高。",
		"reward_mult_bonus": 0.42,
		"equipment_chance_bonus": 0.16,
		"cache_family_bias": "colossus",
		"room_config": {
			"large_space_rock_count": 12,
			"trap_count": 13,
			"chest_crystal_count": 19,
			"clutter_count": 46,
			"enemy_spawn_interval": 36.0,
			"max_patrol_enemy_count": 10,
			"reward_mineral_mult": 1.48,
		},
	},
	{
		"id": "ancient_foundry",
		"title": "古代装配工坊",
		"description": "古代装配臂仍卡在半空，资源箱与蓝图残片被障碍层层包住。",
		"reward_mult_bonus": 0.28,
		"equipment_chance_bonus": 0.18,
		"cache_family_bias": "warped",
		"room_config": {
			"large_space_rock_count": 16,
			"trap_count": 6,
			"chest_crystal_count": 17,
			"clutter_count": 58,
			"enemy_spawn_interval": 48.0,
			"max_patrol_enemy_count": 8,
			"reward_mineral_mult": 1.3,
		},
	},
	{
		"id": "colossus_spine_cache",
		"title": "巨构脊柱仓",
		"description": "粗重装甲梁围住一排冷却货柜，冲锋组件的残留信号非常清晰。",
		"reward_mult_bonus": 0.24,
		"equipment_chance_bonus": 0.2,
		"cache_family_bias": "colossus",
		"room_config": {
			"large_space_rock_count": 15,
			"trap_count": 5,
			"chest_crystal_count": 16,
			"clutter_count": 44,
			"enemy_spawn_interval": 58.0,
			"max_patrol_enemy_count": 7,
			"reward_mineral_mult": 1.26,
		},
	},
	{
		"id": "paradise_magazine",
		"title": "天堂弹仓",
		"description": "弹仓仍在缓慢吐出发光弹链，蓝图碎片混在矿箱之间闪烁。",
		"reward_mult_bonus": 0.18,
		"equipment_chance_bonus": 0.26,
		"cache_family_bias": "paradise",
		"room_config": {
			"large_space_rock_count": 7,
			"trap_count": 10,
			"chest_crystal_count": 18,
			"clutter_count": 36,
			"enemy_spawn_interval": 50.0,
			"max_patrol_enemy_count": 8,
			"reward_mineral_mult": 1.18,
		},
	},
	{
		"id": "red_iris_vault",
		"title": "赤虹密库",
		"description": "黑红色的虹膜薄片贴在舱壁上，靠近时狂热读数会自行升温。",
		"reward_mult_bonus": 0.26,
		"equipment_chance_bonus": 0.18,
		"cache_family_bias": "hell_eye",
		"room_config": {
			"large_space_rock_count": 10,
			"trap_count": 11,
			"chest_crystal_count": 17,
			"clutter_count": 39,
			"enemy_spawn_interval": 52.0,
			"max_patrol_enemy_count": 7,
			"reward_mineral_mult": 1.28,
		},
	},
	{
		"id": "seraph_relay_hold",
		"title": "圣羽中继舱",
		"description": "中继舱里漂着尚未熄灭的僚机核心，金色接口仍能回应方舟信号。",
		"reward_mult_bonus": 0.2,
		"equipment_chance_bonus": 0.22,
		"cache_family_bias": "divine",
		"room_config": {
			"large_space_rock_count": 9,
			"trap_count": 6,
			"chest_crystal_count": 16,
			"clutter_count": 48,
			"enemy_spawn_interval": 64.0,
			"max_patrol_enemy_count": 6,
			"reward_mineral_mult": 1.24,
		},
	},
	{
		"id": "mixed_scrap_bank",
		"title": "混合残件库",
		"description": "不同家族的残件被粗暴压在同一座货架里，收益杂乱却丰厚。",
		"reward_mult_bonus": 0.34,
		"equipment_chance_bonus": 0.12,
		"cache_family_bias": "general",
		"room_config": {
			"large_space_rock_count": 13,
			"trap_count": 8,
			"chest_crystal_count": 20,
			"clutter_count": 60,
			"enemy_spawn_interval": 44.0,
			"max_patrol_enemy_count": 9,
			"reward_mineral_mult": 1.42,
		},
	},
]
const EVENT_PROFILES: Array[Dictionary] = [
	{
		"id": "old_supply_chain",
		"title": "旧时代补给链",
		"category": "minerals",
		"weight": 1.2,
		"mineral_min": 18,
		"mineral_max": 32,
		"risk_level": 0,
		"risk_label": "安全",
		"reward_tag": "矿物",
		"cost": {},
		"description": "你回收了一段仍能解码的补给链路。",
	},
	{
		"id": "ark_medical_relay",
		"title": "方舟医疗中继",
		"category": "heal",
		"weight": 0.9,
		"heal_min": 22,
		"heal_max": 40,
		"risk_level": 0,
		"risk_label": "安全",
		"reward_tag": "治疗",
		"cost": {},
		"description": "方舟核心接管残留医疗协议，快速修复机体结构。",
	},
	{
		"id": "sealed_weapon_cache",
		"title": "密封武备缓存",
		"category": "equipment",
		"weight": 0.9,
		"risk_level": 1,
		"risk_label": "谨慎",
		"reward_tag": "装备",
		"cost": {"hp_loss": 6},
		"description": "缓存中保留着一件可重构装备蓝图。",
	},
	{
		"id": "compute_splice",
		"title": "算力拼接端口",
		"category": "compute",
		"weight": 0.65,
		"compute_bonus": 1,
		"risk_level": 1,
		"risk_label": "谨慎",
		"reward_tag": "算力",
		"cost": {"mineral_cost": 8},
		"description": "你将一段独立演算端口接入方舟核心。",
	},
	{
		"id": "family_resonance",
		"title": "家族共振档案",
		"category": "equipment",
		"weight": 0.75,
		"prefer_family": true,
		"risk_level": 1,
		"risk_label": "谨慎",
		"reward_tag": "定向装备",
		"cost": {"hp_loss": 8},
		"description": "档案中的装备信号与本节点家族倾向高度一致。",
	},
	{
		"id": "beacon_sync",
		"title": "远距信标同步",
		"category": "special",
		"weight": 0.55,
		"risk_level": 2,
		"risk_label": "高危",
		"reward_tag": "增益信标",
		"cost": {"crisis_add": 1},
		"description": "一枚远距增益信标被提前同步进方舟航路。",
	},
	{
		"id": "salvage_contract",
		"title": "回收承包合约",
		"category": "minerals",
		"weight": 0.85,
		"mineral_min": 28,
		"mineral_max": 46,
		"risk_level": 2,
		"risk_label": "高危",
		"reward_tag": "大量矿物",
		"cost": {"hp_loss": 12, "crisis_add": 1},
		"contract": {
			"contract_id": "salvage_contract",
			"title": "回收承包合约",
			"effect_type": "salvage_pressure",
			"duration_nodes": 2,
			"mineral_bonus_rate": 0.35,
			"extra_crisis_on_complete": 1,
			"description": "接下来 2 个完成节点的矿物结算 +35%，但每次额外提升 1 点危机。",
		},
		"description": "你签下一段高风险回收合约，立刻兑现一批星髓矿。",
	},
	{
		"id": "crisis_blackbox",
		"title": "危机黑匣",
		"category": "mixed",
		"weight": 0.7,
		"mineral_min": 10,
		"mineral_max": 18,
		"heal_min": 8,
		"heal_max": 18,
		"risk_level": 2,
		"risk_label": "高危",
		"reward_tag": "混合收益",
		"cost": {"hp_loss": 5, "crisis_add": 1},
		"contract": {
			"contract_id": "crisis_blackbox",
			"title": "黑匣解码窗口",
			"effect_type": "blackbox_pressure",
			"duration_nodes": 2,
			"equipment_chance_bonus": 0.18,
			"frenzy_gain_mult": 0.72,
			"description": "接下来 2 个完成节点的装备出现率 +18%，但武器过载积累降至 72%。",
		},
		"description": "黑匣记录提供少量资源，也修正了近期战损参数。",
	},
	{
		"id": "ore_auction",
		"title": "星髓暗拍",
		"category": "minerals",
		"weight": 0.72,
		"mineral_min": 36,
		"mineral_max": 62,
		"risk_level": 1,
		"risk_label": "谨慎",
		"reward_tag": "矿物竞拍",
		"cost": {"mineral_cost": 10},
		"description": "一段匿名竞拍链路愿意用旧矿抵押换取更完整的星髓矿箱。",
	},
	{
		"id": "field_surgery_pod",
		"title": "战地修补舱",
		"category": "heal",
		"weight": 0.76,
		"heal_min": 34,
		"heal_max": 58,
		"risk_level": 1,
		"risk_label": "谨慎",
		"reward_tag": "深度修复",
		"cost": {"crisis_add": 1},
		"description": "修补舱会强行唤醒沉睡纳米针，伤口愈合时也会点亮附近警戒网。",
	},
	{
		"id": "cold_storage_blueprint",
		"title": "冷库蓝图",
		"category": "equipment",
		"weight": 0.68,
		"prefer_family": true,
		"risk_level": 0,
		"risk_label": "安全",
		"reward_tag": "稳态蓝图",
		"cost": {},
		"description": "冷库里的蓝图没有完全解冻，却足够重构出一件可用装备。",
	},
	{
		"id": "overdrawn_core",
		"title": "透支核心",
		"category": "compute",
		"weight": 0.56,
		"compute_bonus": 2,
		"risk_level": 2,
		"risk_label": "高危",
		"reward_tag": "大量算力",
		"cost": {"hp_loss": 10, "crisis_add": 1},
		"description": "核心端口还剩一段暴烈余量，接入之后，方舟舱壁会短暂发烫。",
	},
	{
		"id": "silent_beacon_hook",
		"title": "静默信标钩",
		"category": "special",
		"weight": 0.48,
		"risk_level": 1,
		"risk_label": "谨慎",
		"reward_tag": "信标接入",
		"cost": {"mineral_cost": 14},
		"description": "一枚静默钩索可以绕开破损航线，把远处信标提前拽入方舟网络。",
	},
	{
		"id": "fire_sale_manifest",
		"title": "清仓舱单",
		"category": "mixed",
		"weight": 0.64,
		"mineral_min": 16,
		"mineral_max": 30,
		"heal_min": 12,
		"heal_max": 24,
		"risk_level": 0,
		"risk_label": "安全",
		"reward_tag": "补给舱单",
		"cost": {},
		"description": "舱单上的货物已经散落很久，能回收多少，全看方舟扫描还能认出多少。",
	},
	{
		"id": "mercenary_marker",
		"title": "雇佣标记",
		"category": "contract",
		"weight": 0.52,
		"mineral_min": 24,
		"mineral_max": 38,
		"risk_level": 2,
		"risk_label": "高危",
		"reward_tag": "战利合约",
		"cost": {"hp_loss": 9},
		"contract": {
			"contract_id": "mercenary_marker",
			"title": "雇佣标记",
			"effect_type": "salvage_pressure",
			"duration_nodes": 3,
			"mineral_bonus_rate": 0.22,
			"extra_crisis_on_complete": 1,
			"description": "接下来 3 个完成节点的矿物结算 +22%，但每次额外提升 1 点危机。",
		},
		"description": "旧雇佣兵留下的标记仍能兑换报酬，只是追踪这笔报酬的人也会醒来。",
	},
	{
		"id": "ark_stability_warrant",
		"title": "方舟稳态担保",
		"category": "contract",
		"weight": 0.54,
		"mineral_min": 18,
		"mineral_max": 30,
		"risk_level": 1,
		"risk_label": "谨慎",
		"reward_tag": "稳态契约",
		"cost": {"mineral_cost": 6},
		"contract": {
			"contract_id": "ark_stability_warrant",
			"title": "方舟稳态担保",
			"effect_type": "stability_trade",
			"duration_nodes": 3,
			"mineral_bonus_rate": 0.16,
			"equipment_chance_bonus": 0.06,
			"shop_focus_text": "通用商品偏好",
			"description": "接下来 3 个完成节点内，矿物结算与装备出现率小幅提高；刷新商品时更容易出现通用装备。",
		},
		"description": "一份保守但干净的担保合同，把回收、检出和采购都往稳态航路上轻轻推了一把。",
	},
	{
		"id": "unstable_decoder",
		"title": "不稳解码器",
		"category": "contract",
		"weight": 0.5,
		"risk_level": 2,
		"risk_label": "高危",
		"reward_tag": "检出契约",
		"cost": {"crisis_add": 1},
		"contract": {
			"contract_id": "unstable_decoder",
			"title": "不稳解码器",
			"effect_type": "blackbox_pressure",
			"duration_nodes": 3,
			"equipment_chance_bonus": 0.22,
			"frenzy_gain_mult": 0.82,
			"description": "接下来 3 个完成节点的装备出现率 +22%，但武器过载积累降至 82%。",
		},
		"description": "解码器会把每个缓存都扫得更深，也会把机体情绪压得更冷。",
	},
	{
		"id": "procurement_discount",
		"title": "方舟采购折扣",
		"category": "contract",
		"weight": 0.5,
		"mineral_min": 12,
		"mineral_max": 24,
		"risk_level": 0,
		"risk_label": "安全",
		"reward_tag": "采购契约",
		"cost": {},
		"contract": {
			"contract_id": "procurement_discount",
			"title": "方舟采购折扣",
			"effect_type": "procurement_discount",
			"duration_nodes": 2,
			"shop_discount_rate": 0.25,
			"description": "接下来 2 个完成节点内，商店装备采购价格降低 25%，折后仍以星髓矿结算。",
		},
		"description": "旧转运栈愿意承认方舟编号，短时间内把装备货价压到更好谈的区间。",
	},
	{
		"id": "procurement_reroll_voucher",
		"title": "货单校准券",
		"category": "contract",
		"weight": 0.52,
		"mineral_min": 8,
		"mineral_max": 18,
		"risk_level": 0,
		"risk_label": "安全",
		"reward_tag": "刷新商品",
		"cost": {},
		"contract": {
			"contract_id": "shop_reroll_voucher",
			"title": "货单校准券",
			"effect_type": "shop_reroll_voucher",
			"duration_nodes": 2,
			"free_shop_rerolls": 1,
			"description": "接下来 2 个完成节点内，商店保留 1 次免费刷新商品的机会。",
		},
		"description": "补给终端吐出一枚短效货单券，方舟可以借它重新校准下一批装备。",
	},
	{
		"id": "colossus_impact_route",
		"title": "巨构撞角航线",
		"category": "contract",
		"weight": 0.58,
		"mineral_min": 14,
		"mineral_max": 24,
		"risk_level": 1,
		"risk_label": "谨慎",
		"reward_tag": "冲锋契约",
		"cost": {"hp_loss": 7},
		"contract": {
			"contract_id": "colossus_impact_route",
			"title": "巨构撞角航线",
			"effect_type": "family_route",
			"family_bias": "colossus",
			"duration_nodes": 2,
			"dash_distance_mult": 1.14,
			"dash_damage_mult": 1.16,
			"dash_aftershock_radius_bonus": 48.0,
			"shop_focus_family": "colossus",
			"shop_focus_text": "星间巨构商品偏好",
			"description": "接下来 2 个完成节点内，冲锋距离与撞击威力提高，余震边缘更宽。",
		},
		"description": "一段巨构龙骨航线仍能校准撞角，代价是机体外壳会先承受一次硬压。",
	},
	{
		"id": "paradise_barrage_route",
		"title": "天堂齐射排程",
		"category": "contract",
		"weight": 0.58,
		"mineral_min": 12,
		"mineral_max": 22,
		"risk_level": 1,
		"risk_label": "谨慎",
		"reward_tag": "火力契约",
		"cost": {"mineral_cost": 8},
		"contract": {
			"contract_id": "paradise_barrage_route",
			"title": "天堂齐射排程",
			"effect_type": "family_route",
			"family_bias": "paradise",
			"duration_nodes": 2,
			"bullet_count_bonus": 1,
			"fire_rate_mult": 0.94,
			"bullet_speed_mult": 1.08,
			"shop_focus_family": "paradise",
			"shop_focus_text": "天堂号商品偏好",
			"description": "接下来 2 个完成节点内，主炮额外铺开一层弹幕，弹速与射击节拍同步上扬。",
		},
		"description": "天堂号残留排程把弹链塞进方舟火控，星髓押金会立刻被扣下。",
	},
	{
		"id": "warped_tide_route",
		"title": "星核潮汐窗口",
		"category": "contract",
		"weight": 0.56,
		"mineral_min": 10,
		"mineral_max": 20,
		"risk_level": 1,
		"risk_label": "谨慎",
		"reward_tag": "引力契约",
		"cost": {"crisis_add": 1},
		"contract": {
			"contract_id": "warped_tide_route",
			"title": "星核潮汐窗口",
			"effect_type": "family_route",
			"family_bias": "warped",
			"duration_nodes": 2,
			"homing_strength_bonus": 1.2,
			"gravity_pull_strength_bonus": 90.0,
			"gravity_pull_radius_bonus": 80.0,
			"shop_focus_family": "warped",
			"shop_focus_text": "扭曲星核商品偏好",
			"description": "接下来 2 个完成节点内，弹道更愿意贴近目标，弱引力会把小群拖进火线。",
		},
		"description": "扭曲星核的潮汐窗口短暂打开，方舟航路也因此被更多观察线看见。",
	},
	{
		"id": "hell_eye_redline_route",
		"title": "赤线热病签",
		"category": "contract",
		"weight": 0.56,
		"mineral_min": 10,
		"mineral_max": 18,
		"risk_level": 2,
		"risk_label": "高危",
		"reward_tag": "狂热契约",
		"cost": {"hp_loss": 6, "crisis_add": 1},
		"contract": {
			"contract_id": "hell_eye_redline_route",
			"title": "赤线热病签",
			"effect_type": "family_route",
			"family_bias": "hell_eye",
			"duration_nodes": 2,
			"frenzy_gain_mult": 1.22,
			"frenzy_damage_mult": 1.12,
			"frenzy_damage_taken_mult": 0.9,
			"shop_focus_family": "hell_eye",
			"shop_focus_text": "地狱之眼商品偏好",
			"description": "接下来 2 个完成节点内，狂热升温更快，爆发期火力与防线一起烧亮。",
		},
		"description": "地狱之眼留下的赤线仍在跳动，签下它时，机体会先被热浪咬住。",
	},
	{
		"id": "divine_seraph_route",
		"title": "圣羽护航令",
		"category": "contract",
		"weight": 0.56,
		"mineral_min": 12,
		"mineral_max": 20,
		"risk_level": 1,
		"risk_label": "谨慎",
		"reward_tag": "僚机契约",
		"cost": {"mineral_cost": 10},
		"contract": {
			"contract_id": "divine_seraph_route",
			"title": "圣羽护航令",
			"effect_type": "family_route",
			"family_bias": "divine",
			"duration_nodes": 2,
			"drone_slots_bonus": 1,
			"drone_fire_interval_mult": 0.9,
			"drone_damage_mult": 1.14,
			"shop_focus_family": "divine",
			"shop_focus_text": "神明使者商品偏好",
			"description": "接下来 2 个完成节点内，额外僚机加入护航，友军火线回应得更快。",
		},
		"description": "神明使者旧令仍能召来一队短程护航，补给接口会先吃掉一笔星髓。",
	},
]

var run_active: bool = false
var run_finished: bool = false
var run_victory: bool = false
var map_nodes: Array[Dictionary] = []
var crisis_level: int = 0
var advanced_crisis_level: int = 0
var compute_capacity: int = 5
var _minerals: int = 0
var minerals: int:
	get:
		return _minerals
	set(value):
		var requested := maxi(0, value)
		if requested > _minerals and calibration_mineral_debt > 0:
			var repayment := mini(calibration_mineral_debt, requested - _minerals)
			calibration_mineral_debt -= repayment
			requested -= repayment
		_minerals = requested
var completed_node_count: int = 0
var current_node_id: int = -1
var current_room_mineral_mult: float = 1.0
var pending_room_loot: Dictionary = {}
var equipment_inventory: Array[String] = []
var equipped_weapon: String = "pulse_cannon"
var equipped_auxiliaries: Array[String] = []
var cleared_crisis_thresholds: Array[int] = []
var pending_boss_threshold: int = 0
var pending_crisis_broadcast: String = ""
var last_crisis_alert_intro_threshold: int = 0
var map_layout_seed: int = 0
var pending_boss_scene: String = ""
var last_boss_reward: Dictionary = {}
var last_boss_completion_summary: Dictionary = {}
var pending_boss_reward: Dictionary = {}
var last_result_summary: Dictionary = {}
var last_node_completion_summary: Dictionary = {}
var active_special_bonus_ids: Array[String] = []
var active_event_contracts: Array[Dictionary] = []
var active_route_directives: Array[Dictionary] = []
var retired_route_directive_ids: Array[String] = []
var active_run_conditions: Array[Dictionary] = []
var force_next_event_id: String = ""
var shop_offer_ids: Array[String] = []
var shop_draft_initialized: bool = false
var shop_reroll_count: int = 0
var shop_preferred_family: String = ""
var shop_beacon_family: String = ""
var shop_beacon_bonus_name: String = ""
var shop_ore_source_focus: String = ""
var shop_ore_source_focus_text: String = ""
var calibration_snapshot: Dictionary = {}
var calibration_shop_price_mult: float = 1.0
var calibration_mineral_mult: float = 1.0
var calibration_mineral_debt: int = 0
var calibration_resonance_family: String = ""
var calibration_resonance_offer_remaining: int = 0
var crisis_modifier_snapshot: Dictionary = {}
var content_state_version: int = 0
var _committed_mutation_ids: Dictionary = {}
var _run_content_facade: RunContentFacade
var balance_telemetry: BalanceTelemetry = BalanceTelemetryScript.new()


func _ready() -> void:
	_apply_master_balance()
	_ensure_run_content_facade()


func _apply_master_balance() -> void:
	CRISIS_THRESHOLDS = [
		int(BalanceServiceScript.get_stage_value("pacing", "crisis_thresholds", 1, 5)),
		int(BalanceServiceScript.get_stage_value("pacing", "crisis_thresholds", 2, 12)),
		int(BalanceServiceScript.get_stage_value("pacing", "crisis_thresholds", 3, 21)),
	]
	TIER_EQUIPMENT_DROP_CHANCES = [
		float(BalanceServiceScript.get_stage_value("economy", "equipment_drop_chance", 1, 0.28)),
		float(BalanceServiceScript.get_stage_value("economy", "equipment_drop_chance", 2, 0.36)),
		float(BalanceServiceScript.get_stage_value("economy", "equipment_drop_chance", 3, 0.48)),
	]
	MAX_READABLE_EQUIPMENT_DROP_CHANCE = float(BalanceServiceScript.get_value("economy", "equipment_drop_chance_cap", 0.85))
	SHOP_OFFER_COUNT = int(BalanceServiceScript.get_value("economy", "shop_offer_count", SHOP_OFFER_COUNT))
	SHOP_REROLL_BASE_COST = int(BalanceServiceScript.get_value("economy", "reroll_base", SHOP_REROLL_BASE_COST))
	SHOP_REROLL_COST_STEP = int(BalanceServiceScript.get_value("economy", "reroll_stage_step", SHOP_REROLL_COST_STEP))
	SHOP_REROLL_REPEAT_STEP = int(BalanceServiceScript.get_value("economy", "reroll_repeat_step", SHOP_REROLL_REPEAT_STEP))


func start_new_run() -> void:
	randomize()
	var selected_advanced_crisis_level := 0
	if MetaProgressionState != null:
		selected_advanced_crisis_level = clampi(int(MetaProgressionState.selected_crisis_level), 0, int(MetaProgressionState.unlocked_crisis_level))
	content_state_version = 1
	_committed_mutation_ids.clear()
	balance_telemetry.clear()
	run_active = true
	run_finished = false
	run_victory = false
	crisis_level = 0
	advanced_crisis_level = selected_advanced_crisis_level
	crisis_modifier_snapshot = AdvancedCrisisResolverScript.new().resolve(advanced_crisis_level)
	balance_telemetry.record("run_started", {"crisis_level": crisis_level, "advanced_crisis_level": advanced_crisis_level})
	compute_capacity = int(BalanceServiceScript.get_value("economy", "starting_compute", 5))
	minerals = int(BalanceServiceScript.get_value("economy", "starting_minerals", 0))
	completed_node_count = 0
	current_node_id = -1
	current_room_mineral_mult = 1.0
	pending_room_loot = _empty_loot()
	equipment_inventory = ["pulse_cannon"]
	equipped_weapon = "pulse_cannon"
	equipped_auxiliaries.clear()
	cleared_crisis_thresholds.clear()
	pending_boss_threshold = 0
	last_crisis_alert_intro_threshold = 0
	map_layout_seed = 0
	pending_boss_scene = ""
	last_boss_reward.clear()
	last_boss_completion_summary.clear()
	last_result_summary.clear()
	last_node_completion_summary.clear()
	active_special_bonus_ids.clear()
	active_event_contracts.clear()
	active_route_directives.clear()
	retired_route_directive_ids.clear()
	active_run_conditions.clear()
	force_next_event_id = ""
	_reset_shop_state()
	pending_boss_reward.clear()
	_apply_preflight_calibration()
	_select_run_conditions()
	_generate_world_map()
	_apply_preflight_intel_to_map()
	_generate_route_directives()


func _apply_preflight_calibration() -> void:
	calibration_snapshot.clear()
	calibration_shop_price_mult = 1.0
	calibration_mineral_mult = 1.0
	calibration_mineral_debt = 0
	calibration_resonance_family = ""
	calibration_resonance_offer_remaining = 0
	GameManager.configure_preflight_modifiers({})
	if MetaProgressionState == null:
		return
	calibration_snapshot = MetaProgressionState.get_selected_calibration_snapshot()
	if calibration_snapshot.is_empty():
		return
	var calibration_id := String(calibration_snapshot.get("id", ""))
	var effects := Dictionary(calibration_snapshot.get("effects", {}))
	GameManager.configure_preflight_modifiers(effects)
	compute_capacity += maxi(0, int(effects.get("starting_compute_bonus", 0)))
	calibration_shop_price_mult = maxf(1.0, float(effects.get("shop_price_mult", 1.0)))
	calibration_mineral_mult = maxf(1.0, float(effects.get("mineral_mult", 1.0)))
	calibration_mineral_debt = maxi(0, int(effects.get("starting_mineral_debt", 0)))
	if int(effects.get("free_shop_rerolls", 0)) > 0:
		active_event_contracts.append({
			"id": "calibration_procurement_voucher",
			"title": String(calibration_snapshot.get("display_name", "采购凭证")),
			"free_shop_rerolls": int(effects.get("free_shop_rerolls", 0)),
			"free_shop_rerolls_used": 0,
			"remaining_nodes": 999,
		})
	if calibration_id == "resonance_compass":
		calibration_resonance_family = _normalize_shop_family(String(calibration_snapshot.get("family", "")))
		calibration_resonance_offer_remaining = maxi(0, int(effects.get("family_weight_draws", 0)))
	if bool(effects.get("grant_random_common_auxiliary", false)):
		for attempt in range(20):
			var item_id := EquipmentCatalogScript.get_random_loot_item_id(equipment_inventory, crisis_level, shop_preferred_family, randi())
			if item_id.is_empty() or item_id == "pulse_cannon" or EquipmentCatalogScript.get_rarity(item_id) != "common":
				continue
			equipment_inventory.append(item_id)
			calibration_snapshot["granted_item_id"] = item_id
			break
	if int(effects.get("map_intel_layers", 0)) > 0:
		calibration_snapshot["map_intel_layers"] = int(effects.get("map_intel_layers", 0))


func _apply_preflight_intel_to_map() -> void:
	var visible_layers := int(calibration_snapshot.get("map_intel_layers", 0))
	if visible_layers <= 0:
		return
	for index in range(map_nodes.size()):
		var node := map_nodes[index]
		if int(node.get("web_layer", 999)) < visible_layers:
			node["preflight_intel_revealed"] = true
			map_nodes[index] = node


func cancel_run() -> void:
	run_active = false
	content_state_version = 0
	_committed_mutation_ids.clear()
	run_finished = false
	run_victory = false
	last_result_summary.clear()
	current_node_id = -1
	current_room_mineral_mult = 1.0
	pending_boss_threshold = 0
	last_crisis_alert_intro_threshold = 0
	map_layout_seed = 0
	pending_boss_scene = ""
	last_boss_reward.clear()
	last_boss_completion_summary.clear()
	last_node_completion_summary.clear()
	pending_room_loot = _empty_loot()
	active_special_bonus_ids.clear()
	active_event_contracts.clear()
	active_route_directives.clear()
	retired_route_directive_ids.clear()
	active_run_conditions.clear()
	force_next_event_id = ""
	_reset_shop_state()
	pending_boss_reward.clear()


# ── 存档 ────────────────────────────────────────────────
# 存档粒度是"世界地图态"：每次回到世界地图时写盘（WorldMap._ready 调用）。
# 探索房间/Boss 战内的实时进度不存，中途退出会回退到进节点前的地图状态。

func has_saved_run() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_run() -> void:
	if not run_active or run_finished:
		return
	var data := {
		"version": SAVE_VERSION,
		"content_state_version": content_state_version,
		"map_nodes": map_nodes,
		"crisis_level": crisis_level,
		"advanced_crisis_level": advanced_crisis_level,
		"compute_capacity": compute_capacity,
		"minerals": minerals,
		"completed_node_count": completed_node_count,
		"current_node_id": current_node_id,
		"current_room_mineral_mult": current_room_mineral_mult,
		"pending_room_loot": pending_room_loot,
		"equipment_inventory": equipment_inventory,
		"equipped_weapon": equipped_weapon,
		"equipped_auxiliaries": equipped_auxiliaries,
		"cleared_crisis_thresholds": cleared_crisis_thresholds,
		"pending_boss_threshold": pending_boss_threshold,
		"last_crisis_alert_intro_threshold": last_crisis_alert_intro_threshold,
		"map_layout_seed": map_layout_seed,
		"pending_boss_scene": pending_boss_scene,
		"pending_boss_reward": pending_boss_reward,
		"last_boss_reward": last_boss_reward,
		"active_special_bonus_ids": active_special_bonus_ids,
		"active_event_contracts": active_event_contracts,
		"active_route_directives": active_route_directives,
		"retired_route_directive_ids": retired_route_directive_ids,
		"active_run_conditions": active_run_conditions,
		"force_next_event_id": force_next_event_id,
		"shop_offer_ids": shop_offer_ids,
		"shop_draft_initialized": shop_draft_initialized,
		"shop_reroll_count": shop_reroll_count,
		"shop_preferred_family": shop_preferred_family,
		"shop_beacon_family": shop_beacon_family,
		"shop_beacon_bonus_name": shop_beacon_bonus_name,
		"shop_ore_source_focus": shop_ore_source_focus,
		"shop_ore_source_focus_text": shop_ore_source_focus_text,
		"calibration_snapshot": calibration_snapshot,
		"calibration_shop_price_mult": calibration_shop_price_mult,
		"calibration_mineral_mult": calibration_mineral_mult,
		"calibration_mineral_debt": calibration_mineral_debt,
		"calibration_resonance_family": calibration_resonance_family,
		"calibration_resonance_offer_remaining": calibration_resonance_offer_remaining,
		"crisis_modifier_snapshot": crisis_modifier_snapshot,
		"player_hp": GameManager.player_hp,
		"score": GameManager.score,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("存档写入失败：%s" % SAVE_PATH)
		return
	f.store_var(data, true)  # full_objects=true 以完整往返 map_nodes 里的 Vector2/嵌套字典
	f.close()


func load_saved_run() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return false
	var data = f.get_var(true)
	f.close()
	if typeof(data) != TYPE_DICTIONARY:
		clear_saved_run()
		return false
	var saved_version := int(data.get("version", 0))
	if saved_version < 1 or saved_version > SAVE_VERSION:
		clear_saved_run()
		return false
	run_active = true
	run_finished = false
	run_victory = false
	content_state_version = maxi(1, int(data.get("content_state_version", 1)))
	_committed_mutation_ids.clear()
	# 类型化数组必须用 assign() 从读回的无类型数组恢复，直接赋值会报类型错误
	map_nodes.assign(data.get("map_nodes", []))
	crisis_level = int(data.get("crisis_level", 0))
	advanced_crisis_level = int(data.get("advanced_crisis_level", 0)) if saved_version >= 3 else 0
	compute_capacity = int(data.get("compute_capacity", 5))
	calibration_mineral_debt = 0
	minerals = int(data.get("minerals", 0))
	completed_node_count = int(data.get("completed_node_count", 0))
	current_node_id = int(data.get("current_node_id", -1))
	current_room_mineral_mult = float(data.get("current_room_mineral_mult", 1.0))
	pending_room_loot = data.get("pending_room_loot", _empty_loot())
	equipment_inventory.assign(data.get("equipment_inventory", ["pulse_cannon"]))
	equipped_weapon = String(data.get("equipped_weapon", "pulse_cannon"))
	equipped_auxiliaries.assign(data.get("equipped_auxiliaries", []))
	cleared_crisis_thresholds.assign(data.get("cleared_crisis_thresholds", []))
	pending_boss_threshold = int(data.get("pending_boss_threshold", 0))
	last_crisis_alert_intro_threshold = int(data.get("last_crisis_alert_intro_threshold", 0))
	map_layout_seed = int(data.get("map_layout_seed", 0))
	pending_boss_scene = String(data.get("pending_boss_scene", ""))
	pending_boss_reward = Dictionary(data.get("pending_boss_reward", {}))
	last_boss_reward = data.get("last_boss_reward", {})
	last_boss_completion_summary.clear()
	last_result_summary.clear()
	last_node_completion_summary.clear()
	active_special_bonus_ids.assign(data.get("active_special_bonus_ids", []))
	active_event_contracts.assign(data.get("active_event_contracts", []))
	active_route_directives.assign(data.get("active_route_directives", []))
	retired_route_directive_ids.assign(data.get("retired_route_directive_ids", []))
	var needs_route_directive_refresh := active_route_directives.size() != ROUTE_DIRECTIVE_COUNT
	for raw_directive in active_route_directives:
		var directive := Dictionary(raw_directive)
		if not directive.has("id") or not directive.has("goal_type") or not directive.has("reward"):
			needs_route_directive_refresh = true
			break
	if needs_route_directive_refresh:
		_generate_route_directives()
	active_run_conditions.assign(data.get("active_run_conditions", []))
	force_next_event_id = String(data.get("force_next_event_id", ""))
	shop_offer_ids.assign(data.get("shop_offer_ids", []))
	shop_draft_initialized = bool(data.get("shop_draft_initialized", false))
	shop_reroll_count = int(data.get("shop_reroll_count", 0))
	shop_preferred_family = String(data.get("shop_preferred_family", ""))
	shop_beacon_family = String(data.get("shop_beacon_family", ""))
	shop_beacon_bonus_name = String(data.get("shop_beacon_bonus_name", ""))
	shop_ore_source_focus = String(data.get("shop_ore_source_focus", ""))
	shop_ore_source_focus_text = String(data.get("shop_ore_source_focus_text", ""))
	calibration_snapshot = Dictionary(data.get("calibration_snapshot", {})).duplicate(true)
	calibration_shop_price_mult = maxf(1.0, float(data.get("calibration_shop_price_mult", 1.0)))
	calibration_mineral_mult = maxf(1.0, float(data.get("calibration_mineral_mult", 1.0)))
	calibration_mineral_debt = maxi(0, int(data.get("calibration_mineral_debt", 0)))
	calibration_resonance_family = String(data.get("calibration_resonance_family", ""))
	calibration_resonance_offer_remaining = maxi(0, int(data.get("calibration_resonance_offer_remaining", 0)))
	crisis_modifier_snapshot = Dictionary(data.get("crisis_modifier_snapshot", {})).duplicate(true)
	if crisis_modifier_snapshot.is_empty():
		crisis_modifier_snapshot = AdvancedCrisisResolverScript.new().resolve(advanced_crisis_level)
	GameManager.player_hp = clampi(int(data.get("player_hp", GameManager.PLAYER_MAX_HP)), 1, GameManager.PLAYER_MAX_HP)
	GameManager.score = int(data.get("score", 0))
	return true


func clear_saved_run() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)


func is_formal_run_active() -> bool:
	return run_active and not run_finished


func get_run_content_context() -> RunContentContext:
	return RunContentContextScript.from_snapshot({
		"state_version": content_state_version,
		"map_nodes": map_nodes.duplicate(true),
		"crisis_level": crisis_level,
		"compute_capacity": compute_capacity,
		"minerals": minerals,
		"player_hp": GameManager.player_hp,
		"equipment_inventory": equipment_inventory.duplicate(),
		"equipped_weapon": equipped_weapon,
		"equipped_auxiliaries": equipped_auxiliaries.duplicate(),
		"active_rules": get_active_rule_snapshot(),
	})


func prepare_choices(node_id: int, context: RunContentContext = null, seed: int = -1) -> Array[Dictionary]:
	_ensure_run_content_facade()
	var safe_context := context if context != null else get_run_content_context()
	return _run_content_facade.prepare_choices(node_id, safe_context, seed)


func resolve_choice(node_id: int, choice_id: String, context: RunContentContext = null, seed: int = -1) -> RunMutationSet:
	_ensure_run_content_facade()
	var safe_context := context if context != null else get_run_content_context()
	return _run_content_facade.resolve_choice(node_id, choice_id, safe_context, seed)


func validate_mutation(context: RunContentContext, mutation: RunMutationSet) -> PackedStringArray:
	_ensure_run_content_facade()
	var errors := _run_content_facade.validate_mutation(context, mutation, _allowed_content_actions())
	if mutation != null and not mutation.metadata.is_empty() and String(mutation.metadata.get("legacy_kind", "")).is_empty() == false:
		var legacy_kind := String(mutation.metadata.get("legacy_kind", ""))
		if not [NODE_EVENT, NODE_REWARD].has(legacy_kind):
			errors.append(RunMutationSet.ERROR_INVALID)
	elif mutation != null:
		for entry in mutation.actions:
			if not _is_content_action_payload_valid(Dictionary(entry)):
				errors.append(RunMutationSet.ERROR_INVALID)
	return errors


func commit_mutation(mutation: RunMutationSet) -> Dictionary:
	var context := get_run_content_context()
	var errors := validate_mutation(context, mutation)
	if mutation != null and _committed_mutation_ids.has(mutation.mutation_id):
		errors.append(RunMutationSet.ERROR_DUPLICATE)
	if not errors.is_empty():
		return {"ok": false, "error_codes": errors, "message": "内容结算未通过校验。"}
	var result: Dictionary = {}
	var legacy_kind := String(mutation.metadata.get("legacy_kind", ""))
	if not legacy_kind.is_empty():
		var choice_id := String(mutation.metadata.get("choice_id", ""))
		var seed := int(mutation.metadata.get("seed", -1))
		if legacy_kind == NODE_EVENT:
			result = resolve_event_choice(mutation.node_id, choice_id, seed)
		else:
			result = resolve_reward_event_choice(mutation.node_id, choice_id, seed)
		if not bool(result.get("ok", false)):
			return result
	else:
		_apply_mutation_costs(mutation)
		for action_entry in mutation.actions:
			_apply_content_action(Dictionary(action_entry))
		result = {"ok": true, "node_id": mutation.node_id, "message": "内容结算已提交。"}
	_committed_mutation_ids[mutation.mutation_id] = true
	content_state_version += 1
	balance_telemetry.record("mutation_committed", {"source_id": mutation.source_id, "node_id": mutation.node_id, "actions": mutation.actions.duplicate(true)})
	result["state_version"] = content_state_version
	return result


func get_active_rule_snapshot() -> Dictionary:
	return {
		"special_bonus_ids": active_special_bonus_ids.duplicate(),
		"event_contracts": get_active_event_contracts(),
		"route_directives": get_route_directive_summaries(),
		"run_conditions": active_run_conditions.duplicate(true),
		"calibration": calibration_snapshot.duplicate(true),
		"advanced_crisis_level": advanced_crisis_level,
		"advanced_crisis": crisis_modifier_snapshot.duplicate(true),
	}


func _get_advanced_crisis_domain(domain: String) -> Dictionary:
	return Dictionary(crisis_modifier_snapshot.get(domain, {})).duplicate(true)


func _get_current_stage() -> int:
	if crisis_level < CRISIS_THRESHOLDS[0]:
		return 1
	if crisis_level < CRISIS_THRESHOLDS[1]:
		return 2
	return 3


func _ensure_run_content_facade() -> void:
	if _run_content_facade != null:
		return
	_run_content_facade = RunContentFacadeScript.new()
	_run_content_facade.set_legacy_adapters(
		Callable(self, "_prepare_legacy_content_choices"),
		Callable(self, "_resolve_legacy_content_choice")
	)


func _prepare_legacy_content_choices(node_id: int, seed: int) -> Array:
	var node := get_map_node(node_id)
	match String(node.get("type", "")):
		NODE_EVENT:
			return prepare_event_choices(node_id, seed)
		NODE_REWARD:
			return prepare_reward_event_choices(node_id, seed)
		_:
			return []


func _resolve_legacy_content_choice(node_id: int, choice_id: String, state_version: int, seed: int) -> RunMutationSet:
	var node := get_map_node(node_id)
	var node_type := String(node.get("type", ""))
	if not [NODE_EVENT, NODE_REWARD].has(node_type):
		return null
	var mutation := RunMutationSetScript.create(
		"legacy:%s:%s:%d" % [node_type, choice_id, state_version],
		"legacy_%s" % node_type,
		node_id,
		state_version
	)
	mutation.metadata = {"legacy_kind": node_type, "choice_id": choice_id, "seed": seed}
	return mutation


func _allowed_content_actions() -> PackedStringArray:
	return PackedStringArray([
		"grant_minerals", "heal", "damage", "grant_compute", "grant_equipment",
		"add_event_contract", "activate_special_bonus", "add_crisis",
	])


func _apply_mutation_costs(mutation: RunMutationSet) -> void:
	minerals -= mutation.mineral_cost
	GameManager.player_hp -= mutation.hp_cost


func _is_content_action_payload_valid(entry: Dictionary) -> bool:
	var action := String(entry.get("action", ""))
	var payload := Dictionary(entry.get("payload", {}))
	match action:
		"grant_minerals", "heal", "damage", "grant_compute", "add_crisis":
			return int(payload.get("amount", -1)) >= 0
		"grant_equipment":
			return EquipmentCatalogScript.has_item(String(payload.get("item_id", "")))
		"add_event_contract":
			return not String(payload.get("id", "")).is_empty()
		"activate_special_bonus":
			return not _get_special_bonus_profile(String(payload.get("bonus_id", ""))).is_empty()
		_:
			return false


func _apply_content_action(entry: Dictionary) -> void:
	var action := String(entry.get("action", ""))
	var payload := Dictionary(entry.get("payload", {}))
	match action:
		"grant_minerals":
			minerals += maxi(0, int(payload.get("amount", 0)))
		"heal":
			var healing := _get_advanced_crisis_domain("healing")
			var calibration_effects := Dictionary(calibration_snapshot.get("effects", {}))
			var amount := maxi(0, int(payload.get("amount", 0)))
			var scaled_amount := int(round(float(amount) * float(healing.get("mult", 1.0)) * float(calibration_effects.get("healing_mult", 1.0))))
			if amount > 0:
				scaled_amount = maxi(int(healing.get("minimum", 0)), scaled_amount)
			GameManager.player_hp = mini(GameManager.PLAYER_MAX_HP, GameManager.player_hp + scaled_amount)
		"damage":
			GameManager.player_hp = maxi(1, GameManager.player_hp - maxi(0, int(payload.get("amount", 0))))
		"grant_compute":
			compute_capacity += maxi(0, int(payload.get("amount", 0)))
		"grant_equipment":
			var item_id := String(payload.get("item_id", ""))
			if EquipmentCatalogScript.has_item(item_id) and not equipment_inventory.has(item_id):
				equipment_inventory.append(item_id)
		"add_event_contract":
			var contract := payload.duplicate(true)
			if not String(contract.get("id", "")).is_empty():
				active_event_contracts.append(contract)
		"activate_special_bonus":
			var bonus_id := String(payload.get("bonus_id", ""))
			if not _get_special_bonus_profile(bonus_id).is_empty() and not active_special_bonus_ids.has(bonus_id):
				active_special_bonus_ids.append(bonus_id)
		"add_crisis":
			_add_crisis_with_alert_stop(maxi(0, int(payload.get("amount", 0))))


func is_alert_active() -> bool:
	return CRISIS_THRESHOLDS.has(crisis_level) and not cleared_crisis_thresholds.has(crisis_level)


func consume_crisis_alert_intro() -> bool:
	if not is_alert_active() or last_crisis_alert_intro_threshold == crisis_level:
		return false
	last_crisis_alert_intro_threshold = crisis_level
	return true


func get_alert_boss_family() -> String:
	var preview: Dictionary = get_alert_boss_preview()
	return String(preview.get("family", ""))


func get_alert_boss_preview() -> Dictionary:
	if not is_alert_active():
		return {}
	if pending_boss_scene.is_empty():
		pending_boss_scene = _pick_crisis_boss_scene(get_alert_stage())
	var preview: Dictionary = Dictionary(BOSS_ALERT_PREVIEWS.get(pending_boss_scene, {})).duplicate(true)
	preview["scene"] = pending_boss_scene
	preview["family"] = _get_boss_family_for_scene(pending_boss_scene)
	preview["stage"] = get_alert_stage()
	return preview


func get_alert_stage() -> int:
	if not is_alert_active():
		return 0
	return CRISIS_THRESHOLDS.find(crisis_level) + 1


func get_formal_boss_budget(family: String) -> Dictionary:
	if not is_formal_run_active():
		return {}
	var stage := get_alert_stage()
	if stage <= 0:
		stage = _get_current_stage()
	return DesignedEnemyCatalog.get_boss_budget(family, stage, crisis_modifier_snapshot)


func is_node_completed(node_id: int) -> bool:
	var node := get_map_node(node_id)
	return bool(node.get("completed", false))


func is_node_accessible(node_id: int) -> bool:
	if node_id == CENTER_ID:
		return true
	var node := get_map_node(node_id)
	if node.is_empty() or bool(node.get("completed", false)):
		return false
	if String(node.get("type", "")) == NODE_SPECIAL:
		return _is_special_node_reached(node_id)
	if is_alert_active():
		return false
	for linked_id in node.get("links", []):
		if int(linked_id) == CENTER_ID or is_node_completed(int(linked_id)):
			return true
	return false


func get_map_node(node_id: int) -> Dictionary:
	if node_id < 0 or node_id >= map_nodes.size():
		return {}
	return map_nodes[node_id]


func get_node_family_bias(node_id: int) -> String:
	return String(get_map_node(node_id).get("family_bias", ""))


func get_node_reward_mult(node_id: int) -> float:
	return float(get_map_node(node_id).get("reward_mult", 1.0))


func get_node_equipment_drop_chance(node_id: int = -1) -> float:
	var id := current_node_id if node_id < 0 else node_id
	var chance := float(get_map_node(id).get("equipment_drop_chance", TIER_EQUIPMENT_DROP_CHANCES[0]))
	chance += float(get_map_node(id).get("reward_cache_equipment_chance_bonus", 0.0))
	chance += _get_event_contract_equipment_chance_bonus()
	return clampf(chance, 0.0, MAX_READABLE_EQUIPMENT_DROP_CHANCE)


func get_event_profiles() -> Array:
	return EVENT_PROFILES.duplicate(true)


func get_event_contract_profiles() -> Array:
	var contracts: Array = []
	for raw_profile in EVENT_PROFILES:
		var profile := Dictionary(raw_profile)
		var contract: Dictionary = profile.get("contract", {})
		if contract.is_empty():
			continue
		var copy := contract.duplicate(true)
		copy["source_event_id"] = String(profile.get("id", ""))
		copy["source_event_title"] = String(profile.get("title", ""))
		contracts.append(copy)
	return contracts


func get_modifier_profiles() -> Array:
	return NODE_MODIFIER_PROFILES.duplicate(true)


func get_opportunity_profiles() -> Array:
	return NODE_OPPORTUNITY_PROFILES.duplicate(true)


func get_run_condition_profiles() -> Array:
	return RUN_CONDITION_PROFILES.duplicate(true)


func get_active_run_condition_summaries() -> Array:
	var summaries: Array = []
	for raw_condition in active_run_conditions:
		var condition := Dictionary(raw_condition)
		summaries.append({
			"id": String(condition.get("id", "")),
			"title": String(condition.get("title", "")),
			"category": String(condition.get("category", "")),
			"description": String(condition.get("description", "")),
			"effects_text": String(condition.get("effects_text", "")),
		})
	return summaries


func get_active_event_contracts() -> Array:
	return active_event_contracts.duplicate(true)


func get_active_event_contract_summaries() -> Array:
	var summaries: Array = []
	for raw_contract in active_event_contracts:
		var contract := Dictionary(raw_contract)
		var title := String(contract.get("title", contract.get("contract_id", "航路契约")))
		var family := String(contract.get("family_bias", ""))
		summaries.append({
			"title": title,
			"family": family,
			"family_name": _get_contract_family_display_name(family),
			"remaining_nodes": int(contract.get("remaining_nodes", 0)),
			"duration_nodes": int(contract.get("duration_nodes", 0)),
			"description": String(contract.get("description", "")),
			"effects_text": _get_event_contract_effects_text(contract),
			"shop_focus_family": String(contract.get("shop_focus_family", "")),
			"shop_focus_text": String(contract.get("shop_focus_text", "")),
		})
	return summaries


func get_route_directive_summaries() -> Array:
	var summaries: Array = []
	for raw_directive in active_route_directives:
		summaries.append(_make_route_directive_summary(Dictionary(raw_directive)))
	return summaries


func get_route_directive_profiles() -> Array:
	return ROUTE_DIRECTIVE_PROFILES.duplicate(true)


func get_reward_profiles() -> Array:
	return REWARD_NODE_PROFILES.duplicate(true)


func get_reward_cache_choice_profiles() -> Array:
	return REWARD_CACHE_CHOICE_PROFILES.duplicate(true)


func get_battle_profiles() -> Array:
	return BATTLE_NODE_PROFILES.duplicate(true)


func prepare_reward_event_choices(node_id: int, seed: int = -1) -> Array:
	var node := get_map_node(node_id)
	if node.is_empty() or String(node.get("type", "")) != NODE_REWARD:
		return []
	node = _ensure_reward_profile_on_node(node)
	map_nodes[node_id] = node
	var tier := maxi(1, int(node.get("tier", 1)))
	var family := String(node.get("cache_family_bias", node.get("family_bias", "")))
	var rng := _make_rng(seed if seed >= 0 else Time.get_ticks_msec())
	var mineral_amount := 36 + tier * 14 + rng.randi_range(0, 12)
	var repair_amount := 16 + tier * 7
	var item_id := EquipmentCatalogScript.get_random_family_loot_item_id(
		equipment_inventory,
		crisis_level,
		family,
		rng.randi()
	)
	if item_id.is_empty():
		item_id = EquipmentCatalogScript.get_random_loot_item_id(equipment_inventory, crisis_level, family, rng.randi())
	var choices: Array = [
		{
			"choice_id": "reward_minerals_%d" % node_id,
			"reward_type": "minerals",
			"cache_type": "minerals",
			"title": "回收星髓矿",
			"description": "优先拆解完整的矿物密封仓。",
			"preview": "获得 %d 星髓矿。" % mineral_amount,
			"amount": mineral_amount,
		},
		{
			"choice_id": "reward_repair_%d" % node_id,
			"reward_type": "repair",
			"cache_type": "repair",
			"title": "启用维修组件",
			"description": "把可用的纳米修复剂导入船体。",
			"preview": "恢复 %d 点生命。" % repair_amount,
			"amount": repair_amount,
		},
		{
			"choice_id": "reward_equipment_%d" % node_id,
			"reward_type": "equipment",
			"cache_type": "equipment",
			"title": "提取装备蓝图",
			"description": "以当前航线偏好筛选一件可用的遗失装备。",
			"preview": "获得装备：%s。" % EquipmentCatalogScript.get_display_name(item_id),
			"item_id": item_id,
		},
	]
	if seed >= 0 and choices.size() > 1:
		choices = _rotate_reward_cache_choices(choices, seed)
	return choices


func resolve_reward_event_choice(node_id: int, choice_id: String, seed: int = -1) -> Dictionary:
	if not is_node_accessible(node_id):
		return {"ok": false, "message": "节点尚不可访问。"}
	var node := get_map_node(node_id)
	if node.is_empty() or String(node.get("type", "")) != NODE_REWARD:
		return {"ok": false, "message": "这不是奖励事件节点。"}
	var selected_choice := _find_reward_cache_choice(prepare_reward_event_choices(node_id, seed), choice_id)
	if selected_choice.is_empty():
		return {"ok": false, "message": "这份补给已经失效。"}
	current_node_id = node_id
	pending_room_loot = _empty_loot()
	var reward_type := String(selected_choice.get("reward_type", ""))
	var result := {
		"ok": true,
		"node_id": node_id,
		"choice": selected_choice.duplicate(true),
		"choice_id": choice_id,
		"reward_type": reward_type,
		"title": String(selected_choice.get("title", "补给")),
		"minerals_added": 0,
		"healed": 0,
		"equipment_name": "",
	}
	match reward_type:
		"minerals":
			var amount := int(selected_choice.get("amount", 0))
			minerals += amount
			result["minerals_added"] = amount
			result["message"] = "你从残骸中取回了 %d 星髓矿。" % amount
		"repair":
			var healed := int(selected_choice.get("amount", 0))
			GameManager.player_hp = mini(GameManager.PLAYER_MAX_HP, GameManager.player_hp + healed)
			result["healed"] = healed
			result["message"] = "维修组件已接入，船体恢复 %d 点生命。" % healed
		"equipment":
			var item_id := String(selected_choice.get("item_id", ""))
			if not item_id.is_empty() and EquipmentCatalogScript.has_item(item_id) and not equipment_inventory.has(item_id):
				equipment_inventory.append(item_id)
				result["equipment_name"] = EquipmentCatalogScript.get_display_name(item_id)
				result["message"] = "已将 %s 收入装备库。" % String(result.get("equipment_name", ""))
			else:
				result["message"] = "这份蓝图已经归档，方舟未能提取新的装备。"
		_:
			return {"ok": false, "message": "未知奖励类型。"}
	var completion := _complete_current_node(true)
	for key in completion.keys():
		if not result.has(key):
			result[key] = completion[key]
	return result


# Compatibility aliases keep save tools and external content scripts working while reward nodes
# transition from combat caches to direct-choice reward events.
func prepare_reward_cache_choices(node_id: int, seed: int = -1) -> Array:
	return prepare_reward_event_choices(node_id, seed)


func start_reward_cache_choice(node_id: int, choice_id: String, seed: int = -1) -> Dictionary:
	return resolve_reward_event_choice(node_id, choice_id, seed)


func prepare_event_choices(node_id: int, seed: int = -1, choice_count: int = 3) -> Array:
	var node := get_map_node(node_id)
	if node.is_empty() or String(node.get("type", "")) != NODE_EVENT:
		return []
	var rng := _make_rng(seed)
	var choices: Array = []
	var used_ids := {}
	if not force_next_event_id.is_empty():
		var forced_profile := _get_event_profile_by_id(force_next_event_id)
		if not forced_profile.is_empty():
			choices.append(_make_event_choice_data(forced_profile, node))
			used_ids[String(forced_profile.get("id", ""))] = true
	while choices.size() < choice_count and choices.size() < EVENT_PROFILES.size():
		var profile := _pick_event_profile_from_pool(node, rng, used_ids)
		if profile.is_empty():
			break
		choices.append(_make_event_choice_data(profile, node))
		used_ids[String(profile.get("id", ""))] = true
	return choices


func resolve_event_choice(node_id: int, choice_id: String, seed: int = -1) -> Dictionary:
	if not is_node_accessible(node_id):
		return {"ok": false, "message": "节点尚不可访问。"}
	var node := get_map_node(node_id)
	if String(node.get("type", "")) != NODE_EVENT:
		return {"ok": false, "message": "这不是事件节点。"}
	var profile := _get_event_profile_by_id(choice_id)
	if profile.is_empty():
		return {"ok": false, "message": "事件方案已失效。"}
	current_node_id = node_id
	pending_room_loot = _empty_loot()
	var rng := _make_rng(seed)
	var result := _apply_event_profile(node, profile, rng)
	# "强制下一个事件"只生效一次：事件结算即清除，否则会永久污染之后每个事件节点的选项
	force_next_event_id = ""
	var pending_contract: Dictionary = result.get("pending_event_contract", {})
	var completion := _complete_current_node(true)
	for key in completion.keys():
		if not result.has(key):
			result[key] = completion[key]
	if bool(completion.get("ok", false)) and not pending_contract.is_empty():
		var activated_contract := _add_event_contract(pending_contract)
		result["contract_title"] = String(activated_contract.get("title", ""))
		result["contract_description"] = String(activated_contract.get("description", ""))
		result["contract_remaining_nodes"] = int(activated_contract.get("remaining_nodes", 0))
		result["contract_effect_type"] = String(activated_contract.get("effect_type", ""))
	result.erase("pending_event_contract")
	result["active_event_contracts"] = get_active_event_contracts()
	return result


func get_node_state_text(node_id: int) -> String:
	if node_id == CENTER_ID:
		return "方舟核心"
	var node := get_map_node(node_id)
	if String(node.get("type", "")) == NODE_SPECIAL:
		return "已接入" if is_special_bonus_active(node_id) else ("可接入" if _is_special_node_reached(node_id) else "未接入")
	if is_node_completed(node_id):
		return "已探索"
	if is_node_accessible(node_id):
		return "可进入"
	if is_alert_active():
		return "警报锁定"
	return "未探索"


func get_node_type_name(node_type: String) -> String:
	match node_type:
		NODE_BASE:
			return "方舟核心"
		NODE_BATTLE:
			return "战斗残片"
		NODE_EVENT:
			return "事件信号"
		NODE_REWARD:
			return "奖励事件"
		NODE_SPECIAL:
			return "增益信标"
	return "未知节点"


func get_node_enemy_family_weights(node_id: int) -> Dictionary:
	var node := get_map_node(node_id)
	if node.is_empty() or String(node.get("type", "")) != NODE_BATTLE:
		return {}
	var room_config: Dictionary = {}
	_apply_node_room_config(room_config, node)
	var battle_config: Dictionary = node.get("battle_room_config", {})
	for key in battle_config.keys():
		_merge_battle_profile_room_config(room_config, key, battle_config[key])
	_apply_ore_source_bias_to_room_config(room_config, node)
	_apply_family_bias_to_room_config(room_config, get_node_family_bias(node_id))
	_apply_beacon_echo_to_room_config(room_config, node)
	_apply_reward_cache_route_calibration_to_room_config(room_config, node)
	_apply_boss_aftershock_to_room_config(room_config, node)
	var weights := {}
	for family in FAMILY_BIASES:
		weights[family] = maxf(0.0, float(room_config.get("%s_family_weight" % family, 1.0)))
	var battle_family := String(room_config.get("battle_family_bias", ""))
	if not battle_family.is_empty() and weights.has(battle_family):
		weights[battle_family] = maxf(
			float(weights[battle_family]),
			maxf(1.0, float(room_config.get("battle_family_weight_boost", 1.0)))
		)
	return weights


func start_explore_node(node_id: int) -> bool:
	if not is_node_accessible(node_id):
		return false
	var node := get_map_node(node_id)
	if node.is_empty() or String(node.get("type", "")) == NODE_BASE:
		return false
	if String(node.get("type", "")) == NODE_SPECIAL or String(node.get("type", "")) == NODE_REWARD:
		return false
	node = _ensure_battle_profile_on_node(node)
	node = _ensure_reward_profile_on_node(node)
	map_nodes[node_id] = node
	current_node_id = node_id
	pending_room_loot = _empty_loot()
	var node_type := String(node.get("type", NODE_BATTLE))
	var room_stage := _get_current_stage()
	var room_config: Dictionary = {
		"enemy_spawn_interval": float(BalanceServiceScript.get_stage_value("exploration", "patrol_spawn_interval", room_stage, 30.0)),
		"max_patrol_enemy_count": int(BalanceServiceScript.get_stage_value("exploration", "patrol_enemy_cap", room_stage, 10)),
	}
	_apply_node_room_config(room_config, node)
	if node_type == NODE_BATTLE:
		var battle_config: Dictionary = node.get("battle_room_config", {})
		for key in battle_config.keys():
			_merge_battle_profile_room_config(room_config, key, battle_config[key])
		room_config["battle_profile_id"] = String(node.get("battle_profile_id", ""))
		room_config["battle_profile_title"] = String(node.get("battle_title", ""))
		room_config["battle_threat"] = int(node.get("battle_threat", 1))
	if node_type == NODE_REWARD:
		# 奖励房默认值只补缺席的键，不覆盖情报/词缀/局势已合入的数值；倍率与已有值相乘
		var reward_config := {
			"large_space_rock_count": 12,
			"trap_count": 4,
			"chest_crystal_count": 14,
			"clutter_count": 35,
			"enemy_spawn_interval": 60.0,
			"max_patrol_enemy_count": 6,
		}
		for key in reward_config.keys():
			if not room_config.has(key):
				room_config[key] = reward_config[key]
		room_config["reward_mineral_mult"] = float(room_config.get("reward_mineral_mult", 1.0)) * 1.12
		var profile_config: Dictionary = node.get("reward_room_config", {})
		for key in profile_config.keys():
			room_config[key] = profile_config[key]
		room_config["reward_profile_id"] = String(node.get("reward_profile_id", ""))
		room_config["reward_profile_title"] = String(node.get("reward_title", ""))
		room_config["reward_cache_family_bias"] = String(node.get("cache_family_bias", ""))
		_apply_reward_cache_choice_to_room_config(room_config, node)
	_apply_ore_source_bias_to_room_config(room_config, node)
	_apply_family_bias_to_room_config(room_config, get_node_family_bias(node_id))
	_apply_beacon_echo_to_room_config(room_config, node)
	_apply_reward_cache_route_calibration_to_room_config(room_config, node)
	_apply_boss_aftershock_to_room_config(room_config, node)
	_apply_loading_context_to_room_config(room_config, node)
	var exploration_crisis := _get_advanced_crisis_domain("exploration")
	room_config["advanced_patrol_interval_mult"] = float(exploration_crisis.get("patrol_interval_mult", 1.0))
	room_config["advanced_patrol_enemy_cap_bonus"] = int(exploration_crisis.get("patrol_enemy_cap_bonus", 0))
	room_config["advanced_trap_count_mult"] = float(exploration_crisis.get("trap_count_mult", 1.0))
	room_config["advanced_crisis_enemy"] = _get_advanced_crisis_domain("enemy")
	room_config["advanced_crisis_boss"] = _get_advanced_crisis_domain("boss")
	room_config["run_stage"] = _get_current_stage()
	var latest_node := get_map_node(node_id)
	_apply_ore_source_bias_to_room_config(room_config, latest_node if not latest_node.is_empty() else node)
	# 词缀/局势写的是裸键，GameManager 白名单只认 battle_ 前缀，这里统一转换（取更强值）
	if room_config.has("patrol_path_min_count"):
		room_config["battle_patrol_path_min_count"] = maxi(
			int(room_config.get("battle_patrol_path_min_count", 0)), int(room_config["patrol_path_min_count"]))
		room_config.erase("patrol_path_min_count")
	if room_config.has("patrol_path_max_count"):
		room_config["battle_patrol_path_max_count"] = maxi(
			int(room_config.get("battle_patrol_path_max_count", 0)), int(room_config["patrol_path_max_count"]))
		room_config.erase("patrol_path_max_count")
	# 进房后 GameManager 的配置会被 consume 清空，倍率必须在这里缓存供拾取时读取
	current_room_mineral_mult = maxf(0.0, float(room_config.get("reward_mineral_mult", 1.0))) * calibration_mineral_mult
	GameManager.set_next_explore_room_config(room_config)
	return true


func resolve_event_node(node_id: int, seed: int = -1) -> Dictionary:
	var choices := prepare_event_choices(node_id, seed, 1)
	if choices.is_empty():
		return {"ok": false, "message": "事件方案生成失败。"}
	return resolve_event_choice(node_id, String(choices[0].get("choice_id", "")), seed)


func record_reward_broken(reward_type: int) -> void:
	if not is_formal_run_active() or current_node_id < 0:
		return
	if pending_room_loot.is_empty():
		pending_room_loot = _empty_loot()
	if reward_type == 1:
		pending_room_loot["minerals"] = int(pending_room_loot.get("minerals", 0)) + randi_range(5, 12)
		return
	if randf() < get_node_equipment_drop_chance():
		var preferred_family := get_node_family_bias(current_node_id)
		var current_node := get_map_node(current_node_id)
		var reward_cache_family := String(current_node.get("reward_cache_choice_family", current_node.get("cache_family_bias", "")))
		if not reward_cache_family.is_empty():
			preferred_family = reward_cache_family
		var loot_owned_ids: Array = equipment_inventory + pending_room_loot.get("equipment", [])
		var item_id: String
		if not reward_cache_family.is_empty():
			item_id = EquipmentCatalogScript.get_random_family_loot_item_id(loot_owned_ids, crisis_level, reward_cache_family)
		else:
			item_id = EquipmentCatalogScript.get_random_loot_item_id(loot_owned_ids, crisis_level, preferred_family)
		var equipment: Array = pending_room_loot.get("equipment", [])
		equipment.append(item_id)
		pending_room_loot["equipment"] = equipment
	else:
		pending_room_loot["minerals"] = int(pending_room_loot.get("minerals", 0)) + randi_range(8, 18)


func record_mineral_collected(amount: int) -> void:
	if not is_formal_run_active() or current_node_id < 0 or amount <= 0:
		return
	if pending_room_loot.is_empty():
		pending_room_loot = _empty_loot()
	var scaled_amount := maxi(1, int(round(float(amount) * get_node_reward_mult(current_node_id) * current_room_mineral_mult)))
	pending_room_loot["minerals"] = int(pending_room_loot.get("minerals", 0)) + scaled_amount


func complete_explore_room_success() -> Dictionary:
	return _complete_current_node(true)


func consume_last_node_completion_summary() -> Dictionary:
	var summary := last_node_completion_summary.duplicate(true)
	last_node_completion_summary.clear()
	return summary


func consume_last_boss_completion_summary() -> Dictionary:
	var summary := last_boss_completion_summary.duplicate(true)
	last_boss_completion_summary.clear()
	return summary


func abandon_current_room() -> void:
	current_node_id = -1
	current_room_mineral_mult = 1.0
	pending_room_loot = _empty_loot()


func begin_crisis_boss() -> bool:
	if not is_alert_active():
		return false
	if MetaProgressionState != null and MetaProgressionState.record_boss_reached(get_alert_stage()):
		MetaProgressionState.save_to_disk()
	pending_boss_threshold = crisis_level
	if pending_boss_scene.is_empty():
		pending_boss_scene = _pick_crisis_boss_scene(get_alert_stage())
	if pending_boss_scene.is_empty():
		return false
	return true


func handle_boss_victory() -> bool:
	if not is_formal_run_active() or pending_boss_threshold <= 0:
		return false
	var threshold := pending_boss_threshold
	var boss_scene := pending_boss_scene
	_prepare_boss_reward(boss_scene, threshold)
	pending_boss_threshold = 0
	pending_boss_scene = ""
	if not cleared_crisis_thresholds.has(threshold):
		cleared_crisis_thresholds.append(threshold)
	if MetaProgressionState != null and MetaProgressionState.record_boss_defeated(get_alert_stage()):
		MetaProgressionState.save_to_disk()
	var boss_aftershock := _apply_boss_aftershock(pending_boss_reward)
	var boss_completion_summary := _make_boss_completion_summary(threshold)
	for key in boss_aftershock.keys():
		boss_completion_summary[key] = boss_aftershock[key]
	last_boss_completion_summary = boss_completion_summary
	SceneTransition.play_boss_victory_to_scene(WORLD_MAP_SCENE)
	return true


func finish_run(victory: bool) -> void:
	if not run_active:
		return
	run_finished = true
	run_victory = victory
	last_result_summary = {
		"victory": victory,
		"score": GameManager.score,
		"crisis_level": crisis_level,
		"compute_capacity": compute_capacity,
		"minerals": minerals,
		"completed_node_count": completed_node_count,
		"equipment_count": equipment_inventory.size(),
		"cleared_boss_count": cleared_crisis_thresholds.size(),
		"last_boss_reward": last_boss_reward.duplicate(true),
		"mechanic_telemetry": balance_telemetry.get_mechanic_statistics(),
	}
	if victory and MetaProgressionState != null:
		MetaProgressionState.record_run_victory(advanced_crisis_level)
		MetaProgressionState.save_to_disk()
	balance_telemetry.record("run_finished", last_result_summary)
	balance_telemetry.flush()
	abandon_current_room()
	clear_saved_run()  # 一局结束（通关或阵亡），存档作废


func get_shop_offer_ids() -> Array[String]:
	if not is_formal_run_active():
		return []
	_ensure_shop_draft()
	_prune_owned_shop_offers()
	return shop_offer_ids.duplicate()


func get_shop_reroll_cost() -> int:
	if _get_free_shop_reroll_count() > 0:
		return 0
	var economy := _get_advanced_crisis_domain("economy")
	return SHOP_REROLL_BASE_COST + _get_current_stage() * SHOP_REROLL_COST_STEP + shop_reroll_count * SHOP_REROLL_REPEAT_STEP + int(economy.get("reroll_base_bonus", 0))


func get_free_shop_reroll_summary() -> Dictionary:
	var remaining := _get_free_shop_reroll_count()
	var source := _get_free_shop_reroll_contract()
	var title := String(source.get("title", "货单校准券"))
	var remaining_nodes := int(source.get("remaining_nodes", 0))
	return {
		"active": remaining > 0,
		"remaining": remaining,
		"title": title if remaining > 0 else "",
		"text": "免费刷新商品 %d 次，剩余 %d 个节点。" % [remaining, remaining_nodes] if remaining > 0 else "",
		"remaining_nodes": remaining_nodes if remaining > 0 else 0,
	}


func get_effective_shop_price(item_id: String) -> int:
	var base_price := EquipmentCatalogScript.get_price(item_id)
	if base_price <= 0:
		return 0
	var economy := _get_advanced_crisis_domain("economy")
	base_price = int(ceil(float(base_price) * calibration_shop_price_mult * float(economy.get("shop_price_mult", 1.0))))
	var discount_rate := _get_active_shop_discount_rate()
	if discount_rate <= 0.0:
		return base_price
	return maxi(1, int(ceil(float(base_price) * (1.0 - discount_rate))))


func get_shop_discount_summary() -> Dictionary:
	var rate := _get_active_shop_discount_rate()
	if rate <= 0.0:
		return {
			"active": false,
			"rate": 0.0,
			"percent": 0,
			"title": "",
			"text": "",
			"remaining_nodes": 0,
		}
	var source := _get_active_shop_discount_contract()
	var title := String(source.get("title", "方舟采购折扣"))
	var remaining := int(source.get("remaining_nodes", 0))
	var percent := int(round(rate * 100.0))
	return {
		"active": true,
		"rate": rate,
		"percent": percent,
		"title": title,
		"text": "采购折扣 %d%%，剩余 %d 节点。" % [percent, remaining],
		"remaining_nodes": remaining,
	}


func get_shop_guidance() -> Dictionary:
	var focus_family := _resolve_shop_focus_family()
	var guidance := get_build_guidance(focus_family)
	var family := String(guidance.get("family", "")).strip_edges()
	var family_name := String(guidance.get("family_name", EquipmentCatalogScript.get_family_display_name(family)))
	var next_node := String(guidance.get("next_node_name", "未标记航线"))
	var title := "采购校准：%s" % family_name
	var summary := "刷新商品时会更容易出现%s装备，帮助补齐下一段航线的短板。" % family_name
	var reroll_hint := "下一段：%s。刷新商品会沿这条航向偏向%s装备。" % [next_node, family_name]
	if not shop_ore_source_focus_text.is_empty():
		summary = "%s %s已写入采购端口，下一批货单会优先保留对应矿源补给。" % [summary, shop_ore_source_focus_text]
	if not shop_beacon_family.is_empty() and family == shop_beacon_family:
		var beacon_name := shop_beacon_bonus_name if not shop_beacon_bonus_name.is_empty() else "信标回响"
		summary = "%s信标已并入方舟商品偏好，刷新时更容易出现%s装备。" % [beacon_name, family_name]
		if not shop_ore_source_focus_text.is_empty():
			summary = "%s %s同步保留。" % [summary, shop_ore_source_focus_text]
		reroll_hint = "下一段：%s。刷新商品会继续沿信标回响偏向该家族。" % next_node
	var discount := get_shop_discount_summary()
	var discount_text := String(discount.get("text", ""))
	if not discount_text.is_empty():
		summary = "%s %s" % [summary, discount_text]
	var reroll_voucher := get_free_shop_reroll_summary()
	var voucher_text := String(reroll_voucher.get("text", ""))
	if not voucher_text.is_empty():
		reroll_hint = "%s %s" % [reroll_hint, voucher_text]
	return {
		"family": family,
		"family_name": family_name,
		"title": title,
		"summary": summary,
		"reroll_hint": reroll_hint,
		"next_node_name": next_node,
		"copy_text": "%s %s" % [summary, reroll_hint],
		"discount_text": discount_text,
		"discount_percent": int(discount.get("percent", 0)),
		"free_reroll_text": voucher_text,
		"free_reroll_remaining": int(reroll_voucher.get("remaining", 0)),
		"ore_source_focus": shop_ore_source_focus,
		"ore_source_focus_text": shop_ore_source_focus_text,
	}


func reroll_shop_offers(preferred_family: String = "") -> Dictionary:
	if not is_formal_run_active():
		return {"ok": false, "message": "方舟航程尚未启动。"}
	var family := _resolve_shop_reroll_family(preferred_family)
	var cost := get_shop_reroll_cost()
	var used_free_reroll := cost == 0 and _get_free_shop_reroll_count() > 0
	if minerals < cost:
		return {"ok": false, "message": "星髓矿不足，需要 %d。" % cost, "cost": cost}
	minerals -= cost
	if used_free_reroll:
		_consume_free_shop_reroll()
	else:
		shop_reroll_count += 1
	shop_preferred_family = family
	shop_offer_ids = _build_shop_offer_ids(shop_preferred_family)
	shop_draft_initialized = true
	return {
		"ok": true,
		"message": "商品券已兑现，本次免费刷新商品。" if used_free_reroll else "商店商品已刷新。",
		"cost": cost,
		"free_reroll": used_free_reroll,
		"preferred_family": shop_preferred_family,
		"offers": shop_offer_ids.duplicate(),
	}


func _resolve_shop_reroll_family(preferred_family: String) -> String:
	var normalized := _normalize_shop_family(preferred_family)
	if not normalized.is_empty():
		return normalized
	normalized = _normalize_shop_family(shop_preferred_family)
	if not normalized.is_empty():
		return normalized
	normalized = _normalize_shop_family(shop_beacon_family)
	if not normalized.is_empty():
		return normalized
	var guidance := get_build_guidance(shop_preferred_family)
	return _normalize_shop_family(String(guidance.get("family", "")))


func buy_equipment(item_id: String) -> Dictionary:
	if not EquipmentCatalogScript.has_item(item_id):
		return {"ok": false, "message": "未知装备。"}
	if equipment_inventory.has(item_id):
		return {"ok": false, "message": "已经拥有该装备。"}
	var base_price := EquipmentCatalogScript.get_price(item_id)
	var price := get_effective_shop_price(item_id)
	if minerals < price:
		return {"ok": false, "message": "星髓矿不足，需要 %d。" % price}
	minerals -= price
	equipment_inventory.append(item_id)
	if shop_offer_ids.has(item_id):
		shop_offer_ids.erase(item_id)
	var message := "购买了 %s。" % EquipmentCatalogScript.get_display_name(item_id)
	if price < base_price:
		message = "采购折扣生效，折后 %d 星髓矿购买了 %s。" % [price, EquipmentCatalogScript.get_display_name(item_id)]
	return {"ok": true, "message": message, "price": price, "base_price": base_price}


func equip_or_toggle(item_id: String) -> Dictionary:
	if not equipment_inventory.has(item_id):
		return {"ok": false, "message": "尚未拥有该装备。"}
	var item_type := EquipmentCatalogScript.get_type(item_id)
	if item_type == EquipmentCatalogScript.TYPE_WEAPON:
		equipped_weapon = item_id
		return {"ok": true, "message": "已切换武器：%s。" % EquipmentCatalogScript.get_display_name(item_id)}
	if item_type == EquipmentCatalogScript.TYPE_AUX:
		if equipped_auxiliaries.has(item_id):
			equipped_auxiliaries.erase(item_id)
			return {"ok": true, "message": "已卸下辅助装备：%s。" % EquipmentCatalogScript.get_display_name(item_id)}
		var cost := EquipmentCatalogScript.get_compute_cost(item_id)
		if get_used_compute() + cost > compute_capacity:
			return {"ok": false, "message": "算力不足，当前 %d/%d。" % [get_used_compute(), compute_capacity]}
		equipped_auxiliaries.append(item_id)
		return {"ok": true, "message": "已装配辅助装备：%s。" % EquipmentCatalogScript.get_display_name(item_id)}
	return {"ok": false, "message": "该物品不能装配。"}


func get_used_compute() -> int:
	var used := 0
	for item_id in equipped_auxiliaries:
		used += EquipmentCatalogScript.get_compute_cost(item_id)
	return used


func get_loadout_summary() -> Dictionary:
	var families := {}
	for item_id in equipped_auxiliaries:
		var family := EquipmentCatalogScript.get_family(item_id)
		families[family] = int(families.get(family, 0)) + 1
	var archetype_sync := _make_archetype_sync_summary()
	return {
		"weapon_id": equipped_weapon,
		"weapon_name": EquipmentCatalogScript.get_display_name(equipped_weapon),
		"aux_count": equipped_auxiliaries.size(),
		"used_compute": get_used_compute(),
		"capacity": compute_capacity,
		"families": families,
		"archetype_sync": archetype_sync,
	}


func get_build_guidance(preferred_family: String = "") -> Dictionary:
	var sync := _make_archetype_sync_summary()
	var family := _select_guidance_family(preferred_family, sync)
	var family_name := EquipmentCatalogScript.get_family_display_name(family)
	var route := _find_guidance_route(family)
	var sync_goal_text := _make_guidance_sync_goal_text(family, sync)
	var title := "航向校准：%s" % family_name
	var summary := _make_guidance_summary(family, sync)
	var node_name := String(route.get("node_name", "未标记航线"))
	var route_title := String(route.get("route_plan_title", "等待航图刷新"))
	var route_summary := String(route.get("route_plan_summary", "方舟尚未找到完全贴合的航线，先清理可进入节点扩展视野。"))
	var copy_text := "%s。%s 下一段：%s，%s。" % [summary, sync_goal_text, node_name, route_title]
	return {
		"family": family,
		"family_name": family_name,
		"title": title,
		"summary": summary,
		"sync_goal_text": sync_goal_text,
		"next_node_id": int(route.get("node_id", -1)),
		"next_node_name": node_name,
		"route_plan_title": route_title,
		"route_plan_summary": route_summary,
		"copy_text": copy_text,
	}


func _select_guidance_family(preferred_family: String, sync: Dictionary) -> String:
	var requested := preferred_family.strip_edges()
	if not requested.is_empty():
		return requested
	var dominant := String(sync.get("dominant_family", "")).strip_edges()
	if not dominant.is_empty():
		return dominant
	var route := _find_guidance_route("")
	var route_family := String(route.get("family", "")).strip_edges()
	if not route_family.is_empty():
		return route_family
	return EquipmentCatalogScript.FAMILY_GENERAL


func _make_guidance_summary(family: String, sync: Dictionary) -> String:
	var family_name := EquipmentCatalogScript.get_family_display_name(family)
	var level := int(sync.get("sync_level", 0))
	match family:
		EquipmentCatalogScript.FAMILY_COLOSSUS:
			return "右键冲锋已经接入%s回路，继续补强撞击、距离和折返收益。" % family_name
		EquipmentCatalogScript.FAMILY_PARADISE:
			return "%s装备正在扩展火力覆盖，优先寻找射速、弹速和散射效果。" % family_name
		EquipmentCatalogScript.FAMILY_WARPED:
			return "%s回路会把弹道牵向敌群，优先追踪追踪与引力装备。" % family_name
		EquipmentCatalogScript.FAMILY_HELL_EYE:
			return "%s回路会放大狂热窗口，优先提高热值积累与爆发火力。" % family_name
		EquipmentCatalogScript.FAMILY_DIVINE:
			return "%s回路依靠僚机扩大战线，优先补足挂载位和友军火力。" % family_name
		_:
			if level > 0:
				return "当前航路已有同家族加成雏形，通用装备负责稳住航程与矿物回收。"
			return "当前航路尚未定型，先用通用装备稳住装配容量，再选择一条五席航路。"


func _make_guidance_sync_goal_text(family: String, sync: Dictionary) -> String:
	if family == EquipmentCatalogScript.FAMILY_GENERAL:
		return "通用装备不参与五席家族加成，可填补装配容量空档。"
	var family_counts: Dictionary = sync.get("family_counts", {})
	var count := int(family_counts.get(family, 0))
	if count >= 4:
		return "四件同家族加成已稳定，后续优先寻找高阶装备放大核心效果。"
	if count >= 2:
		return "四件同家族加成还差 %d 件同族辅助装备。" % maxi(0, 4 - count)
	return "二件同家族加成还差 %d 件同族辅助装备。" % maxi(0, 2 - count)


func _find_guidance_route(family: String) -> Dictionary:
	var fallback := {}
	for node in map_nodes:
		var node_id := int(node.get("id", -1))
		if node_id <= 0 or String(node.get("type", "")) == NODE_SPECIAL:
			continue
		if not is_node_accessible(node_id):
			continue
		var plan: Dictionary = node.get("route_plan", {})
		if plan.is_empty():
			continue
		var route := {
			"node_id": node_id,
			"node_name": String(node.get("name", "未知航线")),
			"family": String(plan.get("family", "")),
			"route_plan_title": String(plan.get("title", "航路预案")),
			"route_plan_summary": String(plan.get("summary", "")),
		}
		if fallback.is_empty():
			fallback = route
		if family.is_empty() or String(plan.get("family", "")) == family:
			return route
	return fallback


func _make_archetype_sync_summary() -> Dictionary:
	var scores := {}
	var family_counts := {}
	for family in EquipmentCatalogScript.get_boss_family_ids():
		scores[family] = 0
		family_counts[family] = 0
	scores[EquipmentCatalogScript.FAMILY_GENERAL] = 0
	family_counts[EquipmentCatalogScript.FAMILY_GENERAL] = 0
	for item_id in equipped_auxiliaries:
		var family := EquipmentCatalogScript.get_family(item_id)
		var score := EquipmentCatalogScript.get_compute_cost(item_id) + _rarity_sync_score(EquipmentCatalogScript.get_rarity(item_id))
		scores[family] = int(scores.get(family, 0)) + maxi(1, score)
		family_counts[family] = int(family_counts.get(family, 0)) + 1
	var dominant_family := ""
	var dominant_score := 0
	for family in EquipmentCatalogScript.get_boss_family_ids():
		var score := int(scores.get(family, 0))
		if score > dominant_score:
			dominant_family = family
			dominant_score = score
	var resonance_family := ""
	var resonance_count := 0
	var resonance_score := 0
	for family in EquipmentCatalogScript.get_boss_family_ids():
		var count := int(family_counts.get(family, 0))
		var score := int(scores.get(family, 0))
		if count > resonance_count or (count == resonance_count and score > resonance_score):
			resonance_family = family
			resonance_count = count
			resonance_score = score
	var sync_level := _archetype_sync_level(dominant_score)
	var resonance_level := _archetype_resonance_level(resonance_count)
	var dominant_family_name := EquipmentCatalogScript.get_family_display_name(dominant_family) if not dominant_family.is_empty() else "未定航路"
	var resonance_family_name := EquipmentCatalogScript.get_family_display_name(resonance_family) if not resonance_family.is_empty() else "未定航路"
	return {
		"dominant_family": dominant_family,
		"dominant_family_name": dominant_family_name,
		"family_count": resonance_count,
		"family_counts": family_counts,
		"resonance_family": resonance_family,
		"resonance_family_name": resonance_family_name,
		"resonance_level": resonance_level,
		"resonance_text": _archetype_resonance_text(resonance_family, resonance_level),
		"resonance_effect_text": _archetype_resonance_effect_text(resonance_family, resonance_level),
		"next_resonance_text": _archetype_next_resonance_text(resonance_family, resonance_count),
		"sync_level": sync_level,
		"sync_text": "同家族加成 %d 级" % sync_level,
		"effect_text": _archetype_sync_effect_text(dominant_family, sync_level),
		"score_text": _archetype_score_text(scores),
		"scores": scores,
	}


func _rarity_sync_score(rarity: String) -> int:
	match rarity:
		"boss":
			return 4
		"epic":
			return 3
		"rare":
			return 2
	return 1


func _archetype_sync_level(score: int) -> int:
	if score >= 12:
		return 3
	if score >= 7:
		return 2
	if score >= 3:
		return 1
	return 0


func _archetype_resonance_level(count: int) -> int:
	if count >= 4:
		return 2
	if count >= 2:
		return 1
	return 0


func _archetype_resonance_text(family: String, level: int) -> String:
	if level <= 0 or family.is_empty():
		return "家族共鸣未唤醒"
	var family_name := EquipmentCatalogScript.get_family_display_name(family)
	return "%s%s" % [family_name, "四件共鸣" if level >= 2 else "二件共鸣"]


func _archetype_next_resonance_text(family: String, count: int) -> String:
	if family.is_empty() or count <= 0:
		return "装配同一家族辅助装备可获得二件同家族加成。"
	var family_name := EquipmentCatalogScript.get_family_display_name(family)
	if count >= 4:
		return "%s四件同家族加成已稳定，继续寻找高阶装备强化核心效果。" % family_name
	if count >= 2:
		return "%s四件同家族加成还差 %d 件同族辅助装备。" % [family_name, maxi(0, 4 - count)]
	return "%s二件同家族加成还差 %d 件同族辅助装备。" % [family_name, maxi(0, 2 - count)]


func _archetype_resonance_effect_text(family: String, level: int) -> String:
	if level <= 0 or family.is_empty():
		return "同族装备尚未形成加成"
	match family:
		EquipmentCatalogScript.FAMILY_COLOSSUS:
			if level >= 2:
				return "冲锋余震展开，撞角会留下第二道冲击。"
			return "冲锋距离与撞击伤害提升。"
		EquipmentCatalogScript.FAMILY_PARADISE:
			if level >= 2:
				return "弹幕多出额外弹线，覆盖火力更密。"
			return "射击循环与弹速同步抬升。"
		EquipmentCatalogScript.FAMILY_WARPED:
			if level >= 2:
				return "引力牵引成环，敌群会被拖向弹道中心。"
			return "追踪修正与锁定距离提升。"
		EquipmentCatalogScript.FAMILY_HELL_EYE:
			if level >= 2:
				return "武器过载火力更强，承受伤害更低。"
			return "武器过载积累速度提升。"
		EquipmentCatalogScript.FAMILY_DIVINE:
			if level >= 2:
				return "僚机群火力加重，并额外开放护航槽位。"
			return "僚机射击间隔缩短。"
	return "同族装备尚未形成加成"


func _archetype_score_text(scores: Dictionary) -> String:
	var parts: Array[String] = []
	for family in EquipmentCatalogScript.get_boss_family_ids():
		var score := int(scores.get(family, 0))
		if score > 0:
			parts.append("%s %d" % [_short_family_name(family), score])
	var general_score := int(scores.get(EquipmentCatalogScript.FAMILY_GENERAL, 0))
	if general_score > 0:
		parts.append("通用 %d" % general_score)
	if parts.is_empty():
		return "通用回路"
	return " / ".join(parts)


func _short_family_name(family: String) -> String:
	match family:
		EquipmentCatalogScript.FAMILY_COLOSSUS:
			return "巨构"
		EquipmentCatalogScript.FAMILY_PARADISE:
			return "天堂"
		EquipmentCatalogScript.FAMILY_WARPED:
			return "星核"
		EquipmentCatalogScript.FAMILY_HELL_EYE:
			return "地狱眼"
		EquipmentCatalogScript.FAMILY_DIVINE:
			return "神使"
	return "通用"


func _archetype_sync_effect_text(family: String, level: int) -> String:
	if level <= 0 or family.is_empty():
		return "同家族加成未激活"
	match family:
		EquipmentCatalogScript.FAMILY_COLOSSUS:
			return "冲锋距离 +%d%% / 撞击 +%d%%" % [level * 5, level * 6]
		EquipmentCatalogScript.FAMILY_PARADISE:
			return "射击加速 / 弹速 +%d%%" % (level * 7)
		EquipmentCatalogScript.FAMILY_WARPED:
			return "追踪强化 / 引力牵引"
		EquipmentCatalogScript.FAMILY_HELL_EYE:
			return "武器过载积累 +%d%% / 武器过载火力 +%d%%" % [level * 8, level * 5]
		EquipmentCatalogScript.FAMILY_DIVINE:
			return "僚机射速 +%d%% / 僚机火力 +%d%%" % [level * 6, level * 7]
	return "同家族加成未激活"


func get_player_stats() -> Dictionary:
	var stats := EquipmentCatalogScript.make_player_stats(equipped_weapon, equipped_auxiliaries)
	_apply_archetype_sync_to_stats(stats)
	for bonus_id in active_special_bonus_ids:
		_apply_special_bonus_to_stats(stats, bonus_id)
	_apply_special_beacon_resonance_to_stats(stats)
	_apply_event_contracts_to_stats(stats)
	# 危机账本：危机等级越高，攻击越强
	var crisis_scale := float(stats.get("crisis_atk_scale", 0.0))
	if crisis_scale > 0.0:
		stats["atk_bonus"] = int(stats.get("atk_bonus", 0)) + int(round(crisis_scale * float(crisis_level)))
	return stats


func get_drone_loadout() -> Array:
	return EquipmentCatalogScript.get_drone_loadout(equipped_weapon, equipped_auxiliaries)


func _apply_archetype_sync_to_stats(stats: Dictionary) -> void:
	var sync := _make_archetype_sync_summary()
	var level := int(sync.get("sync_level", 0))
	var resonance_level := int(sync.get("resonance_level", 0))
	var resonance_family := String(sync.get("resonance_family", ""))
	stats["family_resonance_family"] = resonance_family
	stats["family_resonance_level"] = resonance_level
	stats["family_resonance_count"] = int(sync.get("family_count", 0))
	if level > 0:
		match String(sync.get("dominant_family", "")):
			EquipmentCatalogScript.FAMILY_COLOSSUS:
				stats["dash_distance_mult"] = float(stats.get("dash_distance_mult", 1.0)) * (1.0 + 0.05 * float(level))
				stats["dash_damage_mult"] = float(stats.get("dash_damage_mult", 1.0)) * (1.0 + 0.06 * float(level))
				if level >= 2:
					stats["dash_aftershock_radius"] = maxf(float(stats.get("dash_aftershock_radius", 0.0)), 42.0 + float(level) * 18.0)
					stats["dash_aftershock_damage_mult"] = maxf(float(stats.get("dash_aftershock_damage_mult", 0.0)), 0.12 + float(level) * 0.04)
			EquipmentCatalogScript.FAMILY_PARADISE:
				stats["fire_rate_mult"] = float(stats.get("fire_rate_mult", 1.0)) * (1.0 - 0.04 * float(level))
				stats["bullet_speed_mult"] = float(stats.get("bullet_speed_mult", 1.0)) * (1.0 + 0.07 * float(level))
				if level >= 3:
					stats["bullet_count"] = int(stats.get("bullet_count", 1)) + 1
			EquipmentCatalogScript.FAMILY_WARPED:
				stats["homing_strength"] = float(stats.get("homing_strength", 0.0)) + 0.65 * float(level)
				stats["homing_range"] = float(stats.get("homing_range", 0.0)) + 70.0 * float(level)
				stats["gravity_pull_strength"] = float(stats.get("gravity_pull_strength", 0.0)) + 32.0 * float(level)
				stats["gravity_pull_radius"] = float(stats.get("gravity_pull_radius", 0.0)) + 48.0 * float(level)
			EquipmentCatalogScript.FAMILY_HELL_EYE:
				stats["frenzy_gain_mult"] = float(stats.get("frenzy_gain_mult", 1.0)) * (1.0 + 0.08 * float(level))
				stats["frenzy_damage_mult"] = float(stats.get("frenzy_damage_mult", 1.0)) * (1.0 + 0.05 * float(level))
				if level >= 2:
					stats["frenzy_fire_rate_mult"] = float(stats.get("frenzy_fire_rate_mult", 1.0)) * (1.0 - 0.03 * float(level))
			EquipmentCatalogScript.FAMILY_DIVINE:
				stats["drone_fire_interval_mult"] = float(stats.get("drone_fire_interval_mult", 1.0)) * (1.0 - 0.06 * float(level))
				stats["drone_damage_mult"] = float(stats.get("drone_damage_mult", 1.0)) * (1.0 + 0.07 * float(level))
				if level >= 3:
					stats["drone_slots"] = int(stats.get("drone_slots", 0)) + 1
	if resonance_level > 0:
		_apply_family_resonance_to_stats(stats, resonance_family, resonance_level)


func _apply_family_resonance_to_stats(stats: Dictionary, family: String, level: int) -> void:
	match family:
		EquipmentCatalogScript.FAMILY_COLOSSUS:
			stats["dash_distance_mult"] = float(stats.get("dash_distance_mult", 1.0)) * (1.0 + 0.06 * float(level))
			stats["dash_damage_mult"] = float(stats.get("dash_damage_mult", 1.0)) * (1.0 + 0.08 * float(level))
			if level >= 2:
				stats["dash_aftershock_radius"] = maxf(float(stats.get("dash_aftershock_radius", 0.0)), 96.0)
				stats["dash_aftershock_damage_mult"] = maxf(float(stats.get("dash_aftershock_damage_mult", 0.0)), 0.28)
		EquipmentCatalogScript.FAMILY_PARADISE:
			stats["fire_rate_mult"] = float(stats.get("fire_rate_mult", 1.0)) * (1.0 - 0.03 * float(level))
			stats["bullet_speed_mult"] = float(stats.get("bullet_speed_mult", 1.0)) * (1.0 + 0.06 * float(level))
			if level >= 2:
				stats["bullet_count"] = int(stats.get("bullet_count", 1)) + 1
		EquipmentCatalogScript.FAMILY_WARPED:
			stats["homing_strength"] = float(stats.get("homing_strength", 0.0)) + 0.9 * float(level)
			stats["homing_range"] = float(stats.get("homing_range", 0.0)) + 80.0 * float(level)
			if level >= 2:
				stats["gravity_pull_strength"] = float(stats.get("gravity_pull_strength", 0.0)) + 160.0
				stats["gravity_pull_radius"] = float(stats.get("gravity_pull_radius", 0.0)) + 120.0
		EquipmentCatalogScript.FAMILY_HELL_EYE:
			stats["frenzy_gain_mult"] = float(stats.get("frenzy_gain_mult", 1.0)) * (1.0 + 0.12 * float(level))
			if level >= 2:
				stats["frenzy_damage_mult"] = float(stats.get("frenzy_damage_mult", 1.0)) * 1.12
				stats["frenzy_damage_taken_mult"] = float(stats.get("frenzy_damage_taken_mult", 1.0)) * 0.9
		EquipmentCatalogScript.FAMILY_DIVINE:
			stats["drone_fire_interval_mult"] = float(stats.get("drone_fire_interval_mult", 1.0)) * (1.0 - 0.08 * float(level))
			if level >= 2:
				stats["drone_damage_mult"] = float(stats.get("drone_damage_mult", 1.0)) * 1.15
				stats["drone_slots"] = int(stats.get("drone_slots", 0)) + 1


func is_special_bonus_active(node_id: int) -> bool:
	var node := get_map_node(node_id)
	if node.is_empty() or String(node.get("type", "")) != NODE_SPECIAL:
		return false
	return active_special_bonus_ids.has(String(node.get("bonus_id", "")))


func get_mineral_bonus() -> float:
	return float(get_player_stats().get("mineral_bonus", 0.0))


func get_frenzy_gain_mult() -> float:
	return float(get_player_stats().get("frenzy_gain_mult", 1.0))


func get_frenzy_fire_rate_mult() -> float:
	return float(get_player_stats().get("frenzy_fire_rate_mult", 1.0))


func get_frenzy_damage_mult() -> float:
	return float(get_player_stats().get("frenzy_damage_mult", 1.0))


func get_frenzy_damage_taken_mult() -> float:
	return float(get_player_stats().get("frenzy_damage_taken_mult", 1.0))


func get_damage_taken_mult() -> float:
	return float(get_player_stats().get("damage_taken_mult", 1.0))


func _complete_current_node(success: bool) -> Dictionary:
	if not success or current_node_id <= 0:
		abandon_current_room()
		return {"ok": false, "message": "节点未完成。"}
	var node := get_map_node(current_node_id)
	if node.is_empty() or bool(node.get("completed", false)):
		abandon_current_room()
		return {"ok": false, "message": "节点已结算。"}
	var completion_node_id := current_node_id
	var loot_summary := _commit_pending_room_loot()
	node["completed"] = true
	map_nodes[completion_node_id] = node
	completed_node_count += 1
	var base_crisis_added := _add_crisis_with_alert_stop(1)
	compute_capacity += 1
	var contract_summary := _apply_active_event_contracts_on_node_complete()
	var expired_contracts := _tick_event_contracts()
	var special_refresh := _refresh_special_bonus_nodes()
	var beacon_echo_routes: Array = special_refresh.get("beacon_echo_routes", [])
	var activated_special_ids: Array = special_refresh.get("activated_specials", [])
	var route_update := _advance_route_directives_on_node_complete(node, activated_special_ids)
	var completed_route_directives: Array = Array(loot_summary.get("completed_route_directives", [])).duplicate(true)
	completed_route_directives.append_array(Array(route_update.get("completed_directives", [])))
	var new_route_directives: Array = Array(loot_summary.get("new_route_directives", [])).duplicate(true)
	new_route_directives.append_array(Array(route_update.get("new_directives", [])))
	var route_directive_rewards := Dictionary(loot_summary.get("route_directive_rewards", {})).duplicate(true)
	_merge_route_directive_reward_summary(route_directive_rewards, Dictionary(route_update.get("reward_summary", {})))
	var summary := {
		"ok": true,
		"node_id": completion_node_id,
		"crisis_level": crisis_level,
		"compute_capacity": compute_capacity,
		"alert_active": is_alert_active(),
		"activated_specials": activated_special_ids,
		"beacon_echo_routes": beacon_echo_routes,
		"base_crisis_added": base_crisis_added,
		"base_minerals_committed": int(loot_summary.get("base_minerals", 0)),
		"mineral_bonus_added": int(loot_summary.get("mineral_bonus_added", 0)),
		"event_contract_minerals_added": int(loot_summary.get("event_contract_minerals_added", 0)),
		"minerals_committed": int(loot_summary.get("minerals_committed", 0)),
		"event_contract_crisis_added": int(contract_summary.get("crisis_added", 0)),
		"event_contracts_applied": contract_summary.get("contracts", []),
		"expired_event_contract_count": expired_contracts.size(),
		"expired_event_contracts": expired_contracts,
		"active_event_contracts": get_active_event_contracts(),
		"equipment": Array(loot_summary.get("equipment", [])).duplicate(),
		"equipment_names": Array(loot_summary.get("equipment_names", [])).duplicate(),
		"completed_route_directives": completed_route_directives,
		"new_route_directives": new_route_directives,
		"route_directive_rewards": route_directive_rewards,
		"shop_directive_focus_changed": bool(route_directive_rewards.get("shop_focus_changed", false)),
		"active_route_directives": get_route_directive_summaries(),
	}
	last_node_completion_summary = summary.duplicate(true)
	abandon_current_room()
	return summary


func _commit_pending_room_loot() -> Dictionary:
	var base_minerals := int(pending_room_loot.get("minerals", 0))
	var bonus := int(floor(float(base_minerals) * get_mineral_bonus()))
	var contract_bonus_summary := _get_event_contract_mineral_bonus(base_minerals)
	var contract_bonus := int(contract_bonus_summary.get("minerals_added", 0))
	# 撤离摇篮：撤离结算时额外矿物加成
	var evac_bonus := int(floor(float(base_minerals) * float(get_player_stats().get("evac_mineral_bonus", 0.0))))
	var total_minerals := base_minerals + bonus + contract_bonus + evac_bonus
	minerals += total_minerals
	var committed_equipment: Array[String] = []
	var committed_equipment_names: Array[String] = []
	for item_id in pending_room_loot.get("equipment", []):
		if EquipmentCatalogScript.has_item(item_id) and not equipment_inventory.has(item_id):
			equipment_inventory.append(item_id)
			committed_equipment.append(String(item_id))
			committed_equipment_names.append(EquipmentCatalogScript.get_display_name(String(item_id)))
	return {
		"base_minerals": base_minerals,
		"mineral_bonus_added": bonus,
		"event_contract_minerals_added": contract_bonus,
		"minerals_committed": total_minerals,
		"event_contracts_applied": contract_bonus_summary.get("contracts", []),
		"equipment": committed_equipment,
		"equipment_names": committed_equipment_names,
		"completed_route_directives": Array(pending_room_loot.get("completed_route_directives", [])).duplicate(true),
		"new_route_directives": Array(pending_room_loot.get("new_route_directives", [])).duplicate(true),
		"route_directive_rewards": Dictionary(pending_room_loot.get("route_directive_rewards", {})).duplicate(true),
	}


func _add_crisis_with_alert_stop(amount: int) -> int:
	var added := 0
	for _i in range(maxi(0, amount)):
		if is_alert_active():
			break
		crisis_level += 1
		added += 1
		if is_alert_active():
			break
	if added > 0:
		_queue_crisis_broadcast()
	return added


func debug_add_crisis(amount: int = 1) -> Dictionary:
	if not is_formal_run_active():
		return {"ok": false, "message": "当前没有进行中的正式航程，无法提高危机关注度。"}
	if is_alert_active():
		return {"ok": false, "message": "危机关注度 %d 已触发首领警报，请先处理中心节点。" % crisis_level}
	var requested := clampi(amount, 1, 99)
	var added := _add_crisis_with_alert_stop(requested)
	if added <= 0:
		return {"ok": false, "message": "危机关注度未变化。"}
	save_run()
	var suffix := "已触发首领警报。" if is_alert_active() else ""
	return {
		"ok": true,
		"added": added,
		"crisis_level": crisis_level,
		"alert_active": is_alert_active(),
		"message": "危机关注度 +%d，当前为 %d。%s" % [added, crisis_level, suffix],
	}


func _queue_crisis_broadcast() -> void:
	if is_alert_active():
		pending_crisis_broadcast = String(CRISIS_LOCK_BROADCASTS.get(crisis_level, ""))
	elif CRISIS_THRESHOLDS.has(crisis_level + 1):
		pending_crisis_broadcast = CRISIS_APPROACH_BROADCASTS[randi() % CRISIS_APPROACH_BROADCASTS.size()]
	else:
		pending_crisis_broadcast = CRISIS_TICK_BROADCASTS[randi() % CRISIS_TICK_BROADCASTS.size()]


func consume_crisis_broadcast() -> String:
	var text := pending_crisis_broadcast
	pending_crisis_broadcast = ""
	return text


func _make_event_contract_data(profile: Dictionary, node: Dictionary) -> Dictionary:
	var contract: Dictionary = profile.get("contract", {})
	if contract.is_empty():
		return {}
	var contract_id := String(contract.get("contract_id", profile.get("id", "")))
	if contract_id.is_empty():
		return {}
	var duration := maxi(1, int(contract.get("duration_nodes", 1)))
	return {
		"contract_id": contract_id,
		"source_event_id": String(profile.get("id", "")),
		"title": String(contract.get("title", profile.get("title", contract_id))),
		"description": String(contract.get("description", "")),
		"effect_type": String(contract.get("effect_type", "event_contract")),
		"shop_focus_family": String(contract.get("shop_focus_family", "")),
		"shop_focus_text": String(contract.get("shop_focus_text", "")),
		"remaining_nodes": duration,
		"duration_nodes": duration,
		"mineral_bonus_rate": float(contract.get("mineral_bonus_rate", 0.0)),
		"extra_crisis_on_complete": int(contract.get("extra_crisis_on_complete", 0)),
		"equipment_chance_bonus": float(contract.get("equipment_chance_bonus", 0.0)),
		"shop_discount_rate": float(contract.get("shop_discount_rate", 0.0)),
		"free_shop_rerolls": int(contract.get("free_shop_rerolls", 0)),
		"free_shop_rerolls_used": int(contract.get("free_shop_rerolls_used", 0)),
		"frenzy_gain_mult": float(contract.get("frenzy_gain_mult", 1.0)),
		"family_bias": String(contract.get("family_bias", "")),
		"dash_distance_mult": float(contract.get("dash_distance_mult", 1.0)),
		"dash_damage_mult": float(contract.get("dash_damage_mult", 1.0)),
		"dash_aftershock_radius_bonus": float(contract.get("dash_aftershock_radius_bonus", 0.0)),
		"bullet_count_bonus": int(contract.get("bullet_count_bonus", 0)),
		"fire_rate_mult": float(contract.get("fire_rate_mult", 1.0)),
		"bullet_speed_mult": float(contract.get("bullet_speed_mult", 1.0)),
		"homing_strength_bonus": float(contract.get("homing_strength_bonus", 0.0)),
		"gravity_pull_strength_bonus": float(contract.get("gravity_pull_strength_bonus", 0.0)),
		"gravity_pull_radius_bonus": float(contract.get("gravity_pull_radius_bonus", 0.0)),
		"frenzy_damage_mult": float(contract.get("frenzy_damage_mult", 1.0)),
		"frenzy_damage_taken_mult": float(contract.get("frenzy_damage_taken_mult", 1.0)),
		"drone_slots_bonus": int(contract.get("drone_slots_bonus", 0)),
		"drone_fire_interval_mult": float(contract.get("drone_fire_interval_mult", 1.0)),
		"drone_damage_mult": float(contract.get("drone_damage_mult", 1.0)),
		"source_node_id": int(node.get("id", -1)),
		"source_node_tier": int(node.get("tier", 1)),
	}


func _add_event_contract(contract_data: Dictionary) -> Dictionary:
	var contract_id := String(contract_data.get("contract_id", ""))
	if contract_id.is_empty():
		return {}
	var contract := contract_data.duplicate(true)
	contract["remaining_nodes"] = maxi(1, int(contract.get("remaining_nodes", contract.get("duration_nodes", 1))))
	_apply_event_contract_shop_focus(contract)
	for i in range(active_event_contracts.size()):
		if String(active_event_contracts[i].get("contract_id", "")) == contract_id:
			active_event_contracts[i] = contract
			return contract.duplicate(true)
	active_event_contracts.append(contract)
	return contract.duplicate(true)


func _apply_event_contract_shop_focus(contract: Dictionary) -> void:
	var family := _normalize_shop_family(String(contract.get("shop_focus_family", "")))
	if family.is_empty():
		return
	contract["shop_focus_family"] = family
	if String(contract.get("shop_focus_text", "")).strip_edges().is_empty():
		contract["shop_focus_text"] = "%s商品偏好" % EquipmentCatalogScript.get_family_display_name(family)
	shop_preferred_family = family
	shop_offer_ids.clear()
	shop_draft_initialized = false


func _get_event_contract_mineral_bonus(base_minerals: int) -> Dictionary:
	var minerals_added := 0
	var applied: Array[Dictionary] = []
	if base_minerals <= 0:
		return {"minerals_added": 0, "contracts": applied}
	for contract in active_event_contracts:
		var rate := float(contract.get("mineral_bonus_rate", 0.0))
		if rate <= 0.0:
			continue
		var bonus := int(floor(float(base_minerals) * rate))
		if bonus <= 0:
			continue
		minerals_added += bonus
		applied.append({
			"contract_id": String(contract.get("contract_id", "")),
			"title": String(contract.get("title", "")),
			"minerals_added": bonus,
		})
	return {"minerals_added": minerals_added, "contracts": applied}


func _get_event_contract_equipment_chance_bonus() -> float:
	var bonus := 0.0
	for contract in active_event_contracts:
		bonus += float(contract.get("equipment_chance_bonus", 0.0))
	return bonus


func _get_active_shop_discount_rate() -> float:
	var best_rate := 0.0
	for contract in active_event_contracts:
		best_rate = maxf(best_rate, float(contract.get("shop_discount_rate", 0.0)))
	return clampf(best_rate, 0.0, 0.9)


func _get_active_shop_discount_contract() -> Dictionary:
	var best_contract: Dictionary = {}
	var best_rate := 0.0
	for raw_contract in active_event_contracts:
		var contract := Dictionary(raw_contract)
		var rate := float(contract.get("shop_discount_rate", 0.0))
		if rate > best_rate:
			best_rate = rate
			best_contract = contract
	return best_contract


func _get_free_shop_reroll_count() -> int:
	var remaining := 0
	for contract in active_event_contracts:
		remaining += maxi(0, int(contract.get("free_shop_rerolls", 0)) - int(contract.get("free_shop_rerolls_used", 0)))
	return remaining


func _get_free_shop_reroll_contract() -> Dictionary:
	for raw_contract in active_event_contracts:
		var contract := Dictionary(raw_contract)
		if int(contract.get("free_shop_rerolls", 0)) - int(contract.get("free_shop_rerolls_used", 0)) > 0:
			return contract
	return {}


func _consume_free_shop_reroll() -> bool:
	for i in range(active_event_contracts.size()):
		var contract := Dictionary(active_event_contracts[i])
		var remaining := int(contract.get("free_shop_rerolls", 0)) - int(contract.get("free_shop_rerolls_used", 0))
		if remaining <= 0:
			continue
		contract["free_shop_rerolls_used"] = int(contract.get("free_shop_rerolls_used", 0)) + 1
		active_event_contracts[i] = contract
		return true
	return false


func _apply_event_contracts_to_stats(stats: Dictionary) -> void:
	for contract in active_event_contracts:
		stats["frenzy_gain_mult"] = float(stats.get("frenzy_gain_mult", 1.0)) * float(contract.get("frenzy_gain_mult", 1.0))
		stats["dash_distance_mult"] = float(stats.get("dash_distance_mult", 1.0)) * float(contract.get("dash_distance_mult", 1.0))
		stats["dash_damage_mult"] = float(stats.get("dash_damage_mult", 1.0)) * float(contract.get("dash_damage_mult", 1.0))
		var aftershock_bonus := float(contract.get("dash_aftershock_radius_bonus", 0.0))
		if aftershock_bonus > 0.0:
			stats["dash_aftershock_radius"] = float(stats.get("dash_aftershock_radius", 0.0)) + aftershock_bonus
		stats["bullet_count"] = int(stats.get("bullet_count", 1)) + int(contract.get("bullet_count_bonus", 0))
		stats["fire_rate_mult"] = float(stats.get("fire_rate_mult", 1.0)) * float(contract.get("fire_rate_mult", 1.0))
		stats["bullet_speed_mult"] = float(stats.get("bullet_speed_mult", 1.0)) * float(contract.get("bullet_speed_mult", 1.0))
		stats["homing_strength"] = float(stats.get("homing_strength", 0.0)) + float(contract.get("homing_strength_bonus", 0.0))
		stats["gravity_pull_strength"] = float(stats.get("gravity_pull_strength", 0.0)) + float(contract.get("gravity_pull_strength_bonus", 0.0))
		stats["gravity_pull_radius"] = float(stats.get("gravity_pull_radius", 0.0)) + float(contract.get("gravity_pull_radius_bonus", 0.0))
		stats["frenzy_damage_mult"] = float(stats.get("frenzy_damage_mult", 1.0)) * float(contract.get("frenzy_damage_mult", 1.0))
		stats["frenzy_damage_taken_mult"] = float(stats.get("frenzy_damage_taken_mult", 1.0)) * float(contract.get("frenzy_damage_taken_mult", 1.0))
		stats["drone_slots"] = int(stats.get("drone_slots", 0)) + int(contract.get("drone_slots_bonus", 0))
		stats["drone_fire_interval_mult"] = float(stats.get("drone_fire_interval_mult", 1.0)) * float(contract.get("drone_fire_interval_mult", 1.0))
		stats["drone_damage_mult"] = float(stats.get("drone_damage_mult", 1.0)) * float(contract.get("drone_damage_mult", 1.0))


func _get_event_contract_effects_text(contract: Dictionary) -> String:
	var parts: Array[String] = []
	var mineral_bonus_rate := float(contract.get("mineral_bonus_rate", 0.0))
	if mineral_bonus_rate > 0.0:
		parts.append("矿物 +%d%%" % int(round(mineral_bonus_rate * 100.0)))
	var extra_crisis := int(contract.get("extra_crisis_on_complete", 0))
	if extra_crisis > 0:
		parts.append("危机 +%d" % extra_crisis)
	var equipment_chance_bonus := float(contract.get("equipment_chance_bonus", 0.0))
	if equipment_chance_bonus > 0.0:
		parts.append("装备出现率 +%d%%" % int(round(equipment_chance_bonus * 100.0)))
	var shop_discount_rate := float(contract.get("shop_discount_rate", 0.0))
	if shop_discount_rate > 0.0:
		parts.append("采购折扣 %d%%" % int(round(shop_discount_rate * 100.0)))
	var free_shop_rerolls := maxi(0, int(contract.get("free_shop_rerolls", 0)) - int(contract.get("free_shop_rerolls_used", 0)))
	if free_shop_rerolls > 0:
		parts.append("免费刷新商品 %d 次" % free_shop_rerolls)
	var frenzy_gain_mult := float(contract.get("frenzy_gain_mult", 1.0))
	if frenzy_gain_mult < 1.0:
		parts.append("武器过载积累 %d%%" % int(round(frenzy_gain_mult * 100.0)))
	elif frenzy_gain_mult > 1.0:
		parts.append("武器过载积累 +%d%%" % int(round((frenzy_gain_mult - 1.0) * 100.0)))
	if float(contract.get("dash_distance_mult", 1.0)) > 1.0 or float(contract.get("dash_damage_mult", 1.0)) > 1.0:
		parts.append("冲锋强化")
	if int(contract.get("bullet_count_bonus", 0)) > 0:
		parts.append("弹幕 +%d" % int(contract.get("bullet_count_bonus", 0)))
	if float(contract.get("fire_rate_mult", 1.0)) < 1.0:
		parts.append("射击加速")
	if float(contract.get("gravity_pull_strength_bonus", 0.0)) > 0.0:
		parts.append("引力牵引")
	if float(contract.get("frenzy_damage_mult", 1.0)) > 1.0:
		parts.append("武器过载火力 +%d%%" % int(round((float(contract.get("frenzy_damage_mult", 1.0)) - 1.0) * 100.0)))
	if int(contract.get("drone_slots_bonus", 0)) > 0:
		parts.append("僚机 +%d" % int(contract.get("drone_slots_bonus", 0)))
	var shop_focus_text := String(contract.get("shop_focus_text", "")).strip_edges()
	if not shop_focus_text.is_empty():
		parts.append(shop_focus_text)
	if parts.is_empty():
		return "航路参数已改写"
	return " / ".join(parts)


func _get_contract_family_display_name(family: String) -> String:
	match family:
		"colossus":
			return "星间巨构"
		"paradise":
			return "天堂号"
		"warped":
			return "扭曲星核"
		"hell_eye":
			return "地狱之眼"
		"divine":
			return "神明使者"
	return "通用航路"


func _apply_active_event_contracts_on_node_complete() -> Dictionary:
	var crisis_added := 0
	var applied: Array[Dictionary] = []
	for contract in active_event_contracts:
		var extra_crisis := int(contract.get("extra_crisis_on_complete", 0))
		if extra_crisis <= 0:
			continue
		var actual_added := _add_crisis_with_alert_stop(extra_crisis)
		if actual_added <= 0:
			continue
		crisis_added += actual_added
		applied.append({
			"contract_id": String(contract.get("contract_id", "")),
			"title": String(contract.get("title", "")),
			"crisis_added": actual_added,
		})
	return {"crisis_added": crisis_added, "contracts": applied}


func _tick_event_contracts() -> Array[Dictionary]:
	var remaining_contracts: Array[Dictionary] = []
	var expired_contracts: Array[Dictionary] = []
	for contract in active_event_contracts:
		var ticked := contract.duplicate(true)
		ticked["remaining_nodes"] = int(ticked.get("remaining_nodes", 1)) - 1
		if int(ticked.get("remaining_nodes", 0)) <= 0:
			expired_contracts.append(ticked)
		else:
			remaining_contracts.append(ticked)
	active_event_contracts = remaining_contracts
	return expired_contracts


func _prepare_boss_reward(scene_path: String, threshold: int) -> void:
	last_boss_reward.clear()
	pending_boss_reward.clear()
	var family := _get_boss_family_for_scene(scene_path)
	if family.is_empty():
		return
	var stage := CRISIS_THRESHOLDS.find(threshold) + 1
	var seed := completed_node_count * 1009 + stage * 101 + family.hash()
	pending_boss_reward = {
		"family": family,
		"threshold": threshold,
		"stage": stage,
		"is_final": threshold >= CRISIS_THRESHOLDS.back(),
		"candidate_ids": EquipmentCatalogScript.get_boss_reward_candidate_ids(family, stage, equipment_inventory, seed),
	}


func has_pending_boss_reward() -> bool:
	return not pending_boss_reward.is_empty() and not Array(pending_boss_reward.get("candidate_ids", [])).is_empty()


func get_pending_boss_reward_summary() -> Dictionary:
	if not has_pending_boss_reward():
		return {}
	var summary := pending_boss_reward.duplicate(true)
	summary["ok"] = true
	summary["family_name"] = EquipmentCatalogScript.get_family_display_name(String(summary.get("family", "")))
	return summary


func claim_boss_reward(item_id: String) -> Dictionary:
	if not has_pending_boss_reward():
		return {"ok": false, "message": "没有待确认的执行体缴获。"}
	if not pending_boss_reward.get("candidate_ids", []).has(item_id):
		return {"ok": false, "message": "该装备不在本次缴获列表中。"}
	if equipment_inventory.has(item_id) or not EquipmentCatalogScript.has_item(item_id):
		return {"ok": false, "message": "该装备已不可领取，请选择其他项目。"}
	last_boss_reward = pending_boss_reward.duplicate(true)
	last_boss_reward["item_id"] = item_id
	last_boss_reward.erase("candidate_ids")
	var is_final := bool(pending_boss_reward.get("is_final", false))
	pending_boss_reward.clear()
	equipment_inventory.append(item_id)
	return {
		"ok": true,
		"item_id": item_id,
		"item_name": EquipmentCatalogScript.get_display_name(item_id),
		"is_final": is_final,
	}


func _make_boss_completion_summary(threshold: int) -> Dictionary:
	var family := String(pending_boss_reward.get("family", ""))
	if family.is_empty():
		return {}
	return {
		"ok": true,
		"threshold": threshold,
		"stage": int(pending_boss_reward.get("stage", CRISIS_THRESHOLDS.find(threshold) + 1)),
		"family": family,
		"family_name": EquipmentCatalogScript.get_family_display_name(family),
		"candidate_ids": Array(pending_boss_reward.get("candidate_ids", [])).duplicate(),
		"is_final": bool(pending_boss_reward.get("is_final", false)),
	}


func _apply_boss_aftershock(reward: Dictionary) -> Dictionary:
	var family := _normalize_shop_family(String(reward.get("family", "")))
	if family.is_empty():
		return {}
	var family_name := EquipmentCatalogScript.get_family_display_name(family)
	var focus_text := "%s商品偏好" % family_name
	shop_preferred_family = family
	shop_offer_ids.clear()
	shop_draft_initialized = false
	var calibrated_routes: Array[Dictionary] = []
	var candidates := _get_boss_aftershock_route_candidates(family)
	for target_id in candidates:
		if calibrated_routes.size() >= BOSS_AFTERSHOCK_ROUTE_COUNT:
			break
		var target := get_map_node(int(target_id))
		if target.is_empty():
			continue
		var aftershock_text := "首领余波：%s残响压入航图，%s正在改写下一段商品偏好。" % [family_name, focus_text]
		target["boss_aftershock"] = {
			"family_bias": family,
			"family_name": family_name,
			"shop_focus_text": focus_text,
			"aftershock_text": aftershock_text,
			"equipment_bonus": BOSS_AFTERSHOCK_EQUIPMENT_BONUS,
			"reward_bonus": BOSS_AFTERSHOCK_REWARD_BONUS,
			"stage": int(reward.get("stage", 0)),
			"threshold": int(reward.get("threshold", 0)),
		}
		target["family_bias"] = family
		if String(target.get("type", "")) == NODE_REWARD:
			target["cache_family_bias"] = family
		target["equipment_drop_chance"] = clampf(
			float(target.get("equipment_drop_chance", TIER_EQUIPMENT_DROP_CHANCES[0])) + BOSS_AFTERSHOCK_EQUIPMENT_BONUS,
			0.0,
			MAX_READABLE_EQUIPMENT_DROP_CHANCE
		)
		target["reward_mult"] = float(target.get("reward_mult", 1.0)) + BOSS_AFTERSHOCK_REWARD_BONUS
		_apply_route_plan_to_node(target)
		map_nodes[int(target_id)] = target
		calibrated_routes.append({
			"node_id": int(target_id),
			"node_name": String(target.get("name", "未标记航线")),
			"family_name": family_name,
			"shop_focus_text": focus_text,
			"aftershock_text": aftershock_text,
			"equipment_bonus": BOSS_AFTERSHOCK_EQUIPMENT_BONUS,
			"reward_bonus": BOSS_AFTERSHOCK_REWARD_BONUS,
		})
	return {
		"shop_focus_family": family,
		"shop_focus_name": family_name,
		"shop_focus_text": focus_text,
		"shop_focus_changed": true,
		"boss_aftershock_text": "余波调整：%s残响已并入方舟商品偏好，下一段航线会向%s收束。" % [family_name, family_name],
		"boss_aftershock_routes": calibrated_routes,
		"boss_aftershock_route_count": calibrated_routes.size(),
	}


func _get_boss_aftershock_route_candidates(family: String) -> Array[int]:
	var preferred: Array[int] = []
	var fallback: Array[int] = []
	for node in map_nodes:
		var node_id := int(node.get("id", -1))
		if node_id <= 0 or String(node.get("type", "")) == NODE_SPECIAL:
			continue
		if bool(node.get("completed", false)) or not is_node_accessible(node_id):
			continue
		var route_family := _route_plan_family_for_node(node)
		if route_family == family:
			preferred.append(node_id)
		else:
			fallback.append(node_id)
	preferred.append_array(fallback)
	return preferred


func _reset_shop_state() -> void:
	shop_offer_ids.clear()
	shop_draft_initialized = false
	shop_reroll_count = 0
	shop_preferred_family = ""
	shop_beacon_family = ""
	shop_beacon_bonus_name = ""
	shop_ore_source_focus = ""
	shop_ore_source_focus_text = ""


func _ensure_shop_draft() -> void:
	if shop_draft_initialized:
		return
	shop_offer_ids = _build_shop_offer_ids(_resolve_shop_focus_family())
	shop_draft_initialized = true


func _build_shop_offer_ids(preferred_family: String = "") -> Array[String]:
	var family := _normalize_shop_family(preferred_family)
	var offer_seed := _make_shop_offer_seed(family)
	var offers := EquipmentCatalogScript.get_shop_offer_item_ids(
		equipment_inventory,
		crisis_level,
		family,
		SHOP_OFFER_COUNT,
		offer_seed
	)
	_apply_calibration_resonance_candidates(offers, offer_seed + 2089)
	_reinforce_shop_family_focus(offers, family, offer_seed + 4099)
	_reinforce_shop_ore_source_focus(offers, family, offer_seed + 7127)
	return offers


func _apply_calibration_resonance_candidates(offers: Array[String], seed: int) -> void:
	if calibration_resonance_offer_remaining <= 0 or calibration_resonance_family.is_empty():
		return
	var candidates: Array[String] = []
	for item_id in EquipmentCatalogScript.get_shop_offer_item_ids(equipment_inventory, crisis_level, calibration_resonance_family, 80, seed):
		if EquipmentCatalogScript.get_family(item_id) == calibration_resonance_family and not offers.has(item_id):
			candidates.append(item_id)
	if candidates.is_empty():
		return
	var replacements := 0
	for index in range(offers.size()):
		if replacements >= calibration_resonance_offer_remaining or candidates.is_empty():
			break
		if EquipmentCatalogScript.get_family(offers[index]) == calibration_resonance_family:
			continue
		offers[index] = candidates.pop_front()
		replacements += 1
	calibration_resonance_offer_remaining -= replacements


func _make_shop_offer_seed(preferred_family: String) -> int:
	var family_hash := absi(preferred_family.hash()) % 9973
	return crisis_level * 1009 + completed_node_count * 917 + shop_reroll_count * 1543 + family_hash + 31


func _prune_owned_shop_offers() -> void:
	for i in range(shop_offer_ids.size() - 1, -1, -1):
		if equipment_inventory.has(shop_offer_ids[i]):
			shop_offer_ids.remove_at(i)


func _normalize_shop_family(preferred_family: String) -> String:
	if FAMILY_BIASES.has(preferred_family):
		return preferred_family
	return ""


func _resolve_shop_focus_family() -> String:
	var preferred := _normalize_shop_family(shop_preferred_family)
	if not preferred.is_empty():
		return preferred
	return _normalize_shop_family(shop_beacon_family)


func _reinforce_shop_family_focus(offers: Array[String], preferred_family: String, seed: int) -> void:
	if preferred_family.is_empty():
		return
	var matching_count := 0
	for item_id in offers:
		if EquipmentCatalogScript.get_family(item_id) == preferred_family:
			matching_count += 1
	if matching_count >= SHOP_FOCUS_MIN_OFFERS:
		return
	var candidates: Array[String] = []
	for item_id in EquipmentCatalogScript.get_shop_offer_item_ids([], crisis_level, preferred_family, 80, seed):
		if EquipmentCatalogScript.get_family(item_id) != preferred_family:
			continue
		if equipment_inventory.has(item_id) or offers.has(item_id):
			continue
		candidates.append(item_id)
	if candidates.is_empty():
		return
	var rng := _make_rng(seed + 6113)
	candidates.shuffle()
	while matching_count < SHOP_FOCUS_MIN_OFFERS and not candidates.is_empty():
		var replacement_index := _find_shop_non_focus_replacement_index(offers, preferred_family, rng)
		if replacement_index < 0:
			return
		offers[replacement_index] = candidates.pop_back()
		matching_count += 1


func _find_shop_non_focus_replacement_index(offers: Array[String], preferred_family: String, rng: RandomNumberGenerator) -> int:
	var replacement_indices: Array[int] = []
	for i in range(offers.size()):
		if EquipmentCatalogScript.get_family(offers[i]) != preferred_family:
			replacement_indices.append(i)
	if replacement_indices.is_empty():
		return -1
	return replacement_indices[rng.randi_range(0, replacement_indices.size() - 1)]


func _reinforce_shop_ore_source_focus(offers: Array[String], preferred_family: String, seed: int) -> void:
	if shop_ore_source_focus.is_empty() or offers.is_empty():
		return
	var mineral_count := _count_shop_mineral_offers(offers)
	if mineral_count >= SHOP_ORE_SOURCE_MIN_OFFERS:
		return
	var candidates: Array[String] = []
	for item_id in EquipmentCatalogScript.get_mineral_shop_offer_item_ids(
		equipment_inventory,
		crisis_level,
		preferred_family,
		SHOP_OFFER_COUNT,
		seed
	):
		var id := String(item_id)
		if id.is_empty() or offers.has(id):
			continue
		candidates.append(id)
	if candidates.is_empty():
		return
	var rng := _make_rng(seed + 7331)
	while mineral_count < SHOP_ORE_SOURCE_MIN_OFFERS and not candidates.is_empty():
		var replacement_index := _find_shop_ore_source_replacement_index(offers, preferred_family, rng)
		if replacement_index < 0:
			return
		offers[replacement_index] = candidates.pop_front()
		mineral_count += 1


func _count_shop_mineral_offers(offers: Array[String]) -> int:
	var count := 0
	for item_id in offers:
		if float(EquipmentCatalogScript.get_item(item_id).get("mineral_bonus", 0.0)) > 0.0:
			count += 1
	return count


func _find_shop_ore_source_replacement_index(offers: Array[String], preferred_family: String, rng: RandomNumberGenerator) -> int:
	var replacement_indices: Array[int] = []
	for i in range(offers.size()):
		var item_id := String(offers[i])
		if float(EquipmentCatalogScript.get_item(item_id).get("mineral_bonus", 0.0)) > 0.0:
			continue
		if not preferred_family.is_empty():
			var family := EquipmentCatalogScript.get_family(item_id)
			if family == preferred_family and _count_shop_family_offers(offers, preferred_family) <= SHOP_FOCUS_MIN_OFFERS:
				continue
		replacement_indices.append(i)
	if replacement_indices.is_empty():
		return -1
	return replacement_indices[rng.randi_range(0, replacement_indices.size() - 1)]


func _count_shop_family_offers(offers: Array[String], family: String) -> int:
	var count := 0
	for item_id in offers:
		if EquipmentCatalogScript.get_family(item_id) == family:
			count += 1
	return count


func _empty_loot() -> Dictionary:
	return {
		"minerals": 0,
		"equipment": [],
		"completed_route_directives": [],
		"new_route_directives": [],
		"route_directive_rewards": {},
	}


func _generate_route_directives() -> void:
	active_route_directives.clear()
	retired_route_directive_ids.clear()
	_refill_route_directives()


func _refill_route_directives() -> Array[Dictionary]:
	var added: Array[Dictionary] = []
	var blocked_ids: Array[String] = retired_route_directive_ids.duplicate()
	for raw_directive in active_route_directives:
		blocked_ids.append(String(Dictionary(raw_directive).get("id", "")))
	while active_route_directives.size() < ROUTE_DIRECTIVE_COUNT:
		var directive := _make_random_route_directive(blocked_ids)
		if directive.is_empty():
			retired_route_directive_ids.clear()
			blocked_ids.clear()
			for raw_active in active_route_directives:
				blocked_ids.append(String(Dictionary(raw_active).get("id", "")))
			directive = _make_random_route_directive(blocked_ids)
			if directive.is_empty():
				break
		active_route_directives.append(directive)
		blocked_ids.append(String(directive.get("id", "")))
		added.append(_make_route_directive_summary(directive))
	return added


func _make_random_route_directive(blocked_ids: Array[String]) -> Dictionary:
	var candidates: Array[Dictionary] = []
	for raw_profile in ROUTE_DIRECTIVE_PROFILES:
		var profile := Dictionary(raw_profile)
		if not blocked_ids.has(String(profile.get("id", ""))):
			candidates.append(profile)
	if candidates.is_empty():
		return {}
	var directive := Dictionary(candidates.pick_random()).duplicate(true)
	directive["current"] = 0
	directive["completed"] = false
	directive["claimed"] = false
	return directive


func _make_route_directive_summary(directive: Dictionary) -> Dictionary:
	var current := int(directive.get("current", 0))
	var required := maxi(1, int(directive.get("required", 1)))
	var reward := Dictionary(directive.get("reward", {}))
	var reward_minerals := int(reward.get("minerals", directive.get("reward_minerals", 0)))
	return {
		"directive_id": String(directive.get("id", directive.get("directive_id", ""))),
		"id": String(directive.get("id", directive.get("directive_id", ""))),
		"target_behavior": int(directive.get("target_behavior", -1)),
		"target_name": String(directive.get("target_name", "")),
		"family_name": String(directive.get("family_name", "")),
		"title": String(directive.get("title", "航路指令")),
		"description": String(directive.get("description", "完成方舟航路目标。")),
		"goal_type": String(directive.get("goal_type", "")),
		"target": String(directive.get("target", "")),
		"current": current,
		"required": required,
		"progress_text": "进度 %d/%d" % [mini(current, required), required],
		"reward": reward.duplicate(true),
		"reward_text": String(directive.get("reward_text", "星髓矿 +%d" % reward_minerals)),
		"reward_minerals": reward_minerals,
		"reward_result": Dictionary(directive.get("reward_result", {})).duplicate(true),
		"completed": bool(directive.get("completed", false)),
	}


func _count_map_nodes_by_type(node_type: String) -> int:
	var count := 0
	for node in map_nodes:
		var node_id := int(node.get("id", -1))
		if node_id <= 0:
			continue
		if bool(node.get("completed", false)):
			continue
		if String(node.get("type", "")) == node_type:
			count += 1
	return count


func _count_map_nodes_by_family(family: String) -> int:
	if family.is_empty():
		return 0
	var count := 0
	for node in map_nodes:
		var node_id := int(node.get("id", -1))
		if node_id <= 0 or String(node.get("type", "")) == NODE_SPECIAL:
			continue
		if bool(node.get("completed", false)):
			continue
		var plan: Dictionary = node.get("route_plan", {})
		var route_family := String(plan.get("family", node.get("family_bias", "")))
		if route_family == family:
			count += 1
	return count


func _count_map_nodes_by_ore_source(source_id: String) -> int:
	if source_id.is_empty():
		return 0
	var count := 0
	for node in map_nodes:
		var node_id := int(node.get("id", -1))
		if node_id <= 0 or String(node.get("type", "")) == NODE_SPECIAL:
			continue
		if bool(node.get("completed", false)):
			continue
		if String(node.get("ore_source_bias", "")) == source_id:
			count += 1
	return count


func _count_available_special_bonus_nodes() -> int:
	var count := 0
	for node in map_nodes:
		if String(node.get("type", "")) != NODE_SPECIAL:
			continue
		var bonus_id := String(node.get("bonus_id", ""))
		if bonus_id.is_empty() or active_special_bonus_ids.has(bonus_id):
			continue
		count += 1
	return count


func _advance_route_directives_on_node_complete(completed_node: Dictionary, activated_special_ids: Array) -> Dictionary:
	var completed: Array[Dictionary] = []
	var remaining: Array[Dictionary] = []
	var reward_summary: Dictionary = {}
	for raw_directive in active_route_directives:
		var directive := Dictionary(raw_directive).duplicate(true)
		if _route_directive_matches_node(directive, completed_node, activated_special_ids):
			directive["current"] = int(directive.get("current", 0)) + 1
		var required := maxi(1, int(directive.get("required", 1)))
		if int(directive.get("current", 0)) < required:
			remaining.append(directive)
			continue
		directive["completed"] = true
		directive["claimed"] = true
		var reward_result := _grant_route_directive_reward(directive)
		directive["reward_result"] = reward_result
		completed.append(_make_route_directive_summary(directive))
		_merge_route_directive_reward_summary(reward_summary, reward_result)
		var directive_id := String(directive.get("id", directive.get("directive_id", "")))
		if not directive_id.is_empty() and not retired_route_directive_ids.has(directive_id):
			retired_route_directive_ids.append(directive_id)
	active_route_directives = remaining
	var added := _refill_route_directives()
	return {
		"completed_directives": completed,
		"new_directives": added,
		"reward_summary": reward_summary,
	}


func _route_directive_matches_node(directive: Dictionary, completed_node: Dictionary, activated_special_ids: Array) -> bool:
	match String(directive.get("goal_type", "")):
		"complete_nodes":
			return true
		"complete_type":
			return String(completed_node.get("type", "")) == String(directive.get("target", ""))
		"complete_family":
			var plan := Dictionary(completed_node.get("route_plan", {}))
			var family := String(plan.get("family", completed_node.get("family_bias", "")))
			return family == String(directive.get("target", ""))
		"complete_ore_source":
			return String(completed_node.get("ore_source_bias", "")) == String(directive.get("target", ""))
		"activate_special":
			return not activated_special_ids.is_empty()
	return false


func record_route_directive_elite_kill(behavior: int) -> Dictionary:
	if not is_formal_run_active():
		return {}
	var completed: Array = []
	var remaining: Array[Dictionary] = []
	var minerals_granted := 0
	for raw_directive in active_route_directives:
		var directive := Dictionary(raw_directive)
		if int(directive.get("target_behavior", -1)) != behavior:
			remaining.append(directive)
			continue
		var reward_minerals := int(directive.get("reward_minerals", 0))
		minerals += reward_minerals
		minerals_granted += reward_minerals
		completed.append(_make_route_directive_summary(directive))
	active_route_directives = remaining
	var added := _refill_route_directives()
	var result := {
		"completed": completed,
		"added": added,
		"minerals": minerals_granted,
		"active": get_route_directive_summaries(),
	}
	if current_node_id > 0 and not completed.is_empty():
		if pending_room_loot.is_empty():
			pending_room_loot = _empty_loot()
		var pending_completed: Array = pending_room_loot.get("completed_route_directives", [])
		pending_completed.append_array(completed)
		pending_room_loot["completed_route_directives"] = pending_completed
		var pending_new: Array = pending_room_loot.get("new_route_directives", [])
		pending_new.append_array(added)
		pending_room_loot["new_route_directives"] = pending_new
		var pending_rewards := Dictionary(pending_room_loot.get("route_directive_rewards", {}))
		pending_rewards["minerals"] = int(pending_rewards.get("minerals", 0)) + minerals_granted
		pending_room_loot["route_directive_rewards"] = pending_rewards
	return result


func _grant_route_directive_reward(directive: Dictionary) -> Dictionary:
	var reward: Dictionary = directive.get("reward", {})
	var result := {"minerals": 0, "compute": 0, "equipment": [], "equipment_names": [], "equipment_chance_bonus": 0.0}
	var mineral_amount := int(reward.get("minerals", 0))
	if mineral_amount > 0:
		minerals += mineral_amount
		result["minerals"] = mineral_amount
	var compute_amount := int(reward.get("compute", 0))
	if compute_amount > 0:
		compute_capacity += compute_amount
		result["compute"] = compute_amount
	var equipment_chance_bonus := float(reward.get("equipment_chance_bonus", 0.0))
	if equipment_chance_bonus > 0.0:
		result["equipment_chance_bonus"] = equipment_chance_bonus
		result["equipment_chance_text"] = "装备出现率 +%d%%" % int(round(equipment_chance_bonus * 100.0))
	var equipment_family := String(reward.get("equipment_family", ""))
	if not equipment_family.is_empty():
		var item_id := EquipmentCatalogScript.get_random_family_loot_item_id(equipment_inventory, crisis_level, equipment_family)
		if not item_id.is_empty() and EquipmentCatalogScript.has_item(item_id) and not equipment_inventory.has(item_id):
			equipment_inventory.append(item_id)
			result["equipment"] = [item_id]
			result["equipment_names"] = [EquipmentCatalogScript.get_display_name(item_id)]
	var explicit_equipment: Array = reward.get("equipment", [])
	for raw_item_id in explicit_equipment:
		var explicit_id := String(raw_item_id)
		if explicit_id.is_empty() or not EquipmentCatalogScript.has_item(explicit_id) or equipment_inventory.has(explicit_id):
			continue
		equipment_inventory.append(explicit_id)
		var result_equipment: Array = result.get("equipment", [])
		var result_names: Array = result.get("equipment_names", [])
		result_equipment.append(explicit_id)
		result_names.append(EquipmentCatalogScript.get_display_name(explicit_id))
		result["equipment"] = result_equipment
		result["equipment_names"] = result_names
	var shop_focus_family := _normalize_shop_family(String(reward.get("shop_focus_family", "")))
	if not shop_focus_family.is_empty():
		shop_preferred_family = shop_focus_family
		shop_draft_initialized = false
		shop_offer_ids.clear()
		result["shop_focus_family"] = shop_focus_family
		result["shop_focus_name"] = EquipmentCatalogScript.get_family_display_name(shop_focus_family)
		result["shop_focus_text"] = String(reward.get("shop_focus_text", "%s商品偏好" % EquipmentCatalogScript.get_family_display_name(shop_focus_family)))
		result["shop_focus_changed"] = true
	var shop_focus_ore_source := String(reward.get("shop_focus_ore_source", "")).strip_edges()
	if not shop_focus_ore_source.is_empty():
		shop_ore_source_focus = shop_focus_ore_source
		shop_ore_source_focus_text = String(reward.get("shop_focus_text", _get_ore_source_focus_display_text(shop_focus_ore_source))).strip_edges()
		shop_draft_initialized = false
		shop_offer_ids.clear()
		result["shop_focus_ore_source"] = shop_focus_ore_source
		result["shop_focus_text"] = shop_ore_source_focus_text
		result["shop_focus_changed"] = true
	return result


func _merge_route_directive_reward_summary(total: Dictionary, reward: Dictionary) -> void:
	total["minerals"] = int(total.get("minerals", 0)) + int(reward.get("minerals", 0))
	total["compute"] = int(total.get("compute", 0)) + int(reward.get("compute", 0))
	total["equipment_chance_bonus"] = float(total.get("equipment_chance_bonus", 0.0)) + float(reward.get("equipment_chance_bonus", 0.0))
	if float(total.get("equipment_chance_bonus", 0.0)) > 0.0:
		total["equipment_chance_text"] = "装备出现率 +%d%%" % int(round(float(total.get("equipment_chance_bonus", 0.0)) * 100.0))
	var equipment: Array = total.get("equipment", [])
	for item_id in reward.get("equipment", []):
		equipment.append(String(item_id))
	total["equipment"] = equipment
	var equipment_names: Array = total.get("equipment_names", [])
	for item_name in reward.get("equipment_names", []):
		equipment_names.append(String(item_name))
	total["equipment_names"] = equipment_names
	var shop_focus_family := String(reward.get("shop_focus_family", ""))
	if not shop_focus_family.is_empty():
		total["shop_focus_family"] = shop_focus_family
		total["shop_focus_name"] = String(reward.get("shop_focus_name", ""))
		total["shop_focus_text"] = String(reward.get("shop_focus_text", ""))
		total["shop_focus_changed"] = true
	var shop_focus_ore_source := String(reward.get("shop_focus_ore_source", ""))
	if not shop_focus_ore_source.is_empty():
		total["shop_focus_ore_source"] = shop_focus_ore_source
		total["shop_focus_text"] = String(reward.get("shop_focus_text", ""))
		total["shop_focus_changed"] = true


func _generate_world_map() -> void:
	if active_run_conditions.is_empty():
		_select_run_conditions()
	map_nodes.clear()
	map_nodes.append({
		"id": CENTER_ID,
		"name": "方舟核心",
		"type": NODE_BASE,
		"position": MAP_CENTER,
		"links": [],
		"completed": true,
	})
	map_layout_seed = randi()
	var rng: RandomNumberGenerator = _make_rng(map_layout_seed)
	var layer_counts := _make_branching_layer_counts(rng)
	var main_node_count := 0
	for count in layer_counts:
		main_node_count += int(count)
	var reward_node_count := maxi(1, int(round(float(main_node_count) / 8.0)))
	var type_deck := _make_branching_node_type_deck(main_node_count, reward_node_count, rng)
	var layers: Array[Array] = []
	var occupied_positions: Array[Vector2] = [MAP_CENTER]
	var root_angles := _make_branching_root_angles(rng, int(layer_counts[0]))
	var reward_terminal_indices := _make_reward_terminal_indices(int(layer_counts.back()), reward_node_count)
	for layer_index in range(layer_counts.size()):
		var node_count := int(layer_counts[layer_index])
		var remaining_non_reward_nodes := node_count
		if layer_index == layer_counts.size() - 1:
			remaining_non_reward_nodes -= reward_terminal_indices.size()
		var layer_battle_count := 0
		var layer_event_count := 0
		var specs: Array[Dictionary] = []
		if layer_index == 0:
			for node_index in range(node_count):
				specs.append({"parent_index": -1, "slot": 0, "count": 1})
		else:
			specs = _make_branching_child_specs(layers[layer_index - 1].size(), node_count, rng)
		var layer_ids: Array[int] = []
		for node_index in range(node_count):
			var spec: Dictionary = specs[node_index]
			var parent_id := CENTER_ID
			var angle := 0.0
			var parent_radius := 0.0
			if layer_index == 0:
				angle = root_angles[node_index]
			else:
				parent_id = int(layers[layer_index - 1][int(spec["parent_index"])])
				var parent: Dictionary = map_nodes[parent_id]
				angle = float(parent.get("web_angle", 0.0))
				angle += (float(spec["slot"]) - (float(spec["count"]) - 1.0) * 0.5) * deg_to_rad(42.0)
				angle += rng.randf_range(-MAP_SPIDER_MAX_PATH_BEND, MAP_SPIDER_MAX_PATH_BEND)
				parent_radius = (parent.get("position", MAP_CENTER) as Vector2).distance_to(MAP_CENTER)
			var candidate_radius := MAP_SPIDER_MIN_RADIUS + MAP_SPIDER_RADIUS_STEP * float(layer_index) + rng.randf_range(-MAP_SPIDER_RADIUS_JITTER, MAP_SPIDER_RADIUS_JITTER)
			var radius := candidate_radius if layer_index == 0 else maxf(candidate_radius, parent_radius + MAP_NODE_MIN_DISTANCE + 12.0)
			var is_reward_terminal := layer_index == layer_counts.size() - 1 and reward_terminal_indices.has(node_index)
			var profile_layer := mini(layer_index, 2)
			var node_position := MAP_CENTER + Vector2.RIGHT.rotated(angle) * radius
			while not _is_map_position_available(node_position, occupied_positions):
				radius += MAP_NODE_MIN_DISTANCE + 8.0
				node_position = MAP_CENTER + Vector2.RIGHT.rotated(angle) * radius
			var node_id := map_nodes.size()
			var node_type := NODE_REWARD
			if not is_reward_terminal:
				remaining_non_reward_nodes -= 1
				var required_type := ""
				if layer_battle_count == 0 and layer_event_count == 0 and remaining_non_reward_nodes == 0:
					required_type = NODE_BATTLE
				elif layer_battle_count == 0 and remaining_non_reward_nodes == 0:
					required_type = NODE_BATTLE
				elif layer_event_count == 0 and remaining_non_reward_nodes == 0:
					required_type = NODE_EVENT
				node_type = _draw_branching_node_type(type_deck, required_type)
				if node_type == NODE_BATTLE:
					layer_battle_count += 1
				elif node_type == NODE_EVENT:
					layer_event_count += 1
			var node := {
				"id": node_id,
				"name": "航路节点 %02d" % node_id,
				"type": node_type,
				"position": node_position,
				"links": [],
				"completed": false,
				"ring_index": profile_layer,
				"ring_node_index": node_index,
				"web_layer": layer_index,
				"web_order": node_index,
				"web_parent_id": parent_id,
				"web_angle": angle,
				"is_path_terminal": is_reward_terminal,
				"family_bias": _pick_family_bias(profile_layer, node_index),
			}
			_apply_progression_profile_to_node(node, profile_layer)
			_apply_intel_profile_to_node(node, profile_layer, node_index)
			_apply_modifier_profiles_to_node(node, profile_layer, node_index)
			_apply_run_conditions_to_node(node)
			_apply_opportunity_profile_to_node(node, profile_layer, node_index)
			_apply_battle_profile_to_node(node, profile_layer, node_index)
			_apply_reward_profile_to_node(node, profile_layer, node_index)
			_apply_ore_source_bias_to_node(node, profile_layer, node_index)
			_apply_route_plan_to_node(node)
			map_nodes.append(node)
			layer_ids.append(node_id)
			occupied_positions.append(node_position)
		layers.append(layer_ids)
	_connect_branching_spider(layers)
	_add_branching_lateral_relays(layers)
	_add_planar_web_links()
	_add_branching_beacon_nodes(layers, rng)
	_insert_long_link_bridge_nodes()


func _make_branching_layer_counts(rng: RandomNumberGenerator) -> Array[int]:
	var root_count := rng.randi_range(MAP_SPIDER_INITIAL_NODE_COUNT_MIN, MAP_SPIDER_INITIAL_NODE_COUNT_MAX)
	var main_node_count := MAP_SPIDER_MAIN_NODE_COUNT_MIN if root_count == MAP_SPIDER_INITIAL_NODE_COUNT_MIN else rng.randi_range(MAP_SPIDER_MAIN_NODE_COUNT_MIN, MAP_SPIDER_MAIN_NODE_COUNT_MAX)
	for attempt in range(48):
		var second_layer_count := rng.randi_range(root_count, root_count * 2)
		var third_layer_count := rng.randi_range(second_layer_count, second_layer_count * 2)
		var outer_layer_count := main_node_count - root_count - second_layer_count - third_layer_count
		if outer_layer_count < third_layer_count or outer_layer_count > third_layer_count * 2:
			continue
		return [root_count, second_layer_count, third_layer_count, outer_layer_count]
	# The fallback keeps the 3-root map at its maximum connected size (3 + 6 + 12 + 24).
	return [MAP_SPIDER_INITIAL_NODE_COUNT_MIN, 6, 12, 24]


func _make_reward_terminal_indices(layer_count: int, reward_count: int) -> Dictionary:
	var indices := {}
	for reward_index in range(mini(layer_count, reward_count)):
		var index := int(floor(float(reward_index + 1) * float(layer_count) / float(reward_count + 1)))
		indices[index] = true
	return indices


func _make_branching_node_type_deck(main_node_count: int, reward_node_count: int, rng: RandomNumberGenerator) -> Array[String]:
	var deck: Array[String] = []
	var event_count := int(round(float(main_node_count) / 4.0))
	var battle_count := main_node_count - reward_node_count - event_count
	_append_node_types(deck, NODE_BATTLE, battle_count)
	_append_node_types(deck, NODE_EVENT, event_count)
	for index in range(deck.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var swapped_type := deck[index]
		deck[index] = deck[swap_index]
		deck[swap_index] = swapped_type
	return deck


func _draw_branching_node_type(deck: Array[String], required_type: String = "") -> String:
	if required_type.is_empty():
		return _draw_node_type(deck)
	var type_index := deck.find(required_type)
	if type_index < 0:
		return _draw_node_type(deck)
	var node_type := deck[type_index]
	deck.remove_at(type_index)
	return node_type


func _make_branching_root_angles(rng: RandomNumberGenerator, root_count: int) -> Array[float]:
	var angles: Array[float] = []
	var gaps: Array[float] = []
	var total_gap := 0.0
	var base_gap := TAU / float(root_count)
	for index in range(root_count):
		var gap := base_gap + rng.randf_range(-MAP_SPIDER_GAP_JITTER, MAP_SPIDER_GAP_JITTER)
		gaps.append(gap)
		total_gap += gap
	var angle := rng.randf_range(-PI, PI)
	for gap in gaps:
		angles.append(angle)
		angle += gap * TAU / total_gap
	return angles


func _make_branching_child_specs(parent_count: int, child_count: int, rng: RandomNumberGenerator) -> Array[Dictionary]:
	var child_counts: Array[int] = []
	for parent_index in range(parent_count):
		child_counts.append(1)
	for extra_index in range(maxi(0, child_count - parent_count)):
		var available_parents: Array[int] = []
		for parent_index in range(parent_count):
			if child_counts[parent_index] < 2:
				available_parents.append(parent_index)
		if available_parents.is_empty():
			break
		var selected_parent := available_parents[rng.randi_range(0, available_parents.size() - 1)]
		child_counts[selected_parent] += 1
	var specs: Array[Dictionary] = []
	for parent_index in range(parent_count):
		for slot in range(child_counts[parent_index]):
			specs.append({"parent_index": parent_index, "slot": slot, "count": child_counts[parent_index]})
	return specs


func _connect_branching_spider(layers: Array[Array]) -> void:
	for root_id in layers[0]:
		_add_branching_link_if_clear(CENTER_ID, int(root_id), true)
	for layer_index in range(1, layers.size()):
		for node_id in layers[layer_index]:
			var node: Dictionary = map_nodes[int(node_id)]
			var parent_candidates: Array[int] = [int(node.get("web_parent_id", CENTER_ID))]
			for candidate_id in layers[layer_index - 1]:
				if not parent_candidates.has(int(candidate_id)):
					parent_candidates.append(int(candidate_id))
			var connected := false
			for parent_id in parent_candidates:
				if _add_branching_link_if_clear(parent_id, int(node_id), true):
					node["web_parent_id"] = parent_id
					map_nodes[int(node_id)] = node
					connected = true
					break
			if connected:
				continue
			# Connectivity is mandatory for the progression tree. If every strict
			# candidate is rejected, retain the geometric safety checks and relax
			# only degree/angle limits for the fallback parent search.
			for parent_id in parent_candidates:
				if _add_branching_link_if_clear(parent_id, int(node_id)):
					node["web_parent_id"] = parent_id
					map_nodes[int(node_id)] = node
					connected = true
					break
			if not connected:
				# A generated progression node must never become unreachable. At this
				# last-resort point every geometry-safe option has been exhausted, so
				# preserve the authored parent relationship over visual planar purity.
				var fallback_parent := int(parent_candidates[0]) if not parent_candidates.is_empty() else CENTER_ID
				_add_link(fallback_parent, int(node_id))
				node["web_parent_id"] = fallback_parent
				map_nodes[int(node_id)] = node


func _add_branching_lateral_relays(layers: Array[Array]) -> void:
	var relay_type_deck: Array[String] = []
	_append_node_types(relay_type_deck, NODE_BATTLE, 5)
	_append_node_types(relay_type_deck, NODE_EVENT, 2)
	_append_node_types(relay_type_deck, NODE_REWARD, 1)
	var relay_pairs: Array[Dictionary] = []
	for layer_index in range(1, layers.size()):
		var layer_ids: Array = layers[layer_index]
		for left_index in range(layer_ids.size() - 1):
			for right_index in range(left_index + 1, layer_ids.size()):
				var left_position: Vector2 = map_nodes[int(layer_ids[left_index])].get("position", MAP_CENTER)
				var right_position: Vector2 = map_nodes[int(layer_ids[right_index])].get("position", MAP_CENTER)
				if left_position.distance_to(right_position) >= MAP_NODE_MIN_DISTANCE * 2.0 + 12.0:
					relay_pairs.append({"layer": layer_index, "left": int(layer_ids[left_index]), "right": int(layer_ids[right_index])})
	for relay_index in range(relay_pairs.size()):
		if relay_type_deck.is_empty():
			break
		var pair: Dictionary = relay_pairs[relay_index]
		var left_id := int(pair["left"])
		var right_id := int(pair["right"])
		var left_position: Vector2 = map_nodes[left_id].get("position", MAP_CENTER)
		var right_position: Vector2 = map_nodes[right_id].get("position", MAP_CENTER)
		var midpoint := (left_position + right_position) * 0.5
		var relay_position := midpoint
		var occupied_positions: Array[Vector2] = []
		for node in map_nodes:
			occupied_positions.append(node.get("position", MAP_CENTER))
		if not _is_map_position_available(relay_position, occupied_positions):
			continue
		var layer_index := int(pair["layer"])
		var node_id := map_nodes.size()
		var node_type := _draw_node_type(relay_type_deck)
		var profile_layer := mini(layer_index, 2)
		var relay := {
			"id": node_id,
			"name": "横向航路节点 %02d" % node_id,
			"type": node_type,
			"position": relay_position,
			"links": [],
			"completed": false,
			"ring_index": profile_layer,
			"ring_node_index": relay_index,
			"web_layer": layer_index,
			"web_order": relay_index,
			"web_parent_id": left_id,
			"web_relay": true,
			"family_bias": _pick_family_bias(profile_layer, relay_index),
		}
		_apply_progression_profile_to_node(relay, profile_layer)
		_apply_intel_profile_to_node(relay, profile_layer, relay_index)
		_apply_modifier_profiles_to_node(relay, profile_layer, relay_index)
		_apply_run_conditions_to_node(relay)
		_apply_opportunity_profile_to_node(relay, profile_layer, relay_index)
		_apply_battle_profile_to_node(relay, profile_layer, relay_index)
		_apply_reward_profile_to_node(relay, profile_layer, relay_index)
		_apply_ore_source_bias_to_node(relay, profile_layer, relay_index)
		_apply_route_plan_to_node(relay)
		map_nodes.append(relay)
		if not _add_branching_link_if_clear(left_id, node_id, true):
			map_nodes.pop_back()
			continue
		if not _add_branching_link_if_clear(node_id, right_id, true):
			_remove_map_link(left_id, node_id)
			map_nodes.pop_back()


func _add_planar_web_links() -> void:
	var candidate_pairs: Array[Dictionary] = []
	var seen_pairs := {}
	for raw_node in map_nodes:
		var node: Dictionary = raw_node
		var node_id := int(node.get("id", -1))
		var layer := int(node.get("web_layer", -1))
		if node_id <= CENTER_ID or layer < 0 or bool(node.get("is_path_terminal", false)):
			continue
		var nearby: Array[Dictionary] = []
		var node_position: Vector2 = node.get("position", MAP_CENTER)
		for raw_other in map_nodes:
			var other: Dictionary = raw_other
			var other_id := int(other.get("id", -1))
			var other_layer := int(other.get("web_layer", -1))
			if other_id <= CENTER_ID or other_id == node_id or other_layer < 0:
				continue
			if bool(other.get("is_path_terminal", false)) or abs(other_layer - layer) > 1:
				continue
			if node.get("links", []).has(other_id):
				continue
			var distance := node_position.distance_to(other.get("position", MAP_CENTER))
			if distance < MAP_WEB_MIN_LOCAL_LINK_LENGTH or distance > MAP_WEB_MAX_LOCAL_LINK_LENGTH:
				continue
			nearby.append({"id": other_id, "distance": distance})
		nearby.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return float(a["distance"]) < float(b["distance"])
		)
		for candidate_index in range(mini(MAP_WEB_NEAREST_CANDIDATE_COUNT, nearby.size())):
			var other_id := int(nearby[candidate_index]["id"])
			var key := "%d_%d" % [mini(node_id, other_id), maxi(node_id, other_id)]
			if seen_pairs.has(key):
				continue
			seen_pairs[key] = true
			candidate_pairs.append({
				"from": node_id,
				"to": other_id,
				"distance": float(nearby[candidate_index]["distance"]),
			})
	candidate_pairs.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["distance"]) < float(b["distance"])
	)
	for candidate in candidate_pairs:
		_add_branching_link_if_clear(int(candidate["from"]), int(candidate["to"]), true)


func _insert_long_link_bridge_nodes() -> void:
	var long_links: Array[Dictionary] = []
	var seen_links := {}
	for node in map_nodes:
		var from_id := int(node.get("id", -1))
		for raw_to_id in node.get("links", []):
			var to_id := int(raw_to_id)
			var key := "%d_%d" % [mini(from_id, to_id), maxi(from_id, to_id)]
			if seen_links.has(key):
				continue
			seen_links[key] = true
			var from_position: Vector2 = get_map_node(from_id).get("position", MAP_CENTER)
			var to_position: Vector2 = get_map_node(to_id).get("position", MAP_CENTER)
			if from_position.distance_to(to_position) > MAP_LONG_LINK_LENGTH:
				long_links.append({"from": from_id, "to": to_id})
	var bridge_ids: Array[int] = []
	var bridge_types: Array[String] = []
	_append_node_types(bridge_types, NODE_BATTLE, 5)
	_append_node_types(bridge_types, NODE_EVENT, 2)
	_append_node_types(bridge_types, NODE_REWARD, 1)
	for link in long_links:
		var from_id := int(link["from"])
		var to_id := int(link["to"])
		if not get_map_node(from_id).get("links", []).has(to_id):
			continue
		var from_position: Vector2 = get_map_node(from_id).get("position", MAP_CENTER)
		var to_position: Vector2 = get_map_node(to_id).get("position", MAP_CENTER)
		var bridge_count := maxi(1, int(ceil(from_position.distance_to(to_position) / MAP_LONG_LINK_LENGTH)) - 1)
		var occupied_positions: Array[Vector2] = []
		for node in map_nodes:
			occupied_positions.append(node.get("position", MAP_CENTER))
		var bridge_positions: Array[Vector2] = []
		for bridge_index in range(bridge_count):
			var position := from_position.lerp(to_position, float(bridge_index + 1) / float(bridge_count + 1))
			if not _is_map_position_available(position, occupied_positions):
				bridge_positions.clear()
				break
			bridge_positions.append(position)
			occupied_positions.append(position)
		if bridge_positions.is_empty():
			continue
		_remove_map_link(from_id, to_id)
		var previous_id := from_id
		for bridge_index in range(bridge_positions.size()):
			if bridge_types.is_empty():
				_append_node_types(bridge_types, NODE_BATTLE, 5)
				_append_node_types(bridge_types, NODE_EVENT, 2)
				_append_node_types(bridge_types, NODE_REWARD, 1)
			var node_id := map_nodes.size()
			var profile_layer := mini(2, int(get_map_node(previous_id).get("ring_index", 1)))
			var bridge := {
				"id": node_id, "name": "航路中继 %02d" % node_id, "type": _draw_node_type(bridge_types),
				"position": bridge_positions[bridge_index], "links": [], "completed": false,
				"ring_index": profile_layer, "ring_node_index": bridge_index, "web_bridge": true,
				"family_bias": _pick_family_bias(profile_layer, bridge_index),
			}
			_apply_progression_profile_to_node(bridge, profile_layer)
			_apply_intel_profile_to_node(bridge, profile_layer, bridge_index)
			_apply_modifier_profiles_to_node(bridge, profile_layer, bridge_index)
			_apply_run_conditions_to_node(bridge)
			_apply_opportunity_profile_to_node(bridge, profile_layer, bridge_index)
			_apply_battle_profile_to_node(bridge, profile_layer, bridge_index)
			_apply_reward_profile_to_node(bridge, profile_layer, bridge_index)
			_apply_ore_source_bias_to_node(bridge, profile_layer, bridge_index)
			_apply_route_plan_to_node(bridge)
			map_nodes.append(bridge)
			_add_link(previous_id, node_id)
			previous_id = node_id
			bridge_ids.append(node_id)
		_add_link(previous_id, to_id)
	for bridge_id in bridge_ids:
		var bridge_position: Vector2 = get_map_node(bridge_id).get("position", MAP_CENTER)
		var candidates: Array[Dictionary] = []
		for node in map_nodes:
			var node_id := int(node.get("id", -1))
			if node_id <= CENTER_ID or node_id == bridge_id:
				continue
			if bool(node.get("web_bridge", false)) or String(node.get("type", "")) == NODE_SPECIAL or bool(node.get("is_path_terminal", false)):
				continue
			if get_map_node(bridge_id).get("links", []).has(node_id):
				continue
			var distance_squared := bridge_position.distance_squared_to(node.get("position", MAP_CENTER))
			if distance_squared <= MAP_BRIDGE_NEIGHBOR_DISTANCE * MAP_BRIDGE_NEIGHBOR_DISTANCE:
				candidates.append({"id": node_id, "distance_squared": distance_squared})
		candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return float(a["distance_squared"]) < float(b["distance_squared"])
		)
		var added_connections := 0
		for candidate in candidates:
			if _add_branching_link_if_clear(bridge_id, int(candidate["id"]), true):
				added_connections += 1
				if added_connections >= 2:
					break


func _remove_map_link(a: int, b: int) -> void:
	for node_id in [a, b]:
		var node: Dictionary = map_nodes[node_id]
		var links: Array = node.get("links", [])
		links.erase(b if node_id == a else a)
		node["links"] = links
		map_nodes[node_id] = node


func _add_branching_link_if_clear(from_id: int, to_id: int, enforce_web_constraints: bool = false) -> bool:
	if enforce_web_constraints and not _can_add_web_link(from_id, to_id):
		return false
	var from_position: Vector2 = get_map_node(from_id).get("position", MAP_CENTER)
	var to_position: Vector2 = get_map_node(to_id).get("position", MAP_CENTER)
	for node in map_nodes:
		var node_id := int(node.get("id", -1))
		if node_id == from_id or node_id == to_id:
			continue
		var node_position: Vector2 = node.get("position", MAP_CENTER)
		if _distance_squared_to_map_segment(node_position, from_position, to_position) < 52.0 * 52.0:
			return false
	var checked_links := {}
	for node in map_nodes:
		var existing_from := int(node.get("id", -1))
		for raw_existing_to in node.get("links", []):
			var existing_to := int(raw_existing_to)
			var key := "%d_%d" % [mini(existing_from, existing_to), maxi(existing_from, existing_to)]
			if checked_links.has(key):
				continue
			checked_links[key] = true
			if from_id == existing_from or from_id == existing_to or to_id == existing_from or to_id == existing_to:
				continue
			var existing_from_position: Vector2 = get_map_node(existing_from).get("position", MAP_CENTER)
			var existing_to_position: Vector2 = get_map_node(existing_to).get("position", MAP_CENTER)
			if Geometry2D.segment_intersects_segment(from_position, to_position, existing_from_position, existing_to_position) != null:
				return false
	_add_link(from_id, to_id)
	return true


func _can_add_web_link(from_id: int, to_id: int) -> bool:
	var from_node: Dictionary = get_map_node(from_id)
	var to_node: Dictionary = get_map_node(to_id)
	if from_node.is_empty() or to_node.is_empty() or from_node.get("links", []).has(to_id):
		return false
	if from_node.get("links", []).size() >= _get_web_node_degree_limit(from_id):
		return false
	if to_node.get("links", []).size() >= _get_web_node_degree_limit(to_id):
		return false
	return _has_web_link_angle_clear(from_id, to_id) and _has_web_link_angle_clear(to_id, from_id)


func _get_web_node_degree_limit(node_id: int) -> int:
	if node_id == CENTER_ID:
		return MAP_WEB_ROOT_MAX_DEGREE
	var node: Dictionary = get_map_node(node_id)
	if bool(node.get("is_path_terminal", false)):
		return MAP_WEB_TERMINAL_MAX_DEGREE
	if bool(node.get("web_relay", false)):
		return MAP_WEB_RELAY_MAX_DEGREE
	if bool(node.get("web_bridge", false)):
		return MAP_WEB_BRIDGE_MAX_DEGREE
	return MAP_WEB_NODE_MAX_DEGREE


func _has_web_link_angle_clear(node_id: int, other_id: int) -> bool:
	var node: Dictionary = get_map_node(node_id)
	var node_position: Vector2 = node.get("position", MAP_CENTER)
	var target_position: Vector2 = get_map_node(other_id).get("position", MAP_CENTER)
	var candidate_angle := node_position.angle_to_point(target_position)
	for raw_linked_id in node.get("links", []):
		var linked_position: Vector2 = get_map_node(int(raw_linked_id)).get("position", MAP_CENTER)
		var linked_angle := node_position.angle_to_point(linked_position)
		if absf(wrapf(candidate_angle - linked_angle, -PI, PI)) < MAP_WEB_MIN_LINK_ANGLE:
			return false
	return true


func _distance_squared_to_map_segment(point: Vector2, segment_start: Vector2, segment_end: Vector2) -> float:
	var segment := segment_end - segment_start
	var length_squared := segment.length_squared()
	if length_squared <= 0.0001:
		return point.distance_squared_to(segment_start)
	var progress := clampf((point - segment_start).dot(segment) / length_squared, 0.0, 1.0)
	return point.distance_squared_to(segment_start + segment * progress)


func _add_branching_beacon_nodes(layers: Array[Array], rng: RandomNumberGenerator) -> void:
	if layers.is_empty() or SPECIAL_BONUS_PROFILES.size() < MAP_BEACON_PATH_COUNT:
		return
	var leaves: Array = layers.back()
	for index in range(MAP_BEACON_PATH_COUNT):
		var anchor_id := int(leaves[index * (leaves.size() - 1)])
		var anchor: Dictionary = map_nodes[anchor_id]
		var anchor_position: Vector2 = anchor.get("position", MAP_CENTER)
		var angle := MAP_CENTER.angle_to_point(anchor_position) + rng.randf_range(-MAP_SPIDER_NODE_ANGLE_JITTER, MAP_SPIDER_NODE_ANGLE_JITTER)
		var radius := anchor_position.distance_to(MAP_CENTER) + MAP_NODE_MIN_DISTANCE + 12.0
		var occupied_positions: Array[Vector2] = []
		for node in map_nodes:
			occupied_positions.append(node.get("position", MAP_CENTER))
		var special_position := MAP_CENTER + Vector2.RIGHT.rotated(angle) * radius
		while not _is_map_position_available(special_position, occupied_positions):
			radius += MAP_NODE_MIN_DISTANCE + 8.0
			special_position = MAP_CENTER + Vector2.RIGHT.rotated(angle) * radius
		var special_id := map_nodes.size()
		var profile := SPECIAL_BONUS_PROFILES[index]
		map_nodes.append({
			"id": special_id,
			"name": String(profile.get("name", "增益信标")),
			"type": NODE_SPECIAL,
			"position": special_position,
			"links": [],
			"completed": false,
			"web_layer": layers.size(),
			"web_order": index,
			"web_parent_id": anchor_id,
			"is_path_terminal": true,
			"bonus_id": String(profile.get("bonus_id", "")),
			"bonus_name": String(profile.get("bonus_name", "")),
			"bonus_description": String(profile.get("bonus_description", "")),
			"family_bias": String(profile.get("family_bias", "")),
		})
		# A signal beacon must remain reachable even when the straight visual link
		# intersects the dense outer web. Connectivity takes priority at this point.
		if not _add_branching_link_if_clear(anchor_id, special_id):
			_add_link(anchor_id, special_id)


func _generate_compact_spider_map() -> void:
	if active_run_conditions.is_empty():
		_select_run_conditions()
	map_nodes.clear()
	map_nodes.append({
		"id": CENTER_ID,
		"name": "方舟核心",
		"type": NODE_BASE,
		"position": MAP_CENTER,
		"links": [],
		"completed": true,
	})
	map_layout_seed = randi()
	var layout_rng: RandomNumberGenerator = _make_rng(map_layout_seed)
	var path_angles: Array[float] = _make_spider_path_angles(layout_rng)
	var node_type_deck := _make_spider_node_type_deck()
	var paths: Array[Array] = []
	for path_index in range(MAP_SPIDER_PATH_COUNT):
		var path_ids: Array[int] = []
		var path_bend := layout_rng.randf_range(-MAP_SPIDER_MAX_PATH_BEND, MAP_SPIDER_MAX_PATH_BEND)
		var previous_radius := 0.0
		var normal_node_count := 3 if path_index < MAP_REWARD_PATH_COUNT else 5
		for path_depth in range(normal_node_count):
			var is_reward_terminal := path_index < MAP_REWARD_PATH_COUNT and path_depth == normal_node_count - 1
			var progression_ring_index := mini(path_depth, 2)
			var node_angle := path_angles[path_index] + path_bend * float(path_depth) / float(normal_node_count)
			if path_depth > 0:
				node_angle += layout_rng.randf_range(-MAP_SPIDER_NODE_ANGLE_JITTER, MAP_SPIDER_NODE_ANGLE_JITTER)
			var candidate_radius := MAP_SPIDER_MIN_RADIUS + MAP_SPIDER_RADIUS_STEP * float(path_depth)
			if path_depth > 0:
				candidate_radius += layout_rng.randf_range(-MAP_SPIDER_RADIUS_JITTER, MAP_SPIDER_RADIUS_JITTER)
			var node_radius := candidate_radius if path_depth == 0 else maxf(candidate_radius, previous_radius + MAP_NODE_MIN_DISTANCE + 8.0)
			var node_id := map_nodes.size()
			var node_type := NODE_REWARD if is_reward_terminal else _draw_node_type(node_type_deck)
			var node := {
				"id": node_id,
				"name": "航路节点 %02d" % node_id,
				"type": node_type,
				"position": MAP_CENTER + Vector2.RIGHT.rotated(node_angle) * node_radius,
				"links": [],
				"completed": false,
				"ring_index": progression_ring_index,
				"ring_node_index": path_index,
				"path_index": path_index,
				"path_depth": path_depth,
				"is_path_terminal": is_reward_terminal,
				"family_bias": _pick_family_bias(progression_ring_index, path_index),
			}
			_apply_progression_profile_to_node(node, progression_ring_index)
			_apply_intel_profile_to_node(node, progression_ring_index, path_index)
			_apply_modifier_profiles_to_node(node, progression_ring_index, path_index)
			_apply_run_conditions_to_node(node)
			_apply_opportunity_profile_to_node(node, progression_ring_index, path_index)
			_apply_battle_profile_to_node(node, progression_ring_index, path_index)
			_apply_reward_profile_to_node(node, progression_ring_index, path_index)
			_apply_ore_source_bias_to_node(node, progression_ring_index, path_index)
			_apply_route_plan_to_node(node)
			map_nodes.append(node)
			path_ids.append(node_id)
			previous_radius = node_radius
		paths.append(path_ids)
	_connect_spider_paths(paths, layout_rng)
	_add_spider_beacon_nodes(paths, layout_rng)


func _make_spider_node_type_deck() -> Array[String]:
	var deck: Array[String] = []
	for group_index in range(MAP_REWARD_NODE_COUNT):
		_append_node_types(deck, NODE_BATTLE, 5)
		_append_node_types(deck, NODE_EVENT, 2)
	return deck


func _make_spider_path_angles(rng: RandomNumberGenerator) -> Array[float]:
	var gaps: Array[float] = []
	var total_gap := 0.0
	var base_gap := TAU / float(MAP_SPIDER_PATH_COUNT)
	for path_index in range(MAP_SPIDER_PATH_COUNT):
		var gap := base_gap + rng.randf_range(-MAP_SPIDER_GAP_JITTER, MAP_SPIDER_GAP_JITTER)
		gaps.append(gap)
		total_gap += gap
	var scale := TAU / total_gap
	var angle := rng.randf_range(-PI, PI)
	var angles: Array[float] = []
	for gap in gaps:
		angles.append(angle)
		angle += gap * scale
	return angles


func _connect_spider_paths(paths: Array[Array], rng: RandomNumberGenerator) -> void:
	for path_ids in paths:
		if path_ids.is_empty():
			continue
		_add_link(CENTER_ID, int(path_ids[0]))
		for path_depth in range(1, path_ids.size()):
			_add_link(int(path_ids[path_depth - 1]), int(path_ids[path_depth]))
	for path_depth in range(MAP_SPIDER_LATERAL_DEPTH_COUNT):
		var lateral_link_count := 0
		var chance := 0.72 if path_depth == 0 else 0.48
		for path_index in range(paths.size()):
			if rng.randf() > chance:
				continue
			var current_path: Array = paths[path_index]
			var next_path: Array = paths[(path_index + 1) % paths.size()]
			if current_path.size() <= path_depth or next_path.size() <= path_depth:
				continue
			_add_link(int(current_path[path_depth]), int(next_path[path_depth]))
			lateral_link_count += 1
		if lateral_link_count == 0:
			var current_path: Array = paths[0]
			var next_path: Array = paths[1]
			_add_link(int(current_path[path_depth]), int(next_path[path_depth]))


func _add_spider_beacon_nodes(paths: Array[Array], rng: RandomNumberGenerator) -> void:
	if paths.size() != MAP_SPIDER_PATH_COUNT or SPECIAL_BONUS_PROFILES.size() < MAP_BEACON_PATH_COUNT:
		push_error("Spider map terminal configuration is inconsistent.")
		return
	for index in range(MAP_BEACON_PATH_COUNT):
		var profile := SPECIAL_BONUS_PROFILES[index]
		var path_index := MAP_REWARD_PATH_COUNT + index
		var path_ids: Array = paths[path_index]
		if path_ids.is_empty():
			continue
		var anchor_id := int(path_ids.back())
		var anchor: Dictionary = map_nodes[anchor_id]
		var anchor_position: Vector2 = anchor.get("position", MAP_CENTER)
		var anchor_depth := int(anchor.get("path_depth", 4))
		var angle := MAP_CENTER.angle_to_point(anchor_position) + rng.randf_range(-MAP_SPIDER_NODE_ANGLE_JITTER, MAP_SPIDER_NODE_ANGLE_JITTER)
		var radius := maxf(
			anchor_position.distance_to(MAP_CENTER) + MAP_NODE_MIN_DISTANCE + 8.0,
			MAP_SPIDER_MIN_RADIUS + MAP_SPIDER_RADIUS_STEP * 4.0 + rng.randf_range(-MAP_SPIDER_RADIUS_JITTER, MAP_SPIDER_RADIUS_JITTER)
		)
		var special_id := map_nodes.size()
		map_nodes.append({
			"id": special_id,
			"name": String(profile.get("name", "增益信标")),
			"type": NODE_SPECIAL,
			"position": MAP_CENTER + Vector2.RIGHT.rotated(angle) * radius,
			"links": [],
			"completed": false,
			"path_index": path_index,
			"path_depth": anchor_depth + 1,
			"is_path_terminal": true,
			"bonus_id": String(profile.get("bonus_id", "")),
			"bonus_name": String(profile.get("bonus_name", "")),
			"bonus_description": String(profile.get("bonus_description", "")),
			"family_bias": String(profile.get("family_bias", "")),
		})
		_add_link(anchor_id, special_id)


func _generate_legacy_world_map() -> void:
	if active_run_conditions.is_empty():
		_select_run_conditions()
	map_nodes.clear()
	map_nodes.append({
		"id": CENTER_ID,
		"name": "方舟核心",
		"type": NODE_BASE,
		"position": MAP_CENTER,
		"links": [],
		"completed": true,
	})
	var rings: Array[Array] = []
	var occupied_positions: Array[Vector2] = [MAP_CENTER]
	var node_type_deck := _make_node_type_deck()
	for ring_index in range(MAP_RING_COUNTS.size()):
		var ring_ids: Array[int] = []
		var count := MAP_RING_COUNTS[ring_index]
		var radius := MAP_RING_RADII[ring_index]
		var angle_offset := -PI * 0.5 + float(ring_index) * 0.11
		for i in range(count):
			var angle := angle_offset + TAU * (float(i) + 0.5) / float(count)
			var preferred_position := MAP_CENTER + Vector2(cos(angle), sin(angle)) * radius
			var node_position := _find_non_overlapping_map_position(preferred_position, occupied_positions)
			var node_id := map_nodes.size()
			ring_ids.append(node_id)
			var node := {
				"id": node_id,
				"name": "空间残片 %02d" % node_id,
				"type": _draw_node_type(node_type_deck),
				"position": node_position,
				"links": [],
				"completed": false,
				"ring_index": ring_index,
				"ring_node_index": i,
				"family_bias": _pick_family_bias(ring_index, i),
			}
			_apply_progression_profile_to_node(node, ring_index)
			_apply_intel_profile_to_node(node, ring_index, i)
			_apply_modifier_profiles_to_node(node, ring_index, i)
			_apply_run_conditions_to_node(node)
			_apply_opportunity_profile_to_node(node, ring_index, i)
			_apply_battle_profile_to_node(node, ring_index, i)
			_apply_reward_profile_to_node(node, ring_index, i)
			_apply_ore_source_bias_to_node(node, ring_index, i)
			_apply_route_plan_to_node(node)
			map_nodes.append(node)
			occupied_positions.append(node_position)
		rings.append(ring_ids)
	for id in rings[0]:
		_add_link(CENTER_ID, id)
	_connect_ordered_rings(rings[0], rings[1])
	_connect_ordered_rings(rings[1], rings[2])
	_add_special_bonus_nodes(rings)


func _find_non_overlapping_map_position(preferred_position: Vector2, occupied_positions: Array[Vector2]) -> Vector2:
	if _is_map_position_available(preferred_position, occupied_positions):
		return preferred_position
	for search_ring in range(1, MAP_POSITION_SEARCH_RINGS + 1):
		var search_radius := float(search_ring) * MAP_POSITION_SEARCH_STEP
		for sample_index in range(MAP_POSITION_SEARCH_SAMPLES):
			var angle := TAU * float(sample_index) / float(MAP_POSITION_SEARCH_SAMPLES)
			var candidate := preferred_position + Vector2.RIGHT.rotated(angle) * search_radius
			if _is_map_position_available(candidate, occupied_positions):
				return candidate
	# The expanded map leaves enough room for the search above.  Keep a safe
	# deterministic fallback for malformed/custom map settings rather than
	# silently placing a node at the original overlapping position.
	var fallback := preferred_position
	while not _is_map_position_available(fallback, occupied_positions):
		fallback += Vector2.RIGHT * MAP_POSITION_SEARCH_STEP
	return fallback


func _is_map_position_available(candidate: Vector2, occupied_positions: Array[Vector2]) -> bool:
	for occupied_position in occupied_positions:
		if candidate.distance_squared_to(occupied_position) < MAP_NODE_MIN_DISTANCE * MAP_NODE_MIN_DISTANCE:
			return false
	return true


func _make_node_type_deck() -> Array[String]:
	var deck: Array[String] = []
	_append_node_types(deck, NODE_BATTLE, MAP_BATTLE_NODE_COUNT)
	_append_node_types(deck, NODE_EVENT, MAP_EVENT_NODE_COUNT)
	_append_node_types(deck, NODE_REWARD, MAP_REWARD_NODE_COUNT)
	var target_count := _get_map_exploration_node_total_count()
	while deck.size() < target_count:
		deck.append(NODE_BATTLE)
	while deck.size() > target_count:
		deck.pop_back()
	deck.shuffle()
	return deck


func _get_map_exploration_node_total_count() -> int:
	var total := 0
	for count in MAP_RING_COUNTS:
		total += int(count)
	return total


func _append_node_types(deck: Array[String], node_type: String, count: int) -> void:
	for i in range(maxi(0, count)):
		deck.append(node_type)


func _draw_node_type(deck: Array[String]) -> String:
	if deck.is_empty():
		return NODE_BATTLE
	return deck.pop_back()


func _get_map_exploration_node_count() -> int:
	var total := 0
	for node in map_nodes:
		var node_id := int(node.get("id", -1))
		if node_id <= 0 or String(node.get("type", "")) == NODE_SPECIAL:
			continue
		if bool(node.get("completed", false)):
			continue
		total += 1
	return total


func _pick_family_bias(ring_index: int, node_index: int) -> String:
	if FAMILY_BIASES.is_empty():
		return ""
	return FAMILY_BIASES[(ring_index * 2 + node_index) % FAMILY_BIASES.size()]


func _apply_progression_profile_to_node(node: Dictionary, ring_index: int) -> void:
	var tier := clampi(ring_index + 1, 1, 3)
	var tier_index := tier - 1
	node["tier"] = tier
	node["risk_level"] = TIER_RISK_LEVELS[tier_index]
	node["reward_mult"] = TIER_REWARD_MULTS[tier_index]
	node["equipment_drop_chance"] = TIER_EQUIPMENT_DROP_CHANCES[tier_index]


func _pick_modifier_profile(ring_index: int, node_index: int, offset: int = 0) -> Dictionary:
	if NODE_MODIFIER_PROFILES.is_empty():
		return {}
	var family_offset := 0
	var family_bias := _pick_family_bias(ring_index, node_index)
	if not family_bias.is_empty():
		family_offset = absi(family_bias.hash()) % NODE_MODIFIER_PROFILES.size()
	var index := (ring_index * 11 + node_index * 5 + offset * 7 + family_offset) % NODE_MODIFIER_PROFILES.size()
	return NODE_MODIFIER_PROFILES[index]


func _apply_modifier_profiles_to_node(node: Dictionary, ring_index: int, node_index: int) -> void:
	var modifiers: Array[Dictionary] = []
	var picked_ids := {}
	var first := _pick_modifier_profile(ring_index, node_index)
	if not first.is_empty():
		modifiers.append(first.duplicate(true))
		picked_ids[String(first.get("id", ""))] = true
	var modifier_count := 1
	if ring_index >= 1:
		modifier_count += 1
	if ring_index >= 2 and node_index % 2 == 0:
		modifier_count += 1
	for offset in range(1, modifier_count):
		var next_modifier := _pick_modifier_profile(ring_index, node_index, offset)
		var modifier_id := String(next_modifier.get("id", ""))
		if next_modifier.is_empty() or picked_ids.has(modifier_id):
			continue
		modifiers.append(next_modifier.duplicate(true))
		picked_ids[modifier_id] = true
	node["modifiers"] = modifiers
	for modifier in modifiers:
		node["reward_mult"] = float(node.get("reward_mult", 1.0)) + float(modifier.get("reward_mult_bonus", 0.0))
		node["equipment_drop_chance"] = clampf(
			float(node.get("equipment_drop_chance", TIER_EQUIPMENT_DROP_CHANCES[0])) + float(modifier.get("equipment_chance_bonus", 0.0)),
			0.0,
			MAX_READABLE_EQUIPMENT_DROP_CHANCE
		)


func _select_run_conditions() -> void:
	active_run_conditions.clear()
	if RUN_CONDITION_PROFILES.is_empty():
		return
	var target_count := ACTIVE_RUN_CONDITION_COUNT + int(_get_advanced_crisis_domain("run").get("active_condition_count_bonus", 0))
	var pool: Array[Dictionary] = []
	for raw_condition in RUN_CONDITION_PROFILES:
		pool.append(Dictionary(raw_condition).duplicate(true))
	pool.shuffle()
	var categories := {}
	for condition in pool:
		var category := String(condition.get("category", ""))
		if categories.has(category):
			continue
		active_run_conditions.append(condition.duplicate(true))
		categories[category] = true
		if active_run_conditions.size() >= target_count:
			return
	for condition in pool:
		if active_run_conditions.size() >= target_count:
			return
		var condition_id := String(condition.get("id", ""))
		if _has_active_run_condition(condition_id):
			continue
		active_run_conditions.append(condition.duplicate(true))


func _has_active_run_condition(condition_id: String) -> bool:
	for condition in active_run_conditions:
		if String(condition.get("id", "")) == condition_id:
			return true
	return false


func _apply_run_conditions_to_node(node: Dictionary) -> void:
	var summaries: Array[Dictionary] = []
	for raw_condition in active_run_conditions:
		var condition := Dictionary(raw_condition)
		summaries.append(condition.duplicate(true))
		node["reward_mult"] = float(node.get("reward_mult", 1.0)) + float(condition.get("reward_mult_bonus", 0.0))
		node["equipment_drop_chance"] = clampf(
			float(node.get("equipment_drop_chance", TIER_EQUIPMENT_DROP_CHANCES[0])) + float(condition.get("equipment_chance_bonus", 0.0)),
			0.0,
			MAX_READABLE_EQUIPMENT_DROP_CHANCE
		)
	node["run_conditions"] = summaries


func _pick_opportunity_profile(node: Dictionary, ring_index: int, node_index: int) -> Dictionary:
	if NODE_OPPORTUNITY_PROFILES.is_empty():
		return {}
	var family_offset := absi(String(node.get("family_bias", "")).hash()) % NODE_OPPORTUNITY_PROFILES.size()
	var type_offset := absi(String(node.get("type", "")).hash()) % NODE_OPPORTUNITY_PROFILES.size()
	var index := (ring_index * 13 + node_index * 7 + family_offset + type_offset) % NODE_OPPORTUNITY_PROFILES.size()
	return NODE_OPPORTUNITY_PROFILES[index].duplicate(true)


func _apply_opportunity_profile_to_node(node: Dictionary, ring_index: int, node_index: int) -> void:
	if String(node.get("type", "")) == NODE_SPECIAL:
		return
	var profile := _pick_opportunity_profile(node, ring_index, node_index)
	if profile.is_empty():
		return
	node["opportunity"] = profile.duplicate(true)
	node["opportunity_id"] = String(profile.get("id", ""))
	node["opportunity_title"] = String(profile.get("title", "航行机会"))
	node["opportunity_description"] = String(profile.get("description", "方舟捕捉到一段可利用的航行窗口。"))
	node["opportunity_effects_text"] = String(profile.get("effects_text", "航路参数出现可利用偏移。"))
	node["reward_mult"] = float(node.get("reward_mult", 1.0)) + float(profile.get("reward_mult_bonus", 0.0))
	node["equipment_drop_chance"] = clampf(
		float(node.get("equipment_drop_chance", TIER_EQUIPMENT_DROP_CHANCES[0])) + float(profile.get("equipment_chance_bonus", 0.0)),
		0.0,
		MAX_READABLE_EQUIPMENT_DROP_CHANCE
	)


func _apply_ore_source_bias_to_node(node: Dictionary, ring_index: int, node_index: int) -> void:
	var profile := _pick_ore_source_bias_profile(node, ring_index, node_index)
	if profile.is_empty():
		return
	node["ore_source_bias"] = String(profile.get("id", ""))
	node["ore_source_name"] = String(profile.get("name", ""))
	node["ore_source_label"] = String(profile.get("label", ""))
	node["ore_source_hint"] = String(profile.get("hint", ""))
	node["ore_source_weight"] = float(profile.get("weight", 2.4))
	node["ore_source_room_effect"] = Dictionary(profile.get("room_effect", {})).duplicate(true)
	node["ore_source_room_effect_text"] = String(profile.get("room_effect_text", ""))


func _pick_ore_source_bias_profile(node: Dictionary, ring_index: int, node_index: int) -> Dictionary:
	if ORE_SOURCE_BIAS_PROFILES.is_empty():
		return {}
	var preferred_id := _preferred_ore_source_id_for_node(node)
	if not preferred_id.is_empty():
		for profile in ORE_SOURCE_BIAS_PROFILES:
			if String(profile.get("id", "")) == preferred_id:
				return profile.duplicate(true)
	var index := (ring_index * 5 + node_index * 3 + int(node.get("tier", 1))) % ORE_SOURCE_BIAS_PROFILES.size()
	return ORE_SOURCE_BIAS_PROFILES[index].duplicate(true)


func _preferred_ore_source_id_for_node(node: Dictionary) -> String:
	if String(node.get("type", "")) == NODE_REWARD:
		var cache_family := String(node.get("cache_family_bias", "")).strip_edges()
		match cache_family:
			EquipmentCatalogScript.FAMILY_PARADISE:
				return "gleam_crystal"
			EquipmentCatalogScript.FAMILY_WARPED:
				return "rift_cluster"
			EquipmentCatalogScript.FAMILY_HELL_EYE:
				return "deep_core"
			EquipmentCatalogScript.FAMILY_DIVINE:
				return "gleam_crystal"
			EquipmentCatalogScript.FAMILY_COLOSSUS:
				return "deep_core"
	var family := String(node.get("family_bias", "")).strip_edges()
	match family:
		EquipmentCatalogScript.FAMILY_COLOSSUS:
			return "deep_core"
		EquipmentCatalogScript.FAMILY_PARADISE:
			return "gleam_crystal"
		EquipmentCatalogScript.FAMILY_WARPED:
			return "rift_cluster"
		EquipmentCatalogScript.FAMILY_HELL_EYE:
			return "deep_core"
		EquipmentCatalogScript.FAMILY_DIVINE:
			return "star_marrow"
	return ""


func _pick_battle_profile(ring_index: int, node_index: int) -> Dictionary:
	if BATTLE_NODE_PROFILES.is_empty():
		return {}
	return BATTLE_NODE_PROFILES[(ring_index * 3 + node_index) % BATTLE_NODE_PROFILES.size()]


func _apply_battle_profile_to_node(node: Dictionary, ring_index: int, node_index: int) -> void:
	if String(node.get("type", "")) != NODE_BATTLE:
		return
	var profile := _pick_battle_profile(ring_index, node_index)
	_apply_battle_profile_data_to_node(node, profile)


func _ensure_battle_profile_on_node(node: Dictionary) -> Dictionary:
	if String(node.get("type", "")) != NODE_BATTLE:
		return node
	if not String(node.get("battle_profile_id", "")).is_empty():
		return node
	var ring_index := int(node.get("ring_index", maxi(1, int(node.get("tier", 1))) - 1))
	var ring_node_index := int(node.get("ring_node_index", maxi(0, int(node.get("id", 1)) - 1)))
	var profile := _pick_battle_profile(ring_index, ring_node_index)
	_apply_battle_profile_data_to_node(node, profile)
	return node


func _apply_battle_profile_data_to_node(node: Dictionary, profile: Dictionary) -> void:
	if profile.is_empty():
		return
	node["battle_profile_id"] = String(profile.get("id", ""))
	node["battle_title"] = String(profile.get("title", "战斗态势"))
	node["battle_description"] = String(profile.get("description", "敌方巡逻信号活跃。"))
	node["battle_threat"] = int(profile.get("threat", 1))
	node["battle_room_config"] = profile.get("room_config", {}).duplicate(true)


func _merge_battle_profile_room_config(config: Dictionary, key: String, value) -> void:
	match key:
		"trap_count":
			config["battle_trap_pressure"] = int(value)
		"enemy_spawn_interval":
			config["battle_enemy_spawn_interval"] = float(value)
		"max_patrol_enemy_count":
			config["battle_max_patrol_enemy_count"] = int(value)
		"large_space_rock_count":
			config["battle_large_space_rock_hint"] = int(value)
		"chest_crystal_count":
			config["battle_reward_density_hint"] = int(value)
		"clutter_count":
			config["battle_clutter_density_hint"] = int(value)
		"family_bias":
			config["battle_family_bias"] = String(value)
		"family_weight_boost":
			config["battle_family_weight_boost"] = float(value)
		"patrol_path_min_count":
			config["battle_patrol_path_min_count"] = int(value)
		"patrol_path_max_count":
			config["battle_patrol_path_max_count"] = int(value)
		"elite_replacement_min":
			config["battle_elite_replacement_min"] = int(value)
		"elite_replacement_max":
			config["battle_elite_replacement_max"] = int(value)
		_:
			if not config.has(key):
				config[key] = value


func _pick_reward_profile(ring_index: int, node_index: int) -> Dictionary:
	if REWARD_NODE_PROFILES.is_empty():
		return {}
	return REWARD_NODE_PROFILES[(ring_index * 2 + node_index) % REWARD_NODE_PROFILES.size()]


func _apply_reward_profile_to_node(node: Dictionary, ring_index: int, node_index: int) -> void:
	if String(node.get("type", "")) != NODE_REWARD:
		return
	var profile := _pick_reward_profile(ring_index, node_index)
	_apply_reward_profile_data_to_node(node, profile)


func _ensure_reward_profile_on_node(node: Dictionary) -> Dictionary:
	if String(node.get("type", "")) != NODE_REWARD:
		return node
	if not String(node.get("reward_profile_id", "")).is_empty():
		return node
	var node_id := int(node.get("id", 0))
	var tier := maxi(1, int(node.get("tier", 1)))
	var profile := _pick_reward_profile(tier - 1, node_id)
	_apply_reward_profile_data_to_node(node, profile)
	return node


func _apply_reward_profile_data_to_node(node: Dictionary, profile: Dictionary) -> void:
	if profile.is_empty():
		return
	node["reward_profile_id"] = String(profile.get("id", ""))
	node["reward_title"] = String(profile.get("title", "奖励缓存"))
	node["reward_description"] = String(profile.get("description", "高价值资源缓存。"))
	node["reward_room_config"] = profile.get("room_config", {}).duplicate(true)
	node["reward_profile_mult_bonus"] = float(profile.get("reward_mult_bonus", 0.0))
	node["reward_profile_equipment_bonus"] = float(profile.get("equipment_chance_bonus", 0.0))
	node["cache_family_bias"] = String(profile.get("cache_family_bias", String(node.get("family_bias", ""))))
	node["reward_mult"] = float(node.get("reward_mult", 1.0)) + float(profile.get("reward_mult_bonus", 0.0))
	node["equipment_drop_chance"] = clampf(
		float(node.get("equipment_drop_chance", TIER_EQUIPMENT_DROP_CHANCES[0])) + float(profile.get("equipment_chance_bonus", 0.0)),
		0.0,
		MAX_READABLE_EQUIPMENT_DROP_CHANCE
	)


func _apply_route_plan_to_node(node: Dictionary) -> void:
	var node_type := String(node.get("type", ""))
	if node_type == NODE_BASE or node_type == NODE_SPECIAL:
		return
	node["route_plan"] = _make_route_plan(node)


func _make_route_plan(node: Dictionary) -> Dictionary:
	var node_type := String(node.get("type", NODE_BATTLE))
	var family := _route_plan_family_for_node(node)
	var family_name := _get_contract_family_display_name(family)
	var tier := maxi(1, int(node.get("tier", 1)))
	var risk := int(node.get("risk_level", tier))
	var reward_mult := float(node.get("reward_mult", 1.0))
	var equipment_chance := float(node.get("equipment_drop_chance", 0.0))
	var title := _route_plan_title(node, node_type, family_name)
	return {
		"title": title,
		"summary": _route_plan_summary(node, node_type, family_name, risk),
		"family": family,
		"family_name": family_name,
		"reward_hint": _route_plan_reward_hint(node_type, tier, reward_mult),
		"equipment_hint": _route_plan_equipment_hint(node, node_type, family_name, equipment_chance),
		"ore_source_hint": _route_plan_ore_source_hint(node),
		"tactic_hint": _route_plan_tactic_hint(family, node_type),
	}


func _route_plan_family_for_node(node: Dictionary) -> String:
	var echo: Dictionary = node.get("beacon_echo", {})
	var echo_family := String(echo.get("family_bias", "")).strip_edges()
	if not echo_family.is_empty():
		return echo_family
	var cache_family := String(node.get("cache_family_bias", "")).strip_edges()
	if not cache_family.is_empty():
		return cache_family
	var family := String(node.get("family_bias", "")).strip_edges()
	if not family.is_empty():
		return family
	return EquipmentCatalogScript.FAMILY_GENERAL


func _route_plan_title(node: Dictionary, node_type: String, family_name: String) -> String:
	match node_type:
		NODE_REWARD:
			var reward_title := String(node.get("reward_title", "")).strip_edges()
			if not reward_title.is_empty():
				return "%s回收线" % reward_title
			return "%s资源回收线" % family_name
		NODE_EVENT:
			var intel_title := String(node.get("intel_title", "")).strip_edges()
			if not intel_title.is_empty():
				return "%s处置线" % intel_title
			return "%s事件处置线" % family_name
		_:
			var battle_title := String(node.get("battle_title", "")).strip_edges()
			if not battle_title.is_empty():
				return "%s突破线" % battle_title
			return "%s作战突破线" % family_name


func _route_plan_summary(node: Dictionary, node_type: String, family_name: String, risk: int) -> String:
	var pressure := "低压"
	if risk >= 3:
		pressure = "高压"
	elif risk >= 2:
		pressure = "中压"
	match node_type:
		NODE_REWARD:
			return "%s资源点，可补齐%s装备与星髓矿储备。" % [pressure, family_name]
		NODE_EVENT:
			return "%s信号点，可能改写%s航路或换取短期契约。" % [pressure, family_name]
		_:
			return "%s交战点，敌群会推动%s流派成形。" % [pressure, family_name]


func _route_plan_reward_hint(node_type: String, tier: int, reward_mult: float) -> String:
	var reward_grade := "标准回收"
	if reward_mult >= 1.55:
		reward_grade = "丰厚回收"
	elif reward_mult >= 1.25:
		reward_grade = "优良回收"
	match node_type:
		NODE_REWARD:
			return "%s，矿脉与宝箱密度更高，可囤积星髓矿。" % reward_grade
		NODE_EVENT:
			return "%s，收益取决于处置选择，安全方案通常更稳。" % reward_grade
		_:
			return "%s，第%d层收益会随撤离结算放大。" % [reward_grade, tier]


func _route_plan_equipment_hint(node: Dictionary, node_type: String, family_name: String, equipment_chance: float) -> String:
	var percent := int(round(equipment_chance * 100.0))
	var family_hint := family_name
	if node_type == NODE_REWARD:
		var cache_family := String(node.get("cache_family_bias", "")).strip_edges()
		if not cache_family.is_empty():
			family_hint = _get_contract_family_display_name(cache_family)
	var echo: Dictionary = node.get("beacon_echo", {})
	if not echo.is_empty():
		family_hint = String(echo.get("family_name", family_hint))
	match node_type:
		NODE_EVENT:
			return "装备机会约 %d%%，事件方案会偏向%s或临时航路契约。" % [percent, family_hint]
		NODE_REWARD:
			return "装备机会约 %d%%，缓存信号偏向%s。" % [percent, family_hint]
		_:
			return "装备机会约 %d%%，掉落池偏向%s。" % [percent, family_hint]


func _route_plan_ore_source_hint(node: Dictionary) -> String:
	var source_name := String(node.get("ore_source_name", "星髓矿脉")).strip_edges()
	var source_hint := String(node.get("ore_source_hint", "")).strip_edges()
	if source_hint.is_empty():
		return "矿源：%s，回收队会优先标记附近晶体反应。" % source_name
	return "矿源：%s，%s" % [source_name, source_hint]


func _route_plan_tactic_hint(family: String, node_type: String) -> String:
	var suffix := "进入前优先寻找同家族装备。"
	if node_type == NODE_REWARD:
		suffix = "奖励航线正好用来补强核心装备。"
	elif node_type == NODE_EVENT:
		suffix = "事件方案会改变后续航路节奏。"
	match family:
		EquipmentCatalogScript.FAMILY_COLOSSUS:
			return "冲锋碰撞，借右键突进和反弹角打开缺口，%s" % suffix
		EquipmentCatalogScript.FAMILY_PARADISE:
			return "火力覆盖，用多线弹幕、射速和弹速压住航道，%s" % suffix
		EquipmentCatalogScript.FAMILY_WARPED:
			return "引力牵制，依靠追踪弹道与聚群窗口清理敌影，%s" % suffix
		EquipmentCatalogScript.FAMILY_HELL_EYE:
			return "狂热爆发，围绕受击与命中蓄压，把五秒窗口打满，%s" % suffix
		EquipmentCatalogScript.FAMILY_DIVINE:
			return "僚机协同，让友军火线分担压制并守住侧翼，%s" % suffix
	return "通用回路，优先补齐武器、机动和回收余量，%s" % suffix


func _apply_family_bias_to_room_config(config: Dictionary, family_bias: String) -> void:
	if family_bias.is_empty():
		return
	config["%s_family_weight" % family_bias] = EXPLORE_FAMILY_WEIGHT_BOOST


func _apply_ore_source_bias_to_room_config(config: Dictionary, node: Dictionary) -> void:
	var source_id := String(node.get("ore_source_bias", "")).strip_edges()
	if source_id.is_empty():
		return
	var applied_key := "__ore_source_room_effect_%s" % source_id
	if bool(config.get(applied_key, false)):
		return
	var source_name := String(node.get("ore_source_name", "")).strip_edges()
	var source_weight := maxf(1.0, float(node.get("ore_source_weight", 2.4)))
	config["ore_source_bias"] = source_id
	config["ore_source_name"] = source_name
	config["ore_source_weights"] = _make_ore_source_weight_map(source_id, source_weight)
	var room_effect: Dictionary = node.get("ore_source_room_effect", {})
	if room_effect.is_empty():
		room_effect = _get_ore_source_room_effect(source_id)
	_apply_ore_source_room_effect(config, room_effect)
	var effect_text := String(node.get("ore_source_room_effect_text", "")).strip_edges()
	if effect_text.is_empty():
		effect_text = _get_ore_source_room_effect_text(source_id)
	if not effect_text.is_empty():
		config["ore_source_room_effect_text"] = effect_text
	config[applied_key] = true


func _make_ore_source_weight_map(source_id: String, source_weight: float) -> Dictionary:
	var weights := {}
	for profile in ORE_SOURCE_BIAS_PROFILES:
		var id := String(profile.get("id", ""))
		if id.is_empty():
			continue
		weights[id] = 1.0
	if not source_id.is_empty():
		weights[source_id] = maxf(float(weights.get(source_id, 1.0)), source_weight)
	return weights


func _apply_ore_source_room_effect(config: Dictionary, effect: Dictionary) -> void:
	for raw_key in effect.keys():
		_apply_room_config_delta(config, String(raw_key), effect[raw_key])


func _get_ore_source_room_effect(source_id: String) -> Dictionary:
	for profile in ORE_SOURCE_BIAS_PROFILES:
		if String(profile.get("id", "")) == source_id:
			return Dictionary(profile.get("room_effect", {})).duplicate(true)
	return {}


func _get_ore_source_room_effect_text(source_id: String) -> String:
	for profile in ORE_SOURCE_BIAS_PROFILES:
		if String(profile.get("id", "")) == source_id:
			return String(profile.get("room_effect_text", ""))
	return ""


func _get_ore_source_focus_display_text(source_id: String) -> String:
	for profile in ORE_SOURCE_BIAS_PROFILES:
		if String(profile.get("id", "")) != source_id:
			continue
		var label := String(profile.get("label", profile.get("name", "矿源"))).strip_edges()
		if label.is_empty():
			label = "矿源"
		return "%s采购校准" % label
	return "矿源采购校准"


func _apply_beacon_echo_to_room_config(config: Dictionary, node: Dictionary) -> void:
	var echo: Dictionary = node.get("beacon_echo", {})
	if echo.is_empty():
		return
	var family := String(echo.get("family_bias", ""))
	if not family.is_empty():
		config["reward_cache_family_bias"] = family
		config["%s_family_weight" % family] = maxf(float(config.get("%s_family_weight" % family, 0.0)), EXPLORE_FAMILY_WEIGHT_BOOST)
	var reward_bonus := float(echo.get("reward_bonus", 0.0))
	if reward_bonus > 0.0:
		config["reward_mineral_mult"] = float(config.get("reward_mineral_mult", 1.0)) + reward_bonus
	var bonus_name := String(echo.get("bonus_name", "方舟信标协议"))
	var family_name := String(echo.get("family_name", _get_contract_family_display_name(family)))
	var equipment_bonus := float(echo.get("equipment_bonus", 0.0))
	var effects: Array[String] = []
	if equipment_bonus > 0.0:
		effects.append("装备出现率 +%d%%" % int(round(equipment_bonus * 100.0)))
	if reward_bonus > 0.0:
		effects.append("矿物倍率 +%.2f" % reward_bonus)
	var effect_text := "，".join(effects)
	if effect_text.is_empty():
		effect_text = "航路参数已改写"
	config["beacon_echo_tip_text"] = "信标回响：%s。%s航线被点亮，%s。" % [bonus_name, family_name, effect_text]


func _pick_intel_profile(ring_index: int, node_index: int) -> Dictionary:
	if NODE_INTEL_PROFILES.is_empty():
		return {}
	return NODE_INTEL_PROFILES[(ring_index * 11 + node_index * 5) % NODE_INTEL_PROFILES.size()]


func _apply_intel_profile_to_node(node: Dictionary, ring_index: int, node_index: int) -> void:
	var profile := _pick_intel_profile(ring_index, node_index)
	if profile.is_empty():
		return
	node["intel_id"] = String(profile.get("id", ""))
	node["intel_title"] = String(profile.get("title", ""))
	node["intel_description"] = String(profile.get("description", ""))
	node["room_config"] = profile.get("room_config", {}).duplicate(true)


func _apply_node_room_config(config: Dictionary, node: Dictionary) -> void:
	var intel_config: Dictionary = node.get("room_config", {})
	for key in intel_config.keys():
		config[key] = intel_config[key]
	_apply_run_condition_room_config(config, node.get("run_conditions", []))
	_apply_modifier_room_config(config, node.get("modifiers", []))
	_apply_opportunity_room_config(config, Dictionary(node.get("opportunity", {})))
	var risk := int(node.get("risk_level", 1))
	if risk <= 1:
		return
	config["trap_count"] = maxi(int(config.get("trap_count", 4)), 3 + risk * 2)
	config["enemy_spawn_interval"] = minf(float(config.get("enemy_spawn_interval", 45.0)), maxf(18.0, 48.0 - float(risk) * 5.0))
	config["max_patrol_enemy_count"] = maxi(int(config.get("max_patrol_enemy_count", 8)), 6 + risk * 2)


func _apply_modifier_room_config(config: Dictionary, modifiers: Array) -> void:
	for raw_modifier in modifiers:
		var modifier := Dictionary(raw_modifier)
		var modifier_config: Dictionary = modifier.get("room_config", {})
		for key in modifier_config.keys():
			config[key] = modifier_config[key]


func _apply_run_condition_room_config(config: Dictionary, conditions: Array) -> void:
	for raw_condition in conditions:
		var condition := Dictionary(raw_condition)
		var condition_config: Dictionary = condition.get("room_config", {})
		for key in condition_config.keys():
			config[key] = condition_config[key]


func _apply_opportunity_room_config(config: Dictionary, opportunity: Dictionary) -> void:
	if opportunity.is_empty():
		return
	var room_effect: Dictionary = opportunity.get("room_effect", {})
	for raw_key in room_effect.keys():
		_apply_room_config_delta(config, String(raw_key), room_effect[raw_key])
	var tip := _make_opportunity_tip_text(opportunity)
	if not tip.is_empty():
		config["opportunity_tip_text"] = tip


func _make_opportunity_tip_text(opportunity: Dictionary) -> String:
	var title := String(opportunity.get("title", "航行机会")).strip_edges()
	var effects_text := String(opportunity.get("effects_text", "")).strip_edges()
	if title.is_empty():
		return ""
	if effects_text.is_empty():
		return "航行机会：%s。方舟建议把这段偏移纳入回收节奏。" % title
	return "航行机会：%s。%s" % [title, effects_text]


func _apply_room_config_delta(config: Dictionary, key: String, value) -> void:
	match key:
		"reward_mineral_mult":
			config[key] = maxf(0.1, float(config.get(key, 1.0)) + float(value))
		"enemy_spawn_interval":
			config[key] = maxf(12.0, float(config.get(key, 45.0)) + float(value))
		"large_space_rock_count", "trap_count", "chest_crystal_count", "clutter_count", "max_patrol_enemy_count", "patrol_path_min_count", "patrol_path_max_count":
			config[key] = maxi(0, int(config.get(key, 0)) + int(value))
		_:
			config[key] = value


func _apply_loading_context_to_room_config(config: Dictionary, node: Dictionary) -> void:
	var intel_title := String(node.get("intel_title", "")).strip_edges()
	if not intel_title.is_empty():
		config["node_intel_title"] = intel_title
	var echo_tip := String(config.get("beacon_echo_tip_text", "")).strip_edges()
	var cache_calibration_tip := String(config.get("reward_cache_route_calibration_tip_text", "")).strip_edges()
	var boss_aftershock_tip := String(config.get("boss_aftershock_tip_text", "")).strip_edges()
	var ore_source_tip := String(config.get("ore_source_room_effect_text", "")).strip_edges()
	var opportunity_tip := String(config.get("opportunity_tip_text", "")).strip_edges()
	var modifiers: Array = node.get("modifiers", [])
	var conditions: Array = node.get("run_conditions", [])
	var condition_tip := _build_run_condition_tip_text(conditions)
	if modifiers.is_empty() and echo_tip.is_empty() and cache_calibration_tip.is_empty() and boss_aftershock_tip.is_empty() and ore_source_tip.is_empty() and opportunity_tip.is_empty() and condition_tip.is_empty():
		return
	var modifier_titles := _get_modifier_titles(modifiers, 2)
	if modifier_titles.is_empty() and echo_tip.is_empty() and cache_calibration_tip.is_empty() and boss_aftershock_tip.is_empty() and ore_source_tip.is_empty() and opportunity_tip.is_empty() and condition_tip.is_empty():
		return
	var title_text := " / ".join(modifier_titles)
	var parts: Array[String] = []
	if not condition_tip.is_empty():
		parts.append(condition_tip)
	if not ore_source_tip.is_empty():
		parts.append(ore_source_tip)
	if not opportunity_tip.is_empty():
		parts.append(opportunity_tip)
	if not echo_tip.is_empty():
		parts.append(echo_tip)
	if not cache_calibration_tip.is_empty():
		parts.append(cache_calibration_tip)
	if not boss_aftershock_tip.is_empty():
		parts.append(boss_aftershock_tip)
	if not title_text.is_empty():
		parts.append("航域扰动：%s。方舟已标记异常航路。" % title_text)
	var tip_text := "｜".join(parts)
	if not intel_title.is_empty():
		tip_text = "%s｜%s" % [intel_title, tip_text]
	config["modifier_tip_text"] = tip_text
	if not condition_tip.is_empty():
		config["run_condition_tip_text"] = condition_tip
		config["run_condition_summary_text"] = _build_run_condition_summary_text(conditions)
	var modifier_summary := _build_modifier_summary_text(modifiers)
	var summary_parts: Array[String] = []
	var condition_summary := _build_run_condition_summary_text(conditions)
	if not condition_summary.is_empty():
		summary_parts.append(condition_summary)
	if not ore_source_tip.is_empty():
		summary_parts.append(ore_source_tip)
	if not opportunity_tip.is_empty():
		summary_parts.append(opportunity_tip)
	if not echo_tip.is_empty():
		summary_parts.append(echo_tip)
	if not cache_calibration_tip.is_empty():
		summary_parts.append(cache_calibration_tip)
	if not boss_aftershock_tip.is_empty():
		summary_parts.append(boss_aftershock_tip)
	if not modifier_summary.is_empty():
		summary_parts.append(modifier_summary)
	if not summary_parts.is_empty():
		config["modifier_summary_text"] = "\n".join(summary_parts)


func _build_run_condition_tip_text(conditions: Array) -> String:
	var titles := PackedStringArray()
	for raw_condition in conditions:
		var title := String(Dictionary(raw_condition).get("title", "")).strip_edges()
		if not title.is_empty():
			titles.append(title)
	if titles.is_empty():
		return ""
	return "航域态势：%s。整段航程参数已改写。" % " / ".join(titles)


func _build_run_condition_summary_text(conditions: Array) -> String:
	var lines := PackedStringArray()
	for raw_condition in conditions:
		var condition := Dictionary(raw_condition)
		var title := String(condition.get("title", "")).strip_edges()
		var description := String(condition.get("description", "")).strip_edges()
		var effects_text := String(condition.get("effects_text", "")).strip_edges()
		if title.is_empty():
			continue
		if effects_text.is_empty():
			lines.append("%s：%s" % [title, description])
		else:
			lines.append("%s：%s%s" % [title, description, "（%s）" % effects_text])
	return "\n".join(lines)


func _get_modifier_titles(modifiers: Array, limit: int) -> PackedStringArray:
	var titles := PackedStringArray()
	for raw_modifier in modifiers:
		if titles.size() >= limit:
			break
		var modifier := Dictionary(raw_modifier)
		var title := String(modifier.get("title", "")).strip_edges()
		if not title.is_empty():
			titles.append(title)
	return titles


func _build_modifier_summary_text(modifiers: Array) -> String:
	var lines := PackedStringArray()
	for raw_modifier in modifiers:
		var modifier := Dictionary(raw_modifier)
		var title := String(modifier.get("title", "")).strip_edges()
		var description := String(modifier.get("description", "")).strip_edges()
		if title.is_empty() or description.is_empty():
			continue
		var tag_text := _join_modifier_tags(modifier.get("tags", []))
		if tag_text.is_empty():
			lines.append("%s：%s" % [title, description])
		else:
			lines.append("%s（%s）：%s" % [title, tag_text, description])
	return "\n".join(lines)


func _join_modifier_tags(raw_tags: Array) -> String:
	var tags := PackedStringArray()
	for raw_tag in raw_tags:
		var tag := String(raw_tag).strip_edges()
		if not tag.is_empty():
			tags.append(tag)
	return "、".join(tags)


func _make_rng(seed: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	if seed >= 0:
		rng.seed = seed
	else:
		rng.randomize()
	return rng


func _pick_event_profile(node: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	if not force_next_event_id.is_empty():
		var forced_id := force_next_event_id
		force_next_event_id = ""
		for profile in EVENT_PROFILES:
			if String(profile.get("id", "")) == forced_id:
				return profile.duplicate(true)
	return _pick_event_profile_from_pool(node, rng, {})


func _pick_event_profile_from_pool(node: Dictionary, rng: RandomNumberGenerator, used_ids: Dictionary) -> Dictionary:
	var preferred_family := String(node.get("family_bias", ""))
	var total_weight := 0.0
	for profile in EVENT_PROFILES:
		if used_ids.has(String(profile.get("id", ""))):
			continue
		total_weight += _get_event_profile_weight(profile, preferred_family)
	if total_weight <= 0.0:
		return {}
	var roll := rng.randf() * total_weight
	var cursor := 0.0
	for profile in EVENT_PROFILES:
		if used_ids.has(String(profile.get("id", ""))):
			continue
		cursor += _get_event_profile_weight(profile, preferred_family)
		if roll <= cursor:
			return profile.duplicate(true)
	return {}


func _get_event_profile_by_id(event_id: String) -> Dictionary:
	for profile in EVENT_PROFILES:
		if String(profile.get("id", "")) == event_id:
			return profile.duplicate(true)
	return {}


func _make_reward_cache_choice_data(cache_type: String, node: Dictionary) -> Dictionary:
	var node_id := int(node.get("id", -1))
	var reward_title := String(node.get("reward_title", "奖励缓存")).strip_edges()
	var family := String(node.get("cache_family_bias", node.get("family_bias", ""))).strip_edges()
	if family.is_empty():
		family = EquipmentCatalogScript.FAMILY_GENERAL
	var family_name := EquipmentCatalogScript.get_family_display_name(family)
	if cache_type == "family":
		var shop_focus_text := "%s商品偏好" % family_name
		return {
			"choice_id": "cache_family_%d" % node_id,
			"cache_type": "family",
			"title": "%s同家族装备箱" % family_name,
			"description": "锁定%s回响，蓝图、敌群信号和商店货单都会向这条航路靠拢。" % family_name,
			"preview": "%s蓝图更容易出现，并获得少量星髓收益与%s。" % [family_name, shop_focus_text],
			"family_bias": family,
			"family_name": family_name,
			"mineral_mult_bonus": REWARD_CACHE_FAMILY_MINERAL_BONUS,
			"chest_bonus": 1,
			"equipment_bonus": REWARD_CACHE_FAMILY_EQUIPMENT_BONUS,
			"shop_focus": true,
			"shop_focus_family": family,
			"shop_focus_text": shop_focus_text,
		}
	if cache_type == "shop":
		var shop_focus_text := "%s商品偏好" % family_name
		return {
			"choice_id": "cache_shop_%d" % node_id,
			"cache_type": "shop",
			"title": "%s采购校准箱" % family_name,
			"description": "方舟把%s缓存坐标同步给商店终端，下一批货单会沿这条航路刷新。" % family_name,
			"preview": "%s，并让装备出现率小幅提高。" % shop_focus_text,
			"family_bias": family,
			"family_name": family_name,
			"mineral_mult_bonus": 0.0,
			"chest_bonus": 0,
			"equipment_bonus": REWARD_CACHE_FAMILY_EQUIPMENT_BONUS,
			"shop_focus": true,
			"shop_focus_family": family,
			"shop_focus_text": shop_focus_text,
		}
	match cache_type:
		"minerals":
			return {
				"choice_id": "cache_minerals_%d" % node_id,
				"cache_type": "minerals",
				"title": "星髓回收箱",
				"description": "%s内的矿脉会被优先标定，撤离时带回更多星髓。" % reward_title,
				"preview": "星髓收益提高，矿脉与宝箱密度小幅上升。",
				"family_bias": family,
				"mineral_mult_bonus": REWARD_CACHE_MINERAL_MULT_BONUS,
				"chest_bonus": REWARD_CACHE_MINERAL_CHEST_BONUS,
				"equipment_bonus": 0.0,
			}
		"equipment":
			return {
				"choice_id": "cache_equipment_%d" % node_id,
				"cache_type": "equipment",
				"title": "封存蓝图箱",
				"description": "方舟会把扫描带宽让给装备残片，更容易从货柜里检出蓝图。",
				"preview": "装备蓝图检出提高，掉落仍会参考当前缓存倾向。",
				"family_bias": family,
				"mineral_mult_bonus": 0.0,
				"chest_bonus": 0,
				"equipment_bonus": REWARD_CACHE_EQUIPMENT_BONUS,
			}
		"family":
			return {
				"choice_id": "cache_family_%d" % node_id,
				"cache_type": "family",
				"title": "%s同家族装备箱" % family_name,
				"description": "锁定%s回响，蓝图与敌群信号都会向这条航路靠拢。" % family_name,
				"preview": "%s蓝图更容易出现，并获得少量星髓收益。" % family_name,
				"family_bias": family,
				"family_name": family_name,
				"mineral_mult_bonus": REWARD_CACHE_FAMILY_MINERAL_BONUS,
				"chest_bonus": 1,
				"equipment_bonus": REWARD_CACHE_FAMILY_EQUIPMENT_BONUS,
			}
	return {}


func _rotate_reward_cache_choices(choices: Array, seed: int) -> Array:
	var result := choices.duplicate(true)
	var shift := absi(seed) % result.size()
	for _i in range(shift):
		result.append(result.pop_front())
	return result


func _find_reward_cache_choice(choices: Array, choice_id: String) -> Dictionary:
	for raw_choice in choices:
		var choice := Dictionary(raw_choice)
		if String(choice.get("choice_id", "")) == choice_id:
			return choice
	return {}


func _apply_reward_cache_choice_to_node(node_id: int, choice: Dictionary) -> Dictionary:
	var node := get_map_node(node_id)
	if node.is_empty():
		return {}
	node["reward_cache_choice_id"] = String(choice.get("choice_id", ""))
	node["reward_cache_choice_type"] = String(choice.get("cache_type", ""))
	node["reward_cache_choice_title"] = String(choice.get("title", "奖励缓存"))
	node["reward_cache_choice_summary"] = String(choice.get("preview", "缓存参数已锁定。"))
	node["reward_cache_choice_family"] = String(choice.get("family_bias", node.get("cache_family_bias", "")))
	node["reward_cache_mineral_bonus"] = float(choice.get("mineral_mult_bonus", 0.0))
	node["reward_cache_chest_bonus"] = int(choice.get("chest_bonus", 0))
	node["reward_cache_equipment_chance_bonus"] = float(choice.get("equipment_bonus", 0.0))
	var shop_focus_family := _normalize_shop_family(String(choice.get("shop_focus_family", "")))
	var shop_focus_text := String(choice.get("shop_focus_text", "")).strip_edges()
	if bool(choice.get("shop_focus", false)) and shop_focus_family.is_empty():
		shop_focus_family = _normalize_shop_family(String(choice.get("family_bias", "")))
	if not shop_focus_family.is_empty():
		if shop_focus_text.is_empty():
			shop_focus_text = "%s商品偏好" % EquipmentCatalogScript.get_family_display_name(shop_focus_family)
		node["reward_cache_shop_focus_family"] = shop_focus_family
		node["reward_cache_shop_focus_text"] = shop_focus_text
		shop_preferred_family = shop_focus_family
		shop_offer_ids.clear()
		shop_draft_initialized = false
	var family := String(choice.get("family_bias", "")).strip_edges()
	if String(choice.get("cache_type", "")) == "family" and not family.is_empty():
		node["cache_family_bias"] = family
		node["family_bias"] = family
	map_nodes[node_id] = node
	var calibrated_routes := _apply_reward_cache_route_calibration(node_id, shop_focus_family, shop_focus_text)
	var result := {
		"reward_cache_calibrated_routes": calibrated_routes,
		"calibrated_route_count": calibrated_routes.size(),
	}
	if shop_focus_family.is_empty():
		result["shop_focus_changed"] = false
		return result
	result["shop_focus_changed"] = true
	result["shop_focus_family"] = shop_focus_family
	result["shop_focus_name"] = EquipmentCatalogScript.get_family_display_name(shop_focus_family)
	result["shop_focus_text"] = shop_focus_text
	return result


func _apply_reward_cache_choice_to_room_config(room_config: Dictionary, node: Dictionary) -> void:
	var choice_id := String(node.get("reward_cache_choice_id", "")).strip_edges()
	if choice_id.is_empty():
		return
	var choice_type := String(node.get("reward_cache_choice_type", ""))
	var choice_title := String(node.get("reward_cache_choice_title", "奖励缓存"))
	var choice_summary := String(node.get("reward_cache_choice_summary", "缓存参数已锁定。"))
	var choice_family := String(node.get("reward_cache_choice_family", node.get("cache_family_bias", "")))
	var shop_focus_family := String(node.get("reward_cache_shop_focus_family", ""))
	var shop_focus_text := String(node.get("reward_cache_shop_focus_text", "")).strip_edges()
	var mineral_bonus := float(node.get("reward_cache_mineral_bonus", 0.0))
	var chest_bonus := int(node.get("reward_cache_chest_bonus", 0))
	var equipment_bonus := float(node.get("reward_cache_equipment_chance_bonus", 0.0))
	room_config["reward_cache_choice_id"] = choice_id
	room_config["reward_cache_choice_type"] = choice_type
	room_config["reward_cache_choice_title"] = choice_title
	room_config["reward_cache_choice_summary"] = choice_summary
	room_config["reward_cache_choice_family"] = choice_family
	room_config["reward_equipment_chance_bonus"] = equipment_bonus
	if not shop_focus_family.is_empty():
		room_config["reward_cache_shop_focus_family"] = shop_focus_family
	if not shop_focus_text.is_empty():
		room_config["reward_cache_shop_focus_text"] = shop_focus_text
	if mineral_bonus > 0.0:
		room_config["reward_mineral_mult"] = float(room_config.get("reward_mineral_mult", 1.0)) + mineral_bonus
	if chest_bonus > 0:
		room_config["chest_crystal_count"] = int(room_config.get("chest_crystal_count", 0)) + chest_bonus
	if not choice_family.is_empty():
		room_config["reward_cache_family_bias"] = choice_family
		if choice_type == "family":
			room_config["%s_family_weight" % choice_family] = maxf(
				float(room_config.get("%s_family_weight" % choice_family, 0.0)),
				EXPLORE_FAMILY_WEIGHT_BOOST
			)


func _apply_reward_cache_route_calibration(source_node_id: int, family: String, shop_focus_text: String) -> Array[Dictionary]:
	var normalized_family := _normalize_shop_family(family)
	if normalized_family.is_empty():
		return []
	var source := get_map_node(source_node_id)
	if source.is_empty():
		return []
	var family_name := EquipmentCatalogScript.get_family_display_name(normalized_family)
	var focus_text := shop_focus_text.strip_edges()
	if focus_text.is_empty():
		focus_text = "%s商品偏好" % family_name
	var calibrated: Array[Dictionary] = []
	for raw_target_id in source.get("links", []):
		var target_id := int(raw_target_id)
		if target_id <= 0 or target_id == source_node_id:
			continue
		var target := get_map_node(target_id)
		if target.is_empty() or bool(target.get("completed", false)):
			continue
		if String(target.get("type", "")) == NODE_SPECIAL:
			continue
		var calibration_text := "奖励调整：%s沿相邻航线同步，%s已写入方舟商品偏好。" % [family_name, focus_text]
		target["reward_cache_route_calibration"] = {
			"source_node_id": source_node_id,
			"source_node_name": String(source.get("name", "奖励缓存")),
			"family_bias": normalized_family,
			"family_name": family_name,
			"shop_focus_text": focus_text,
			"calibration_text": calibration_text,
			"equipment_bonus": REWARD_CACHE_ROUTE_EQUIPMENT_BONUS,
			"reward_bonus": REWARD_CACHE_ROUTE_REWARD_BONUS,
		}
		target["family_bias"] = normalized_family
		if String(target.get("type", "")) == NODE_REWARD:
			target["cache_family_bias"] = normalized_family
		target["equipment_drop_chance"] = clampf(
			float(target.get("equipment_drop_chance", TIER_EQUIPMENT_DROP_CHANCES[0])) + REWARD_CACHE_ROUTE_EQUIPMENT_BONUS,
			0.0,
			MAX_READABLE_EQUIPMENT_DROP_CHANCE
		)
		target["reward_mult"] = float(target.get("reward_mult", 1.0)) + REWARD_CACHE_ROUTE_REWARD_BONUS
		_apply_route_plan_to_node(target)
		map_nodes[target_id] = target
		calibrated.append({
			"node_id": target_id,
			"node_name": String(target.get("name", "未标记航线")),
			"family_name": family_name,
			"shop_focus_text": focus_text,
			"calibration_text": calibration_text,
			"equipment_bonus": REWARD_CACHE_ROUTE_EQUIPMENT_BONUS,
			"reward_bonus": REWARD_CACHE_ROUTE_REWARD_BONUS,
		})
	return calibrated


func _apply_reward_cache_route_calibration_to_room_config(config: Dictionary, node: Dictionary) -> void:
	var calibration: Dictionary = node.get("reward_cache_route_calibration", {})
	if calibration.is_empty():
		return
	var family := _normalize_shop_family(String(calibration.get("family_bias", "")))
	if not family.is_empty():
		config["reward_cache_family_bias"] = family
		config["%s_family_weight" % family] = maxf(float(config.get("%s_family_weight" % family, 0.0)), EXPLORE_FAMILY_WEIGHT_BOOST)
	var equipment_bonus := float(calibration.get("equipment_bonus", 0.0))
	if equipment_bonus > 0.0:
		config["reward_equipment_chance_bonus"] = float(config.get("reward_equipment_chance_bonus", 0.0)) + equipment_bonus
	var reward_bonus := float(calibration.get("reward_bonus", 0.0))
	if reward_bonus > 0.0:
		config["reward_mineral_mult"] = float(config.get("reward_mineral_mult", 1.0)) + reward_bonus
	var calibration_tip := _make_reward_cache_route_calibration_tip(calibration)
	if not calibration_tip.is_empty():
		config["reward_cache_route_calibration_tip_text"] = calibration_tip


func _make_reward_cache_route_calibration_tip(calibration: Dictionary) -> String:
	var calibration_text := String(calibration.get("calibration_text", "")).strip_edges()
	if not calibration_text.is_empty():
		return calibration_text
	var family_name := String(calibration.get("family_name", _get_contract_family_display_name(String(calibration.get("family_bias", ""))))).strip_edges()
	var focus_text := String(calibration.get("shop_focus_text", "")).strip_edges()
	if family_name.is_empty() and focus_text.is_empty():
		return ""
	if focus_text.is_empty():
		focus_text = "%s商品偏好" % family_name
	return "奖励调整：%s沿相邻航线同步，%s已写入方舟商品偏好。" % [family_name, focus_text]


func _apply_boss_aftershock_to_room_config(config: Dictionary, node: Dictionary) -> void:
	var aftershock: Dictionary = node.get("boss_aftershock", {})
	if aftershock.is_empty():
		return
	var family := _normalize_shop_family(String(aftershock.get("family_bias", "")))
	if not family.is_empty():
		config["reward_cache_family_bias"] = family
		config["%s_family_weight" % family] = maxf(float(config.get("%s_family_weight" % family, 0.0)), EXPLORE_FAMILY_WEIGHT_BOOST)
	var equipment_bonus := float(aftershock.get("equipment_bonus", 0.0))
	if equipment_bonus > 0.0:
		config["reward_equipment_chance_bonus"] = float(config.get("reward_equipment_chance_bonus", 0.0)) + equipment_bonus
	var reward_bonus := float(aftershock.get("reward_bonus", 0.0))
	if reward_bonus > 0.0:
		config["reward_mineral_mult"] = float(config.get("reward_mineral_mult", 1.0)) + reward_bonus
	var tip := _make_boss_aftershock_tip(aftershock)
	if not tip.is_empty():
		config["boss_aftershock_tip_text"] = tip


func _make_boss_aftershock_tip(aftershock: Dictionary) -> String:
	var aftershock_text := String(aftershock.get("aftershock_text", "")).strip_edges()
	if not aftershock_text.is_empty():
		return aftershock_text
	var family_name := String(aftershock.get("family_name", _get_contract_family_display_name(String(aftershock.get("family_bias", ""))))).strip_edges()
	var focus_text := String(aftershock.get("shop_focus_text", "")).strip_edges()
	if family_name.is_empty() and focus_text.is_empty():
		return ""
	if focus_text.is_empty():
		focus_text = "%s商品偏好" % family_name
	return "首领余波：%s残响压入航图，%s正在改写下一段商品偏好。" % [family_name, focus_text]


func _make_event_choice_data(profile: Dictionary, node: Dictionary) -> Dictionary:
	var event_id := String(profile.get("id", ""))
	var reward_preview := _make_event_reward_preview(profile, node)
	var cost_preview := _make_event_cost_preview(profile, node)
	var contract_preview := _make_event_contract_preview(profile)
	var tactic_preview := _make_event_tactic_preview(profile, node)
	var risk_label := String(profile.get("risk_label", _risk_label_for_level(int(profile.get("risk_level", 0)))))
	var preview_parts: Array[String] = [risk_label, reward_preview, cost_preview]
	if not tactic_preview.is_empty():
		preview_parts.append(tactic_preview)
	if not contract_preview.is_empty():
		preview_parts.append(contract_preview)
	return {
		"choice_id": event_id,
		"title": String(profile.get("title", event_id)),
		"category": String(profile.get("category", "mixed")),
		"flavor_text": String(profile.get("description", "未解析的异常信号正在等待回应。")),
		"background_path": "res://assets/ui/events/%s.svg" % event_id,
		"preview": " / ".join(preview_parts),
		"reward_preview": reward_preview,
		"cost_preview": cost_preview,
		"tactic_preview": tactic_preview,
		"contract_preview": contract_preview,
		"risk_level": int(profile.get("risk_level", 0)),
		"risk_label": risk_label,
		"reward_tag": String(profile.get("reward_tag", "")),
		"node_tier": int(node.get("tier", 1)),
		"family_bias": String(node.get("family_bias", "")),
	}


func _make_event_preview(profile: Dictionary, node: Dictionary) -> String:
	var parts: Array[String] = [
		String(profile.get("risk_label", _risk_label_for_level(int(profile.get("risk_level", 0))))),
		_make_event_reward_preview(profile, node),
		_make_event_cost_preview(profile, node),
	]
	var tactic_preview := _make_event_tactic_preview(profile, node)
	if not tactic_preview.is_empty():
		parts.append(tactic_preview)
	var contract_preview := _make_event_contract_preview(profile)
	if not contract_preview.is_empty():
		parts.append(contract_preview)
	return " / ".join(parts)


func _make_event_reward_preview(profile: Dictionary, node: Dictionary) -> String:
	var category := String(profile.get("category", "mixed"))
	match category:
		"minerals":
			var low := int(round(float(profile.get("mineral_min", 12)) * float(node.get("reward_mult", 1.0))))
			var high := int(round(float(profile.get("mineral_max", 24)) * float(node.get("reward_mult", 1.0))))
			return "获得约 %d-%d 星髓矿。" % [low, high]
		"heal":
			return "恢复约 %d-%d 生命。" % [int(profile.get("heal_min", 16)), int(profile.get("heal_max", 28))]
		"equipment":
			return "打捞一份装备蓝图，信号会偏向本节点回响。"
		"compute":
			return "立刻提升 %d 点算力容量。" % int(profile.get("compute_bonus", 1))
		"special":
			return "远处信标提前并入航路，增益回响开始点亮。"
		"mixed":
			return "获得少量矿物并恢复生命。"
	return "处理异常信号并封存该节点。"


func _make_event_cost_preview(profile: Dictionary, node: Dictionary) -> String:
	var cost: Dictionary = profile.get("cost", {})
	var parts: Array[String] = []
	var tier := maxi(1, int(node.get("tier", 1)))
	var hp_loss := _scaled_event_hp_loss(cost, tier)
	var mineral_cost := _scaled_event_mineral_cost(cost, tier)
	var crisis_add := int(cost.get("crisis_add", 0))
	if hp_loss > 0:
		parts.append("代价：生命 -%d" % hp_loss)
	if mineral_cost > 0:
		parts.append("代价：星髓矿 -%d" % mineral_cost)
	if crisis_add > 0:
		parts.append("代价：危机 +%d" % crisis_add)
	if parts.is_empty():
		return "无直接代价"
	return " / ".join(parts)


func _make_event_contract_preview(profile: Dictionary) -> String:
	var contract: Dictionary = profile.get("contract", {})
	if contract.is_empty():
		return ""
	var duration := int(contract.get("duration_nodes", 1))
	var mineral_bonus_rate := float(contract.get("mineral_bonus_rate", 0.0))
	var extra_crisis := int(contract.get("extra_crisis_on_complete", 0))
	var equipment_chance_bonus := float(contract.get("equipment_chance_bonus", 0.0))
	var frenzy_gain_mult := float(contract.get("frenzy_gain_mult", 1.0))
	var shop_discount_rate := float(contract.get("shop_discount_rate", 0.0))
	var free_shop_rerolls := int(contract.get("free_shop_rerolls", 0))
	var parts: Array[String] = []
	if mineral_bonus_rate > 0.0:
		parts.append("矿物 +%d%%" % int(round(mineral_bonus_rate * 100.0)))
	if extra_crisis > 0:
		parts.append("每节点危机 +%d" % extra_crisis)
	if equipment_chance_bonus > 0.0:
		parts.append("装备出现率 +%d%%" % int(round(equipment_chance_bonus * 100.0)))
	if shop_discount_rate > 0.0:
		parts.append("采购折扣 %d%%" % int(round(shop_discount_rate * 100.0)))
	if free_shop_rerolls > 0:
		parts.append("免费刷新商品 %d 次" % free_shop_rerolls)
	if frenzy_gain_mult < 1.0:
		parts.append("狂热获取 %d%%" % int(round(frenzy_gain_mult * 100.0)))
	if float(contract.get("dash_distance_mult", 1.0)) > 1.0 or float(contract.get("dash_damage_mult", 1.0)) > 1.0:
		parts.append("冲锋强化")
	if int(contract.get("bullet_count_bonus", 0)) > 0:
		parts.append("弹幕 +%d" % int(contract.get("bullet_count_bonus", 0)))
	if float(contract.get("fire_rate_mult", 1.0)) < 1.0:
		parts.append("射击加速")
	if float(contract.get("gravity_pull_strength_bonus", 0.0)) > 0.0:
		parts.append("引力牵引")
	if frenzy_gain_mult > 1.0:
		parts.append("武器过载积累 +%d%%" % int(round((frenzy_gain_mult - 1.0) * 100.0)))
	if float(contract.get("frenzy_damage_mult", 1.0)) > 1.0:
		parts.append("武器过载火力 +%d%%" % int(round((float(contract.get("frenzy_damage_mult", 1.0)) - 1.0) * 100.0)))
	if int(contract.get("drone_slots_bonus", 0)) > 0:
		parts.append("僚机 +%d" % int(contract.get("drone_slots_bonus", 0)))
	var shop_focus_text := String(contract.get("shop_focus_text", "")).strip_edges()
	if not shop_focus_text.is_empty():
		parts.append(shop_focus_text)
	if parts.is_empty():
		return "临时契约 %d 节点" % duration
	return "临时契约 %d 节点：%s" % [duration, " / ".join(parts)]


func _make_event_tactic_preview(profile: Dictionary, node: Dictionary) -> String:
	var family := _event_tactic_family(profile, node)
	var category := String(profile.get("category", "mixed"))
	var tactic := _event_tactic_text_for_family(family)
	match category:
		"minerals":
			return "战法：%s，矿物收益会给这条路线更快成形。" % tactic
		"heal":
			return "战法：%s，修复余量能支撑更激进的下一跳。" % tactic
		"equipment":
			return "战法：%s，装备信号更容易补上同调缺口。" % tactic
		"compute":
			return "战法：%s，额外算力会放大辅助机组合空间。" % tactic
		"special":
			return "战法：%s，信标回响会染亮邻近航线。" % tactic
		"contract":
			return "战法：%s，临时契约会把后续节点推向该节奏。" % tactic
	return "战法：%s，收益与代价会一起改写航路节奏。" % tactic


func _event_tactic_family(profile: Dictionary, node: Dictionary) -> String:
	var contract: Dictionary = profile.get("contract", {})
	var contract_family := String(contract.get("family_bias", "")).strip_edges()
	if not contract_family.is_empty():
		return contract_family
	var profile_family := String(profile.get("family_bias", "")).strip_edges()
	if not profile_family.is_empty():
		return profile_family
	var node_family := String(node.get("family_bias", "")).strip_edges()
	if not node_family.is_empty():
		return node_family
	return EquipmentCatalogScript.FAMILY_GENERAL


func _event_tactic_text_for_family(family: String) -> String:
	match family:
		EquipmentCatalogScript.FAMILY_COLOSSUS:
			return "冲锋碰撞"
		EquipmentCatalogScript.FAMILY_PARADISE:
			return "火力覆盖"
		EquipmentCatalogScript.FAMILY_WARPED:
			return "引力牵制"
		EquipmentCatalogScript.FAMILY_HELL_EYE:
			return "狂热爆发"
		EquipmentCatalogScript.FAMILY_DIVINE:
			return "僚机协同"
	return "通用回路"


func _risk_label_for_level(risk_level: int) -> String:
	match risk_level:
		0:
			return "安全"
		1:
			return "谨慎"
		2:
			return "高危"
	return "极端"


func _get_event_profile_weight(profile: Dictionary, preferred_family: String) -> float:
	var weight := float(profile.get("weight", 1.0))
	if bool(profile.get("prefer_family", false)) and not preferred_family.is_empty():
		weight *= 1.35
	return weight


func _apply_event_profile(node: Dictionary, profile: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var event_id := String(profile.get("id", ""))
	var title := String(profile.get("title", event_id))
	var category := String(profile.get("category", "mixed"))
	var description := String(profile.get("description", "事件完成。"))
	var result := {
		"ok": true,
		"event_id": event_id,
		"event_title": title,
		"event_category": category,
		"node_tier": int(node.get("tier", 1)),
		"family_bias": String(node.get("family_bias", "")),
		"message": "",
		"minerals_gained": 0,
		"heal_gained": 0,
		"equipment_id": "",
		"compute_gained": 0,
		"special_bonus_id": "",
		"risk_level": int(profile.get("risk_level", 0)),
		"risk_label": String(profile.get("risk_label", _risk_label_for_level(int(profile.get("risk_level", 0))))),
		"reward_tag": String(profile.get("reward_tag", "")),
		"cost_preview": _make_event_cost_preview(profile, node),
		"tactic_preview": _make_event_tactic_preview(profile, node),
		"hp_lost": 0,
		"minerals_spent": 0,
		"crisis_added": 0,
	}
	var lines: Array[String] = [title, description]
	_apply_event_cost(profile, node, result, lines)
	# 按 category 分发奖励，与 _make_event_reward_preview 的承诺保持一致
	match String(profile.get("category", "mixed")):
		"minerals":
			var amount := _roll_event_minerals(profile, node, rng)
			pending_room_loot["minerals"] = int(pending_room_loot.get("minerals", 0)) + amount
			result["minerals_gained"] = amount
			lines.append("获得 %d 星髓矿。" % amount)
		"heal":
			var heal := _roll_event_heal(profile, rng)
			GameManager.player_hp = mini(GameManager.PLAYER_MAX_HP, GameManager.player_hp + heal)
			result["heal_gained"] = heal
			lines.append("恢复 %d 生命。" % heal)
		"equipment":
			var item_id := EquipmentCatalogScript.get_random_loot_item_id(
				equipment_inventory,
				crisis_level,
				String(node.get("family_bias", "")),
				rng.randi()
			)
			pending_room_loot["equipment"] = [item_id]
			result["equipment_id"] = item_id
			lines.append("获得装备蓝图：%s。" % EquipmentCatalogScript.get_display_name(item_id))
		"compute":
			var compute_bonus := int(profile.get("compute_bonus", 1))
			compute_capacity += compute_bonus
			result["compute_gained"] = compute_bonus
			lines.append("额外接入 %d 点算力容量。" % compute_bonus)
		"special":
			var bonus_id := _activate_event_special_bonus(String(node.get("family_bias", "")))
			result["special_bonus_id"] = bonus_id
			lines.append("同步增益信标：%s。" % get_special_bonus_display_name(bonus_id))
		"contract":
			pass  # 契约类事件没有直接奖励，契约本体在下方统一签订
		_:
			var minerals_gained := _roll_event_minerals(profile, node, rng)
			var heal_amount := _roll_event_heal(profile, rng)
			pending_room_loot["minerals"] = int(pending_room_loot.get("minerals", 0)) + minerals_gained
			GameManager.player_hp = mini(GameManager.PLAYER_MAX_HP, GameManager.player_hp + heal_amount)
			result["minerals_gained"] = minerals_gained
			result["heal_gained"] = heal_amount
			lines.append("获得 %d 星髓矿，并恢复 %d 生命。" % [minerals_gained, heal_amount])
	var contract_data := _make_event_contract_data(profile, node)
	if not contract_data.is_empty():
		result["pending_event_contract"] = contract_data
		lines.append("签订临时契约：%s。" % String(contract_data.get("title", "")))
	result["message"] = "\n".join(lines)
	return result


func _apply_event_cost(profile: Dictionary, node: Dictionary, result: Dictionary, lines: Array[String]) -> void:
	var cost: Dictionary = profile.get("cost", {})
	var tier := maxi(1, int(node.get("tier", 1)))
	var hp_loss := _scaled_event_hp_loss(cost, tier)
	var mineral_cost := _scaled_event_mineral_cost(cost, tier)
	var crisis_add := int(cost.get("crisis_add", 0))
	var cost_lines: Array[String] = []
	if hp_loss > 0:
		var actual_hp_loss := mini(hp_loss, maxi(0, GameManager.player_hp - 1))
		GameManager.player_hp = maxi(1, GameManager.player_hp - actual_hp_loss)
		result["hp_lost"] = actual_hp_loss
		if actual_hp_loss > 0:
			cost_lines.append("生命 -%d" % actual_hp_loss)
	if mineral_cost > 0:
		var actual_mineral_cost := mini(mineral_cost, minerals)
		minerals -= actual_mineral_cost
		result["minerals_spent"] = actual_mineral_cost
		if actual_mineral_cost > 0:
			cost_lines.append("星髓矿 -%d" % actual_mineral_cost)
	if crisis_add > 0:
		var actual_crisis_add := _add_crisis_with_alert_stop(crisis_add)
		result["crisis_added"] = actual_crisis_add
		if actual_crisis_add > 0:
			cost_lines.append("危机 +%d" % actual_crisis_add)
	if not cost_lines.is_empty():
		lines.append("代价结算：%s。" % " / ".join(cost_lines))


func _scaled_event_hp_loss(cost: Dictionary, tier: int) -> int:
	var base := int(cost.get("hp_loss", 0))
	if base <= 0:
		return 0
	return maxi(1, int(round(float(base) * (1.0 + float(tier - 1) * 0.18))))


func _scaled_event_mineral_cost(cost: Dictionary, tier: int) -> int:
	var base := int(cost.get("mineral_cost", 0))
	if base <= 0:
		return 0
	return maxi(1, int(round(float(base) * (1.0 + float(tier - 1) * 0.2))))


func _roll_event_minerals(profile: Dictionary, node: Dictionary, rng: RandomNumberGenerator) -> int:
	var amount := rng.randi_range(int(profile.get("mineral_min", 12)), int(profile.get("mineral_max", 24)))
	amount = int(round(float(amount) * float(node.get("reward_mult", 1.0))))
	return maxi(1, amount)


func _roll_event_heal(profile: Dictionary, rng: RandomNumberGenerator) -> int:
	return rng.randi_range(int(profile.get("heal_min", 16)), int(profile.get("heal_max", 28)))


func _activate_event_special_bonus(family_bias: String) -> String:
	# 优先激活同族中尚未激活的信标（每族有多枚，跳过已激活的才能拿到第二枚）；
	# 同族全部已激活或无同族时，退而激活任意未激活的信标
	var fallback := ""
	for profile in SPECIAL_BONUS_PROFILES:
		var bonus_id := String(profile.get("bonus_id", ""))
		if bonus_id.is_empty() or active_special_bonus_ids.has(bonus_id):
			continue
		if String(profile.get("family_bias", "")) == family_bias:
			active_special_bonus_ids.append(bonus_id)
			return bonus_id
		if fallback.is_empty():
			fallback = bonus_id
	if fallback.is_empty():
		fallback = "colossus_charge_beacon"
	if not active_special_bonus_ids.has(fallback):
		active_special_bonus_ids.append(fallback)
	return fallback


func get_special_bonus_display_name(bonus_id: String) -> String:
	for profile in SPECIAL_BONUS_PROFILES:
		if String(profile.get("bonus_id", "")) == bonus_id:
			return String(profile.get("bonus_name", bonus_id))
	return bonus_id


func get_special_bonus_display_names(bonus_ids: Array) -> Array[String]:
	var names: Array[String] = []
	for bonus_id in bonus_ids:
		var name := get_special_bonus_display_name(String(bonus_id))
		if not name.is_empty() and not names.has(name):
			names.append(name)
	return names


func get_active_special_bonus_summaries() -> Array:
	var summaries: Array = []
	for bonus_id in active_special_bonus_ids:
		var id := String(bonus_id)
		var profile := _get_special_bonus_profile(id)
		if profile.is_empty():
			continue
		summaries.append({
			"bonus_id": id,
			"name": String(profile.get("bonus_name", id)),
			"beacon_name": String(profile.get("name", "增益信标")),
			"family": String(profile.get("family_bias", "general")),
			"description": String(profile.get("bonus_description", "")),
			"effects_text": _get_special_bonus_effects_text(id),
		})
	return summaries


func get_active_special_beacon_resonance_summaries() -> Array:
	var summaries: Array = []
	var family_counts := _get_active_special_beacon_family_counts()
	for family in FAMILY_BIASES:
		var count := int(family_counts.get(family, 0))
		if count < 2:
			continue
		var family_name := EquipmentCatalogScript.get_family_display_name(family)
		summaries.append({
			"family": family,
			"family_name": family_name,
			"count": count,
			"name": "%s信标共鸣" % family_name,
			"effects_text": _get_special_beacon_resonance_effects_text(family, count),
		})
	return summaries


func _get_special_bonus_profile(bonus_id: String) -> Dictionary:
	for profile in SPECIAL_BONUS_PROFILES:
		if String(profile.get("bonus_id", "")) == bonus_id:
			return profile
	return {}


func _get_special_bonus_effects_text(bonus_id: String) -> String:
	match bonus_id:
		"vector_supply_beacon":
			return "航速 +8%，矿物回收 +12%"
		"colossus_charge_beacon":
			return "冲锋距离 +16%，冲锋速度 +8%，撞击威力 +18%，冲锋余震展开"
		"paradise_fire_beacon":
			return "弹幕 +1，散射 +6度，弹速 +8%，分裂弹 +1"
		"warped_gravity_beacon":
			return "子弹追踪强化，锁定范围 360，引力牵引展开"
		"hell_eye_frenzy_beacon":
			return "狂热积累 +20%，狂热火力 +12%，狂热防线强化"
		"divine_drone_beacon":
			return "僚机挂载位 +1，僚机射速 +10%，僚机火力 +12%，矿物回收 +6%"
		"ark_guard_beacon":
			return "常态受击 -10%，航速 +3%"
		"colossus_mirror_ram_beacon":
			return "冲锋距离 +10%，余震范围 +70，余震伤害提高"
		"paradise_skyline_beacon":
			return "弹幕 +1，分裂弹角度扩大，弹速 +6%"
		"warped_tide_beacon":
			return "引力牵引半径扩大，牵引强度提高，追踪更稳"
		"hell_eye_redline_beacon":
			return "狂热积累 +18%，狂热火力 +10%，狂热减伤强化"
		"divine_seraph_beacon":
			return "僚机挂载位 +1，僚机射速 +8%，僚机火力 +18%"
	return "方舟协议已接入"


func _get_active_special_beacon_family_counts() -> Dictionary:
	var counts := {}
	for bonus_id in active_special_bonus_ids:
		var profile := _get_special_bonus_profile(String(bonus_id))
		if profile.is_empty():
			continue
		var family := String(profile.get("family_bias", "general"))
		if family == "general" or family.is_empty():
			continue
		counts[family] = int(counts.get(family, 0)) + 1
	return counts


func _apply_special_beacon_resonance_to_stats(stats: Dictionary) -> void:
	var family_counts := _get_active_special_beacon_family_counts()
	for family in family_counts.keys():
		var count := int(family_counts.get(family, 0))
		if count < 2:
			continue
		var level := count - 1
		match String(family):
			EquipmentCatalogScript.FAMILY_COLOSSUS:
				stats["dash_distance_mult"] = float(stats.get("dash_distance_mult", 1.0)) * (1.0 + 0.05 * float(level))
				stats["dash_damage_mult"] = float(stats.get("dash_damage_mult", 1.0)) * (1.0 + 0.12 * float(level))
				stats["dash_aftershock_radius"] = maxf(float(stats.get("dash_aftershock_radius", 0.0)), 210.0 + 24.0 * float(level))
				stats["dash_aftershock_damage_mult"] = maxf(float(stats.get("dash_aftershock_damage_mult", 0.0)), 0.48 + 0.04 * float(level))
			EquipmentCatalogScript.FAMILY_PARADISE:
				stats["fire_rate_mult"] = float(stats.get("fire_rate_mult", 1.0)) * (1.0 - 0.04 * float(level))
				stats["bullet_speed_mult"] = float(stats.get("bullet_speed_mult", 1.0)) * (1.0 + 0.06 * float(level))
				stats["bullet_split_count"] = int(stats.get("bullet_split_count", 0)) + level
			EquipmentCatalogScript.FAMILY_WARPED:
				stats["homing_strength"] = float(stats.get("homing_strength", 0.0)) + 0.9 * float(level)
				stats["gravity_pull_strength"] = float(stats.get("gravity_pull_strength", 0.0)) + 140.0 * float(level)
				stats["gravity_pull_radius"] = float(stats.get("gravity_pull_radius", 0.0)) + 90.0 * float(level)
			EquipmentCatalogScript.FAMILY_HELL_EYE:
				stats["frenzy_gain_mult"] = float(stats.get("frenzy_gain_mult", 1.0)) * (1.0 + 0.1 * float(level))
				stats["frenzy_damage_mult"] = float(stats.get("frenzy_damage_mult", 1.0)) * (1.0 + 0.08 * float(level))
				stats["frenzy_damage_taken_mult"] = float(stats.get("frenzy_damage_taken_mult", 1.0)) * (1.0 - 0.04 * float(level))
			EquipmentCatalogScript.FAMILY_DIVINE:
				stats["drone_fire_interval_mult"] = float(stats.get("drone_fire_interval_mult", 1.0)) * (1.0 - 0.06 * float(level))
				stats["drone_damage_mult"] = float(stats.get("drone_damage_mult", 1.0)) * (1.0 + 0.1 * float(level))
				stats["drone_slots"] = int(stats.get("drone_slots", 0)) + level


func _get_special_beacon_resonance_effects_text(family: String, count: int) -> String:
	var level := maxi(1, count - 1)
	match family:
		EquipmentCatalogScript.FAMILY_COLOSSUS:
			return "冲锋距离 +%d%%，撞击威力 +%d%%，余震范围展开" % [level * 5, level * 12]
		EquipmentCatalogScript.FAMILY_PARADISE:
			return "射击加速，弹速 +%d%%，分裂弹继续外扩" % (level * 6)
		EquipmentCatalogScript.FAMILY_WARPED:
			return "追踪强化，引力牵引半径与强度提高"
		EquipmentCatalogScript.FAMILY_HELL_EYE:
			return "狂热积累 +%d%%，狂热火力 +%d%%" % [level * 10, level * 8]
		EquipmentCatalogScript.FAMILY_DIVINE:
			return "僚机挂载 +%d，僚机射速与火力提高" % level
	return "信标共鸣已接入"


func _add_special_bonus_nodes(rings: Array[Array]) -> void:
	if rings.is_empty() or rings[0].is_empty():
		return
	var occupied_positions: Array[Vector2] = []
	for node in map_nodes:
		occupied_positions.append(node.get("position", MAP_CENTER))
	for index in range(SPECIAL_BONUS_PROFILES.size()):
		var profile := SPECIAL_BONUS_PROFILES[index]
		var anchor_id := int(rings[0][index % rings[0].size()])
		var anchor := map_nodes[anchor_id]
		var anchor_pos: Vector2 = anchor.get("position", MAP_CENTER + Vector2.RIGHT * 180.0)
		var preferred_position: Vector2 = anchor_pos + Vector2(profile.get("offset", Vector2.ZERO))
		var special_position := _find_non_overlapping_map_position(preferred_position, occupied_positions)
		var special_id := map_nodes.size()
		map_nodes.append({
			"id": special_id,
			"name": String(profile.get("name", "增益信标")),
			"type": NODE_SPECIAL,
			"position": special_position,
			"links": [],
			"completed": false,
			"bonus_id": String(profile.get("bonus_id", "")),
			"bonus_name": String(profile.get("bonus_name", "")),
			"bonus_description": String(profile.get("bonus_description", "")),
			"family_bias": String(profile.get("family_bias", "")),
		})
		occupied_positions.append(special_position)
		_add_link(anchor_id, special_id)


func _connect_ordered_rings(parent_ids: Array, child_ids: Array) -> void:
	for child_index in range(child_ids.size()):
		var parent_index := int(floor(float(child_index) * float(parent_ids.size()) / float(child_ids.size())))
		parent_index = clampi(parent_index, 0, parent_ids.size() - 1)
		_add_link(int(parent_ids[parent_index]), int(child_ids[child_index]))


func _add_link(a: int, b: int) -> void:
	var node_a := map_nodes[a]
	var node_b := map_nodes[b]
	var links_a: Array = node_a.get("links", [])
	var links_b: Array = node_b.get("links", [])
	if not links_a.has(b):
		links_a.append(b)
	if not links_b.has(a):
		links_b.append(a)
	node_a["links"] = links_a
	node_b["links"] = links_b
	map_nodes[a] = node_a
	map_nodes[b] = node_b


func _refresh_special_bonus_nodes() -> Dictionary:
	var activated: Array[String] = []
	var echo_routes: Array[Dictionary] = []
	for node in map_nodes:
		if String(node.get("type", "")) != NODE_SPECIAL:
			continue
		var bonus_id := String(node.get("bonus_id", ""))
		if bonus_id.is_empty() or active_special_bonus_ids.has(bonus_id):
			continue
		var node_id := int(node.get("id", -1))
		if _is_special_node_reached(node_id):
			active_special_bonus_ids.append(bonus_id)
			activated.append(bonus_id)
			_apply_special_beacon_shop_focus(node)
			echo_routes.append_array(_apply_special_beacon_echo(node))
	return {
		"activated_specials": activated,
		"beacon_echo_routes": echo_routes,
	}


func _apply_special_beacon_shop_focus(special_node: Dictionary) -> void:
	var family := _normalize_shop_family(String(special_node.get("family_bias", "")))
	if family.is_empty() or family == EquipmentCatalogScript.FAMILY_GENERAL:
		return
	shop_preferred_family = family
	shop_beacon_family = family
	shop_beacon_bonus_name = String(special_node.get("bonus_name", "")).strip_edges()
	shop_draft_initialized = false
	shop_offer_ids.clear()


func _apply_special_beacon_echo(special_node: Dictionary) -> Array[Dictionary]:
	var echo_routes: Array[Dictionary] = []
	var special_id := int(special_node.get("id", -1))
	var bonus_id := String(special_node.get("bonus_id", ""))
	var family := String(special_node.get("family_bias", ""))
	if special_id <= 0 or bonus_id.is_empty() or family.is_empty():
		return echo_routes
	var bonus_name := String(special_node.get("bonus_name", get_special_bonus_display_name(bonus_id)))
	var family_name := _get_contract_family_display_name(family)
	for raw_anchor_id in special_node.get("links", []):
		var anchor_id := int(raw_anchor_id)
		var anchor := get_map_node(anchor_id)
		if anchor.is_empty():
			continue
		for raw_target_id in anchor.get("links", []):
			var target_id := int(raw_target_id)
			if target_id <= 0 or target_id == special_id:
				continue
			var target := get_map_node(target_id)
			if target.is_empty() or bool(target.get("completed", false)):
				continue
			if String(target.get("type", "")) == NODE_SPECIAL:
				continue
			if not Dictionary(target.get("beacon_echo", {})).is_empty():
				continue
			target["beacon_echo"] = {
				"bonus_id": bonus_id,
				"bonus_name": bonus_name,
				"family_bias": family,
				"family_name": family_name,
				"equipment_bonus": BEACON_ECHO_EQUIPMENT_BONUS,
				"reward_bonus": BEACON_ECHO_REWARD_BONUS,
			}
			target["family_bias"] = family
			target["equipment_drop_chance"] = clampf(
				float(target.get("equipment_drop_chance", TIER_EQUIPMENT_DROP_CHANCES[0])) + BEACON_ECHO_EQUIPMENT_BONUS,
				0.0,
				MAX_READABLE_EQUIPMENT_DROP_CHANCE
			)
			target["reward_mult"] = float(target.get("reward_mult", 1.0)) + BEACON_ECHO_REWARD_BONUS
			_apply_route_plan_to_node(target)
			map_nodes[target_id] = target
			echo_routes.append({
				"node_id": target_id,
				"node_name": String(target.get("name", "未知航线")),
				"bonus_id": bonus_id,
				"bonus_name": bonus_name,
				"family_name": family_name,
				"equipment_bonus": BEACON_ECHO_EQUIPMENT_BONUS,
				"reward_bonus": BEACON_ECHO_REWARD_BONUS,
			})
	return echo_routes


func _is_special_node_reached(node_id: int) -> bool:
	var node := get_map_node(node_id)
	if node.is_empty() or String(node.get("type", "")) != NODE_SPECIAL:
		return false
	for linked_id in node.get("links", []):
		var id := int(linked_id)
		if id == CENTER_ID or is_node_completed(id):
			return true
	return false


func _apply_special_bonus_to_stats(stats: Dictionary, bonus_id: String) -> void:
	match bonus_id:
		"vector_supply_beacon":
			stats["speed_mult"] = float(stats.get("speed_mult", 1.0)) * 1.08
			stats["mineral_bonus"] = float(stats.get("mineral_bonus", 0.0)) + 0.12
		"colossus_charge_beacon":
			stats["dash_distance_mult"] = float(stats.get("dash_distance_mult", 1.0)) * 1.16
			stats["dash_speed_mult"] = float(stats.get("dash_speed_mult", 1.0)) * 1.08
			stats["dash_damage_mult"] = float(stats.get("dash_damage_mult", 1.0)) * 1.18
			stats["dash_aftershock_radius"] = maxf(float(stats.get("dash_aftershock_radius", 0.0)), 110.0)
			stats["dash_aftershock_damage_mult"] = maxf(float(stats.get("dash_aftershock_damage_mult", 0.0)), 0.32)
		"paradise_fire_beacon":
			stats["bullet_count"] = int(stats.get("bullet_count", 1)) + 1
			stats["spread_degrees"] = float(stats.get("spread_degrees", 0.0)) + 6.0
			stats["bullet_speed_mult"] = float(stats.get("bullet_speed_mult", 1.0)) * 1.08
			stats["bullet_split_count"] = int(stats.get("bullet_split_count", 0)) + 1
			stats["bullet_split_spread_degrees"] = maxf(float(stats.get("bullet_split_spread_degrees", 0.0)), 16.0)
			stats["bullet_split_damage_mult"] = maxf(float(stats.get("bullet_split_damage_mult", 0.0)), 0.26)
		"warped_gravity_beacon":
			stats["homing_strength"] = maxf(float(stats.get("homing_strength", 0.0)), 2.0)
			stats["homing_range"] = maxf(float(stats.get("homing_range", 0.0)), 360.0)
			stats["gravity_pull_strength"] = maxf(float(stats.get("gravity_pull_strength", 0.0)), 180.0)
			stats["gravity_pull_radius"] = maxf(float(stats.get("gravity_pull_radius", 0.0)), 190.0)
		"hell_eye_frenzy_beacon":
			stats["frenzy_gain_mult"] = float(stats.get("frenzy_gain_mult", 1.0)) * 1.2
			stats["frenzy_fire_rate_mult"] = float(stats.get("frenzy_fire_rate_mult", 1.0)) * 0.94
			stats["frenzy_damage_taken_mult"] = float(stats.get("frenzy_damage_taken_mult", 1.0)) * 0.94
			stats["frenzy_damage_mult"] = float(stats.get("frenzy_damage_mult", 1.0)) * 1.12
		"divine_drone_beacon":
			stats["drone_slots"] = int(stats.get("drone_slots", 0)) + 1
			stats["drone_fire_interval_mult"] = float(stats.get("drone_fire_interval_mult", 1.0)) * 0.9
			stats["drone_damage_mult"] = float(stats.get("drone_damage_mult", 1.0)) * 1.12
			stats["mineral_bonus"] = float(stats.get("mineral_bonus", 0.0)) + 0.06
		"ark_guard_beacon":
			stats["damage_taken_mult"] = float(stats.get("damage_taken_mult", 1.0)) * 0.9
			stats["speed_mult"] = float(stats.get("speed_mult", 1.0)) * 1.03
		"colossus_mirror_ram_beacon":
			stats["dash_distance_mult"] = float(stats.get("dash_distance_mult", 1.0)) * 1.1
			stats["dash_aftershock_radius"] = maxf(float(stats.get("dash_aftershock_radius", 0.0)), 180.0)
			stats["dash_aftershock_damage_mult"] = maxf(float(stats.get("dash_aftershock_damage_mult", 0.0)), 0.42)
		"paradise_skyline_beacon":
			stats["bullet_count"] = int(stats.get("bullet_count", 1)) + 1
			stats["bullet_speed_mult"] = float(stats.get("bullet_speed_mult", 1.0)) * 1.06
			stats["bullet_split_count"] = int(stats.get("bullet_split_count", 0)) + 1
			stats["bullet_split_spread_degrees"] = maxf(float(stats.get("bullet_split_spread_degrees", 0.0)), 24.0)
			stats["bullet_split_damage_mult"] = maxf(float(stats.get("bullet_split_damage_mult", 0.0)), 0.22)
		"warped_tide_beacon":
			stats["homing_strength"] = maxf(float(stats.get("homing_strength", 0.0)), 1.7)
			stats["homing_range"] = maxf(float(stats.get("homing_range", 0.0)), 420.0)
			stats["gravity_pull_strength"] = maxf(float(stats.get("gravity_pull_strength", 0.0)), 230.0)
			stats["gravity_pull_radius"] = maxf(float(stats.get("gravity_pull_radius", 0.0)), 260.0)
		"hell_eye_redline_beacon":
			stats["frenzy_gain_mult"] = float(stats.get("frenzy_gain_mult", 1.0)) * 1.18
			stats["frenzy_fire_rate_mult"] = float(stats.get("frenzy_fire_rate_mult", 1.0)) * 0.9
			stats["frenzy_damage_taken_mult"] = float(stats.get("frenzy_damage_taken_mult", 1.0)) * 0.9
			stats["frenzy_damage_mult"] = float(stats.get("frenzy_damage_mult", 1.0)) * 1.1
		"divine_seraph_beacon":
			stats["drone_slots"] = int(stats.get("drone_slots", 0)) + 1
			stats["drone_fire_interval_mult"] = float(stats.get("drone_fire_interval_mult", 1.0)) * 0.92
			stats["drone_damage_mult"] = float(stats.get("drone_damage_mult", 1.0)) * 1.18


func _pick_crisis_boss_scene(stage: int) -> String:
	var pools := {
		1: [
			"res://scenes/gameplay/boss/BossBattle_Frontier.tscn",
			"res://scenes/gameplay/boss/BossBattle_PeachBlossom.tscn",
			"res://scenes/gameplay/boss/BossBattle_Source.tscn",
			"res://scenes/gameplay/boss/BossBattle_Sentry.tscn",
			"res://scenes/gameplay/boss/BossBattle_ImitationAngel.tscn",
		],
		2: [
			"res://scenes/gameplay/boss/BossBattle_Heavy.tscn",
			"res://scenes/gameplay/boss/BossBattle_Utopia.tscn",
			"res://scenes/gameplay/boss/BossBattle_Spore.tscn",
			"res://scenes/gameplay/boss/BossBattle_Admin.tscn",
			"res://scenes/gameplay/boss/BossBattle_HolyBloodBrokenSword.tscn",
		],
		3: [
			"res://scenes/gameplay/boss/BossBattle_Nebula.tscn",
			"res://scenes/gameplay/boss/BossBattle_Eden.tscn",
			"res://scenes/gameplay/boss/BossBattle_Anti.tscn",
			"res://scenes/gameplay/boss/BossBattle_Gate.tscn",
			"res://scenes/gameplay/boss/BossBattle_CrystalMother.tscn",
		],
	}
	var candidates: Array = pools.get(stage, [])
	candidates.shuffle()
	for path in candidates:
		if ResourceLoader.exists(path):
			return path
	return ""


func _get_boss_family_for_scene(scene_path: String) -> String:
	var scene_families := {
		"res://scenes/gameplay/boss/BossBattle_Frontier.tscn": EquipmentCatalogScript.FAMILY_COLOSSUS,
		"res://scenes/gameplay/boss/BossBattle_Heavy.tscn": EquipmentCatalogScript.FAMILY_COLOSSUS,
		"res://scenes/gameplay/boss/BossBattle_Nebula.tscn": EquipmentCatalogScript.FAMILY_COLOSSUS,
		"res://scenes/gameplay/boss/BossBattle_PeachBlossom.tscn": EquipmentCatalogScript.FAMILY_PARADISE,
		"res://scenes/gameplay/boss/BossBattle_Utopia.tscn": EquipmentCatalogScript.FAMILY_PARADISE,
		"res://scenes/gameplay/boss/BossBattle_Eden.tscn": EquipmentCatalogScript.FAMILY_PARADISE,
		"res://scenes/gameplay/boss/BossBattle_Source.tscn": EquipmentCatalogScript.FAMILY_WARPED,
		"res://scenes/gameplay/boss/BossBattle_Spore.tscn": EquipmentCatalogScript.FAMILY_WARPED,
		"res://scenes/gameplay/boss/BossBattle_Anti.tscn": EquipmentCatalogScript.FAMILY_WARPED,
		"res://scenes/gameplay/boss/BossBattle_Sentry.tscn": EquipmentCatalogScript.FAMILY_HELL_EYE,
		"res://scenes/gameplay/boss/BossBattle_Admin.tscn": EquipmentCatalogScript.FAMILY_HELL_EYE,
		"res://scenes/gameplay/boss/BossBattle_Gate.tscn": EquipmentCatalogScript.FAMILY_HELL_EYE,
		"res://scenes/gameplay/boss/BossBattle_ImitationAngel.tscn": EquipmentCatalogScript.FAMILY_DIVINE,
		"res://scenes/gameplay/boss/BossBattle_HolyBloodBrokenSword.tscn": EquipmentCatalogScript.FAMILY_DIVINE,
		"res://scenes/gameplay/boss/BossBattle_CrystalMother.tscn": EquipmentCatalogScript.FAMILY_DIVINE,
	}
	return String(scene_families.get(scene_path, ""))
