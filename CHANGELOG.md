# Changelog

宠动Keep 前端（chongdong_keep）版本史，格式遵循
[Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)。

项目尚未对外发版（未上架、无 tag），全部条目归入 `[Unreleased]`，
按开发批次（日期 + commit 区间）倒序分组；每条附 commit hash 便于追溯。

## [Unreleased]

### 2026-09-17 · 发布准备与门禁修复（ace0df6、372136f）

#### Added

- Android 正式签名接线：key.properties 存在走 release 签名，缺失回退 debug 并打 WARN；凭据不完整或密钥文件不存在构建即报错，防静默错签；applicationId 零改动（ace0df6）
- `docs/RELEASE_CHECKLIST.md` 发布清单：签名/版本/合规/市场/后端就绪五节 + 时间线硬门槛（ace0df6）

#### Fixed

- CelebrationScale 曲线 `chain()` 误挂在 TweenSequenceItem 上导致的编译失败；测试查找器限定组件子树，不再误计页面转场动画（372136f）

### 2026-09-17 · E5 无障碍（f508d0a..b8585e6）

#### Added

- 登录页验证码/协议勾选按钮语义、首页消息中心与切换宝贝按钮角色、UserAvatar/buildLocalImage `semanticLabel` 参数（f508d0a、6c96f32、b8585e6）
- 纯装饰元素排除读屏：PageHero 爪印水印、EmptyState 主 emoji、BadgeCircle 字形、天气字形、物种水印（71e1e0c 等）

### 2026-09-16/17 · R4/R5 分享卡海报可读性（cc75a1d..e3c83b9、cfe7de5、0236dbf）

#### Fixed

- 五套海报版式落地「浅底深字、深底白字」：新增墨色 token `posterInk`（实测对比度 mint 5.45:1 / coral 6.37:1 / posterData 7.14:1），主辅文字全色直用、取消 alpha 派生；两处 10px 升 fsCaption（cfe7de5 等）
- 数据风 `_mapFrame`/`_playBlock` dark 双态，共用块青底白字遗留清零（8e0d00a、cc75a1d）
- `DESIGN_SYSTEM.md` §5.4 海报版式规则 + 五版式对比实测表（e3c83b9、0236dbf）

### 2026-09-16 · D3 克制的愉悦感（a7572dd..81bf68a）+ HOLD 返工（c8c282d、1d380cf）

#### Added

- CelebrationScale 纯 scale 弹跳（禁透明度入场），日历今日格打卡点亮时播放一次；组件级棘轮防重播（a7572dd、c8c282d）
- 首页连胜 3/7/14/30 里程碑奖杯说明条、四处 PressableScale 按压反馈、补签 SnackBar 票点图标、空态文案按日轮换（57f7ac6、8f0ac1d..7c43c35、0e47b75、918dacf）
- 两份设计提案：暂停/继续时长语义（推荐口径 B）、消息 Tab 本地消息形态（推荐里程碑通知先行）（4c4adae、81bf68a）

#### Fixed

- 遛狗「不舒服」五枚症状按钮 emoji 换 Material 图标，落实按钮零 emoji（1d380cf）

### 2026-09-16 · D2 品牌守护（d74c1f2..dc8152e）

#### Changed

- 板外私造色 4 处清零；30 条命令式/指责式文案改温柔治愈系；emoji 政策定稿（功能位 Material 化）；称谓表（你/宝贝/它）；BrandCopy 四类文案池 + 7 条守护测试；四处裸弹层收编 AppBottomSheet（d74c1f2、c7afc4c、18ffa7c、30e9348、47e64b7、dc8152e）

### 2026-09-15/16 · D1 设计系统 v3（a450871..f204922）

#### Added

- `docs/DESIGN_SYSTEM.md` 设计契约 v3：token 语义表/渐变白名单/字重豁免/图标 family 规则/组件选型指南（f204922）
- 新组件：AppChip、ErrorRetry、LoadingView；iconSm/Md/Lg 图标尺寸 token 43 处落地；cardElevatedOutline 描边轻影变体（cf15a8a、b5e47d0、23158b2、a450871）

#### Changed

- 密集宫格改描边平面；功能图标全库统一 `_rounded`（65 行 23 文件）；四页手写空态收编 EmptyState；app_theme 字面量全部归档 token（b7102b1、f788d30、fd4efc4、fbd5f82）

### 2026-09-15 · 质感 v2 十四页 + 审查返工（f082f53..bab027b）

#### Changed

- 全局质感底座 v2（PageHero/EmptyState/IconChip/numericStat）铺开至日历/健康/猫玩/排行榜/遛狗/宠物/家庭/医院/商城/设置等十四页：白卡浮起、emoji 界面件 Material 图标化、字重纪律（w800/w900 退役）、板外色回收（bb9432e..87a9128 等）

#### Added

- 注销账号接通 `DELETE /users/me`：两步危险确认 + 防重入 + Mock 链路用例（d620e19、586da08）

### 2026-09-13 · 设计五改版 + 整页空白事故修复（48e8bd0..5c867cf）

#### Changed

- 五步设计落地：canvas 画布/双层投影、首页 Hero 渐变大卡、悬浮玻璃 Dock、周报字重交响、设置页分组化（48e8bd0..4480579）

#### Fixed

- 真机「整页空白」三连根因修复：FadeTransition 停在透明度 0（动效红线由来）、BackdropFilter 毛玻璃、DockItem 松约束下误用 Center；Impeller 禁用规避小米/HyperOS 渲染异常（95518f3、6050749、5c867cf）

### 2026-09-05 · M4 收官与真机回归（78e1ebc..a5da52d）

#### Added

- 排行榜/徽章接真实接口、补签卡接通、周报本地聚合、设置页收官（开关持久化/导出/删除记录）、出发照片与隐私开关接真、本地运动提醒、Web 平台启用（e3e76d3、9240a05、1cd1eba、e5fe558、facb2ef、78e1ebc 等）
- 分享卡 5 套真实版式 + 腾讯静态图轨迹描线（配额耗尽/Web 自动回退手绘）（23f23d9、8c0ee8e）

#### Fixed

- 首页冷启动红屏（滚动视图无界高度下 CrossAxisAlignment.stretch）+ 回归守卫测试；multipart 上传 40006；腾讯逆地理配额缓存；周报图表溢出等真机回归 20+ 项（a44eed5、78c9deb、49052fc、1ff85bb 等）

### 2026-09-05 前 · 初始开发

- 双模式架构（Mock/Live）、登录/宠物/运动记录/打卡日历核心链路、遛狗/陪猫玩、健康页、消息商城占位等（见 `git log --reverse`）

[Unreleased]: https://keepachangelog.com/zh-CN/1.1.0/
