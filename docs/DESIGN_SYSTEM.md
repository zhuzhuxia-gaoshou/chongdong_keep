# 宠动Keep 设计契约 v3

> 2026-09-15 D1 设计夜定稿。上位版本：质感 v2（同日 B 阶段 17 commit）。
> 唯一事实来源（代码）：`lib/theme/app_colors.dart` / `lib/theme/app_dimens.dart` / `lib/theme/app_theme.dart`（含 AppText）/ `lib/widgets/ui_kit.dart`。
> 本文档是契约的**人读版**：token 与组件变更必须同 commit 更新本文；本文与代码冲突时以代码为准，并立即回来修文档。

---

## 0. 设计基调与红线

### 0.1 基调
薄荷绿 + 米白 + 珊瑚橙浅色系（用户拍板，**不改配色、不做深色模式**）。
高级感配方 = 画布与卡片半档分离 + 双层投影 + 大号细体数字 + 全库一致的圆角语言。

### 0.2 四条红线（历史事故，任何 UI 改动前先自查）
1. **滚动视图无界高度下 `CrossAxisAlignment.stretch`**（09-13 首页红屏根因）。
2. **松高度约束下直接放 `Center`**（09-13 整页空白根因）。EmptyState / ErrorRetry / LoadingView 自身**不含 Center**，由调用方在有界 body 内包 `Center`。
3. **透明度类入场动效**（FadeTransition / AnimatedOpacity）禁止——装饰层用**静态**低透明度图形（PageHero 装饰圆即此写法）。动画纪律（2026-09-16 D3 夜修订）：scale 类微庆祝被授权引入，唯一出口 `CelebrationScale`（纯 scale、静止态恒 1.0 完整可见、仅 celebrate 上升沿触发一次，初始可见性绝不依赖动画推进）；透明度类动效仍然零容忍。
4. **禁改**：包名 / keystore / Manifest 权限 / 幂等键 / 打卡口径；不动 `android/`、`pubspec.yaml`（零新依赖）、后端。

---

## 1. 色彩（AppColors）

### 1.1 色板语义表

| token | 值 | 语义与用途 |
|---|---|---|
| `mint` | `0xFF4CAF82` | 品牌主色：主操作、选中态、进度、统计数字 |
| `mintLight` | `0xFFE8F5EF` | 薄荷 tonal 底：选中面、空态圆底、图标章 |
| `mintBright` | `0xFF6BC89D` | `heroGradient` 终止端（PageHero 页头） |
| `mintDeep` | `0xFF2E7D5F` | 首页今日目标卡渐变深端；其 20% 作渐变卡落地影 |
| `mintLine` | `0xFFD0E9DC` | mintLight 填充卡的描边伴侣 |
| `sky` / `skyDeep` / `skyLine` | `0xFFE4F2FC` / `0xFF4A9FD9` / `0xFFD4E8F7` | 天蓝辅色：信息类图标章 / 链接蓝 |
| `coral` / `coralLight` / `coralDeep` / `coralLine` | `0xFFFF8A65` / `0xFFFFE8DF` / `0xFFEE6D45` / `0xFFFFD9C8` | 珊瑚点缀：急救语义、警示提示、票点 |
| `amber` / `amberLight` | `0xFFFFB74D` / `0xFFFFF3E0` | 症状自查「建议观察」中间风险档（已收编，勿页面私造） |
| `warning` / `warningText` | `0xFFFFF3CD` / `0xFF8A6D3B` | 开发标识（MOCK 角标）、预警文案底 |
| `cream` / `sand` | `0xFFFBF9F5` / `0xFFF5F1EA` | 次级中性底：输入框填充 / 图标章与状态圆底（图片加载失败占位底亦走 sand，D2-1 收编冷灰 `0xFFEFEFEF`） |
| `posterMagazine` / `posterData` / `posterNight` | `0xFF7E57C2` / `0xFF26C6DA` / `0xFF37474F` | 海报模板身份色（D2-1 从 share_card_page 收编）：仅导出海报的模板切换引用，属内容生成面的版式语言，**非 UI 语义色，板外禁用**；底上文字色按 §5.4「浅底深字、深底白字」（posterData 浅底深字 / posterMagazine·posterNight 深底白字） |
| `posterInk` | `0xFF1F2A2B` | 海报浅底墨色（R5 守门员 HOLD 返工收编，2026-09-17）：`text` 同青灰色相加深（`2E3A3B` → `1F2A2B`，色相 186° 不变）。三套浅底版式（mint 可爱 / posterData 数据 / coral 生日）主文字与辅文**全色直用**，辅文不做 alpha 派生；WCAG 实算压 mint ≈5.45 / coral ≈6.37 / posterData ≈7.14:1（text 压 mint 仅 4.35，故不能直用）。属内容生成面，**板外禁用**——App 界面主文字仍是 `text` |
| `canvas` | `0xFFF3EFE8` | 页面画布，比卡片深半档，白卡凭投影浮起 |
| `card` | `0xFFFFFFFF` | 卡片白 |
| `line` | `0xFFECEAE5` | 描边、分隔线 |
| `text` / `textSoft` / `textMute` | `0xFF2E3A3B` / `0xFF7A8688` / `0xFFA8B0B2` | 主文字 / 次级文字 / 弱化文字 |
| `onAccent` | `0xFFFFFFFF` | 渐变/强调面之上的文字与图标 |
| `heroGradient` | mint → mintBright | 五处页头共用品牌渐变配方 |
| `coralGradient` | coral → coralDeep | 急救语义渐变（唯一主角豁免，见 1.2） |

### 1.2 用色规则
- **渐变白名单（唯一主角原则）**：全库只允许三处渐变——① `heroGradient`（PageHero 页头）② 首页今日目标卡 `[mint → mintDeep]` 对角渐变 ③ `coralGradient`（急救语义豁免）。新增渐变一律拒绝，走 tonal。
- **影基色一律 `text` 色相（2E3A3B 族）**，禁止裸黑 `Colors.black`（D1-1 守门员点名项，已收编为 `shadowCardLight`）。
- **tonal 配方** = 淡底 + 同族深字/图标 + 描边伴侣色：`mintLight+mint+mintLine`、`coralLight+coral+coralLine`、`sky+skyDeep+skyLine`。tonal 面不加影。
- **禁板外私造色**：页面需要新语义色时先收编进 AppColors 再用（amber 收编为先例）。
- **品牌色透明度变体一律派生（D2-1 定稿）**：品牌色的 alpha 变体（渐变卡落地影 = mintDeep 20%、徽章辉光 = mint 30%）必须写 `AppColors.xxx.withValues(alpha: n)` 从 token 派生，禁止硬编码 ARGB 字面量——主色若调、变体随动；独立 token 会重复编码同一色相，造成失联。
- **D2-1 色彩秩序审计结论（2026-09-15）**：板外 `Color(0x…)` 扫描 4 处违例全部处置——home 渐变卡落地影 `0x332E7D5F`→派生、ui_kit BadgeCircle 辉光 `0x4D4CAF82`→派生、local_image 占位灰 `0xFFEFEFEF`→`sand`、share 海报三色→`poster*` token 收编；复查命令见 §7。

---

## 2. 尺寸（AppDimens）

### 2.1 圆角七档
| token | 值 | 用途 |
|---|---|---|
| `rXs` | 4 | 微徽标（MOCK 角标） |
| `rSm` | 8 | 小元素 |
| `rMd` | 12 | 输入框、图标章、宫格卡、snackBar |
| `rLg` | 16 | 白卡默认（cardBox / cardTheme / dialog） |
| `rXl` | 20 | 大面积容器、底抽屉顶角、首页目标卡 |
| `rXxl` | 28 | 悬浮 Dock、PageHero 底沿 |
| `rFull` | 999 | 胶囊、主按钮 |

### 2.2 间距：严格 4 级制
可用档：`sp4 / sp8 / sp12 / sp16 / sp20 / sp24 / sp32 / sp40 / sp60`。禁止 6/10/13/14 这类偏格值。
**豁免（历史定稿，硬归档会改尺寸，有意保留）**：主按钮 vertical 14、次按钮 vertical 13、输入框 contentPadding 14/13（app_theme.dart 内有注释标记）。

### 2.3 字号十档
| token | 值 | 语义 |
|---|---|---|
| `fsMicro` | 10 | 微标签（统计说明/徽章） |
| `fsCaption` | 11 | 注脚、协议小字 |
| `fsFoot` | 12 | 分区标题、字段 label、AppChip 主文案 |
| `fsBody` | 13 | 正文-小 |
| `fsBodyMid` | 14 | 正文（PRD 规范正文） |
| `fsSub` | 15 | 强调正文/弹窗标题/主按钮 |
| `fsTitle` | 17 | 页面级标题 |
| `fsHeadline` | 18 | 区块大字、PageHero 标题 |
| `fsStat` | 20 | 统计数值 |
| `fsDisplay` | 24 | 展示级标题（`textTheme.headlineLarge`；D1-6 补档） |

**豁免（不入十档）**：`AppText.numericHero` 52 / `numericSection` 30（展示体专用尺寸）；emoji 与登录品牌字标等展示字形。
**落地要求**：页面 TextStyle 一律引用 token，禁止裸数字字号（D1-6 已将 textTheme 九槽与按钮/输入框/圆角全部归档）。

### 2.4 图标尺寸三档（D1-2）
| token | 值 | 用途 |
|---|---|---|
| `iconSm` | 16 | 行内小图标（按钮内联/紧凑行尾） |
| `iconMd` | 20 | 常规功能图标（菜单尾箭头/列表行） |
| `iconLg` | 24 | 大号功能图标（宫格/空态引导） |

**豁免（非功能 Icon，不入三档）**：PageHero 爪印水印（emoji 字形 64）、EmptyState emoji（40）、BadgeCircle emoji（`size*0.5`）、ErrorRetry 状态图形（32，插画级）、LoadingView 进度圈（28，参数化）、IconChip 内部推导（`size*0.56`）、profile 头像编辑角标 `edit_rounded`（`sp20*0.55`≈11，20px 角标内推导，D2-3 从 ✏️ 收编）。
功能 Icon 的 `size:` 字面量现状（守门员 D4 终审纠正为事实表述，2026-09-16 grep）：**16–24 区间已清零**（`size: 1[6-9]|2[0-4]` = 0 处）；**<16 的功能图标尚有 14 处待归档**（login 13 / home 14×2 / calendar 票点 10 / weekly_report 15×2 / pet_detail 13 / profile 14 / share_card 操作按钮 15×2 / walk 14×3 / tencent_map 14），**>24 的占位插画级另有 8 处待判定归档或豁免**（health_safety 30 / cat_play 26 / add_pet 30×2 / walk 地图占位 40 / local_image 28×2 / tencent_map 40）。新增图标必须走三档；待归档项只减不增。

### 2.5 投影刻度（影基色统一 text 色相 2E3A3B）
| token | 结构 | 用途 |
|---|---|---|
| `shadowCard` | 双层：4% text (0,1,2) + 6% text (0,6,16) | 白卡默认浮起（SectionCard/cardBox 默认） |
| `shadowCardLight` | 单层：4% text (0,2,6) | 描边浮起卡的轻接触影（`cardElevatedOutline`） |
| `shadowFloat` | 单层：10% text (0,8,24) | 悬浮层（Dock/浮层） |
| `shadowNone` | 空 | 显式无影 |

### 2.6 表面配方与密集宫格禁令（D1-4 结论）
- **`cardBox()`**：默认白底 + `shadowCard` 双层影；传 `borderColor` 即转描边平面（零影）；传 `color` 即 tonal 平面；`radius` 参数用于与同格位选中态圆角对齐。
- **`cardElevatedOutline()`**：白底 + line 描边 + `shadowCardLight` 轻影——用于「带描边但仍需与画布分离」的表面，典型是双态选择卡的未选中面（选中面 tonal 平面）。禁止再手写 decoration（D1-1 已收编 add_pet_page 裸黑影）。
- **密集宫格禁令**：格间距 ≤ `sp8` 的宫格不得用默认双层影（环境影 offset 6/blur 16 外扩约 22px，远超 8px 沟槽，必压邻格）。改用 `cardBox(borderColor: AppColors.line, radius: 与选中态一致)` 描边平面。已处置：health 症状宫格（4 列）、cat 玩法宫格（2 列）。

---

## 3. 字体排印（AppText + 字重纪律）

### 3.1 数字体四档（数据数字唯一合法出口）
| 档 | 规格 | 用途 |
|---|---|---|
| `numericHero` | 52 / w300 / ls -1.5 / h 1.0 | 首页今日目标大数字（浅底 text 色、深底 white） |
| `numericSection` | 30 / w400 / ls -0.8 / h 1.05 | 周报完成率、连胜天数 |
| `numericInline` | fsTitle 17 / w500 / ls -0.3 | 列表行的距离/时长 |
| `numericStat` | fsStat 20 / w600 / ls -0.3 | StatTile 等小空间数字 |

**原则：数据数字永远走数字体，禁止 w800/w900 粗体堆数字**（2026-09 字重交响，全库已清零）。

### 3.2 字重豁免清单（正式化，下轮审计以此为准，勿误报）
以下展示位允许偏离常规字重阶梯（w500 正文 / w600 标题 / w700 区块与页头）：
1. `share_card_page` —— 海报版式（文件头有声明）。**字重豁免 ≠ 可读性豁免**：五套版式文字色按 §5.4「浅底深字、深底白字」执行，浅底版式不得以本条豁免为由保留白字。
2. `login_page` 品牌字标
3. `pet_detail` / `profile` 宠物名昵称标题
4. `walk_page` 头像首字
5. 各页空态标题（EmptyState title w700）
6. `MockDevBadge`「MOCK」微徽标（w800 语义强调，非数据数字）

### 3.3 textTheme 桥接（D1-6）
Material textTheme 九槽全部映射 AppDimens 档位：headlineLarge=`fsDisplay`、headlineMedium=`fsHeadline`、titleLarge=`fsTitle`、titleMedium=`fsSub`、bodyLarge=`fsBodyMid`、bodyMedium=`fsBody`、bodySmall=`fsCaption`、labelLarge=`fsBody`、labelSmall=`fsMicro`。组件主题（按钮/输入框/卡片/底抽屉/snackBar/dialog/tabBar）的字号与圆角同样全部走 token，视觉零变化等值归档。

---

## 4. 图标（D1-5 审计结论）

### 4.1 family 规则
1. **功能图标一律 `_rounded`**（与品牌圆角语言一致），禁裸名、禁 `_sharp`。
2. **例外 A「同位双态」**：main_page 底部导航 inactive=`_outlined`（描线=未选）/ active=`_rounded`（实心=已选），仅限此一处，属状态语言而非 family 混用。
3. 名字自带 `_outline/_off` 语义者仍须加 `_rounded` 后缀（`delete_outline_rounded` / `location_off_rounded`）——**描线是语义，不是 family**。
4. rounded 家族内部的双态（如 `check_circle_rounded` ↔ `radio_button_unchecked_rounded`）不算例外。

### 4.2 审计现状（2026-09-15 D1 夜）
- 审计前：109 个图标名 = 57 `_rounded` / 14 `_outlined` / 38 裸名（64 处非 rounded 使用位）。
- 审计后：lib/ 全库 143 处 = 138 处 `_rounded` + 5 处导航双态 `_outlined` 例外；裸名 0、`_sharp` 0（commit 记录口径 141+5 另含测试夹具 4 处）。
- 复查命令：`grep -rho "Icons\.[a-zA-Z0-9_]*" lib/ | tr -d '\r' | sort -u | grep -v "_rounded"` 应只剩 main_page 导航五枚。
- 新增图标：先用 Material 图标站确认存在 `_rounded` 变体再引入。

---

## 5. 组件选型指南

### 5.1 表面选型决策表
| 需求 | 用 | 不要 |
|---|---|---|
| 设置/个人页分区（软标题+多行聚合） | `SectionCard(title:, children:)` | 手写白卡+标题 Column |
| 普通白卡内容面 | `AppDimens.cardBox()` 默认（自带双层影） | 手写 BoxDecoration |
| tonal 语义面（选中态/风险提示） | `cardBox(color: mintLight/coralLight/…)` 平面 | tonal 上加影 |
| 密集宫格（格距 ≤ sp8） | `cardBox(borderColor: line, radius: 同选中态)` 描边平面 | 默认双层影（压边，见 2.6） |
| 双态卡的未选中面 | `cardElevatedOutline()` | 裸黑手写影 |
| 胶囊：双态选择 / tonal 标签 / 说明条 | `AppChip`（selected 双态 / 显式 tonal 三色 / `message` 说明条三形态） | 三处各写一份 |
| 页面级空态 | `EmptyState` | 裸文本+大 emoji 手写 |
| 页面级加载 / 错误 | `LoadingView` / `ErrorRetry` | 裸 `Center(CircularProgressIndicator())` |
| 菜单行 | `MenuTile` | Row+箭头手写 |
| 统计小卡 | `StatTile`（数值自动走 `numericStat`） | 手写 w800 数字 |
| 菜单行前导 | `IconChip`（tonal 方块图标章） | emoji 前导、裸图标 |
| 可按压反馈 | 外层叠 `PressableScale`（`lib/widgets/pressable_scale.dart`），波纹交给 InkWell/按钮 | 任何透明度/缩放入场动效 |
| 成功时刻微庆祝（D3-1，如日历今日格点亮） | `CelebrationScale`（`lib/widgets/celebration_scale.dart`：celebrate 上升沿触发一次 1.0→1.15→1.0 纯 scale 弹跳，播完复位静态） | 透明度动效 / 常驻循环动画 / 首帧历史态重播 |
| 底部弹层（选择器 / 确认 / 结果面板） | `AppBottomSheet.show(context, title:, isScrollControlled:, builder:)`（`lib/widgets/app_bottom_sheet.dart`：透明底 + 白面板 rXl + 抓手条 + 居中标题 + SafeArea + sp20 内边距 + 键盘避让） | 裸调 `showModalBottomSheet` 手写面板/抓手条（D2-6 已收编 home 宠物选择、walk 出发照片/运动结果/症状 4 处克隆，板外清零） |

### 5.2 页面三态约定
- `EmptyState(emoji, title, message?, messages?, actionLabel?+onAction?)`：空态；CTA 可选。`messages?`（D3-5 空态文案轮换）：传非空数组时按 BrandCopy 确定性轮换取一条（默认日序，同日稳定隔天换新），优先于 `message`；为 null/空数组时行为与单文案完全一致。数据源建议直接传 BrandCopy 各池。
- `ErrorRetry(message, onRetry?, icon = wifi_off_rounded, actionLabel = '重试')`：异常态；`onRetry` 为空则不渲染按钮。
- `LoadingView(message?, size = 28)`：加载态。
- 共同约定：`mainAxisSize.min`、**自身不含 Center**——调用方在有界 body 内包 `Center`（红线 2 的防线在调用侧）；列表页可作 ListView 首 child。
- 收编边界：页面级才收编；按钮内联 16px 进度圈、home 天气 10px 微圈属行内指示器，**有意不收**。

### 5.3 有意保留的伪空态豁免（D1-8 写明）
- `mall`：品牌化「即将上线」占位页，有意保留。
- `route_favorites`：静态演示数据 itemCount 恒 4，无空分支；待真实数据接入时挂 EmptyState。
- `pet_detail` 卡内「暂无记录」标签与行内提示、`weekly_report` 空行提示、`emergency_care` 联系人缺失提示：均为**卡内行内占位**，非整页空态，不在收编范围。

### 5.4 分享卡海报版式：浅底深字、深底白字（R4 决-1 定稿，2026-09-16；R5 守门员 HOLD 返工修订，2026-09-17）
`lib/pages/share/share_card_page.dart` 五套导出版式（可爱 / 杂志 / 数据 / 夜景 / 生日）的文字色统一规则：

1. **规则**：**浅底深字、深底白字**。浅底版式主文字与辅文一律 **`AppColors.posterInk`** 全色直用（R5 修订：R4 的 `AppColors.text` 压 mint 实算仅 4.35:1 触红线，其 72% alpha 派生辅文 2.80~3.50:1 更不达标，故收编同色相加深的 `posterInk` 替换）；**辅文不用 alpha 派生，层级靠字号 / 字重区分**；深底版式保持白字系（white / white70 / white60）。**配色 token 现有值不动**——可读性靠换文字色解决，不靠调底色。**字号下限 `fsCaption` 11**：海报浅底路径全部文字 ≥11（R4 位置行 10→11；R5 兑现 `_dataCell` label 原 :550 与 `_playBlock`「一起玩了N分钟」原 :584 两处 10→`fsCaption`，后者与深底共用、白字侧同升）。
2. **判定方法**：以版式底色 token 为基准算白字对比度，**< 4.5:1（WCAG AA 正文）即视为浅底**，≥ 4.5:1 为深底。新增版式先算再定文字色，不凭观感；**主文字对比度 ≥4.5:1 是红线**，「≈4.5」这类贴线近似值不算达标（R4 mint 行「≈4.5」实为 4.35 的教训）。
3. **白色的归属**：白色只留给非文字元素——品牌线 / 爪印字形 / 胶囊底 / 头像圆底 / 地图白壳与描线 / 轨迹起终点标记。浅底版式路径上不得出现白字文字。
4. **机制**：共用块 `_badge / _mapFrame / _playBlock / _pill` 均带 `{bool dark = false}` 双态（cc75a1d `_badge` 先例），浅底版式调用一律传 `dark: true`，深底版式不传；含 `withValues` / 三元的 `TextStyle` 不得 `const`（`const TextStyle(color: AppColors.posterInk)` 合法——static const 引用）。深字侧淡底（徽章 / 数据格 / 猫玩块）= `posterInk` 6%，手绘回退描线亦走 `posterInk`。App 侧模板选择器芯片按 `_templates` 的 `darkText` 标记同走本规则（芯片底即版式身份色，白字缺口相同）。
5. **字重豁免 ≠ 可读性豁免**：§3.2 第 1 条对本页的豁免仅覆盖海报版式语言的重字重（w800 数字字形），**不豁免文字对比度**；文件头声明已同步此措辞，两处互引。

五套版式一览（对比度为 R5 WCAG 2.x 相对亮度**实算**值，sRGB 线性化后 L = 0.2126R + 0.7152G + 0.0722B，比值 = (L浅+0.05)/(L深+0.05)；基准 = 版式底色 token）：

| 版式 | 底色 token（L） | 主文字色 | 白字对比度 | 深字（posterInk，L=0.0212）对比度 | 结论 |
|---|---|---|---|---|---|
| 可爱风 | `mint` `0xFF4CAF82`（0.3381） | `AppColors.posterInk`（宠名 fsHeadline 18 / 胶囊数字 17，层级拉开；辅文同色全色） | 2.71:1 ✗ | **5.45:1** ✓ | 浅底深字 |
| 杂志风 | `posterMagazine` `0xFF7E57C2`（0.1515） | 白（white / white70 / white60） | 5.21:1 ✓ | — | 深底白字 |
| 数据风 | `posterData` `0xFF26C6DA`（0.4586） | `AppColors.posterInk`（数据格/徽章/猫玩块底 posterInk 6%） | 2.06:1 ✗ | **7.14:1** ✓ | 浅底深字 |
| 夜景风 | `posterNight` `0xFF37474F`（0.0588） | 白（white / white70 / white60） | 9.65:1 ✓ | — | 深底白字 |
| 生日风 | `coral` `0xFFFF8A65`（0.4038） | `AppColors.posterInk`（辅文同色全色） | 2.31:1 ✗ | **6.37:1** ✓ | 浅底深字 |

R5 修订记录：R4 表内 `text`（L=0.0392）深字对比度实算为 mint **4.35** / posterData 5.70 / coral **5.09**（原表「≈4.5 / ≈5.7 / ≈5.3」前后两项失真），72% 派生辅文压 mint 2.80 / 压 coral 3.20 / 压胶囊 35% 白底 3.50——全部由 `posterInk` 全色替换后达标；`posterInk` 压胶囊底（35% 白罩 mint，L=0.5122）≈7.89:1。

**审计命令**：`grep -n "Colors.white" lib/pages/share/share_card_page.dart`——命中应**只剩**三类：① 深底版式（杂志 / 夜景）的文字与装饰，含只被它们触达的 `dark = false` 分支（`_badge` / `_pill` / `_playBlock` / `_mapFrame` 浅色侧，以及杂志专用 `_statCol` / `_vLine`）；② 非文字元素（头像圆底 / 地图白边 / `_pill` 胶囊底 / `_mapFrame` 白 24% 底纹 / `_CardRoutePainter` 晕层与起终点标记）；③ 模板选择器的深底芯片（杂志 / 夜景）版式名。任何浅底版式（可爱 / 数据 / 生日）路径上的白字文字即违例。**基线**：R4 落地 commit（4be1d39）命中 33 处，全部落入 ①②③，逐行清单见该 commit body；R5（cfe7de5）复核仍 33 处，未增删白色。**配套命令**：`grep -n "AppColors.text\b\|withValues(alpha: 0.72)" lib/pages/share/share_card_page.dart`——海报浅底路径应零命中（允许命中：文件头注释、模板选择器选中边框等页面 chrome）；`grep -n "fontSize: 10"` 同文件——浅底路径应零命中（杂志深底版式与选择器芯片的 10 属既有范围）。

---

## 6. emoji 占位与称谓（品牌守护者 D2 夜定稿）

> 本章 D2 夜（2026-09-15/16）正式定稿：§6.2 emoji 政策（D2-3）、§6.3 称谓表（D2-5）。编号保持稳定，便于外部引用。

### 6.1 现状盘点（emoji 作为品牌字形的使用位，2026-09-15 扫描；D2-3 复核）
| 位置 | emoji | 形态 | D2-3 归类 |
|---|---|---|---|
| `PageHero.watermark` | 默认 🐾（各页可覆写） | 64px 白 14% 右下装饰水印 | 品牌字形 |
| `EmptyState.emoji` | 各页自定（🐾/💬/🐈…） | 88 mintLight 圆底内 40px 主视觉 | 品牌字形 |
| `BadgeCircle.emoji` / profile 徽章条 | 徽章图形（🔥🏅💎🚀👑…） | `size*0.5` 字形 | 身份字形 |
| `AppChip.leading` | pet_detail 宠物切换传 `speciesEmoji` | 前导小件 | 身份字形（功能语义则传 Icon，见 §6.2-6） |
| 宠物物种 / 运动类型 / 头像回退 | 🐕 🐈 🐾 👩 | 胶囊、行前导、CircleAvatar 回退 | 身份字形 |
| 天气 `conditionIcon` | 🌤️ 等（服务返回） | 首页天气行 | 数据字形 |
| 卡内行内占位 / SnackBar / Dialog 句末 | 🐾 💗 🥺 🎉 | 语气符 | 文案语气符 |
| 急救/症状风险文案 | ⚠️ | 风险卡建议行 | 安全语义豁免 |
| 登录页品牌区 / mall 占位页 | 🐾 48px / 🛒 44px | 品牌字标 / §5.3 有意保留占位页 | 品牌字形 |
| 分享海报模板 | 📖📊🌙🎂🎉📍 | 导出海报内容 | 内容生成面（不在 App UI 口径内） |
| ~~profile 编辑角标 ✏️×2 / record 照片丢失 📷~~ | — | — | **功能位违例，D2-3 已 Material 化**（`edit_rounded` / `no_photography_rounded`） |
| ~~walk 症状选择 OutlinedButton 前导 😫🤮😷🦴❓×5~~ | — | — | **功能位违例（D2-3 漏网：emoji 数据表与 `Button(` 分行，行级 grep 未命中），守门员 D4 返工已 Material 化**（`sentiment_dissatisfied_rounded` / `sick_rounded` / `masks_rounded` / `healing_rounded` / `help_outline_rounded`，iconSm） |

### 6.2 emoji 使用政策（品牌守护者 D2-3 定稿，2026-09-15）
**总纲：emoji 是品牌的「语气与身份」，不是「功能与状态」。** 与 §4 的衔接：凡表达动作、状态、导航、筛选的位置，用 Material `_rounded` 图标；凡表达品牌气质、宠物身份、情绪陪伴的位置，用 emoji。

1. **功能位零 emoji**：按钮 / Tab / AppBar 动作 / 菜单行前导（走 `IconChip`）/ 编辑·删除·更多等操作角标 / 加载·错误·缺失等状态占位 / 导航——一律 Material 图标。审计现状：本轮扫描 lib/pages+widgets 共 86 行 emoji，功能位违例 3 处已清零（profile 头像编辑角标 ✏️、昵称编辑提示 ✏️、record 出发照片丢失 📷），其余全部落入下列白名单；守门员 D4 终审补捉 walk 症状按钮 5 处漏网（emoji 在独立数据表中，见 §6.1 末行），已 Material 化。
2. **内容位白名单（四类）**：
   - **品牌字形**：PageHero 水印 🐾、登录页字标 🐾、EmptyState 主 emoji、mall 占位页 🛒。
   - **身份字形**：宠物 `speciesEmoji`（🐕/🐈）、头像回退（👩/🐾）、徽章图形、运动类型字形。它们是宠物/成就的「头像替身」，允许出现在胶囊前导、列表行前导、卡片角。
   - **数据字形**：天气 `conditionIcon` 等由服务返回的状态字形。
   - **文案语气符**：句末 🐾 💗 🥺 🌸 与庆典 🎉；急救/风险内容内的 ⚠️ 属安全语义豁免（安全 > 品牌集）。
3. **品牌语气符集**：`🐾 💗 🥺 🌸` 为主，`🎉` 仅限成就/庆典（打卡成功、连胜、徽章解锁）。✅ ❌ ⭐ 👍 等「功能感」符号不进文案（cat_play「打卡成功✅」由 D2-4 文案库替换为品牌集）。
4. **密度上限**：一句话 ≤ 1 个语气符；同一 SnackBar / Dialog 只用一种 emoji；一屏可见语气符 ≤ 3（EmptyState 主 emoji 不计）。
5. **无障碍**：emoji 不得作为唯一信息载体——旁边必须有文字（EmptyState 有 title、胶囊有 label、天气字形伴随文字描述）。新增纯装饰 emoji 建议包 `ExcludeSemantics`；现有 PageHero 水印属静态装饰层，列入待办不追溯。
6. **`AppChip.leading` 决议**：功能语义（筛选 / 排序 / 设置）传 `Icon(size: iconSm)`；身份语义（宠物切换）传 `Text(speciesEmoji)`。禁止为同一语义在不同页面混用两种形态。
7. **审计命令**：`grep -rnP "[\x{1F000}-\x{1FFFF}\x{2600}-\x{27BF}]" lib/pages lib/widgets --include="*.dart"`，逐行对照第 2 条白名单；命中 `Button(` / `Tab(` / `MenuTile(leading:` / 操作角标 / 状态占位的即违例。**注意**：emoji 数据表（`for (final s in const [(…), …])` 元组 / 常量列表）与消费它的 `Button(` 常分行，行级 grep 只见数据行不见按钮——命中数据表时需跨行核对其消费点（D4 漏网教训：walk 症状按钮）。

### 6.3 称谓表（品牌守护者 D2-5 定稿，2026-09-16）

**对用户的称谓**
| 场景 | 统一口径 | 示例（现状即范本） | 禁用 |
|---|---|---|---|
| 直接称呼 | 一律「你」 | 「你的手机号」「陪宝贝玩 5 分钟」 | 「您」——品牌是陪伴的朋友不是客服，全库当前零「您」，勿引入 |
| 昵称数据回退 | 「铲屎官」（仅占位数据位） | `nickname ?? '铲屎官'`（home/profile）、排行榜「匿名铲屎官」 | 回退改「用户」等系统腔；「铲屎官」不得写入主动文案正文 |
| 代码/文档语境 | 「用户」仅限注释与 PRD 对齐 | — | 涌入用户可见文案 |

**对宠物的称谓**
| 场景 | 统一口径 | 示例 | 禁用 |
|---|---|---|---|
| 情感语境主称谓 | 「宝贝」（跨物种统一，全库主流现状） | 「宝贝的名字还没填哦」「带 2 只宝贝出发」 | 「毛孩子 / 主子 / 汪星人 / 喵星人」网络腔漂移（当前零出现，勿引入） |
| 第三人称叙述 | 「它 / 它的」 | 「它的运动记录仍会保留」「带它去遛一圈吧」 | 「他 / 她」拟人错位 |
| 物种限定修饰 | 物种词可修饰，不替代 | 「添加一只猫咪宝贝吧」 | 用「宠物」做情感称呼 |
| 功能名词语境 | 「宠物」保留于档案/机构/商城等功能语义 | 宠物档案、宠物医院、宠物商城、「添加宠物」CTA | 功能语境强行拟人（如页面名改「宝贝档案」） |

**App 自称**
| 场景 | 统一口径 | 示例 |
|---|---|---|
| 全库字面 | 「宠动Keep」（大写 K；2026-09-16 grep 零大小写漂移） | 「欢迎加入宠动Keep！」「分享宠动Keep」 |
| 海报版式语言 | 「CHONGDONG KEEP」全大写（内容生成面豁免，§6.1） | share_card 海报页脚 |
| 分享语境第一人称 | 「我在宠动Keep…」 | 周报 / 运动记录分享语 |

**语气规范**：遵循 §8.1 温柔文案四标尺（不命令 / 不指责 / 语气符收尾 / 安全合规让位）；示例句式见 §8.2 对照表、§8.4 BrandCopy 文案库（人读镜像 `docs/copy_library.md`）。
**称谓审计命令**：`grep -rn "您\|毛孩子\|主子\|汪星人\|喵星人" lib/ --include="*.dart"`（应为空）；「铲屎官」命中应全部位于昵称回退 / mock 数据位。

---

## 7. 变更纪律与门禁
- **门禁**：每个代码 commit 前 `flutter analyze` 零问题 + `flutter test` 全绿且**只增不减**（v3 定稿基线 **97**；演进 92 → 95（AppChip +3）→ 97（ErrorRetry/LoadingView +2））。纯文档 commit 免门禁。
- **token 变更**：改代码与改本文档必须同 commit；新档位需在 commit message 说明理由（fsDisplay 补档为先例）。
- **新组件**：进 `ui_kit.dart`（或独立文件）+ 配测试用例 + 在 §5 选型指南登记 + 遵守三态组件「不含 Center」等约定。
- **commit 格式**：`type(scope): 中文一句话`；每任务独立 commit，禁止混合。
- **审计工具命令**（防回归）：
  - 图标字面量：`grep -rn "size: [0-9]\+" lib/ --include="*.dart"`（全量口径，D4 起生效；16–24 区间应为 0，其余对照 §2.4 待归档基线只减不增）。豁免（非功能 Icon）：PageHero 水印 64 / EmptyState emoji 40 / BadgeCircle `size*0.5` / IconChip `size*0.56` 推导 / ErrorRetry 32 / LoadingView 28 参数化。
  - 色彩字面量：`grep -rn "Color(0x" lib/ --include="*.dart" | grep -v "lib/theme"`（应为空，D2-1 起生效；`Colors.white/grey` 等系统色豁免）
  - 图标 family：见 §4.2 复查命令
  - 裸黑影：`grep -rn "Colors.black" lib/pages/`（应仅在豁免注释与登记豁免中出现）。登记豁免：`share_card_page` 夜景风地图角标 `Colors.black45`——海报内容遮罩而非投影（D4 登记）；同页卡壳影已由裸黑 15% 改走 `shadowFloat`。
  - 弹层品牌壳：`grep -rn "showModalBottomSheet" lib/ --include="*.dart" | grep -v app_bottom_sheet.dart`（应为空，D2-6 起生效）
  - 海报可读性：`grep -n "Colors.white" lib/pages/share/share_card_page.dart`（命中应只剩深底版式与非文字元素，判定口径与 33 处基线见 §5.4；R4 起生效，R5 cfe7de5 复核仍 33）；配套 `grep -n "AppColors.text\b\|withValues(alpha: 0.72)"` 与 `grep -n "fontSize: 10"` 同文件，海报浅底路径应零命中（R5 起生效，允许命中范围见 §5.4 末段）

---

## 8. 附录 A：温柔文案标尺与 D2-2 对照表（品牌守护者 2026-09-15 D2 夜）

### 8.1 温柔文案标尺（四条，全库用户可见文案以此为准）
1. **不命令**：禁「请 / 必须 / 不要 / 需」开头的祈使句。改为「先…哦」「…就好啦」「再…一下」的引导式。
2. **不指责**：禁「错误 / 不正确 / 无效 / 有误」判词。改为「好像没填对呢 / 再核对一下哦」的陪伴式。
3. **语气符收尾**：解释、引导、安抚类句子以「哦 / 呀 / 呢 / 啦」收尾；陈述事实的短句（如「该日期无需补签」）可不加，避免油腻。
4. **安全与合规让位**：免责声明、急救就医指令、系统级契约报错保留规范措辞（安全 > 语气）；但非急救的安全建议仍按 1–3 润色（「不要强行按压」→「先别强行按压哦」）。

**审计口径**：`grep -rn "请\|不要\|必须" lib/pages lib/widgets lib/services/weather_service.dart lib/network/api_exception.dart | grep -v "邀请\|申请\|请求\|// \|/// "` 输出应仅剩 §8.3 豁免清单。
**测试纪律**：`api_exception_test` 断言为 `contains` 子串（网络 / 频繁 / 太频繁 / 昵称 / 图片 / 服务器 / 请求失败），改写须保留关键词；本轮零测试改动。

### 8.2 对照表（30 条：原文 → 改文 · 理由）
| # | 位置 | 原文 | 改文 | 理由 |
|---|---|---|---|---|
| 1 | api_exception 网络 | 网络不给力，请检查网络后重试 | 网络不给力，稍后再试试呀 | 去「请」；保留「网络」 |
| 2 | api_exception 40101/40104 | 登录已过期，请重新登录 | 登录悄悄过期啦，再登录一次就好 | 去「请」；拟人化缓冲 |
| 3 | api_exception 40102 | 验证码错误或已过期 | 验证码不对或过期了，再核对一下哦 | 去「错误」判词 |
| 4 | api_exception 40103 | 发送太频繁了，请稍等再试 | 发送太频繁啦，稍等一下再试哦 | 去「请」；保留「频繁」 |
| 5 | api_exception 40001 + 400xx 兜底 | 请求参数有误 | 信息好像没填对，再核对一下哦 | 去「有误」判词 |
| 6 | api_exception 40002 | 昵称需为1~12个字符 | 昵称要 1~12 个字符哦 | 去「需」；保留「昵称」 |
| 7 | api_exception 403xx | 没有权限执行此操作 | 暂时没有权限做这件事哦 | 系统腔→陪伴腔 |
| 8 | api_exception 429xx | 操作太频繁，请稍后再试 | 操作太频繁啦，稍等一下再试哦 | 去「请」；保留「太频繁」 |
| 9 | api_exception 5xxxx（含 unwrapEnvelope 载体） | 服务器开小差了，请稍后重试 | 服务器开小差了，稍后再来哦 | 去「请」；保留「服务器」 |
| 10 | api_exception 兜底 | 请求失败，请稍后重试 | 请求失败啦，稍后再试试呀 | 去「请」；保留「请求失败」 |
| 11 | login 发码校验 | 请输入11位手机号 | 手机号还没输够 11 位哦 | 命令→状态描述 |
| 12 | login 协议校验 | 请先同意用户协议和隐私政策 | 先勾一下用户协议和隐私政策，就能继续啦 | 命令→引导 |
| 13 | login 登录校验 | 请输入正确的手机号和验证码 | 手机号或验证码好像没填对呢，再核对一下哦 | 去「正确的」暗示指责 |
| 14 | login 手机号 hint | 请输入手机号 | 你的手机号 | 占位符去「请输入」 |
| 15 | login 验证码 hint | 请输入验证码 | 短信验证码 | 占位符去「请输入」 |
| 16 | add_pet 名字校验 | 请输入宠物名字 | 宝贝的名字还没填哦 | 命令→状态；称谓「宝贝」 |
| 17 | add_pet 体重校验 | 体重需大于 0 kg | 体重要大于 0 kg 哦 | 去「需」 |
| 18 | add_pet 相册权限 | 无法打开相册，请检查权限 | 打不开相册呀，去设置里允许一下权限吧 | 去「请」；给路径 |
| 19 | profile 相机权限 | 无法打开相机或相册，请检查权限 | 打不开相机或相册呀，去设置里允许一下权限吧 | 同上 |
| 20 | walk 定位权限 | 需要定位权限才能记录遛狗路线，请在设置中开启 | 记录遛狗路线需要定位权限呢，去设置里开启就好 | 去「请」 |
| 21 | walk 无宠物空态标题 | 请先添加宠物 | 还没有宝贝档案 | 空态标题去命令；与首页「还没有…」句族对齐 |
| 22 | settings 通知权限 | 没有通知权限，请在系统设置里允许宠动Keep发送通知 | 还没拿到通知权限呢，去系统设置里允许宠动Keep发通知吧 | 去「请」 |
| 23 | badges 加载失败 | 加载失败，请重试 | 没加载出来呢，再试一次吧 | 去「失败/请」 |
| 24 | ranking 加载失败 | 加载失败，请下拉重试 | 没加载出来呢，下拉再试试呀 | 同上 |
| 25 | home 消息中心 | 消息中心即将开放，敬请期待 | 消息中心即将开放，敬请期待哦 | 与 main_page 同句族补语气符 |
| 26 | emergency_care 提示 | 不要自行喂药喂食（可能加重病情） | 先别自行喂药喂食哦（可能加重病情） | 「不要」→「先别…哦」，语义不减 |
| 27 | health_safety 抽搐建议 | 保持冷静，不要强行按压 | 保持冷静，先别强行按压哦 | 同上 |
| 28 | weather 雷暴建议 | 雷暴天气，请待在室内 | 雷暴天气，先待在室内哦 | 去「请」 |
| 29 | weather 雷暴预警 | 请待在室内，不要外出 | 待在室内更安全哦，先别外出啦 | 去「请/不要」 |
| 30 | nearby_hospitals 兜底 | 紧急情况请直接拨打… | 紧急情况可以直接拨打… | 「请」→「可以」 |

### 8.3 豁免清单（有意保留，下轮审计勿误报）
- **免责声明 ×2**：`emergency_care_page` 页脚、`health_safety_page` 页脚（合规文案保留规范措辞）。
- **急救就医指令 ×1**：`health_safety_page`「抽搐/中毒/严重外伤请立即就医」（安全优先，祈使保明确）。
- **系统级契约报错**：`mock_transport` 的 40001/40002 等 message（手机号格式不正确 / 请求体不能为空 / confirm 必须为 true…）——服务端语义，UI 经 `friendlyMessage` 转译。
- **异常载体文案**：`transport.dart` / `api_client.dart` 构造 ApiException 的 message（UI 只展示 `friendlyMessage`，不露出）。
- **信息型校验**：该日期无需补签 / 仅支持 JPG/PNG/WebP 图片 / 图片大小超出限制 / 内容不存在或已删除（陈述事实、无指责，不强加语气符）。
- **非命令用法**：「敬请期待哦」（敬语惯用）、「要不要就医」（疑问式）。

### 8.4 温柔文案库（D2-4）
- **代码唯一出口** `lib/utils/brand_copy.dart`（`BrandCopy`）；**人读镜像** `docs/copy_library.md`；两者改一处必同步另一处。
- 四类池：打卡成功 ×5 / 未达门槛 ×3 / 补签成功 ×4 / 连胜（里程碑 6 档 + 通用 ×3 + 0 天 ×3）/ 运动记录空态 ×3。
- 轮换用**确定性种子**（缺省日序 `daySeed`，成功类 toast 传业务量），同一天稳定、隔天换新——彩蛋感且可测试；页面禁止把文案字面量复制回来。
- **品牌守护测试** `test/brand_copy_test.dart`：遍历全部条目校验 §6.2-4 密度（≤1 语气符）、§6.2-3 品牌集（🐾💗🥺🌸🎉）、§8.1 不命令不指责，另测 pick 确定性 / 占位符替换 / 里程碑命中。新增条目必须过此测试。
- 落地引用 5 处：cat_play 打卡 SnackBar（顺带清除 ✅）、calendar 补签 SnackBar + PageHero 连胜副标题、walk 结果横幅、record_history 空态副文案。

---
**UI Designer** · 设计契约 v3 · 2026-09-15 D1 设计夜
**配套基线**：flutter analyze 零问题 · flutter test 97/97 · 前端 dev 分支（不 push）
