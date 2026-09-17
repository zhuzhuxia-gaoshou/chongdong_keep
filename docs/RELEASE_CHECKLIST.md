# 宠动Keep 发布清单（E4-2 固化）

> 2026-09-17 · 移动发布工程师整理。目标：白天用户拍板后，按本清单从「可装机体验」走到「可上架」。
> 现状定位：**代码与工程化已就绪，四件用户资产未到位**（keystore / 域名备案 / 软著 / 服务器续费 09-27）。
> 红线提醒：本清单只描述，不代做——创建 keystore、购买域名、部署上线均为用户白天动作。

---

## 一、签名（E4-1 已接线，待用户建 keystore）

### 当前行为（`android/app/build.gradle`，commit ace0df6）

| key.properties 状态 | 构建行为 |
|---|---|
| 文件不存在 | 正常构建，**debug 签名回退**，Gradle 日志打 WARN「不可上架」 |
| 存在但缺任一必填字段 | 构建失败，报错列出缺失的 key 名 |
| storeFile 指向的密钥文件不存在 | 构建失败报错（防静默错签） |

- 必填四项：`storeFile` / `storePassword` / `keyAlias` / `keyPassword`。
- `storeFile` 支持**相对路径**，从 `android/` 目录解析（如 `../chongdong-upload.jks`）。
- `key.properties`、`*.jks`、`*.keystore` 均已在 `android/.gitignore`（第 9-12 行），不会入库。
- `applicationId = com.chongdong.chongdong_keep` **一行不动**（SPEC §5.3 禁改项）。
- ⚠️ 「缺失→debug 回退」路径已实测（24.6MB release APK 构建成功）；「正式签名」路径**未验证**——需要用户真实 keystore 才能闭环。

### 用户白天建 keystore 步骤（约 5 分钟）

```bash
# 1. 生成（密码自己保管，丢了无法更新应用！）
keytool -genkey -v -keystore chongdong-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
# 2. 把 jks 放到 android/ 目录之外的安全位置（如 D:\myprojects\keys\）
# 3. 新建 android/key.properties（不入库）：
#    storeFile=../../keys/chongdong-upload.jks   （相对 android/ 解析）
#    storePassword=***、keyAlias=upload、keyPassword=***
# 4. 验证：flutter build apk --release，日志无 WARN 即走正式签名
```

---

## 二、版本与构建

| 项 | 现状 | 说明 |
|---|---|---|
| 版本号 | `1.0.0+1`（pubspec.yaml） | 上架前如需递增：改 `version`，`+` 后是 versionCode |
| 体验包（Mock） | ✅ 已验证 | `flutter build apk --release` → `build/app/outputs/flutter-apk/app-release.apk`（24.6MB）；**Mock 模式 + debug 签名，只装真机体验，不可提交商店** |
| Live 包（连真后端） | 命令见 README | `--dart-define=API_BASE_URL=...`（可另注 QWEATHER_KEY/QWEATHER_HOST/TENCENT_MAP_KEY）；密钥只在编译期注入，不入库 |
| Web 包 | `flutter build web` | 产物 `build/web`，静态托管即可 |
| 权限基线 | Manifest 11 项 | 与 SPEC §5.3 存档一致，**只增不删**；Impeller 禁用 meta-data（小米/HyperOS 白屏规避）保留 |

---

## 三、合规（一硬门槛待补）

| 项 | 状态 |
|---|---|
| 首启隐私同意门 | ✅ 登录前必须勾选协议（未勾点登录被 SnackBar 拦截，login_page.dart `_agreed`） |
| **协议/隐私政策全文入口** | ❌ **未接**：《用户协议》《隐私政策》两个 TextSpan 仅着色无点击行为（login_page.dart:313-318）。上架硬门槛——需接全文页（内容源：`chongdong_server/docs/legal/` 两份模板，挂 HTTPS 后远程加载或内置打包，二选一） |
| 法务模板 | 后端仓库 `docs/legal/` 已有两份 HTML（运营者/邮箱/日期为 `{{占位}}`，**发布前需法务审阅 + 填真值**） |
| 账号删除权 | ✅ 设置页注销 → `DELETE /users/me {confirm:true}`，事务清数据、token 失效 |
| 第三方 SDK 事实 | 腾讯位置服务（轨迹/静态图/逆地理）+ 和风天气，模板中已如实列出；不得宣传未实现能力（相册保存、后台持续追踪等尚未接通，模板已按事实措辞） |

---

## 四、市场上架材料

- [ ] 正式签名 APK/AAB（依赖第一节）
- [ ] 软著证书（国内主流商店硬性要求；纯用户动作，周期以受理为准）
- [ ] ICP 备案域名 + 可公网访问的隐私政策 URL（依赖后端部署）
- [ ] 应用截图/介绍文案（App 内截图即可，温柔治愈系口径见 DESIGN_SYSTEM §8）
- [ ] 测试账号（给审核员：真实手机号能收验证码，或与后端商定白名单假号）

---

## 五、后端就绪（依赖用户「部署」拍板）

| 项 | 状态 |
|---|---|
| 部署物 | `deploy/` 脚本 + `docs/ops/`（pm2 ecosystem、nginx HTTPS 模板、全流程 README）已备好，**均未执行** |
| env 安全 | 必需变量缺失/弱 secret 启动即失败（82cb736） |
| 健康探活 | `GET /ping` 带 DB/Redis 状态（c72bff7） |
| 数据库索引 | `exercise_records(userId,startTime)` 迁移**提案未部署**（5a78ffc），随下次 `migrate deploy` 应用 |
| 限流 | sms-code 已限；其余 16 端点限流为提案未安装（`docs/SECURITY_AUDIT.md`），上线首周建议关注异常流量 |
| 冒烟 | `deploy/smoke.sh` 全链路用例就绪，部署后跑一遍 |

---

## 六、时间线与硬门槛

| 顺序 | 事项 | 归属 | 卡点 |
|---|---|---|---|
| 1 | 服务器续费 | 用户 | **09-27 到期**，过期则部署基线（环境/数据）消失，一切上线动作延后 |
| 2 | 建 keystore + key.properties | 用户 | 5 分钟；正式签名唯一前提 |
| 3 | 域名购买 + ICP 备案 | 用户 | 决定隐私政策 URL 与 HTTPS，周期以服务商为准；**今天提交最划算** |
| 4 | 部署后端（deploy.sh + smoke.sh） | 用户拍板后工程师执行 | 依赖 1、3（HTTPS） |
| 5 | 接协议全文入口（第三章 ❌ 项） | 工程师 | 上架硬门槛，半天工作量 |
| 6 | 软著申请 | 用户 | 与 3 并行 |
| 7 | 出正式签名包 + 商店提审 | 工程师 | 依赖 2、4、5、6 |
| 8 | 插件批准：保存相册（分享卡存图）/ flutter_secure_storage（token 加密） | 用户 | 二期体验项，不阻塞上架 |

**硬门槛（不满足不提审）**：正式签名 ✗ / 协议全文入口 ✗ / 隐私政策公网可访问 ✗ / 后端未部署 ✗。
