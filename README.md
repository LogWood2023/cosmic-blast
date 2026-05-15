# 高能⭐宇宙⭐大爆炸

2D 俯视角太空射击游戏 · Godot 4.6

## 玩法

驾驶星际战机，在深空中迎战来犯敌机。用鼠标瞄准射击，收集强化道具，在难度不断攀升的弹幕中存活。

| 操作 | 按键 |
|------|------|
| 移动 | WASD / 方向键 |
| 瞄准 + 射击 | 鼠标左键（按住连发） |

## 敌机类型

| 类型 | 外观 | 速度 | 生命 | 特征 |
|------|------|------|------|------|
| 快速机 | 紫色 | 快 | 1 | 一击即碎，穿梭游走 |
| 标准机 | 红色 | 中 | 3 | 均衡型 |
| 重型机 | 绿色 | 慢 | 6 | 厚甲耐打 |

## 道具

| 道具 | 效果 |
|------|------|
| 🔥 射速提升 | 射击间隔 -0.05s（最低 0.08s） |
| ⭐ 攻击提升 | 攻击力 +1 |
| 💚 生命恢复 | 生命 +1（上限 3） |
| 🛡 能量护盾 | 5 秒无敌 |

## 技术架构

```
Godot 4.6 · GDScript · 2D 俯视角

项目结构：
  assets/         资源（图片、音效、音乐）
  scenes/         场景（菜单、游戏、结束）
  scripts/        脚本（玩家、敌人、道具、UI 等）

核心模式：
  Area2D 碰撞检测      信号驱动（area_entered）
  PackedScene 嵌套      Autoload 全局管理
  状态机 AI             smoothstep 缓动
  region_rect 帧动画    Tween 补间动画
  _draw() 绘图 API      Parallax 卷动背景
```

## 运行

1. 安装 [Godot 4.6](https://godotengine.org/)
2. `git clone` 本项目
3. 用 Godot 打开 `project.godot`
4. 按 F5 运行

## 导出

Project → Export → Windows Desktop → Export Project
