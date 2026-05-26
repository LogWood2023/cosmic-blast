extends Node

const ENEMIES: Array[Dictionary] = [
	{"id":"ColossusShardArm","name":"巨构碎臂","family":"星间巨构","behavior":0,"hp":30,"damage":12,"size":Vector2(84,108),"color":Color(0.45,0.47,0.52,1),"accent":Color(1,0.22,0.12,1),"pos":Vector2(960,160),"mechanic":"高速近战冲刺。进入警告后会锁定玩家方向并向前穿刺，主要依靠碰撞伤害压迫走位。"},
	{"id":"ColossusShieldBee","name":"装甲盾蜂","family":"星间巨构","behavior":1,"hp":42,"damage":8,"size":Vector2(96,76),"color":Color(0.34,0.38,0.42,1),"accent":Color(1,0.55,0.18,1),"pos":Vector2(960,170),"mechanic":"护盾吸伤单位。冷却阶段受到玩家子弹会减伤并积累护盾能量，能量满后释放一圈反击弹。"},
	{"id":"ColossusGravityClaw","name":"引力钩爪","family":"星间巨构","behavior":2,"hp":32,"damage":10,"size":Vector2(76,96),"color":Color(0.4,0.36,0.45,1),"accent":Color(0.95,0.28,0.2,1),"pos":Vector2(960,170),"mechanic":"近战控制单位。会向玩家发射高速钩爪弹，玩家过近时会受到短距离拉扯与伤害。"},
	{"id":"ColossusGuard","name":"巨构护卫","family":"星间巨构","behavior":3,"hp":115,"damage":14,"size":Vector2(116,104),"color":Color(0.36,0.4,0.45,1),"accent":Color(1,0.36,0.12,1),"pos":Vector2(960,160),"mechanic":"中型护盾冲锋精英。冷却阶段正面减伤，周期性朝玩家短距离盾冲，吸收伤害后可释放反击环弹。"},
	{"id":"ColossusCoreDevourer","name":"核心吞噬者","family":"星间巨构","behavior":4,"hp":125,"damage":15,"size":Vector2(112,112),"color":Color(0.3,0.32,0.38,1),"accent":Color(1,0.15,0.1,1),"pos":Vector2(960,160),"mechanic":"吸弹反击精英。冷却阶段有减伤效果，积累受击次数后释放环弹，并周期性向玩家发射高伤害能量矛。"},
	{"id":"ParadisePatrol","name":"天堂巡逻机","family":"天堂号","behavior":5,"hp":24,"damage":8,"size":Vector2(80,92),"color":Color(0.9,0.86,0.68,1),"accent":Color(0.35,0.72,1,1),"pos":Vector2(960,170),"mechanic":"基础火力单位。停顿时稳定朝玩家点射，压力简单但持续。"},
	{"id":"ParadiseArcScatter","name":"弧光散射机","family":"天堂号","behavior":6,"hp":28,"damage":7,"size":Vector2(104,72),"color":Color(0.95,0.9,0.72,1),"accent":Color(0.4,0.85,1,1),"pos":Vector2(960,170),"mechanic":"扇形覆盖单位。会朝玩家方向释放多发弧形散弹，用于覆盖大片闪避区域。"},
	{"id":"ParadiseRailChain","name":"圣轨连射机","family":"天堂号","behavior":7,"hp":34,"damage":6,"size":Vector2(68,116),"color":Color(0.86,0.83,0.72,1),"accent":Color(0.5,0.9,1,1),"pos":Vector2(960,170),"mechanic":"连射压制单位。停顿后进行三连发追踪点射，迫使玩家持续横移。"},
	{"id":"ParadiseCalibrator","name":"天堂校准者","family":"天堂号","behavior":8,"hp":105,"damage":10,"size":Vector2(108,92),"color":Color(0.95,0.88,0.62,1),"accent":Color(0.25,0.75,1,1),"pos":Vector2(960,160),"mechanic":"精准射击精英。先三连点射，再周期性发射更快、更痛的校准弹。"},
	{"id":"ParadiseSanctumSuppressor","name":"圣域压制者","family":"天堂号","behavior":9,"hp":125,"damage":10,"size":Vector2(112,100),"color":Color(0.88,0.84,0.7,1),"accent":Color(0.2,0.65,1,1),"pos":Vector2(960,160),"mechanic":"区域压制精英。会在玩家周围生成四方向交叉射击，短时间封锁上下左右逃跑路线。"},
	{"id":"WarpedMicroCore","name":"微型引力核","family":"扭曲星核","behavior":10,"hp":34,"damage":12,"size":Vector2(88,88),"color":Color(0.45,0.22,0.72,1),"accent":Color(0.9,0.45,1,1),"pos":Vector2(960,170),"mechanic":"弱吸力干扰单位。停顿时将全局吸力中心设为自身，轻微牵引玩家，同时释放低速弹。"},
	{"id":"WarpedRefractionShooter","name":"折光射手","family":"扭曲星核","behavior":11,"hp":28,"damage":10,"size":Vector2(84,92),"color":Color(0.33,0.25,0.7,1),"accent":Color(0.85,0.55,1,1),"pos":Vector2(960,170),"mechanic":"折射射击单位。先发射偏斜慢弹，短暂延迟后再次朝玩家位置补射，制造二段转向压力。"},
	{"id":"WarpedOrbitDisruptor","name":"轨道扰流器","family":"扭曲星核","behavior":12,"hp":38,"damage":8,"size":Vector2(96,96),"color":Color(0.3,0.22,0.62,1),"accent":Color(0.7,0.35,1,1),"pos":Vector2(960,170),"mechanic":"环形扰流单位。周期性释放全向环弹，表现为轨道扰动与弹幕干扰。"},
	{"id":"WarpedCollapseBeacon","name":"坍缩信标","family":"扭曲星核","behavior":13,"hp":120,"damage":14,"size":Vector2(112,112),"color":Color(0.18,0.12,0.28,1),"accent":Color(0.86,0.25,1,1),"pos":Vector2(960,160),"mechanic":"短时吸力精英。开启约 1.4 秒吸力后释放 12 枚环形弹，适合测试吸引与爆发组合。"},
	{"id":"WarpedDeflectionMatrix","name":"偏转矩阵","family":"扭曲星核","behavior":14,"hp":115,"damage":12,"size":Vector2(108,108),"color":Color(0.28,0.18,0.58,1),"accent":Color(0.5,0.85,1,1),"pos":Vector2(960,160),"mechanic":"旋转弹幕精英。每轮释放八方向环弹，发射角度逐轮偏移，模拟弹道偏转矩阵。"},
	{"id":"HellEyeInvertedMoth","name":"倒影眼虫","family":"地狱之眼","behavior":15,"hp":24,"damage":8,"size":Vector2(76,84),"color":Color(0.22,0.08,0.1,1),"accent":Color(1,0.08,0.08,1),"pos":Vector2(960,170),"mechanic":"操作干扰小怪。射击玩家，近距离命中节奏会短暂反转玩家移动方向。"},
	{"id":"HellEyeBlindMoth","name":"盲点飞蛾","family":"地狱之眼","behavior":16,"hp":24,"damage":10,"size":Vector2(104,68),"color":Color(0.05,0.05,0.07,1),"accent":Color(0.75,0.05,0.08,1),"pos":Vector2(960,170),"mechanic":"遮蔽干扰小怪。会在玩家附近生成半透明黑雾，短暂影响视野；靠近时造成额外伤害。"},
	{"id":"HellEyeMisalignedGazer","name":"错位凝视者","family":"地狱之眼","behavior":17,"hp":30,"damage":9,"size":Vector2(84,84),"color":Color(0.16,0.08,0.12,1),"accent":Color(1,0.18,0.1,1),"pos":Vector2(960,170),"mechanic":"错位射击小怪。子弹朝玩家方向随机偏移，制造视觉与实际弹道的轻微错位感。"},
	{"id":"HellEyeInvertPriest","name":"颠倒司祭","family":"地狱之眼","behavior":18,"hp":120,"damage":14,"size":Vector2(108,116),"color":Color(0.18,0.07,0.11,1),"accent":Color(1,0.05,0.15,1),"pos":Vector2(960,160),"mechanic":"控制干扰精英。周期性反转玩家移动方向，同时释放慢速扇形弹幕。"},
	{"id":"HellEyeHorizonDeflector","name":"视界偏转者","family":"地狱之眼","behavior":19,"hp":135,"damage":16,"size":Vector2(112,108),"color":Color(0.12,0.06,0.1,1),"accent":Color(0.95,0.08,0.2,1),"pos":Vector2(960,160),"mechanic":"视界偏转精英。以随机倾斜角发射多列弹幕，用弹道方向暗示视野偏斜。"},
	{"id":"DivineWingRaider","name":"圣羽掠袭者","family":"神明使者","behavior":20,"hp":24,"damage":12,"size":Vector2(100,64),"color":Color(0.94,0.92,0.82,1),"accent":Color(0.7,0.95,1,1),"pos":Vector2(960,170),"mechanic":"高速掠袭小怪。移动速度很快，穿越战场时持续向下投放光羽弹。"},
	{"id":"DivineBlinkBeacon","name":"闪现信标","family":"神明使者","behavior":21,"hp":28,"damage":8,"size":Vector2(76,96),"color":Color(0.72,0.9,1,1),"accent":Color(1,0.95,0.55,1),"pos":Vector2(960,170),"mechanic":"瞬移射击小怪。周期性闪现到玩家附近安全距离，然后立即朝玩家发射高速光弹。"},
	{"id":"DivineBrokenWingAssassin","name":"折翼刺客","family":"神明使者","behavior":22,"hp":32,"damage":14,"size":Vector2(84,100),"color":Color(0.82,0.86,0.9,1),"accent":Color(1,0.86,0.42,1),"pos":Vector2(960,170),"mechanic":"闪避突刺小怪。会靠近玩家侧翼并执行短距离冲刺，主要依靠碰撞伤害。"},
	{"id":"DivineSeraphHunter","name":"炽天追猎者","family":"神明使者","behavior":23,"hp":115,"damage":16,"size":Vector2(112,104),"color":Color(0.98,0.92,0.72,1),"accent":Color(1,0.72,0.24,1),"pos":Vector2(960,160),"mechanic":"高机动精英。连续瞬移到玩家周围射击，每第三次行动会改为高速突刺。"},
	{"id":"DivineOraclePhantom","name":"神谕幻影","family":"神明使者","behavior":24,"hp":130,"damage":12,"size":Vector2(108,112),"color":Color(0.78,0.9,1,1),"accent":Color(1,0.88,0.38,1),"pos":Vector2(960,160),"mechanic":"残影精英。生成无碰撞幻影并由幻影延迟射击，本体随后闪现并发射追踪感较强的光弹。"}
]


static func get_enemy(id: String) -> Dictionary:
	for enemy in ENEMIES:
		if enemy.id == id:
			return enemy
	return {}
