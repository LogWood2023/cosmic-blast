class_name EquipmentCatalog
extends RefCounted

const TYPE_WEAPON: String = "weapon"
const TYPE_AUX: String = "aux"

const FAMILY_GENERAL: String = "general"
const FAMILY_COLOSSUS: String = "colossus"
const FAMILY_PARADISE: String = "paradise"
const FAMILY_WARPED: String = "warped"
const FAMILY_HELL_EYE: String = "hell_eye"
const FAMILY_DIVINE: String = "divine"

const CRISIS_EPIC_UNLOCK_LEVEL: int = 12
const CRISIS_EPIC_FULL_WEIGHT_LEVEL: int = 21
const PREFERRED_FAMILY_WEIGHT: float = 3.5
const GENERAL_FAMILY_WEIGHT: float = 1.1

static var _auxiliary_catalog_cache: Dictionary = {}

const WEAPONS: Dictionary = {
	"pulse_cannon": {
		"name": "脉冲机炮",
		"type": TYPE_WEAPON,
		"price": 0,
		"atk_bonus": 0,
		"fire_rate_mult": 1.0,
		"bullet_count": 1,
		"spread_degrees": 0.0,
		"description": "方舟核心保留下来的标准武器。",
	},
	"twin_lance": {
		"name": "双联光矛",
		"type": TYPE_WEAPON,
		"price": 35,
		"atk_bonus": 1,
		"fire_rate_mult": 1.05,
		"bullet_count": 2,
		"spread_degrees": 9.0,
		"description": "两道轻型光矛并行射击，覆盖更宽。",
	},
	"rail_spike": {
		"name": "星轨钉刺炮",
		"type": TYPE_WEAPON,
		"price": 45,
		"atk_bonus": 6,
		"fire_rate_mult": 1.35,
		"bullet_count": 1,
		"spread_degrees": 0.0,
		"description": "射速较慢，但单发伤害更高。",
	},
	"storm_array": {
		"name": "风暴阵列",
		"type": TYPE_WEAPON,
		"price": 65,
		"atk_bonus": 0,
		"fire_rate_mult": 1.15,
		"bullet_count": 3,
		"spread_degrees": 18.0,
		"description": "三联散射阵列会铺开巡逻空域的密集火线。",
	},
	"comet_shredder": {
		"name": "彗尾撕裂炮",
		"type": TYPE_WEAPON,
		"price": 80,
		"atk_bonus": 2,
		"fire_rate_mult": 0.92,
		"bullet_count": 2,
		"spread_degrees": 12.0,
		"bullet_speed_mult": 1.08,
		"description": "双发高速弹道持续咬住中距离目标。",
	},
	"prism_volley": {
		"name": "棱镜齐射器",
		"type": TYPE_WEAPON,
		"price": 92,
		"atk_bonus": 0,
		"fire_rate_mult": 1.05,
		"bullet_count": 4,
		"spread_degrees": 26.0,
		"description": "宽角散射武器把天堂号的火力网提前铺开。",
	},
	"nova_borer": {
		"name": "新星钻孔炮",
		"type": TYPE_WEAPON,
		"price": 105,
		"atk_bonus": 9,
		"fire_rate_mult": 1.55,
		"bullet_count": 1,
		"spread_degrees": 0.0,
		"bullet_speed_mult": 1.22,
		"description": "慢速高伤主炮，单点突破厚甲单位。",
	},
	"aurora_needler": {
		"name": "极光针束",
		"type": TYPE_WEAPON,
		"price": 96,
		"atk_bonus": 1,
		"fire_rate_mult": 0.72,
		"bullet_count": 1,
		"spread_degrees": 0.0,
		"description": "高频轻弹在连续命中间催热机体反应。",
	},
	"void_saw": {
		"name": "虚空锯链",
		"type": TYPE_WEAPON,
		"price": 118,
		"atk_bonus": 4,
		"fire_rate_mult": 0.86,
		"bullet_count": 2,
		"spread_degrees": 6.0,
		"homing_strength": 1.5,
		"homing_range": 300.0,
		"description": "带轻微航向修正的双联弹道，服务引力流派。",
	},
	"pulse_hail": {
		"name": "脉冲冰雹",
		"type": TYPE_WEAPON,
		"price": 72,
		"atk_bonus": 0,
		"fire_rate_mult": 0.64,
		"bullet_count": 1,
		"spread_degrees": 0.0,
		"description": "低伤高频弹雨让狂热计量稳步升温。",
	},
	"ion_carbine": {
		"name": "离子卡宾",
		"type": TYPE_WEAPON,
		"price": 58,
		"atk_bonus": 3,
		"fire_rate_mult": 0.98,
		"bullet_count": 1,
		"spread_degrees": 0.0,
		"bullet_speed_mult": 1.12,
		"description": "均衡型步枪，弹速更快，手感直接。",
	},
	"meteor_hammer": {
		"name": "陨锤炮",
		"type": TYPE_WEAPON,
		"price": 120,
		"atk_bonus": 12,
		"fire_rate_mult": 1.85,
		"bullet_count": 1,
		"spread_degrees": 0.0,
		"description": "极慢重炮在贴身冲刺后补上沉重爆发。",
	},
	"starfall_shotgun": {
		"name": "坠星霰炮",
		"type": TYPE_WEAPON,
		"price": 110,
		"atk_bonus": 1,
		"fire_rate_mult": 1.18,
		"bullet_count": 5,
		"spread_degrees": 38.0,
		"description": "近距离多弹片武器，对密集敌群效率很高。",
	},
	"graviton_piercer": {
		"name": "引力穿针",
		"type": TYPE_WEAPON,
		"price": 115,
		"atk_bonus": 5,
		"fire_rate_mult": 1.12,
		"bullet_count": 1,
		"spread_degrees": 0.0,
		"homing_strength": 2.5,
		"homing_range": 420.0,
		"description": "单发追踪弹道会在闪避航线外侧咬住目标。",
	},
	"solar_bloom": {
		"name": "日冕绽放",
		"type": TYPE_WEAPON,
		"price": 130,
		"atk_bonus": 2,
		"fire_rate_mult": 0.95,
		"bullet_count": 6,
		"spread_degrees": 42.0,
		"description": "高覆盖扇面武器，形成明亮而密集的火力墙。",
	},
	"dusk_repeater": {
		"name": "暮色连发机",
		"type": TYPE_WEAPON,
		"price": 88,
		"atk_bonus": 2,
		"fire_rate_mult": 0.68,
		"bullet_count": 1,
		"spread_degrees": 0.0,
		"bullet_speed_mult": 1.04,
		"description": "轻量连发机构保留了最干净的持续火力。",
	},
	"oracle_beam": {
		"name": "神谕束流",
		"type": TYPE_WEAPON,
		"price": 135,
		"atk_bonus": 6,
		"fire_rate_mult": 0.90,
		"bullet_count": 2,
		"spread_degrees": 4.0,
		"description": "神使系双束武器与僚机火线交错压制。",
	},
	"ember_scythe": {
		"name": "余烬镰炮",
		"type": TYPE_WEAPON,
		"price": 98,
		"atk_bonus": 4,
		"fire_rate_mult": 0.82,
		"bullet_count": 2,
		"spread_degrees": 18.0,
		"description": "斜切双弹道，覆盖移动中的小型敌机。",
	},
	"frostline_rail": {
		"name": "霜线轨炮",
		"type": TYPE_WEAPON,
		"price": 125,
		"atk_bonus": 8,
		"fire_rate_mult": 1.28,
		"bullet_count": 1,
		"spread_degrees": 0.0,
		"bullet_speed_mult": 1.35,
		"description": "高速直线轨炮会把危险单位钉在星尘里。",
	},
	"drone_command_staff": {
		"name": "僚机指挥杖",
		"type": TYPE_WEAPON,
		"price": 140,
		"atk_bonus": 1,
		"fire_rate_mult": 1.08,
		"bullet_count": 2,
		"spread_degrees": 8.0,
		"drone_slots": 1,
		"description": "牺牲部分主炮效率，换取额外无人机联动空间。",
	},
}

const AUXILIARIES: Dictionary = {
	"overclock_core": {
		"name": "超频核心",
		"type": TYPE_AUX,
		"price": 30,
		"compute_cost": 2,
		"atk_bonus": 1,
		"fire_rate_mult": 0.88,
		"speed_mult": 1.0,
		"mineral_bonus": 0.0,
		"description": "降低开火间隔，并略微提升攻击。",
	},
	"vector_thruster": {
		"name": "矢量推进副机",
		"type": TYPE_AUX,
		"price": 25,
		"compute_cost": 1,
		"atk_bonus": 0,
		"fire_rate_mult": 1.0,
		"speed_mult": 1.18,
		"mineral_bonus": 0.0,
		"description": "提升机体机动速度。",
	},
	"salvage_ai": {
		"name": "回收演算副机",
		"type": TYPE_AUX,
		"price": 40,
		"compute_cost": 2,
		"atk_bonus": 0,
		"fire_rate_mult": 1.0,
		"speed_mult": 1.0,
		"mineral_bonus": 0.25,
		"description": "成功撤离时提高矿物回收量。",
	},
	"targeting_ghost": {
		"name": "幽灵瞄准副机",
		"type": TYPE_AUX,
		"price": 55,
		"compute_cost": 3,
		"atk_bonus": 3,
		"fire_rate_mult": 0.96,
		"speed_mult": 1.0,
		"mineral_bonus": 0.0,
		"description": "提升攻击，并小幅优化射击循环。",
	},
	"choir_shard": {
		"name": "圣歌碎片副机",
		"type": TYPE_AUX,
		"price": 75,
		"compute_cost": 5,
		"atk_bonus": 2,
		"fire_rate_mult": 0.84,
		"speed_mult": 1.08,
		"mineral_bonus": 0.1,
		"description": "高算力消耗的综合强化模块。",
	},
	"colossus_impact_mirror": {
		"name": "巨构冲击镜",
		"type": TYPE_AUX,
		"price": 0,
		"compute_cost": 4,
		"family": FAMILY_COLOSSUS,
		"rarity": "boss",
		"boss_drop": true,
		"effect_id": "dash_impact_mirror",
		"dash_shield_duration": 0.9,
		"atk_bonus": 2,
		"description": "星间巨构掉落的冲刺组件，强化近身撞击和机动突进。",
	},
	"paradise_cover_matrix": {
		"name": "天堂火力矩阵",
		"type": TYPE_AUX,
		"price": 0,
		"compute_cost": 4,
		"family": FAMILY_PARADISE,
		"rarity": "boss",
		"boss_drop": true,
		"effect_id": "cover_fire_matrix",
		"atk_bonus": 1,
		"fire_rate_mult": 0.78,
		"speed_mult": 1.0,
		"mineral_bonus": 0.0,
		"bullet_count_bonus": 1,
		"spread_degrees_bonus": 10.0,
		"bullet_speed_mult": 1.18,
		"bullet_split_count": 2,
		"bullet_split_spread_degrees": 18.0,
		"bullet_split_damage_mult": 0.32,
		"description": "天堂号掉落的弹幕矩阵，显著加快射击循环。",
	},
	"warped_gravity_lens": {
		"name": "扭曲引力透镜",
		"type": TYPE_AUX,
		"price": 0,
		"compute_cost": 4,
		"family": FAMILY_WARPED,
		"rarity": "boss",
		"boss_drop": true,
		"effect_id": "gravity_lens",
		"atk_bonus": 3,
		"fire_rate_mult": 0.95,
		"speed_mult": 1.0,
		"mineral_bonus": 0.0,
		"homing_strength": 5.0,
		"homing_range": 520.0,
		"gravity_pull_strength": 240.0,
		"gravity_pull_radius": 220.0,
		"description": "扭曲星核剥落的引力镜片，会让弹道主动贴近猎物。",
	},
	"hell_eye_frenzy_iris": {
		"name": "地狱狂热虹膜",
		"type": TYPE_AUX,
		"price": 0,
		"compute_cost": 4,
		"family": FAMILY_HELL_EYE,
		"rarity": "boss",
		"boss_drop": true,
		"effect_id": "frenzy_iris",
		"atk_bonus": 1,
		"fire_rate_mult": 0.88,
		"speed_mult": 1.06,
		"mineral_bonus": 0.0,
		"frenzy_gain_mult": 1.35,
		"frenzy_fire_rate_mult": 0.82,
		"frenzy_damage_taken_mult": 0.82,
		"frenzy_damage_mult": 1.18,
		"description": "地狱之眼残留的虹膜仍在发热，狂热窗口因此更加凶险。",
	},
	"divine_drone_seed": {
		"name": "神使无人机种子",
		"type": TYPE_AUX,
		"price": 0,
		"compute_cost": 4,
		"family": FAMILY_DIVINE,
		"rarity": "boss",
		"boss_drop": true,
		"effect_id": "drone_seed",
		"drone_behavior": "shooter",
		"drone_slots": 1,
		"drone_damage_mult": 1.3,
		"description": "神明使者留下的种子会唤醒僚机群的第一声圣歌。",
	},
	"colossus_aftershock_keel": {
		"name": "巨构余震龙骨",
		"type": TYPE_AUX,
		"price": 0,
		"compute_cost": 5,
		"family": FAMILY_COLOSSUS,
		"rarity": "boss",
		"boss_drop": true,
		"boss_drop_stage": 2,
		"effect_id": "dash_aftershock_keel",
		"dash_aftershock_radius": 150.0,
		"dash_aftershock_damage_mult": 0.5,
		"atk_bonus": 3,
		"description": "龙骨把冲锋余震压回机体，折返后的撞击仍然沉重。",
	},
	"colossus_singularity_ram": {
		"name": "巨构奇点撞锤",
		"type": TYPE_AUX,
		"price": 0,
		"compute_cost": 6,
		"family": FAMILY_COLOSSUS,
		"rarity": "boss",
		"boss_drop": true,
		"boss_drop_stage": 3,
		"effect_id": "singularity_ram",
		"dash_chain": 3,
		"dash_damage_mult": 1.4,
		"description": "撞锤内部封着一枚微型坍缩核，冲锋会像重炮一样撕开航线。",
	},
	"paradise_sunburst_rack": {
		"name": "天堂日冕弹架",
		"type": TYPE_AUX,
		"price": 0,
		"compute_cost": 5,
		"family": FAMILY_PARADISE,
		"rarity": "boss",
		"boss_drop": true,
		"boss_drop_stage": 2,
		"effect_id": "sunburst_rack",
		"atk_bonus": 2,
		"fire_rate_mult": 0.74,
		"speed_mult": 1.0,
		"mineral_bonus": 0.0,
		"bullet_count_bonus": 1,
		"spread_degrees_bonus": 16.0,
		"bullet_speed_mult": 1.26,
		"bullet_split_count": 3,
		"bullet_split_spread_degrees": 26.0,
		"bullet_split_damage_mult": 0.42,
		"description": "日冕弹架会把每轮射击铺成更亮的扇面，压住整条前线。",
	},
	"paradise_heavenfall_array": {
		"name": "天堂坠光阵列",
		"type": TYPE_AUX,
		"price": 0,
		"compute_cost": 6,
		"family": FAMILY_PARADISE,
		"rarity": "boss",
		"boss_drop": true,
		"boss_drop_stage": 3,
		"effect_id": "heavenfall_array",
		"atk_bonus": 3,
		"fire_rate_mult": 0.68,
		"speed_mult": 1.0,
		"mineral_bonus": 0.0,
		"bullet_count_bonus": 2,
		"spread_degrees_bonus": 18.0,
		"bullet_speed_mult": 1.35,
		"bullet_split_count": 4,
		"bullet_split_spread_degrees": 34.0,
		"bullet_split_damage_mult": 0.52,
		"description": "阵列仍在执行天堂号最后的齐射指令，弹幕像光雨一样落下。",
	},
	"warped_event_horizon_spool": {
		"name": "星核视界线轴",
		"type": TYPE_AUX,
		"price": 0,
		"compute_cost": 5,
		"family": FAMILY_WARPED,
		"rarity": "boss",
		"boss_drop": true,
		"boss_drop_stage": 2,
		"effect_id": "event_horizon_spool",
		"atk_bonus": 4,
		"fire_rate_mult": 0.98,
		"speed_mult": 1.0,
		"mineral_bonus": 0.0,
		"homing_strength": 7.0,
		"homing_range": 620.0,
		"bullet_speed_mult": 1.12,
		"gravity_pull_strength": 360.0,
		"gravity_pull_radius": 270.0,
		"description": "线轴把弹道轻轻拽向视界边缘，猎物越远，牵引越清晰。",
	},
	"warped_gravity_well_core": {
		"name": "星核重井核心",
		"type": TYPE_AUX,
		"price": 0,
		"compute_cost": 6,
		"family": FAMILY_WARPED,
		"rarity": "boss",
		"boss_drop": true,
		"boss_drop_stage": 3,
		"effect_id": "gravity_well_core",
		"atk_bonus": 5,
		"fire_rate_mult": 0.94,
		"speed_mult": 1.0,
		"mineral_bonus": 0.0,
		"homing_strength": 9.0,
		"homing_range": 760.0,
		"bullet_speed_mult": 1.18,
		"gravity_pull_strength": 560.0,
		"gravity_pull_radius": 340.0,
		"description": "重井核心会替子弹记住敌人的质量，让躲闪变成一场缓慢坠落。",
	},
	"hell_eye_redline_crown": {
		"name": "地狱红线王冠",
		"type": TYPE_AUX,
		"price": 0,
		"compute_cost": 5,
		"family": FAMILY_HELL_EYE,
		"rarity": "boss",
		"boss_drop": true,
		"boss_drop_stage": 2,
		"effect_id": "redline_crown",
		"atk_bonus": 2,
		"fire_rate_mult": 0.86,
		"speed_mult": 1.08,
		"mineral_bonus": 0.0,
		"frenzy_gain_mult": 1.52,
		"frenzy_fire_rate_mult": 0.76,
		"frenzy_damage_taken_mult": 0.76,
		"frenzy_damage_mult": 1.32,
		"description": "王冠把红线钉进神经回路，狂热来得更快，也更难停下。",
	},
	"hell_eye_apocalypse_pupil": {
		"name": "地狱启示瞳",
		"type": TYPE_AUX,
		"price": 0,
		"compute_cost": 6,
		"family": FAMILY_HELL_EYE,
		"rarity": "boss",
		"boss_drop": true,
		"boss_drop_stage": 3,
		"effect_id": "apocalypse_pupil",
		"atk_bonus": 4,
		"fire_rate_mult": 0.82,
		"speed_mult": 1.12,
		"mineral_bonus": 0.0,
		"frenzy_gain_mult": 1.75,
		"frenzy_fire_rate_mult": 0.68,
		"frenzy_damage_taken_mult": 0.68,
		"frenzy_damage_mult": 1.52,
		"description": "瞳孔深处仍有末日倒影，狂热期会把攻防都推向红线尽头。",
	},
	"divine_seraphim_link": {
		"name": "神使炽天链路",
		"type": TYPE_AUX,
		"price": 0,
		"compute_cost": 5,
		"family": FAMILY_DIVINE,
		"rarity": "boss",
		"boss_drop": true,
		"boss_drop_stage": 2,
		"effect_id": "seraphim_link",
		"drone_behavior": "guardian",
		"drone_slots": 2,
		"description": "链路让第二组僚机听见同一段圣歌，护航火线随之展开。",
	},
	"divine_oracle_swarm_core": {
		"name": "神使蜂群圣核",
		"type": TYPE_AUX,
		"price": 0,
		"compute_cost": 6,
		"family": FAMILY_DIVINE,
		"rarity": "boss",
		"boss_drop": true,
		"boss_drop_stage": 3,
		"effect_id": "oracle_swarm_core",
		"drone_behavior": "kamikaze",
		"drone_slots": 3,
		"description": "圣核把碎裂神谕分发给整支蜂群，方舟周围会亮起新的护航轨道。",
	},
	"impact_servos": {
		"name": "冲击伺服肢",
		"type": TYPE_AUX,
		"price": 55,
		"compute_cost": 2,
		"family": FAMILY_COLOSSUS,
		"rarity": "common",
		"dash_damage_mult": 1.2,
		"description": "冲刺撞击造成更高伤害，是巨构流派的入门组件。",
	},
	"extended_ram_plate": {
		"name": "延展撞角板",
		"type": TYPE_AUX,
		"price": 62,
		"compute_cost": 3,
		"family": FAMILY_COLOSSUS,
		"rarity": "common",
		"dash_mining": 1.0,
		"description": "延长冲刺航线，让机体主动撞入敌群深处。",
	},
	"kinetic_reflector": {
		"name": "动能折返器",
		"type": TYPE_AUX,
		"price": 85,
		"compute_cost": 4,
		"family": FAMILY_COLOSSUS,
		"rarity": "rare",
		"dash_chain": 2,
		"description": "强化反弹后的动能保留，连续穿梭不再失速。",
	},
	"scatter_regulator": {
		"name": "散射调节阀",
		"type": TYPE_AUX,
		"price": 52,
		"compute_cost": 2,
		"family": FAMILY_PARADISE,
		"rarity": "common",
		"atk_bonus": 0,
		"fire_rate_mult": 0.94,
		"speed_mult": 1.0,
		"mineral_bonus": 0.0,
		"bullet_count_bonus": 1,
		"spread_degrees_bonus": 8.0,
		"description": "增加弹道数量并扩大散射角。",
	},
	"coil_accelerator": {
		"name": "线圈加速器",
		"type": TYPE_AUX,
		"price": 58,
		"compute_cost": 2,
		"family": FAMILY_PARADISE,
		"rarity": "common",
		"atk_bonus": 1,
		"fire_rate_mult": 0.96,
		"speed_mult": 1.0,
		"mineral_bonus": 0.0,
		"bullet_speed_mult": 1.18,
		"description": "提升弹速，让覆盖火力更快抵达目标。",
	},
	"barrage_clock": {
		"name": "弹幕时钟",
		"type": TYPE_AUX,
		"price": 90,
		"compute_cost": 4,
		"family": FAMILY_PARADISE,
		"rarity": "rare",
		"atk_bonus": 1,
		"fire_rate_mult": 0.82,
		"speed_mult": 1.0,
		"mineral_bonus": 0.0,
		"bullet_count_bonus": 1,
		"description": "压缩开火循环，并额外增加一条弹道。",
	},
	"gravity_threader": {
		"name": "引力穿线器",
		"type": TYPE_AUX,
		"price": 60,
		"compute_cost": 3,
		"family": FAMILY_WARPED,
		"rarity": "common",
		"atk_bonus": 1,
		"fire_rate_mult": 1.0,
		"speed_mult": 1.0,
		"mineral_bonus": 0.0,
		"homing_strength": 2.2,
		"homing_range": 360.0,
		"description": "引力线穿过弹道，轻微偏转会把火力牵向目标。",
	},
	"singularity_spool": {
		"name": "奇点线轴",
		"type": TYPE_AUX,
		"price": 82,
		"compute_cost": 4,
		"family": FAMILY_WARPED,
		"rarity": "rare",
		"atk_bonus": 2,
		"fire_rate_mult": 1.0,
		"speed_mult": 1.0,
		"mineral_bonus": 0.0,
		"homing_strength": 3.4,
		"homing_range": 460.0,
		"description": "追踪范围被进一步拉长，高速规避时仍能锁住目标。",
	},
	"tidal_calculator": {
		"name": "潮汐演算器",
		"type": TYPE_AUX,
		"price": 72,
		"compute_cost": 3,
		"family": FAMILY_WARPED,
		"rarity": "common",
		"atk_bonus": 0,
		"fire_rate_mult": 0.95,
		"speed_mult": 1.04,
		"mineral_bonus": 0.0,
		"homing_strength": 1.6,
		"homing_range": 420.0,
		"description": "把机动与追踪结合，降低瞄准压力。",
	},
	"frenzy_injector": {
		"name": "狂热注射器",
		"type": TYPE_AUX,
		"price": 56,
		"compute_cost": 2,
		"family": FAMILY_HELL_EYE,
		"rarity": "common",
		"atk_bonus": 0,
		"fire_rate_mult": 0.96,
		"speed_mult": 1.0,
		"mineral_bonus": 0.0,
		"frenzy_gain_mult": 1.22,
		"description": "灼热药剂压入循环，狂热计量更快冲上红线。",
	},
	"blood_heat_sink": {
		"name": "血热散逸片",
		"type": TYPE_AUX,
		"price": 74,
		"compute_cost": 3,
		"family": FAMILY_HELL_EYE,
		"rarity": "common",
		"atk_bonus": 1,
		"fire_rate_mult": 1.0,
		"speed_mult": 1.0,
		"mineral_bonus": 0.0,
		"frenzy_damage_taken_mult": 0.9,
		"description": "血热被散逸片重新分流，狂热中承受的冲击更低。",
	},
	"redline_metronome": {
		"name": "红线节拍器",
		"type": TYPE_AUX,
		"price": 88,
		"compute_cost": 4,
		"family": FAMILY_HELL_EYE,
		"rarity": "rare",
		"atk_bonus": 1,
		"fire_rate_mult": 0.92,
		"speed_mult": 1.03,
		"mineral_bonus": 0.0,
		"frenzy_gain_mult": 1.16,
		"frenzy_fire_rate_mult": 0.88,
		"description": "红线节拍压迫神经，狂热来得更快，火力也更急。",
	},
	"drone_hangar": {
		"name": "折叠无人机库",
		"type": TYPE_AUX,
		"price": 92,
		"compute_cost": 5,
		"family": FAMILY_DIVINE,
		"rarity": "rare",
		"drone_behavior": "shooter",
		"drone_slots": 1,
		"drone_fire_interval_mult": 0.8,
		"description": "折叠舱门在战斗中展开，额外僚机接入护航队列。",
	},
	"oracle_sync_chip": {
		"name": "神谕同步芯片",
		"type": TYPE_AUX,
		"price": 70,
		"compute_cost": 3,
		"family": FAMILY_DIVINE,
		"rarity": "common",
		"drone_behavior": "shooter",
		"drone_slots": 1,
		"atk_bonus": 1,
		"description": "轻量控制芯片会牵起第一组僚机火线。",
	},
	"wingman_protocol": {
		"name": "僚机协议",
		"type": TYPE_AUX,
		"price": 64,
		"compute_cost": 2,
		"family": FAMILY_DIVINE,
		"rarity": "common",
		"drone_behavior": "guardian",
		"drone_slots": 1,
		"description": "协议校准主机与僚机节拍，护航火线更稳。",
	},
	"mineral_sieve": {
		"name": "星髓筛分器",
		"type": TYPE_AUX,
		"price": 45,
		"compute_cost": 2,
		"family": FAMILY_GENERAL,
		"rarity": "common",
		"atk_bonus": 0,
		"fire_rate_mult": 1.0,
		"speed_mult": 1.0,
		"mineral_bonus": 0.18,
		"description": "筛分器在撤离前拦下碎矿，更多星髓被带回方舟。",
	},
	"armor_lattice": {
		"name": "装甲晶格",
		"type": TYPE_AUX,
		"price": 50,
		"compute_cost": 2,
		"family": FAMILY_GENERAL,
		"rarity": "common",
		"atk_bonus": 1,
		"fire_rate_mult": 1.02,
		"speed_mult": 0.96,
		"mineral_bonus": 0.0,
		"description": "牺牲少量机动，换取更扎实的输出结构。",
	},
	"coolant_loop": {
		"name": "冷却回路",
		"type": TYPE_AUX,
		"price": 48,
		"compute_cost": 2,
		"family": FAMILY_GENERAL,
		"rarity": "common",
		"atk_bonus": 0,
		"fire_rate_mult": 0.9,
		"speed_mult": 1.0,
		"mineral_bonus": 0.0,
		"description": "武器循环被重新冷却，开火间隔随之收紧。",
	},
	"survey_lidar": {
		"name": "勘探激光雷达",
		"type": TYPE_AUX,
		"price": 42,
		"compute_cost": 1,
		"family": FAMILY_GENERAL,
		"rarity": "common",
		"atk_bonus": 0,
		"fire_rate_mult": 1.0,
		"speed_mult": 1.04,
		"mineral_bonus": 0.1,
		"description": "激光雷达扫过碎石带，航线与矿脉信号同时变清晰。",
	},
	"ammo_compressor": {
		"name": "弹仓压缩器",
		"type": TYPE_AUX,
		"price": 76,
		"compute_cost": 3,
		"family": FAMILY_GENERAL,
		"rarity": "rare",
		"atk_bonus": 2,
		"fire_rate_mult": 0.94,
		"speed_mult": 1.0,
		"mineral_bonus": 0.0,
		"description": "压缩器把弹仓余量挤回炮膛，主炮输出更扎实。",
	},
	"navigation_daemon": {
		"name": "导航守护进程",
		"type": TYPE_AUX,
		"price": 68,
		"compute_cost": 3,
		"family": FAMILY_GENERAL,
		"rarity": "common",
		"atk_bonus": 0,
		"fire_rate_mult": 1.0,
		"speed_mult": 1.14,
		"mineral_bonus": 0.0,
		"description": "导航线程守住逃生航线，机体速度更利落。",
	},
	"field_balancer": {
		"name": "力场平衡器",
		"type": TYPE_AUX,
		"price": 84,
		"compute_cost": 4,
		"family": FAMILY_GENERAL,
		"rarity": "rare",
		"atk_bonus": 1,
		"fire_rate_mult": 0.96,
		"speed_mult": 1.06,
		"mineral_bonus": 0.08,
		"description": "平衡器压平力场噪声，武器、引擎与回收链路一同顺畅。",
	},
	"risk_ledger": {
		"name": "危机账本",
		"type": TYPE_AUX,
		"price": 95,
		"compute_cost": 4,
		"family": FAMILY_GENERAL,
		"rarity": "rare",
		"atk_bonus": 3,
		"fire_rate_mult": 1.0,
		"speed_mult": 1.0,
		"mineral_bonus": 0.16,
		"description": "账本只记录危险航线，越靠近危机，回报越沉。",
	},
	"phase_bootloader": {
		"name": "相位启动器",
		"type": TYPE_AUX,
		"price": 78,
		"compute_cost": 3,
		"family": FAMILY_COLOSSUS,
		"rarity": "rare",
		"dash_rebound_bonus": 0.28,
		"description": "相位脉冲先一步点亮航线，冲刺距离与撞击余威同时拉高。",
	},
	"cache_diviner": {
		"name": "缓存占卜器",
		"type": TYPE_AUX,
		"price": 66,
		"compute_cost": 2,
		"family": FAMILY_GENERAL,
		"rarity": "common",
		"atk_bonus": 0,
		"fire_rate_mult": 1.0,
		"speed_mult": 1.03,
		"mineral_bonus": 0.14,
		"description": "缓存信号在暗区提前浮现，矿脉回收更有把握。",
	},
}

const AUXILIARY_EXPANSION_ROWS: Array[Dictionary] = [
	{"id": "colossus_impact_coil", "name": "巨构冲击线圈", "family": FAMILY_COLOSSUS, "rarity": "common", "price": 68, "compute_cost": 2, "description": "短促脉冲灌入撞角，冲锋落点会炸出更硬的火花。", "stats": {"dash_damage_mult": 1.14}},
	{"id": "colossus_ramming_keel", "name": "巨构撞击龙骨", "family": FAMILY_COLOSSUS, "rarity": "common", "price": 74, "compute_cost": 3, "description": "加长舰首受力线，反弹时机体仍能稳住航向。", "stats": {"dash_rebound_bonus": 0.2}},
	{"id": "colossus_phase_anchor", "name": "巨构相位锚", "family": FAMILY_COLOSSUS, "rarity": "rare", "price": 118, "compute_cost": 5, "description": "厚重相位锚锁住冲锋瞬间，让无伤窗口拖得更长。", "stats": {"dash_trail_damage_mult": 0.35}},
	{"id": "colossus_afterburner_vane", "name": "巨构尾焰导叶", "family": FAMILY_COLOSSUS, "rarity": "common", "price": 86, "compute_cost": 3, "description": "尾焰导叶切开撤出角，冲锋后立刻接上下一段机动。", "stats": {"dash_shield_duration": 0.4}},
	{"id": "colossus_kinetic_battery", "name": "巨构动能电池", "family": FAMILY_COLOSSUS, "rarity": "rare", "price": 126, "compute_cost": 5, "description": "撞击余波被封进电池，下一次突进会更沉。", "stats": {"dash_aftershock_radius": 110.0, "dash_aftershock_damage_mult": 0.35}},
	{"id": "colossus_rebound_gyros", "name": "巨构折返陀螺", "family": FAMILY_COLOSSUS, "rarity": "common", "price": 82, "compute_cost": 3, "description": "陀螺仪校准镜面反弹，擦过墙体与敌甲后依旧利落。", "stats": {"dash_aftershock_radius": 85.0, "dash_aftershock_damage_mult": 0.25}},
	{"id": "colossus_crash_recorder", "name": "巨构撞击记录仪", "family": FAMILY_COLOSSUS, "rarity": "rare", "price": 135, "compute_cost": 4, "description": "记录仪复写最近的碰撞矢量，下一条冲锋线更凶。", "stats": {"dash_chain": 1, "dash_damage_mult": 1.15}},
	{"id": "colossus_titan_piston", "name": "巨构泰坦活塞", "family": FAMILY_COLOSSUS, "rarity": "epic", "price": 168, "compute_cost": 6, "description": "巨型活塞在机腹下咆哮，正面撞击像落锤砸穿护甲。", "stats": {"dash_trail_damage_mult": 0.5, "atk_bonus": 3}},
	{"id": "colossus_vector_plow", "name": "巨构矢量犁", "family": FAMILY_COLOSSUS, "rarity": "common", "price": 70, "compute_cost": 2, "description": "低耗鼻阵撬开短程冲锋，让每一次贴脸都更痛。", "stats": {"dash_damage_mult": 1.18}},
	{"id": "colossus_guarded_charge", "name": "巨构护航冲锋核", "family": FAMILY_COLOSSUS, "rarity": "rare", "price": 142, "compute_cost": 5, "description": "护航算法压低偏航，速度、距离与撞击稳定性一并抬升。", "stats": {"dash_rebound_bonus": 0.4}},
	{"id": "colossus_shear_boots", "name": "巨构剪切推进靴", "family": FAMILY_COLOSSUS, "rarity": "common", "price": 78, "compute_cost": 3, "description": "推进靴从敌阵侧翼刮过，留下又快又锐的切线。", "stats": {"dash_trail_damage_mult": 0.22}},
	{"id": "colossus_momentum_vault", "name": "巨构动量库", "family": FAMILY_COLOSSUS, "rarity": "epic", "price": 182, "compute_cost": 7, "description": "庞大动量舱持续蓄压，整架机体像一枚迟来的攻城弹。", "stats": {"dash_shield_duration": 0.6}},

	{"id": "paradise_splitter_board", "name": "天堂分流板", "family": FAMILY_PARADISE, "rarity": "common", "price": 76, "compute_cost": 2, "description": "分流板把主炮拆成更多弹线，前方空域被迅速填满。", "stats": {"bullet_count_bonus": 1, "spread_degrees_bonus": 6.0}},
	{"id": "paradise_rapid_breech", "name": "天堂速射炮闩", "family": FAMILY_PARADISE, "rarity": "common", "price": 82, "compute_cost": 3, "description": "炮闩压缩循环，覆盖火力一轮接着一轮落下。", "stats": {"fire_rate_mult": 0.9}},
	{"id": "paradise_tracer_fan", "name": "天堂曳光扇", "family": FAMILY_PARADISE, "rarity": "common", "price": 88, "compute_cost": 3, "description": "曳光扇张开更宽弹幕，弹速仍保持干净利落。", "stats": {"spread_degrees_bonus": 12.0, "bullet_speed_mult": 1.08}},
	{"id": "paradise_pressure_chamber", "name": "天堂增压膛", "family": FAMILY_PARADISE, "rarity": "rare", "price": 124, "compute_cost": 4, "description": "膛压被抬高，齐射更硬，弹流更快。", "stats": {"atk_bonus": 2, "bullet_speed_mult": 1.16}},
	{"id": "paradise_salvo_kernel", "name": "天堂齐射核心", "family": FAMILY_PARADISE, "rarity": "rare", "price": 138, "compute_cost": 5, "description": "核心支撑更大的弹幕帷幕，开火节奏也被重新拉紧。", "stats": {"bullet_count_bonus": 1, "fire_rate_mult": 0.94, "spread_degrees_bonus": 10.0}},
	{"id": "paradise_skyline_magazine", "name": "天堂天际弹仓", "family": FAMILY_PARADISE, "rarity": "common", "price": 92, "compute_cost": 3, "description": "弹仓沿天际线铺弹，整片屏幕被干净火线切开。", "stats": {"bullet_speed_mult": 1.12, "fire_rate_mult": 0.96}},
	{"id": "paradise_cascade_nozzle", "name": "天堂瀑流喷口", "family": FAMILY_PARADISE, "rarity": "rare", "price": 146, "compute_cost": 5, "description": "持续射击会扩成瀑流，弹幕一层压过一层。", "stats": {"bullet_count_bonus": 1, "spread_degrees_bonus": 16.0}},
	{"id": "paradise_starfall_clock", "name": "天堂坠星钟", "family": FAMILY_PARADISE, "rarity": "epic", "price": 174, "compute_cost": 6, "description": "坠星钟校准齐射时序，密集弹雨像准点落下的审判。", "stats": {"fire_rate_mult": 0.82, "bullet_speed_mult": 1.1, "spread_degrees_bonus": 8.0}},
	{"id": "paradise_halo_lattice", "name": "天堂光环晶格", "family": FAMILY_PARADISE, "rarity": "common", "price": 78, "compute_cost": 2, "description": "轻型晶格微调火线，低耗也能铺出明亮弹幕。", "stats": {"fire_rate_mult": 0.95, "spread_degrees_bonus": 4.0}},
	{"id": "paradise_orbital_rake", "name": "天堂轨道耙", "family": FAMILY_PARADISE, "rarity": "rare", "price": 132, "compute_cost": 4, "description": "轨道耙扫过前弧，弹扇按规整间距掠过敌群。", "stats": {"bullet_count_bonus": 1, "fire_rate_mult": 0.98}},
	{"id": "paradise_plasma_conductor", "name": "天堂等离子导体", "family": FAMILY_PARADISE, "rarity": "common", "price": 84, "compute_cost": 3, "description": "导体加快等离子输送，原本的武器手感依旧清晰。", "stats": {"atk_bonus": 1, "bullet_speed_mult": 1.14}},
	{"id": "paradise_burst_synchronizer", "name": "天堂爆发同步器", "family": FAMILY_PARADISE, "rarity": "epic", "price": 188, "compute_cost": 7, "description": "同步器把爆发火力拧成一束，重型弹幕瞬间倾泻。", "stats": {"bullet_count_bonus": 1, "fire_rate_mult": 0.86, "bullet_speed_mult": 1.18}},

	{"id": "warped_seek_processor", "name": "扭曲索敌处理器", "family": FAMILY_WARPED, "rarity": "common", "price": 78, "compute_cost": 2, "description": "处理器提前读出目标偏转，弯曲弹道开始寻找猎物。", "stats": {"homing_strength": 1.8, "homing_range": 320.0}},
	{"id": "warped_orbit_compass", "name": "扭曲轨道罗盘", "family": FAMILY_WARPED, "rarity": "common", "price": 86, "compute_cost": 3, "description": "轨道罗盘贴着闪避航线旋转，追踪弹不会轻易丢失目标。", "stats": {"speed_mult": 1.03, "homing_strength": 2.0, "homing_range": 360.0}},
	{"id": "warped_tide_hook", "name": "扭曲潮汐钩", "family": FAMILY_WARPED, "rarity": "rare", "price": 128, "compute_cost": 4, "description": "潮汐钩抓住中程质量影，弹道被更强的引力拖回去。", "stats": {"homing_strength": 3.0, "homing_range": 460.0}},
	{"id": "warped_mass_marker", "name": "扭曲质量标记器", "family": FAMILY_WARPED, "rarity": "common", "price": 92, "compute_cost": 3, "description": "高质量目标被悄悄标亮，修正弹道因此更干净。", "stats": {"atk_bonus": 1, "homing_strength": 2.3, "homing_range": 390.0}},
	{"id": "warped_echo_lens", "name": "扭曲回声透镜", "family": FAMILY_WARPED, "rarity": "rare", "price": 136, "compute_cost": 5, "description": "透镜折回目标回声，追踪与弹速一同被推高。", "stats": {"bullet_speed_mult": 1.12, "homing_strength": 3.4, "homing_range": 500.0}},
	{"id": "warped_curve_predictor", "name": "扭曲曲线预言器", "family": FAMILY_WARPED, "rarity": "common", "price": 80, "compute_cost": 2, "description": "廉价预言器描出弧线落点，轻弹也会微微转头。", "stats": {"homing_strength": 1.6, "homing_range": 340.0}},
	{"id": "warped_null_sleeve", "name": "扭曲虚无套筒", "family": FAMILY_WARPED, "rarity": "rare", "price": 142, "compute_cost": 5, "description": "虚无套筒稳定远端弹道，越过混乱空域仍能保持牵引。", "stats": {"bullet_speed_mult": 1.1, "homing_range": 560.0}},
	{"id": "warped_pulse_snare", "name": "扭曲脉冲索套", "family": FAMILY_WARPED, "rarity": "rare", "price": 150, "compute_cost": 5, "description": "脉冲索套圈住聚集敌影，连射弹流会向中心收束。", "stats": {"fire_rate_mult": 0.94, "homing_strength": 3.1, "homing_range": 470.0}},
	{"id": "warped_magnetar_seed", "name": "扭曲磁星种子", "family": FAMILY_WARPED, "rarity": "epic", "price": 176, "compute_cost": 6, "description": "高密度种子在弹道里醒来，敌群被看不见的手拖住。", "stats": {"atk_bonus": 2, "homing_strength": 4.0, "homing_range": 540.0}},
	{"id": "warped_lensing_core", "name": "扭曲透镜核心", "family": FAMILY_WARPED, "rarity": "common", "price": 88, "compute_cost": 3, "description": "小型核心弯折慢弹，让迟到的火力也能追上猎物。", "stats": {"homing_strength": 2.4, "homing_range": 420.0}},
	{"id": "warped_gravity_wake", "name": "扭曲引力尾迹", "family": FAMILY_WARPED, "rarity": "rare", "price": 154, "compute_cost": 5, "description": "稳定尾迹留在航线之后，后续弹道借势继续偏转。", "stats": {"speed_mult": 1.04, "homing_strength": 3.3, "homing_range": 510.0}},
	{"id": "warped_event_harpoon", "name": "扭曲事件鱼叉", "family": FAMILY_WARPED, "rarity": "epic", "price": 190, "compute_cost": 7, "description": "事件鱼叉刺穿概率薄层，远处目标也被强行拽进准星。", "stats": {"atk_bonus": 2, "bullet_speed_mult": 1.16, "homing_strength": 4.5, "homing_range": 620.0}},

	{"id": "hell_eye_heat_credit", "name": "地狱热债凭证", "family": FAMILY_HELL_EYE, "rarity": "common", "price": 76, "compute_cost": 2, "description": "每一次交火都会记下一笔热债，狂热槽随之更快升温。", "stats": {"frenzy_gain_mult": 1.12}},
	{"id": "hell_eye_adrenal_pump", "name": "地狱肾上腺泵", "family": FAMILY_HELL_EYE, "rarity": "common", "price": 84, "compute_cost": 3, "description": "泵体把灼热信号压进血线，爆发窗口来得更可靠。", "stats": {"speed_mult": 1.03, "frenzy_gain_mult": 1.16}},
	{"id": "hell_eye_red_suture", "name": "地狱红缝线", "family": FAMILY_HELL_EYE, "rarity": "rare", "price": 128, "compute_cost": 4, "description": "红缝线封住裂口，狂热中仍保留凶狠攻势。", "stats": {"atk_bonus": 1, "frenzy_damage_taken_mult": 0.88}},
	{"id": "hell_eye_fever_clock", "name": "地狱热病钟", "family": FAMILY_HELL_EYE, "rarity": "common", "price": 90, "compute_cost": 3, "description": "齿轮按热病节拍咬合，短促爆发会更频繁地响起。", "stats": {"frenzy_gain_mult": 1.14, "frenzy_fire_rate_mult": 0.94}},
	{"id": "hell_eye_ember_limiter", "name": "地狱余烬限幅器", "family": FAMILY_HELL_EYE, "rarity": "rare", "price": 138, "compute_cost": 5, "description": "限幅器锁住余烬流失，狂热防线被烧得更亮。", "stats": {"frenzy_gain_mult": 1.1, "frenzy_damage_taken_mult": 0.86}},
	{"id": "hell_eye_pain_index", "name": "地狱痛觉索引", "family": FAMILY_HELL_EYE, "rarity": "common", "price": 82, "compute_cost": 2, "description": "来袭压力被编进索引，疼痛转化成更稳定的热量。", "stats": {"frenzy_gain_mult": 1.18}},
	{"id": "hell_eye_iris_cache", "name": "地狱虹膜缓存", "family": FAMILY_HELL_EYE, "rarity": "rare", "price": 146, "compute_cost": 5, "description": "虹膜缓存保留热反应曲线，爆发窗口被拉得更亮。", "stats": {"atk_bonus": 1, "frenzy_gain_mult": 1.18, "frenzy_fire_rate_mult": 0.9}},
	{"id": "hell_eye_blood_meter", "name": "地狱血温计", "family": FAMILY_HELL_EYE, "rarity": "common", "price": 88, "compute_cost": 3, "description": "血温计盯住每次伤害交换，热值一格格顶上去。", "stats": {"frenzy_gain_mult": 1.2}},
	{"id": "hell_eye_overheat_spur", "name": "地狱过热马刺", "family": FAMILY_HELL_EYE, "rarity": "epic", "price": 174, "compute_cost": 6, "description": "过热马刺刺进引擎，狂热射速被逼到危险边缘。", "stats": {"fire_rate_mult": 0.96, "frenzy_fire_rate_mult": 0.82}},
	{"id": "hell_eye_frenzy_relay", "name": "地狱狂热继电器", "family": FAMILY_HELL_EYE, "rarity": "rare", "price": 152, "compute_cost": 5, "description": "继电器把狂热信号分给武器与护盾，攻防都带着红光。", "stats": {"atk_bonus": 2, "frenzy_damage_taken_mult": 0.9}},
	{"id": "hell_eye_wound_chorus", "name": "地狱创口合唱", "family": FAMILY_HELL_EYE, "rarity": "common", "price": 94, "compute_cost": 3, "description": "连续创口合成稳定节拍，机体在痛感里加速。", "stats": {"frenzy_gain_mult": 1.15, "speed_mult": 1.04}},
	{"id": "hell_eye_last_stand_logic", "name": "地狱背水逻辑", "family": FAMILY_HELL_EYE, "rarity": "epic", "price": 196, "compute_cost": 7, "description": "背水逻辑接管临界状态，越逼近失控越能压出火力。", "stats": {"atk_bonus": 2, "frenzy_gain_mult": 1.24, "frenzy_fire_rate_mult": 0.86, "frenzy_damage_taken_mult": 0.86}},

	{"id": "divine_wingman_bus", "name": "神使僚机总线", "family": FAMILY_DIVINE, "rarity": "common", "price": 86, "compute_cost": 3, "description": "总线拓宽指令带宽，第一架僚机会更快回应呼唤。", "stats": {"drone_behavior": "shooter", "drone_slots": 1}},
	{"id": "divine_swarm_router", "name": "神使蜂群路由器", "family": FAMILY_DIVINE, "rarity": "rare", "price": 138, "compute_cost": 5, "description": "路由器把僚机指令散入战场边缘，友军火线覆盖得更远。", "stats": {"drone_behavior": "shooter", "drone_slots": 1, "drone_damage_mult": 1.15}},
	{"id": "divine_oracle_port", "name": "神使神谕端口", "family": FAMILY_DIVINE, "rarity": "common", "price": 80, "compute_cost": 2, "description": "低耗端口点亮神谕回路，护航火力从此接入主机。", "stats": {"drone_behavior": "medic", "drone_slots": 1}},
	{"id": "divine_repair_familiar", "name": "神使修复使魔", "family": FAMILY_DIVINE, "rarity": "rare", "price": 132, "compute_cost": 4, "description": "修复使魔盘旋在侧，矿石回收与僚机链路一同稳定下来。", "stats": {"drone_behavior": "medic", "drone_slots": 1, "drone_heal_amount": 7.0}},
	{"id": "divine_lantern_node", "name": "神使灯塔节点", "family": FAMILY_DIVINE, "rarity": "common", "price": 92, "compute_cost": 3, "description": "灯塔节点牵住僚机方位，急转闪避时队形仍不散。", "stats": {"drone_behavior": "guardian", "drone_slots": 1}},
	{"id": "divine_auto_hangar", "name": "神使自动机库", "family": FAMILY_DIVINE, "rarity": "epic", "price": 184, "compute_cost": 7, "description": "沉重机库自行开闸，更多僚机从冷光里滑出。", "stats": {"drone_behavior": "shooter", "drone_slots": 2}},
	{"id": "divine_choir_protocol", "name": "神使圣歌协议", "family": FAMILY_DIVINE, "rarity": "rare", "price": 146, "compute_cost": 5, "description": "圣歌协议同步主炮与僚机节拍，火线像合唱一样落下。", "stats": {"drone_behavior": "guardian", "drone_slots": 1, "drone_shield_radius": 300.0}},
	{"id": "divine_remote_gunner", "name": "神使遥控炮手", "family": FAMILY_DIVINE, "rarity": "common", "price": 96, "compute_cost": 3, "description": "遥控炮手守住侧翼，护航火力变得更直接。", "stats": {"drone_behavior": "shooter", "drone_slots": 1, "atk_bonus": 2}},
	{"id": "divine_seed_vault", "name": "神使种子舱", "family": FAMILY_DIVINE, "rarity": "rare", "price": 150, "compute_cost": 5, "description": "种子舱保留额外僚机胚核，漫长航线也不会失去护卫。", "stats": {"drone_behavior": "miner", "drone_slots": 1, "mineral_bonus": 0.1, "drone_mining_radius": 280.0}},
	{"id": "divine_tactical_nest", "name": "神使战术巢", "family": FAMILY_DIVINE, "rarity": "epic", "price": 172, "compute_cost": 6, "description": "战术巢在机体外侧展开，友军火力覆盖成环。", "stats": {"drone_behavior": "medic", "drone_slots": 1}},
	{"id": "divine_pulse_familiar", "name": "神使脉冲使魔", "family": FAMILY_DIVINE, "rarity": "common", "price": 84, "compute_cost": 2, "description": "轻型使魔信号跟随机体脉冲，移动时也能稳住护航节拍。", "stats": {"drone_behavior": "kamikaze", "drone_slots": 1}},
	{"id": "divine_companion_kernel", "name": "神使伴星核心", "family": FAMILY_DIVINE, "rarity": "rare", "price": 158, "compute_cost": 5, "description": "伴星核心放大友军火力，僚机群的回应更有分量。", "stats": {"drone_behavior": "kamikaze", "drone_slots": 1, "drone_blast_damage_mult": 1.4}},

	{"id": "general_contract_scanner", "name": "契约扫描仪", "family": FAMILY_GENERAL, "rarity": "common", "price": 72, "compute_cost": 2, "description": "扫描仪提前读出航路契约，回收价值浮现在暗区边缘。", "stats": {"mineral_bonus": 0.12}},
	{"id": "general_supply_predictor", "name": "补给预报器", "family": FAMILY_GENERAL, "rarity": "common", "price": 84, "compute_cost": 3, "description": "预报器标出下一段补给潮，机动与回收都更从容。", "stats": {"speed_mult": 1.04, "mineral_bonus": 0.1}},
	{"id": "general_stability_chip", "name": "稳定芯片", "family": FAMILY_GENERAL, "rarity": "common", "price": 78, "compute_cost": 2, "description": "朴素芯片压住系统噪声，武器与引擎都多了一点余量。", "stats": {"atk_bonus": 1, "speed_mult": 1.03}},
	{"id": "general_salvage_ledger", "name": "回收账本", "family": FAMILY_GENERAL, "rarity": "rare", "price": 118, "compute_cost": 4, "description": "账本记下每条航线的损耗，撤离时总能多带回一些星髓。", "stats": {"atk_bonus": 1, "mineral_bonus": 0.16}},
	{"id": "general_microfoundry", "name": "微型铸炉", "family": FAMILY_GENERAL, "rarity": "rare", "price": 126, "compute_cost": 4, "description": "随舰铸炉吞下碎矿与废热，转而喂给武器回路。", "stats": {"atk_bonus": 2, "fire_rate_mult": 0.98, "mineral_bonus": 0.08}},
	{"id": "colossus_quarry_mandrel", "name": "巨构采场心轴", "family": FAMILY_COLOSSUS, "rarity": "rare", "price": 156, "compute_cost": 5, "description": "心轴把矿脉震成细亮裂纹，冲锋撞击会带出更厚的星髓。", "stats": {"dash_mining": 1.0, "mineral_bonus": 0.12}},
	{"id": "colossus_orebreaker_keel", "name": "巨构碎矿龙骨", "family": FAMILY_COLOSSUS, "rarity": "epic", "price": 206, "compute_cost": 7, "description": "重型龙骨专为硬矿和装甲而生，长距离冲锋会把航路犁开。", "stats": {"dash_mining": 1.0, "mineral_bonus": 0.16}},
	{"id": "paradise_mining_barrage", "name": "天堂采矿弹幕", "family": FAMILY_PARADISE, "rarity": "rare", "price": 150, "compute_cost": 5, "description": "密集弹幕像蓝白雨线落下，矿壳和敌阵一起被剥开。", "stats": {"mineral_bonus": 0.1, "bullet_count_bonus": 1, "spread_degrees_bonus": 8.0}},
	{"id": "paradise_lumen_belt", "name": "天堂辉流弹带", "family": FAMILY_PARADISE, "rarity": "epic", "price": 198, "compute_cost": 6, "description": "辉流弹带穿过矿尘仍不失速，明亮弹线把回收点逐一照亮。", "stats": {"mineral_bonus": 0.14, "bullet_speed_mult": 1.18, "fire_rate_mult": 0.92}},
	{"id": "warped_quarry_lens", "name": "扭曲采场透镜", "family": FAMILY_WARPED, "rarity": "rare", "price": 158, "compute_cost": 5, "description": "透镜折弯矿尘的质量影，松散碎矿会被拖回弹道中心。", "stats": {"mineral_bonus": 0.12, "gravity_pull_strength": 480.0, "gravity_pull_radius": 230.0}},
	{"id": "warped_treasure_orbit", "name": "扭曲珍藏轨环", "family": FAMILY_WARPED, "rarity": "epic", "price": 212, "compute_cost": 7, "description": "轨环绕着高价值目标低声旋转，追踪火力会替你咬住暗处矿光。", "stats": {"mineral_bonus": 0.15, "homing_strength": 4.2, "homing_range": 580.0, "bullet_speed_mult": 1.1}},
	{"id": "hell_eye_molten_ledger", "name": "地狱熔账", "family": FAMILY_HELL_EYE, "rarity": "rare", "price": 152, "compute_cost": 5, "description": "熔账吞下每一次伤痛和收获，狂热升温时回收链也烧得更亮。", "stats": {"mineral_bonus": 0.1, "frenzy_gain_mult": 1.2, "frenzy_damage_taken_mult": 0.94}},
	{"id": "hell_eye_redline_collector", "name": "地狱红线收集器", "family": FAMILY_HELL_EYE, "rarity": "epic", "price": 204, "compute_cost": 6, "description": "红线越过安全刻度，狂热火力会把矿尘熔成可带走的星髓。", "stats": {"mineral_bonus": 0.14, "frenzy_damage_mult": 1.18, "frenzy_fire_rate_mult": 0.9}},
	{"id": "divine_salvage_squadron", "name": "神使回收中队", "family": FAMILY_DIVINE, "rarity": "rare", "price": 164, "compute_cost": 5, "description": "小队在主机身侧展开，护航火线会顺手标定散落矿光。", "stats": {"drone_behavior": "miner", "drone_slots": 1, "drone_mining_radius": 380.0, "mineral_bonus": 0.11}},
	{"id": "divine_foundry_companion", "name": "神使铸炉伴星", "family": FAMILY_DIVINE, "rarity": "epic", "price": 218, "compute_cost": 7, "description": "伴星拖着细小铸炉巡航，友军射击间隔被压低，碎矿也被及时收拢。", "stats": {"drone_behavior": "miner", "drone_slots": 1, "mineral_bonus": 0.16, "drone_mining_radius": 400.0}},
	{"id": "general_ore_beacon_array", "name": "矿脉信标阵列", "family": FAMILY_GENERAL, "rarity": "rare", "price": 136, "compute_cost": 4, "description": "信标阵列在暗区边缘点亮矿脉回声，撤离航线因此更轻快。", "stats": {"mineral_bonus": 0.18, "speed_mult": 1.05}},
	{"id": "general_extraction_cradle", "name": "撤离摇篮", "family": FAMILY_GENERAL, "rarity": "epic", "price": 188, "compute_cost": 6, "description": "摇篮稳住货舱与主炮供能，带着满仓星髓离场时仍能开火。", "stats": {"mineral_bonus": 0.2, "atk_bonus": 2, "speed_mult": 1.02}},
]


static func get_item(id: String) -> Dictionary:
	var item := _get_item_ref(id).duplicate(true)
	if item.is_empty():
		return {}
	if not item.has("icon"):
		item["icon"] = "res://assets/images/equipment/%s.png" % id
	return item


static func has_item(id: String) -> bool:
	return WEAPONS.has(id) or _get_auxiliary_catalog().has(id)


static func get_type(id: String) -> String:
	return String(get_item(id).get("type", ""))


static func get_display_name(id: String) -> String:
	return String(get_item(id).get("name", id))


static func get_price(id: String) -> int:
	return int(_get_item_ref(id).get("price", 0))


static func get_compute_cost(id: String) -> int:
	return int(_get_item_ref(id).get("compute_cost", 0))


static func get_family(id: String) -> String:
	return String(_get_item_ref(id).get("family", FAMILY_GENERAL))


static func get_rarity(id: String) -> String:
	return String(_get_item_ref(id).get("rarity", "common"))


static func get_family_display_name(family: String) -> String:
	match family:
		FAMILY_COLOSSUS:
			return "星间巨构"
		FAMILY_PARADISE:
			return "天堂号"
		FAMILY_WARPED:
			return "扭曲星核"
		FAMILY_HELL_EYE:
			return "地狱之眼"
		FAMILY_DIVINE:
			return "神明使者"
	return "通用"


static func get_boss_family_ids() -> Array[String]:
	return [
		FAMILY_COLOSSUS,
		FAMILY_PARADISE,
		FAMILY_WARPED,
		FAMILY_HELL_EYE,
		FAMILY_DIVINE,
	]


static func get_rarity_display_name(rarity: String) -> String:
	match rarity:
		"rare":
			return "稀有"
		"epic":
			return "史诗"
		"boss":
			return "遗物"
	return "普通"


static func is_boss_drop(id: String) -> bool:
	return bool(_get_item_ref(id).get("boss_drop", false))


static func get_effect_id(id: String) -> String:
	return String(_get_item_ref(id).get("effect_id", ""))


static func get_boss_drop_stage(id: String) -> int:
	return int(_get_item_ref(id).get("boss_drop_stage", 1))


static func get_weapon_item_ids() -> Array[String]:
	var ids: Array[String] = []
	for id in WEAPONS.keys():
		ids.append(String(id))
	return ids


static func get_auxiliary_item_ids(include_boss_drops: bool = true) -> Array[String]:
	var ids: Array[String] = []
	for id in _get_auxiliary_catalog().keys():
		var item_id := String(id)
		if include_boss_drops or not is_boss_drop(item_id):
			ids.append(item_id)
	return ids


static func get_shop_item_ids() -> Array[String]:
	var ids: Array[String] = []
	for id in get_weapon_item_ids():
		if id != "pulse_cannon":
			ids.append(id)
	for id in get_auxiliary_item_ids(false):
		ids.append(id)
	return ids


static func get_loot_item_ids() -> Array[String]:
	var ids: Array[String] = []
	for id in get_shop_item_ids():
		if get_price(id) > 0:
			ids.append(id)
	return ids


static func get_shop_offer_item_ids(owned_ids: Array, crisis_level: int = 0, preferred_family: String = "", offer_count: int = 12, seed: int = -1) -> Array[String]:
	var candidates := _get_progression_candidates(get_shop_item_ids(), owned_ids, crisis_level)
	var offers := _pick_weighted_unique(candidates, maxi(0, offer_count), crisis_level, preferred_family, seed)
	_ensure_shop_family_variety(offers, candidates, crisis_level, preferred_family, seed)
	_ensure_late_epic_offer(offers, candidates, crisis_level, seed)
	return offers


static func get_mineral_shop_offer_item_ids(owned_ids: Array, crisis_level: int = 0, preferred_family: String = "", offer_count: int = 8, seed: int = -1) -> Array[String]:
	var candidates: Array[String] = []
	for item_id in _get_progression_candidates(get_shop_item_ids(), owned_ids, crisis_level):
		if float(_get_item_ref(item_id).get("mineral_bonus", 0.0)) <= 0.0:
			continue
		candidates.append(item_id)
	if candidates.is_empty():
		return []
	return _pick_weighted_unique(candidates, maxi(0, offer_count), crisis_level, preferred_family, seed)


static func get_random_loot_item_id(owned_ids: Array, crisis_level: int = 0, preferred_family: String = "", seed: int = -1) -> String:
	var candidates := _get_progression_candidates(get_loot_item_ids(), owned_ids, crisis_level)
	if candidates.is_empty():
		candidates = _get_progression_candidates(get_loot_item_ids(), [], crisis_level)
	var picked := _pick_weighted_unique(candidates, 1, crisis_level, preferred_family, seed)
	if not picked.is_empty():
		return picked[0]
	return "pulse_cannon"


static func get_random_family_loot_item_id(owned_ids: Array, crisis_level: int = 0, family: String = "", seed: int = -1) -> String:
	if family.is_empty():
		return get_random_loot_item_id(owned_ids, crisis_level, "", seed)
	var candidates := _get_progression_candidates(get_loot_item_ids(), owned_ids, crisis_level)
	var family_candidates: Array[String] = []
	for item_id in candidates:
		if get_family(item_id) == family:
			family_candidates.append(item_id)
	if family_candidates.is_empty():
		return get_random_loot_item_id(owned_ids, crisis_level, family, seed)
	var picked := _pick_weighted_unique(family_candidates, 1, crisis_level, family, seed)
	if not picked.is_empty():
		return picked[0]
	return get_random_loot_item_id(owned_ids, crisis_level, family, seed)


static func get_boss_drop_item_ids() -> Array[String]:
	var ids: Array[String] = []
	for id in _get_auxiliary_catalog().keys():
		var item_id := String(id)
		if is_boss_drop(item_id):
			ids.append(item_id)
	return ids


static func get_boss_drop_for_family(family: String, owned_ids: Array) -> String:
	for id in get_boss_drop_item_ids():
		if get_family(id) == family and not owned_ids.has(id):
			return id
	return ""


static func get_boss_drop_for_family_stage(family: String, stage: int, owned_ids: Array) -> String:
	var normalized_stage := clampi(stage, 1, 3)
	for id in get_boss_drop_item_ids():
		if get_family(id) == family and get_boss_drop_stage(id) == normalized_stage and not owned_ids.has(id):
			return id
	return get_boss_drop_for_family(family, owned_ids)


static func get_build_tags(id: String) -> Array[String]:
	var item := get_item(id)
	if item.is_empty():
		return []
	var tags: Array[String] = []
	_append_unique_tag(tags, _family_archetype_tag(get_family(id)))
	if float(item.get("dash_distance_mult", 1.0)) > 1.0 or float(item.get("dash_speed_mult", 1.0)) > 1.0:
		_append_unique_tag(tags, "冲锋机动")
	if float(item.get("dash_damage_mult", 1.0)) > 1.0 or float(item.get("dash_aftershock_radius", 0.0)) > 0.0:
		_append_unique_tag(tags, "撞击爆发")
	if int(item.get("bullet_count", 0)) >= 3 or int(item.get("bullet_count_bonus", 0)) > 0 or float(item.get("spread_degrees_bonus", 0.0)) > 0.0 or float(item.get("spread_degrees", 0.0)) >= 18.0:
		_append_unique_tag(tags, "火力覆盖")
	if float(item.get("fire_rate_mult", 1.0)) < 0.95 or float(item.get("bullet_speed_mult", 1.0)) > 1.08:
		_append_unique_tag(tags, "连射加压")
	if float(item.get("homing_strength", 0.0)) > 0.0 or float(item.get("homing_range", 0.0)) > 0.0:
		_append_unique_tag(tags, "追踪修正")
	if float(item.get("gravity_pull_strength", 0.0)) > 0.0 or float(item.get("gravity_pull_radius", 0.0)) > 0.0:
		_append_unique_tag(tags, "引力牵制")
	if float(item.get("frenzy_gain_mult", 1.0)) > 1.0:
		_append_unique_tag(tags, "狂热蓄压")
	if float(item.get("frenzy_fire_rate_mult", 1.0)) < 1.0 or float(item.get("frenzy_damage_mult", 1.0)) > 1.0 or float(item.get("frenzy_damage_taken_mult", 1.0)) < 1.0:
		_append_unique_tag(tags, "狂热爆发")
	if int(item.get("drone_slots", 0)) > 0:
		_append_unique_tag(tags, "僚机协同")
	if float(item.get("drone_fire_interval_mult", 1.0)) < 1.0 or float(item.get("drone_damage_mult", 1.0)) > 1.0:
		_append_unique_tag(tags, "友军火线")
	if float(item.get("mineral_bonus", 0.0)) > 0.0:
		_append_unique_tag(tags, "回收增益")
	if int(item.get("atk_bonus", 0)) > 0:
		_append_unique_tag(tags, "主炮强化")
	if float(item.get("speed_mult", 1.0)) > 1.0:
		_append_unique_tag(tags, "航速修正")
	if tags.is_empty():
		_append_unique_tag(tags, "基础回路")
	if tags.size() > 3:
		tags = tags.slice(0, 3)
	return tags


static func get_build_summary_text(id: String) -> String:
	var tags := get_build_tags(id)
	if tags.is_empty():
		return ""
	return "战法：%s" % "、".join(tags)


static func get_effect_summary_text(id: String) -> String:
	var item := get_item(id)
	if item.is_empty():
		return ""
	var parts: Array[String] = []
	var item_type := String(item.get("type", ""))
	if int(item.get("atk_bonus", 0)) > 0:
		parts.append("攻击 +%d" % int(item.get("atk_bonus", 0)))
	var fire_rate_mult := float(item.get("fire_rate_mult", 1.0))
	if fire_rate_mult < 1.0:
		parts.append("射击间隔 -%d%%" % int(round((1.0 - fire_rate_mult) * 100.0)))
	elif fire_rate_mult > 1.0 and item_type == TYPE_WEAPON:
		parts.append("射击间隔 +%d%%" % int(round((fire_rate_mult - 1.0) * 100.0)))
	var speed_mult := float(item.get("speed_mult", 1.0))
	if speed_mult > 1.0:
		parts.append("航速 +%d%%" % int(round((speed_mult - 1.0) * 100.0)))
	var bullet_count := int(item.get("bullet_count", 0))
	if item_type == TYPE_WEAPON and bullet_count > 1:
		parts.append("弹幕 %d线" % bullet_count)
	var bullet_bonus := int(item.get("bullet_count_bonus", 0))
	if bullet_bonus > 0:
		parts.append("弹幕 +%d" % bullet_bonus)
	var spread_bonus := float(item.get("spread_degrees_bonus", item.get("spread_degrees", 0.0)))
	if spread_bonus > 0.0:
		parts.append("散射 +%d度" % int(round(spread_bonus)))
	var bullet_speed_mult := float(item.get("bullet_speed_mult", 1.0))
	if bullet_speed_mult > 1.0:
		parts.append("弹速 +%d%%" % int(round((bullet_speed_mult - 1.0) * 100.0)))
	var bullet_split_count := int(item.get("bullet_split_count", 0))
	if bullet_split_count > 0:
		parts.append("分裂弹 +%d" % bullet_split_count)
	var bullet_split_spread_degrees := float(item.get("bullet_split_spread_degrees", 0.0))
	if bullet_split_spread_degrees > 0.0:
		parts.append("分裂角 %d度" % int(round(bullet_split_spread_degrees)))
	var mineral_bonus := float(item.get("mineral_bonus", 0.0))
	if mineral_bonus > 0.0:
		parts.append("矿物 +%d%%" % int(round(mineral_bonus * 100.0)))
	var dash_distance_mult := float(item.get("dash_distance_mult", 1.0))
	if dash_distance_mult > 1.0:
		parts.append("冲锋距离 +%d%%" % int(round((dash_distance_mult - 1.0) * 100.0)))
	var dash_speed_mult := float(item.get("dash_speed_mult", 1.0))
	if dash_speed_mult > 1.0:
		parts.append("冲锋速度 +%d%%" % int(round((dash_speed_mult - 1.0) * 100.0)))
	var dash_damage_mult := float(item.get("dash_damage_mult", 1.0))
	if dash_damage_mult > 1.0:
		parts.append("冲锋撞击 +%d%%" % int(round((dash_damage_mult - 1.0) * 100.0)))
	var dash_aftershock_radius := float(item.get("dash_aftershock_radius", 0.0))
	if dash_aftershock_radius > 0.0:
		parts.append("冲锋余震 %d" % int(round(dash_aftershock_radius)))
	var dash_aftershock_damage_mult := float(item.get("dash_aftershock_damage_mult", 0.0))
	if dash_aftershock_damage_mult > 0.0:
		parts.append("余震伤害 %d%%" % int(round(dash_aftershock_damage_mult * 100.0)))
	var homing_strength := float(item.get("homing_strength", 0.0))
	if homing_strength > 0.0:
		parts.append("追踪强度 %.1f" % homing_strength)
	var homing_range := float(item.get("homing_range", 0.0))
	if homing_range > 0.0:
		parts.append("锁定范围 %d" % int(round(homing_range)))
	var gravity_pull_strength := float(item.get("gravity_pull_strength", 0.0))
	if gravity_pull_strength > 0.0:
		parts.append("引力牵引 %d" % int(round(gravity_pull_strength)))
	var gravity_pull_radius := float(item.get("gravity_pull_radius", 0.0))
	if gravity_pull_radius > 0.0:
		parts.append("引力半径 %d" % int(round(gravity_pull_radius)))
	var frenzy_gain_mult := float(item.get("frenzy_gain_mult", 1.0))
	if frenzy_gain_mult > 1.0:
		parts.append("狂热积累 +%d%%" % int(round((frenzy_gain_mult - 1.0) * 100.0)))
	var frenzy_fire_rate_mult := float(item.get("frenzy_fire_rate_mult", 1.0))
	if frenzy_fire_rate_mult < 1.0:
		parts.append("狂热射击 +%d%%" % int(round((1.0 - frenzy_fire_rate_mult) * 100.0)))
	var frenzy_damage_mult := float(item.get("frenzy_damage_mult", 1.0))
	if frenzy_damage_mult > 1.0:
		parts.append("狂热火力 +%d%%" % int(round((frenzy_damage_mult - 1.0) * 100.0)))
	var frenzy_damage_taken_mult := float(item.get("frenzy_damage_taken_mult", 1.0))
	if frenzy_damage_taken_mult < 1.0:
		parts.append("狂热减伤 +%d%%" % int(round((1.0 - frenzy_damage_taken_mult) * 100.0)))
	var drone_behavior := String(item.get("drone_behavior", ""))
	if drone_behavior != "":
		var _bn := {"shooter": "射手僚机", "miner": "采矿僚机", "guardian": "护盾僚机", "kamikaze": "自爆僚机", "medic": "治疗僚机"}
		parts.append(String(_bn.get(drone_behavior, "僚机")))
	var drone_slots := int(item.get("drone_slots", 0))
	if drone_slots > 0:
		parts.append("僚机位 +%d" % drone_slots)
	var drone_fire_interval_mult := float(item.get("drone_fire_interval_mult", 1.0))
	if drone_fire_interval_mult < 1.0:
		parts.append("僚机射速 +%d%%" % int(round((1.0 - drone_fire_interval_mult) * 100.0)))
	var drone_damage_mult := float(item.get("drone_damage_mult", 1.0))
	if drone_damage_mult > 1.0:
		parts.append("僚机火力 +%d%%" % int(round((drone_damage_mult - 1.0) * 100.0)))
	if float(item.get("drone_range_mult", 1.0)) > 1.0:
		parts.append("僚机射程 +%d%%" % int(round((float(item.get("drone_range_mult", 1.0)) - 1.0) * 100.0)))
	if float(item.get("drone_bullet_speed_mult", 1.0)) > 1.0:
		parts.append("僚机弹速 +%d%%" % int(round((float(item.get("drone_bullet_speed_mult", 1.0)) - 1.0) * 100.0)))
	if float(item.get("drone_homing_strength", 0.0)) > 0.0:
		parts.append("僚机追踪")
	if float(item.get("drone_mining_radius", 0.0)) > 0.0:
		parts.append("僚机采矿")
	if parts.is_empty():
		return "基础回路稳定"
	if parts.size() > 3:
		parts = parts.slice(0, 3)
	return "，".join(parts)


static func get_ui_meta_text(id: String, include_price: bool = false, price: int = 0) -> String:
	var item := get_item(id)
	if item.is_empty():
		return ""
	var parts: Array[String] = []
	var item_type := String(item.get("type", ""))
	parts.append("武器" if item_type == TYPE_WEAPON else "辅助机")
	parts.append(get_family_display_name(get_family(id)))
	parts.append(get_rarity_display_name(get_rarity(id)))
	if item_type == TYPE_AUX:
		parts.append("算力 %d" % get_compute_cost(id))
	if include_price:
		parts.append("%d 星髓矿" % price)
	var summary := get_effect_summary_text(id)
	if not summary.is_empty():
		parts.append(summary)
	var build_summary := get_build_summary_text(id)
	if not build_summary.is_empty():
		parts.append(build_summary)
	return " / ".join(parts)


static func make_player_stats(weapon_id: String, aux_ids: Array[String]) -> Dictionary:
	var weapon := get_item(weapon_id)
	if weapon.is_empty():
		weapon = get_item("pulse_cannon")
	var stats := {
		"atk_bonus": int(weapon.get("atk_bonus", 0)),
		"fire_rate_mult": float(weapon.get("fire_rate_mult", 1.0)),
		"speed_mult": 1.0,
		"bullet_count": int(weapon.get("bullet_count", 1)),
		"spread_degrees": float(weapon.get("spread_degrees", 0.0)),
		"bullet_split_count": int(weapon.get("bullet_split_count", 0)),
		"bullet_split_spread_degrees": float(weapon.get("bullet_split_spread_degrees", 0.0)),
		"bullet_split_damage_mult": float(weapon.get("bullet_split_damage_mult", 0.0)),
		"mineral_bonus": 0.0,
		"dash_distance_mult": 1.0,
		"dash_speed_mult": 1.0,
		"dash_damage_mult": 1.0,
		"dash_aftershock_radius": float(weapon.get("dash_aftershock_radius", 0.0)),
		"dash_aftershock_damage_mult": float(weapon.get("dash_aftershock_damage_mult", 0.0)),
		"dash_chain": int(weapon.get("dash_chain", 0)),
		"dash_trail_damage_mult": float(weapon.get("dash_trail_damage_mult", 0.0)),
		"dash_rebound_bonus": float(weapon.get("dash_rebound_bonus", 0.0)),
		"dash_mining": float(weapon.get("dash_mining", 0.0)),
		"dash_shield_duration": float(weapon.get("dash_shield_duration", 0.0)),
		"bullet_speed_mult": float(weapon.get("bullet_speed_mult", 1.0)),
		"homing_strength": float(weapon.get("homing_strength", 0.0)),
		"homing_range": float(weapon.get("homing_range", 0.0)),
		"gravity_pull_strength": float(weapon.get("gravity_pull_strength", 0.0)),
		"gravity_pull_radius": float(weapon.get("gravity_pull_radius", 0.0)),
		"frenzy_gain_mult": 1.0,
		"frenzy_fire_rate_mult": 1.0,
		"frenzy_damage_mult": 1.0,
		"frenzy_damage_taken_mult": 1.0,
		"drone_slots": int(weapon.get("drone_slots", 0)),
		"drone_fire_interval_mult": float(weapon.get("drone_fire_interval_mult", 1.0)),
		"drone_damage_mult": float(weapon.get("drone_damage_mult", 1.0)),
		"drone_range_mult": float(weapon.get("drone_range_mult", 1.0)),
		"drone_bullet_speed_mult": float(weapon.get("drone_bullet_speed_mult", 1.0)),
		"drone_homing_strength": float(weapon.get("drone_homing_strength", 0.0)),
		"drone_mining_radius": float(weapon.get("drone_mining_radius", 0.0)),
	}
	for aux_id in aux_ids:
		var aux := get_item(aux_id)
		if aux.is_empty():
			continue
		stats["atk_bonus"] = int(stats["atk_bonus"]) + int(aux.get("atk_bonus", 0))
		stats["fire_rate_mult"] = float(stats["fire_rate_mult"]) * float(aux.get("fire_rate_mult", 1.0))
		stats["speed_mult"] = float(stats["speed_mult"]) * float(aux.get("speed_mult", 1.0))
		stats["mineral_bonus"] = float(stats["mineral_bonus"]) + float(aux.get("mineral_bonus", 0.0))
		stats["bullet_count"] = int(stats["bullet_count"]) + int(aux.get("bullet_count_bonus", 0))
		stats["spread_degrees"] = float(stats["spread_degrees"]) + float(aux.get("spread_degrees_bonus", 0.0))
		stats["bullet_split_count"] = int(stats["bullet_split_count"]) + int(aux.get("bullet_split_count", 0))
		stats["bullet_split_spread_degrees"] = maxf(float(stats["bullet_split_spread_degrees"]), float(aux.get("bullet_split_spread_degrees", 0.0)))
		stats["bullet_split_damage_mult"] = float(stats["bullet_split_damage_mult"]) + float(aux.get("bullet_split_damage_mult", 0.0))
		stats["dash_distance_mult"] = float(stats["dash_distance_mult"]) * float(aux.get("dash_distance_mult", 1.0))
		stats["dash_speed_mult"] = float(stats["dash_speed_mult"]) * float(aux.get("dash_speed_mult", 1.0))
		stats["dash_damage_mult"] = float(stats["dash_damage_mult"]) * float(aux.get("dash_damage_mult", 1.0))
		stats["dash_aftershock_radius"] = float(stats["dash_aftershock_radius"]) + float(aux.get("dash_aftershock_radius", 0.0))
		stats["dash_aftershock_damage_mult"] = float(stats["dash_aftershock_damage_mult"]) + float(aux.get("dash_aftershock_damage_mult", 0.0))
		stats["dash_chain"] = int(stats["dash_chain"]) + int(aux.get("dash_chain", 0))
		stats["dash_trail_damage_mult"] = maxf(float(stats["dash_trail_damage_mult"]), float(aux.get("dash_trail_damage_mult", 0.0)))
		stats["dash_rebound_bonus"] = float(stats["dash_rebound_bonus"]) + float(aux.get("dash_rebound_bonus", 0.0))
		stats["dash_mining"] = maxf(float(stats["dash_mining"]), float(aux.get("dash_mining", 0.0)))
		stats["dash_shield_duration"] = maxf(float(stats["dash_shield_duration"]), float(aux.get("dash_shield_duration", 0.0)))
		stats["bullet_speed_mult"] = float(stats["bullet_speed_mult"]) * float(aux.get("bullet_speed_mult", 1.0))
		stats["homing_strength"] = float(stats["homing_strength"]) + float(aux.get("homing_strength", 0.0))
		stats["homing_range"] = maxf(float(stats["homing_range"]), float(aux.get("homing_range", 0.0)))
		stats["gravity_pull_strength"] = float(stats["gravity_pull_strength"]) + float(aux.get("gravity_pull_strength", 0.0))
		stats["gravity_pull_radius"] = maxf(float(stats["gravity_pull_radius"]), float(aux.get("gravity_pull_radius", 0.0)))
		stats["frenzy_gain_mult"] = float(stats["frenzy_gain_mult"]) * float(aux.get("frenzy_gain_mult", 1.0))
		stats["frenzy_fire_rate_mult"] = float(stats["frenzy_fire_rate_mult"]) * float(aux.get("frenzy_fire_rate_mult", 1.0))
		stats["frenzy_damage_mult"] = float(stats["frenzy_damage_mult"]) * float(aux.get("frenzy_damage_mult", 1.0))
		stats["frenzy_damage_taken_mult"] = float(stats["frenzy_damage_taken_mult"]) * float(aux.get("frenzy_damage_taken_mult", 1.0))
		stats["drone_slots"] = int(stats["drone_slots"]) + int(aux.get("drone_slots", 0))
		stats["drone_fire_interval_mult"] = float(stats["drone_fire_interval_mult"]) * float(aux.get("drone_fire_interval_mult", 1.0))
		stats["drone_damage_mult"] = float(stats["drone_damage_mult"]) * float(aux.get("drone_damage_mult", 1.0))
		stats["drone_range_mult"] = float(stats["drone_range_mult"]) * float(aux.get("drone_range_mult", 1.0))
		stats["drone_bullet_speed_mult"] = float(stats["drone_bullet_speed_mult"]) * float(aux.get("drone_bullet_speed_mult", 1.0))
		stats["drone_homing_strength"] = float(stats["drone_homing_strength"]) + float(aux.get("drone_homing_strength", 0.0))
		stats["drone_mining_radius"] = maxf(float(stats["drone_mining_radius"]), float(aux.get("drone_mining_radius", 0.0)))
	# 机制强度多件累加，但设软上限防止叠满后失控（数值可在流派平衡时调整）
	stats["drone_homing_strength"] = minf(float(stats["drone_homing_strength"]), 8.0)
	stats["homing_strength"] = minf(float(stats["homing_strength"]), 18.0)
	stats["gravity_pull_strength"] = minf(float(stats["gravity_pull_strength"]), 820.0)
	stats["dash_aftershock_radius"] = minf(float(stats["dash_aftershock_radius"]), 260.0)
	stats["dash_aftershock_damage_mult"] = minf(float(stats["dash_aftershock_damage_mult"]), 0.9)
	stats["bullet_split_damage_mult"] = minf(float(stats["bullet_split_damage_mult"]), 0.75)
	stats["dash_chain"] = mini(int(stats["dash_chain"]), 6)
	stats["dash_rebound_bonus"] = minf(float(stats["dash_rebound_bonus"]), 1.0)
	return stats


# 僚机装载：每件僚机装备按其 behavior 贡献 drone_slots 个对应类型僚机（混合僚机群）
static func get_drone_loadout(weapon_id: String, aux_ids: Array) -> Array:
	var loadout: Array = []
	var ids: Array = [weapon_id]
	ids.append_array(aux_ids)
	for item_id in ids:
		var item := get_item(String(item_id))
		if item.is_empty():
			continue
		var behavior := String(item.get("drone_behavior", ""))
		var slots := int(item.get("drone_slots", 0))
		if behavior == "" or slots <= 0:
			continue
		for i in range(slots):
			loadout.append({
				"behavior": behavior,
				"atk_bonus": int(item.get("atk_bonus", 0)),
				"drone_damage_mult": float(item.get("drone_damage_mult", 1.0)),
				"drone_fire_interval_mult": float(item.get("drone_fire_interval_mult", 1.0)),
				"drone_range_mult": float(item.get("drone_range_mult", 1.0)),
				"drone_bullet_speed_mult": float(item.get("drone_bullet_speed_mult", 1.0)),
				"drone_homing_strength": float(item.get("drone_homing_strength", 0.0)),
				"drone_mining_radius": float(item.get("drone_mining_radius", 0.0)),
				"drone_shield_radius": float(item.get("drone_shield_radius", 0.0)),
				"drone_blast_damage_mult": float(item.get("drone_blast_damage_mult", 1.0)),
				"drone_heal_amount": float(item.get("drone_heal_amount", 0.0)),
			})
	return loadout


static func _get_auxiliary_catalog() -> Dictionary:
	if not _auxiliary_catalog_cache.is_empty():
		return _auxiliary_catalog_cache
	var catalog := AUXILIARIES.duplicate(true)
	for row in AUXILIARY_EXPANSION_ROWS:
		var item_id := String(row.get("id", ""))
		if item_id.is_empty():
			continue
		catalog[item_id] = _make_expansion_auxiliary(row)
	_auxiliary_catalog_cache = catalog
	return _auxiliary_catalog_cache


static func _get_item_ref(id: String) -> Dictionary:
	if WEAPONS.has(id):
		return WEAPONS[id]
	var auxiliary_catalog := _get_auxiliary_catalog()
	if auxiliary_catalog.has(id):
		return auxiliary_catalog[id]
	return {}


static func _make_expansion_auxiliary(row: Dictionary) -> Dictionary:
	var stats: Dictionary = row.get("stats", {})
	var item := {
		"name": String(row.get("name", row.get("id", ""))),
		"type": TYPE_AUX,
		"price": int(row.get("price", 0)),
		"compute_cost": clampi(int(row.get("compute_cost", 1)), 1, 7),
		"family": String(row.get("family", FAMILY_GENERAL)),
		"rarity": String(row.get("rarity", "common")),
		"atk_bonus": int(stats.get("atk_bonus", 0)),
		"fire_rate_mult": float(stats.get("fire_rate_mult", 1.0)),
		"speed_mult": float(stats.get("speed_mult", 1.0)),
		"mineral_bonus": float(stats.get("mineral_bonus", 0.0)),
		"description": String(row.get("description", "")),
	}
	for key in [
		"bullet_count_bonus",
		"spread_degrees_bonus",
		"bullet_split_count",
		"bullet_split_spread_degrees",
		"bullet_split_damage_mult",
		"dash_distance_mult",
		"dash_speed_mult",
		"dash_damage_mult",
		"dash_aftershock_radius",
		"dash_aftershock_damage_mult",
		"bullet_speed_mult",
		"homing_strength",
		"homing_range",
		"gravity_pull_strength",
		"gravity_pull_radius",
		"frenzy_gain_mult",
		"frenzy_fire_rate_mult",
		"frenzy_damage_mult",
		"frenzy_damage_taken_mult",
		"drone_slots",
		"drone_fire_interval_mult",
		"drone_damage_mult",
		"drone_range_mult",
		"drone_bullet_speed_mult",
		"drone_homing_strength",
		"drone_mining_radius",
		"drone_behavior",
		"drone_shield_radius",
		"drone_blast_damage_mult",
		"drone_heal_amount",
		"dash_chain",
		"dash_trail_damage_mult",
		"dash_rebound_bonus",
		"dash_mining",
		"dash_shield_duration",
	]:
		if stats.has(key):
			item[key] = stats[key]
	return item


static func _family_archetype_tag(family: String) -> String:
	match family:
		FAMILY_COLOSSUS:
			return "冲锋碰撞"
		FAMILY_PARADISE:
			return "火力覆盖"
		FAMILY_WARPED:
			return "引力牵制"
		FAMILY_HELL_EYE:
			return "狂热爆发"
		FAMILY_DIVINE:
			return "僚机协同"
	return "通用回路"


static func _append_unique_tag(tags: Array[String], tag: String) -> void:
	if tag.is_empty() or tags.has(tag):
		return
	tags.append(tag)


static func _get_progression_candidates(source_ids: Array[String], owned_ids: Array, crisis_level: int) -> Array[String]:
	var candidates: Array[String] = []
	for id in source_ids:
		var item_id := String(id)
		if owned_ids.has(item_id):
			continue
		if is_boss_drop(item_id):
			continue
		if not _is_available_at_crisis(item_id, crisis_level):
			continue
		candidates.append(item_id)
	return candidates


static func _is_available_at_crisis(item_id: String, crisis_level: int) -> bool:
	var rarity := get_rarity(item_id)
	if rarity == "boss":
		return false
	if rarity == "epic":
		return crisis_level >= CRISIS_EPIC_UNLOCK_LEVEL
	return true


static func _pick_weighted_unique(candidates: Array[String], pick_count: int, crisis_level: int, preferred_family: String, seed: int) -> Array[String]:
	var picked: Array[String] = []
	if pick_count <= 0 or candidates.is_empty():
		return picked
	var pool := candidates.duplicate()
	var rng := _make_rng(seed)
	while picked.size() < pick_count and not pool.is_empty():
		var index := _pick_weighted_index(pool, crisis_level, preferred_family, rng)
		picked.append(String(pool[index]))
		pool.remove_at(index)
	return picked


static func _pick_weighted_index(candidates: Array[String], crisis_level: int, preferred_family: String, rng: RandomNumberGenerator) -> int:
	var total_weight := 0.0
	for item_id in candidates:
		total_weight += _get_item_progression_weight(item_id, crisis_level, preferred_family)
	if total_weight <= 0.0:
		return 0
	var roll := rng.randf() * total_weight
	var cursor := 0.0
	for i in range(candidates.size()):
		cursor += _get_item_progression_weight(candidates[i], crisis_level, preferred_family)
		if roll <= cursor:
			return i
	return candidates.size() - 1


static func _get_item_progression_weight(item_id: String, crisis_level: int, preferred_family: String) -> float:
	var item := _get_item_ref(item_id)
	if item.is_empty():
		return 0.0
	var weight := 1.0
	match String(item.get("rarity", "common")):
		"rare":
			weight *= 0.7
		"epic":
			weight *= 0.55 if crisis_level >= CRISIS_EPIC_FULL_WEIGHT_LEVEL else 0.22
	var family := String(item.get("family", FAMILY_GENERAL))
	if not preferred_family.is_empty() and family == preferred_family:
		weight *= PREFERRED_FAMILY_WEIGHT
	elif family == FAMILY_GENERAL:
		weight *= GENERAL_FAMILY_WEIGHT
	return weight


static func _ensure_late_epic_offer(offers: Array[String], candidates: Array[String], crisis_level: int, seed: int) -> void:
	if crisis_level < CRISIS_EPIC_FULL_WEIGHT_LEVEL or offers.is_empty():
		return
	for item_id in offers:
		if get_rarity(item_id) == "epic":
			return
	var epic_candidates: Array[String] = []
	for item_id in candidates:
		if get_rarity(item_id) == "epic" and not offers.has(item_id):
			epic_candidates.append(item_id)
	if epic_candidates.is_empty():
		return
	var rng := _make_rng(seed + 7919 if seed >= 0 else seed)
	var epic_id := epic_candidates[rng.randi_range(0, epic_candidates.size() - 1)]
	for i in range(offers.size() - 1, -1, -1):
		if get_rarity(offers[i]) != "epic":
			offers[i] = epic_id
			return
	offers[offers.size() - 1] = epic_id


static func _ensure_shop_family_variety(offers: Array[String], candidates: Array[String], crisis_level: int, preferred_family: String, seed: int) -> void:
	if offers.size() < 4 or candidates.is_empty():
		return
	var protected_families: Array[String] = [FAMILY_GENERAL]
	var boss_families: Array[String] = [
		FAMILY_COLOSSUS,
		FAMILY_PARADISE,
		FAMILY_WARPED,
		FAMILY_HELL_EYE,
		FAMILY_DIVINE,
	]
	if not preferred_family.is_empty() and boss_families.has(preferred_family):
		protected_families.append(preferred_family)
	var rng := _make_rng(seed + 1543 if seed >= 0 else seed)
	var family_pool := boss_families.duplicate()
	while not family_pool.is_empty():
		if protected_families.size() >= 4:
			break
		var family_index := rng.randi_range(0, family_pool.size() - 1)
		var family := String(family_pool[family_index])
		family_pool.remove_at(family_index)
		if not protected_families.has(family):
			protected_families.append(family)
	for family in protected_families:
		if _offer_family_count(offers, family) > 0:
			continue
		var replacement := _pick_family_replacement(candidates, offers, family, crisis_level, preferred_family, rng)
		if replacement.is_empty():
			continue
		var replace_index := _find_replaceable_offer_index(offers, protected_families)
		if replace_index >= 0:
			offers[replace_index] = replacement


static func _pick_family_replacement(candidates: Array[String], offers: Array[String], family: String, crisis_level: int, preferred_family: String, rng: RandomNumberGenerator) -> String:
	var family_candidates: Array[String] = []
	for item_id in candidates:
		if offers.has(item_id):
			continue
		if get_family(item_id) != family:
			continue
		family_candidates.append(item_id)
	if family_candidates.is_empty():
		return ""
	return family_candidates[_pick_weighted_index(family_candidates, crisis_level, preferred_family, rng)]


static func _find_replaceable_offer_index(offers: Array[String], protected_families: Array[String]) -> int:
	for i in range(offers.size() - 1, -1, -1):
		var family := get_family(offers[i])
		if protected_families.has(family) and _offer_family_count(offers, family) <= 1:
			continue
		return i
	return -1


static func _offer_family_count(offers: Array[String], family: String) -> int:
	var count := 0
	for item_id in offers:
		if get_family(item_id) == family:
			count += 1
	return count


static func _make_rng(seed: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	if seed >= 0:
		rng.seed = seed
	else:
		rng.randomize()
	return rng
