extends Node

const ENEMIES: Array[Dictionary] = [
	{"id":"ColossusShardArm","name":"巨构碎臂","family":"星间巨构","behavior":0,"hp":30,"damage":12,"size":Vector2(84,108),"color":Color(0.45,0.47,0.52,1),"accent":Color(1,0.22,0.12,1),"pos":Vector2(960,160),"mechanic":"突入战场后会短暂蓄势并锁定闯入者方位，随后以重臂贯穿航道，逼迫目标离开直线航迹。"},
	{"id":"ColossusShieldBee","name":"装甲盾蜂","family":"星间巨构","behavior":1,"hp":42,"damage":8,"size":Vector2(96,76),"color":Color(0.34,0.38,0.42,1),"accent":Color(1,0.55,0.18,1),"pos":Vector2(960,170),"mechanic":"受击时展开短促护盾，硬化外壳会削弱来袭火力；护盾未熄时再次受击，将把能量束折返给锁定目标，并持续压向目标前方。"},
	{"id":"ColossusGravityClaw","name":"引力钩爪","family":"星间巨构","behavior":2,"hp":32,"damage":10,"size":Vector2(76,96),"color":Color(0.4,0.36,0.45,1),"accent":Color(0.95,0.28,0.2,1),"pos":Vector2(960,170),"mechanic":"会以碎臂般的突刺逼近目标，命中后钩爪咬合舰体并拖拽航向；被缠住时必须交替挣脱，拖延越久越危险。"},
	{"id":"ColossusGuard","name":"巨构护卫","family":"星间巨构","behavior":3,"hp":1150,"damage":14,"size":Vector2(232,208),"color":Color(0.36,0.4,0.45,1),"accent":Color(1,0.36,0.12,1),"pos":Vector2(960,160),"mechanic":"融合碎臂冲锋与盾蜂护罩的重型守卫。受击和突进时都会撑开装甲场，突锋期间难以撼动，撞击会把目标狠狠抛离。"},
	{"id":"ColossusCoreDevourer","name":"核心吞噬者","family":"星间巨构","behavior":4,"hp":1250,"damage":15,"size":Vector2(224,224),"color":Color(0.3,0.32,0.38,1),"accent":Color(1,0.15,0.1,1),"pos":Vector2(960,160),"mechanic":"以护盾守住核心，并从装甲裂缝中放出引力钩爪。每次受击都会唤醒新的咬合实体，战场越久，钩爪越密。"},
	{"id":"ParadisePatrol","name":"天堂巡逻机","family":"天堂号","behavior":5,"hp":24,"damage":8,"size":Vector2(80,92),"color":Color(0.9,0.86,0.68,1),"accent":Color(0.35,0.72,1,1),"pos":Vector2(960,170),"mechanic":"保持侧翼航线，寻找清晰射角后进行稳定点射。它不会急于贴身，而是用持续火线封住回旋空间。"},
	{"id":"ParadiseArcScatter","name":"弧光散射机","family":"天堂号","behavior":6,"hp":28,"damage":7,"size":Vector2(104,72),"color":Color(0.95,0.9,0.72,1),"accent":Color(0.4,0.85,1,1),"pos":Vector2(960,170),"mechanic":"游走在另一侧翼，以扇形弧光覆盖近中距离空域。阵线被它打开后，回避路线会被快速压缩。"},
	{"id":"ParadiseRailChain","name":"圣轨连射机","family":"天堂号","behavior":7,"hp":34,"damage":6,"size":Vector2(68,116),"color":Color(0.86,0.83,0.72,1),"accent":Color(0.5,0.9,1,1),"pos":Vector2(960,170),"mechanic":"偏好尾随航道，捕捉无遮挡瞬间打出连续圣轨。它的节奏稳定，总能在混战中补上致命火线。"},
	{"id":"ParadiseCalibrator","name":"天堂校准者","family":"天堂号","behavior":8,"hp":1050,"damage":10,"size":Vector2(216,184),"color":Color(0.95,0.88,0.62,1),"accent":Color(0.25,0.75,1,1),"pos":Vector2(960,160),"mechanic":"远距校准核心会拉开安全航线，投下醒目的狙击光束；光束稳定后，校准弹会以极高速度撕开直线空域。"},
	{"id":"ParadiseSanctumSuppressor","name":"圣域压制者","family":"天堂号","behavior":9,"hp":1250,"damage":10,"size":Vector2(224,200),"color":Color(0.88,0.84,0.7,1),"accent":Color(0.2,0.65,1,1),"pos":Vector2(960,160),"mechanic":"靠近后进入圣域旋转，向四向持续喷吐压制弹幕。只要让它完成展开，周围空域会被逐步封死。"},
	{"id":"WarpedMicroCore","name":"微型引力核","family":"扭曲星核","behavior":10,"hp":34,"damage":12,"size":Vector2(88,88),"color":Color(0.45,0.22,0.72,1),"accent":Color(0.9,0.45,1,1),"pos":Vector2(960,170),"mechanic":"以异常自旋扰动弹道，靠近后牵引来袭火力并改写飞行轨迹。破裂时会释放环形乱流，逼迫附近目标急转。"},
	{"id":"WarpedRefractionShooter","name":"折光射手","family":"扭曲星核","behavior":11,"hp":28,"damage":10,"size":Vector2(84,92),"color":Color(0.33,0.25,0.7,1),"accent":Color(0.85,0.55,1,1),"pos":Vector2(960,170),"mechanic":"发射能在边界与障碍上折返的折光弹。一次射击可能从意想不到的角度回到战场中心。"},
	{"id":"WarpedOrbitDisruptor","name":"轨道扰流器","family":"扭曲星核","behavior":12,"hp":38,"damage":8,"size":Vector2(96,96),"color":Color(0.3,0.22,0.62,1),"accent":Color(0.7,0.35,1,1),"pos":Vector2(960,170),"mechanic":"绕向目标背侧后放出紫色扰流电链，拖慢航速并持续蚕食装甲。越靠近它，视野和节奏越容易被夺走。"},
	{"id":"WarpedCollapseBeacon","name":"坍缩信标","family":"扭曲星核","behavior":13,"hp":1200,"damage":14,"size":Vector2(224,224),"color":Color(0.18,0.12,0.28,1),"accent":Color(0.86,0.25,1,1),"pos":Vector2(960,160),"mechanic":"以自旋核心释放可折返的散射光束，部分攻势会在短暂停顿后再次爆发。它让战场边界也变成危险源。"},
	{"id":"WarpedDeflectionMatrix","name":"偏转矩阵","family":"扭曲星核","behavior":14,"hp":1150,"damage":12,"size":Vector2(216,216),"color":Color(0.28,0.18,0.58,1),"accent":Color(0.5,0.85,1,1),"pos":Vector2(960,160),"mechanic":"靠近后张开斥力场，既能以电链压制目标，也会把来袭弹丸推离自身。直线火力在它面前很难保持可靠。"},
	{"id":"HellEyeInvertedMoth","name":"倒影眼虫","family":"地狱之眼","behavior":15,"hp":24,"damage":8,"size":Vector2(76,84),"color":Color(0.22,0.08,0.1,1),"accent":Color(1,0.08,0.08,1),"pos":Vector2(960,170),"mechanic":"本体隐入暗影，只留下偏移的伪影诱导判断。真正的突刺往往来自视线边缘。"},
	{"id":"HellEyeBlindMoth","name":"盲点飞蛾","family":"地狱之眼","behavior":16,"hp":24,"damage":10,"size":Vector2(104,68),"color":Color(0.05,0.05,0.07,1),"accent":Color(0.75,0.05,0.08,1),"pos":Vector2(960,170),"mechanic":"以黑线黏住目标视域，持续制造压迫和暗角。它不急着击毁目标，而是先夺走判断空间。"},
	{"id":"HellEyeMisalignedGazer","name":"错位凝视者","family":"地狱之眼","behavior":17,"hp":30,"damage":9,"size":Vector2(84,84),"color":Color(0.16,0.08,0.12,1),"accent":Color(1,0.18,0.1,1),"pos":Vector2(960,170),"mechanic":"凝视会积累黑色错位，当阈值被填满，瞄准感会被强行扭曲，锁定点也随之漂移。"},
	{"id":"HellEyeInvertPriest","name":"颠倒司祭","family":"地狱之眼","behavior":18,"hp":1200,"damage":14,"size":Vector2(216,232),"color":Color(0.18,0.07,0.11,1),"accent":Color(1,0.05,0.15,1),"pos":Vector2(960,160),"mechanic":"以更强的倒错仪式延长黑色凝视。若目标已经陷入扰乱，视窗会被彻底翻转，恢复节奏也更加艰难。"},
	{"id":"HellEyeHorizonDeflector","name":"视界偏转者","family":"地狱之眼","behavior":19,"hp":1350,"damage":18,"size":Vector2(224,216),"color":Color(0.12,0.06,0.1,1),"accent":Color(0.95,0.08,0.2,1),"pos":Vector2(960,160),"mechanic":"会放出环绕目标的多重幻影，并以真实本体完成凶猛冲撞。命中时目标会被抛离，伪影仍会干扰下一次判断。"},
	{"id":"DivineWingRaider","name":"圣羽掠袭者","family":"神明使者","behavior":20,"hp":24,"damage":6,"size":Vector2(100,64),"color":Color(0.94,0.92,0.82,1),"accent":Color(0.7,0.95,1,1),"pos":Vector2(960,170),"mechanic":"沿直线高速掠袭，并在冲锋途中向两翼洒下圣羽弹。它不是单点威胁，而是一条移动的交叉火线。"},
	{"id":"DivineBlinkBeacon","name":"闪现信标","family":"神明使者","behavior":21,"hp":30,"damage":8,"size":Vector2(76,96),"color":Color(0.72,0.9,1,1),"accent":Color(1,0.95,0.55,1),"pos":Vector2(960,170),"mechanic":"受击后化为白光短暂消失，随后出现在目标背后重新开火。追击它时，背侧航线必须始终留有余地。"},
	{"id":"DivineBrokenWingAssassin","name":"折翼刺客","family":"神明使者","behavior":22,"hp":32,"damage":14,"size":Vector2(84,100),"color":Color(0.82,0.86,0.9,1),"accent":Color(1,0.86,0.42,1),"pos":Vector2(960,170),"mechanic":"每次刺杀前都会以白光重定位，短暂显形后发动突锋。它擅长从背后重置距离，打断稳定输出。"},
	{"id":"DivineSeraphHunter","name":"炽天追猎者","family":"神明使者","behavior":23,"hp":1150,"damage":16,"size":Vector2(224,208),"color":Color(0.98,0.92,0.72,1),"accent":Color(1,0.72,0.24,1),"pos":Vector2(960,160),"mechanic":"大型追猎核心会在受击后重新闪现并锁定新的突锋线。冲刺阶段几乎不受拦截影响，命中会强行切断操作节奏。"},
	{"id":"DivineOraclePhantom","name":"神谕幻影","family":"神明使者","behavior":24,"hp":1300,"damage":12,"size":Vector2(216,224),"color":Color(0.78,0.9,1,1),"accent":Color(1,0.88,0.38,1),"pos":Vector2(960,160),"mechanic":"倾向占据背侧航路，并周期性唤出蓝色圣羽幻影。幻影无法被击落，却会立刻锁定目标完成一次预兆突袭。"}
]


static func get_enemy(id: String) -> Dictionary:
	for enemy in ENEMIES:
		if enemy.id == id:
			return enemy
	return {}
