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
3. **透明度类入场动效**（FadeTransition / AnimatedOpacity）禁止——装饰层用**静态**低透明度图形（PageHero 装饰圆即此写法）。本阶段原则：不引入任何动画。
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
| `cream` / `sand` | `0xFFFBF9F5` / `0xFFF5F1EA` | 次级中性底：输入框填充 / 图标章与状态圆底 |
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

**豁免（非功能 Icon，不入三档）**：PageHero 爪印水印（emoji 字形 64）、EmptyState emoji（40）、BadgeCircle emoji（`size*0.5`）、ErrorRetry 状态图形（32，插画级）、LoadingView 进度圈（28，参数化）、IconChip 内部推导（`size*0.56`）。
功能 Icon 的 `size:` 字面量已全库清零（2026-09-15 复查 grep `size: 1[6-9]` / `size: 2[0-4]` = 0 处），新增图标必须走三档。

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
1. `share_card_page` —— 海报版式（文件头有声明）
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

### 5.2 页面三态约定
- `EmptyState(emoji, title, message?, actionLabel?+onAction?)`：空态；CTA 可选。
- `ErrorRetry(message, onRetry?, icon = wifi_off_rounded, actionLabel = '重试')`：异常态；`onRetry` 为空则不渲染按钮。
- `LoadingView(message?, size = 28)`：加载态。
- 共同约定：`mainAxisSize.min`、**自身不含 Center**——调用方在有界 body 内包 `Center`（红线 2 的防线在调用侧）；列表页可作 ListView 首 child。
- 收编边界：页面级才收编；按钮内联 16px 进度圈、home 天气 10px 微圈属行内指示器，**有意不收**。

### 5.3 有意保留的伪空态豁免（D1-8 写明）
- `mall`：品牌化「即将上线」占位页，有意保留。
- `route_favorites`：静态演示数据 itemCount 恒 4，无空分支；待真实数据接入时挂 EmptyState。
- `pet_detail` 卡内「暂无记录」标签与行内提示、`weekly_report` 空行提示、`emergency_care` 联系人缺失提示：均为**卡内行内占位**，非整页空态，不在收编范围。

---

## 6. emoji 占位（章节骨架——品牌守护者 D2 夜补全）

> 本章为骨架预留：emoji 政策与称谓表由品牌守护者次夜正式定稿。补全时保持编号稳定，便于外部引用。

### 6.1 现状盘点（emoji 作为品牌字形的使用位，2026-09-15 扫描）
| 位置 | emoji | 形态 |
|---|---|---|
| `PageHero.watermark` | 默认 🐾（各页可覆写） | 64px 白 14% 右下装饰水印 |
| `EmptyState.emoji` | 各页自定（🐾/💬/🐈…） | 88 mintLight 圆底内 40px 主视觉 |
| `BadgeCircle.emoji` | 徽章图形 | `size*0.5` 字形 |
| `AppChip.leading` | 允许传 emoji 字形 | 政策待定：优先功能图标（§4） |
| 卡内行内占位 | 🐾（pet_detail）🌸（weekly_report）等 | 行内点缀 |
| 登录页品牌区 | 🐾 爪印字标 | 品牌字标豁免位 |

### 6.2 emoji 使用政策（**待品牌守护者补全**）
预留要点：何时允许 emoji vs 必须 Material 图标（功能/装饰边界）；emoji 密度上限；可否作为唯一信息载体（无障碍替身文本）；与 §4 图标 family 规则的衔接。

### 6.3 称谓表（**待品牌守护者补全**）
预留要点：对宠物的称谓（宝贝/毛孩子/它…）按场景与物种的统一口径；对用户的自称（「你」 vs 「铲屎官」）；语气规范（温柔、不命令）；示例句式库。

---

## 7. 变更纪律与门禁
- **门禁**：每个代码 commit 前 `flutter analyze` 零问题 + `flutter test` 全绿且**只增不减**（v3 定稿基线 **97**；演进 92 → 95（AppChip +3）→ 97（ErrorRetry/LoadingView +2））。纯文档 commit 免门禁。
- **token 变更**：改代码与改本文档必须同 commit；新档位需在 commit message 说明理由（fsDisplay 补档为先例）。
- **新组件**：进 `ui_kit.dart`（或独立文件）+ 配测试用例 + 在 §5 选型指南登记 + 遵守三态组件「不含 Center」等约定。
- **commit 格式**：`type(scope): 中文一句话`；每任务独立 commit，禁止混合。
- **审计工具命令**（防回归）：
  - 图标字面量：`grep -rn "size: 1[6-9]\|size: 2[0-4]" lib/`（应为空）
  - 图标 family：见 §4.2 复查命令
  - 裸黑影：`grep -rn "Colors.black" lib/pages/`（应仅在豁免注释中出现）

---
**UI Designer** · 设计契约 v3 · 2026-09-15 D1 设计夜
**配套基线**：flutter analyze 零问题 · flutter test 97/97 · 前端 dev 分支（不 push）
