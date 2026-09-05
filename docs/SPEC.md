# 宠动Keep · 技术规格书（SPEC）

> **版本**: v1.0（2026-09-05 重写，合并原《前后端协作规范》《API 接口契约 v0.2a》《交接文档》《前端开发计划》的有效内容）
> **负责人**: 项目唯一开发者（单人全栈）
> **配套文档**: 《PRD.md》（产品）、《PROGRESS.md》（进度）
> **本文件地位**: 技术实现的一处真相源。改接口/改架构先改这里，再写代码。

---

## 一、系统架构

### 1.1 总体拓扑

```
宠动Keep APP (Flutter · Android) ←——已完成，M1-M3+体验补全全部合入 main
   │  HTTP/JSON · Bearer JWT
   ▼
后端 API (从零重建 · 推荐 Node.js 20 + Express + MySQL)
   ├── MySQL   主数据（users / pets / exercise_records / refresh_tokens / badges）
   ├── Redis   延后引入（排行榜阶段再上，初期 MySQL 单库够用）
   ├── 文件存储 本地盘起步 → 对象存储（腾讯云 COS，¥50/月起）
   ├── 短信    真短信服务商（阿里/腾讯云，需签名+模板报备，尽早启动）
   └── 第三方  （二期把天气/地图代理到后端，APP 彻底不持第三方密钥）
```

> **背景**: 原后端负责人退出且 Git 仓库丢失，但 `47.104.129.148` 实为**本人购入的阿里云服务器**（当年把 IP 交给伙伴部署），旧后端至今仍在上面运行。服务器上大概率留有源码目录、`.env`（数据库密码）与部署脚本——**阶段 0 第 0 步先登录勘察**：能找回代码就改为「接管现有代码」，找不回再按本契约从零重建（重建依据 = §四 契约 v0.2a，按前端已实现行为定义，前端零改动可对接）。勘察期间旧服务保持只读不动。

### 1.2 仓库划分

| 仓库 | 内容 | 状态 | 分支模型 |
|---|---|---|---|
| `chongdong_keep`（GitHub: zhuzhuxia-gaoshou） | Flutter 前端 | ✅ 已有，main 可发布 | main ← dev |
| `chongdong_server`（新建，GitHub 私有） | 后端 + SQL 迁移 + 部署脚本 | ⬜ 待创建 | main ← dev |

### 1.3 环境清单

| 环境 | 地址 | 用途 |
|---|---|---|
| dev | VMware 虚拟机（Docker）里的后端容器（VM 内网 IP 待补到 SECRETS）；旧 47.104.129.148 仅作行为参考 | 开发联调，万能码 8888 |
| test | 阿里云服务器（已购）+ 测试库 | 上线前回归 |
| prod | 阿里云服务器（已购）；必须 HTTPS + 域名 + ICP 备案（周期 2-4 周，尽早启动） | 正式发布 |

### 1.4 后端技术选型（单人全栈推荐，定稿后勿反复摇摆）

| 层 | 选型 | 理由 |
|---|---|---|
| 运行时 | Node.js 20 LTS + Express | 与丢失的旧服务同栈（契约 D5 佐证 Express）；生态资料最多，AI 辅助开发效率最高 |
| 数据库 | MySQL 8（`mysql2` 连接池） | 契约数据模型基线即关系型；单库起步 |
| 缓存 | 无 → Redis（排行榜阶段） | 初期访问量用不上，降低运维面 |
| 认证 | JWT（access 10min + refresh 7d，可复用旧值）+ refresh_tokens 表 | ⑤ logout 用表删除即可，无需 Redis |
| 文件 | 本地盘 `uploads/` → 腾讯云 COS | 起步零成本，迁 COS 只换 URL 前缀 |
| 迁移 | 手写 SQL 脚本 `migrations/*.sql`（顺序执行，进仓库） | 无框架依赖，可追溯可回滚 |
| 部署 | 开发期：VMware 虚拟机 + Docker（docker-compose 编排 MySQL 8 + 后端，Windows 宿主直连 VM IP）；生产：已有阿里云服务器（Docker 部署 + nginx 反代） | 设施已就绪，零采购 |

### 1.5 后端目录骨架（0.2 建仓库时照此搭）

```
chongdong_server/
├── src/
│   ├── app.js              # Express 装配（信封统一包裹、错误码中间件）
│   ├── config.js           # 读 .env（端口/DB/短信/JWT 密钥）
│   ├── routes/             # auth / users / pets / upload / records / checkins / stats / ranking / badges
│   ├── controllers/        # 业务逻辑（对应契约 §四 各节）
│   ├── dao/                # SQL 封装（mysql2 连接池）
│   ├── middleware/         # authGuard（Bearer 校验）/ errorHandler（统一信封+错误码分段）
│   └── utils/              # envelope.js（{code,message,data}）/ smsCode.js / idGen.js
├── migrations/             # 001_init_users.sql ...
│                          # （验证码不用建表：dev 万能码 8888 直接放行；
│                          #   真短信接入前用进程内 Map 存码+TTL 即可，单实例足够）
├── uploads/                # 本地文件起步（gitignore）
├── .env.example            # 字段清单（真 .env gitignore）
├── package.json
└── README.md               # 「如何跑起来」三行命令
```

---

## 二、前端技术规格

### 2.1 技术栈（锁定，新增依赖需谨慎评估 Gradle 兼容）

| 分类 | 选型 |
|---|---|
| 框架 | Flutter 3.27.4 / Dart 3.6.2 / Material |
| 状态管理 | provider（ChangeNotifier） |
| 网络 | http + 自研 ApiClient（信封解包/401 单飞刷新/重试） |
| 定位 | geolocator 13 + permission_handler 11 |
| 地图 | 腾讯地图 WebService API + webview_flutter 展示 |
| 天气 | 和风天气 API |
| 存储 | shared_preferences（token 安全存储升级待做） |
| 拨号/外链 | url_launcher 6.3 |
| 图片 | image_picker + cached_network_image |
| 分享 | screenshot + share_plus |
| 测试门禁 | dart analyze 零问题 + flutter test 全绿 |

### 2.2 Mock/Live 双模式（核心机制）

- 判定收敛在 `lib/services/api_config.dart`：注入 `API_BASE_URL` ⇒ Live；未注入或显式 `MOCK=1` ⇒ Mock
- Mock = `MockTransport`（内置契约一致的假后端，固定验证码 123456，access TTL 120s 逼真触发刷新）
- Live = `HttpTransport` → 真后端
- 页面/仓库零感知切换；设置页显示当前环境 host + 「测试连接」ping

### 2.3 关键技术规则（踩过坑的，勿破坏）

| 规则 | 说明 |
|---|---|
| 坐标系 | 存储/上报一律 WGS-84；显示侧（腾讯地图、逆地理、POI 入参）先转 GCJ-02（`lib/utils/coord_convert.dart`） |
| 幂等上报 | 运动记录必带 clientRecordId（UUID v4）；重复提交服务端不重复入库返回 duplicated:true |
| 打卡判定 | isCompleted && duration≥300s，**不限运动类型**（前后端 + 本地兜底三处一致） |
| 推荐运动量公式 | cat: 15+(age<2?15:(age>7?-5:0))；狗-柯基/法斗/吉娃娃: age<1?20:(age>8?15:30)；狗-金毛/拉布拉多/边牧: age<1?40:(age>8?30:60)；其他狗: age<1?25:(age>8?20:40) —— 前后端不可各自私改 |
| GPS 漂移 | 15m/s 阈值数据入口拦截；弱信号=精度>30m 或 30s 无有效点 |
| 本地优先 | 记录先落本地再异步上报；失败入退避队列（30s→1m→2m→5m 封顶）+ 切回前台补传 |
| Content-Type | 所有 JSON 请求显式 `application/json; charset=utf-8`（真机 40000 事故根因） |
| 错误码容错 | 40100/40101 均触发刷新重放；expiresIn 字符串/数字均可解析；40000-40099 兜底展示后端中文 message |

### 2.4 前端目录结构

```
lib/
├── main.dart              # 入口 + 前台恢复(resumed)补传钩子
├── models/                # user/pet/exercise_record/walk_session + dto/(线上DTO)
├── network/               # api_client / transport / token_store / api_exception
├── repositories/          # auth / user / pet / record
├── services/
│   ├── api_config.dart    # Mock/Live 开关 + 密钥注入
│   ├── app_state.dart     # 全局状态：登录/宠物CRUD/记录/打卡/上传重试
│   ├── mock/              # MockTransport 假后端
│   ├── storage_service.dart # SharedPreferences（含遛狗会话快照）
│   ├── map_service.dart   # GPS/距离/漂移过滤/逆地理/医院POI
│   ├── weather_service.dart
│   └── upload_retry_schedule.dart
├── utils/                 # coord_convert / iso_time / uuid
├── theme/ widgets/        # 主题令牌 / 地图轨迹·医院·共享组件
└── pages/                 # 17+ 页面（auth/home/walk/cat/calendar/...）
test/                      # 80 用例（网络/Mock/DTO/恢复/退避/坐标）
```

---

## 三、数据模型基线（后端建表最小集）

> 字段名与前端 Dart 模型一致；后端可扩充不可改名/改语义。ID 一律字符串。

### users
| 字段 | 类型 | 说明 |
|---|---|---|
| id | string | 服务端生成 |
| phone | string | 登录凭证，返回统一脱敏（如 138****8000） |
| nickname | string | 1-12 字 |
| avatarUrl | string? | HTTPS |
| createdAt | datetime | |
| totalExerciseCount | int | 服务端统计，**不接受客户端上报** |
| streakDays | int | 连续打卡，服务端计算 |
| signCardCount | int | 补签卡，初始 3 |
| isPublicRank | bool | 隐私：是否参与公开排行榜，默认 true（设置页开关经 ⑦ 同步） |

### pets
id / userId(隶属) / name / species(dog/cat) / breed / gender(male/female) / ageYears / birthDate(为准) / weight(kg) / avatarUrl? / allergies[] / chronicConditions[] / isNeutered / isVaccinated / emergencyContact? —— 单用户上限 20 只（超限 40003）。

### exercise_records
id / clientRecordId(幂等键) / petId / userId / type(walkDog/catPlay) / startTime / endTime(带时区) / duration(**秒**) / distance(**公里**,两位小数) / steps / route(GeoPoint[]，存储自定但出入网 JSON 不变；≥5000 点前端抽稀) / locationName? / startPhotoUrl?(本地模型叫 startPhotoPath，API 层换名) / isCompleted / isManual —— 软删除宠物后记录保留。

### 派生逻辑归后端
打卡判定、周报/月报聚合、排行榜分数、徽章解锁——**全部服务端计算下发**，前端只渲染（防客户端造假）。

---

## 四、API 契约 v0.2a（后端重建的唯一实现依据）

> 契约按前端已实现行为定义（含对旧服务联调时的容错），**新后端直接按本文实现即与前端无缝对接**；下表「曾实现」指旧服务（代码已丢失，仅线上行为可参考）实现过的接口，重建时同样照契约实现。

### 4.1 全局约定

| 项 | 约定 |
|---|---|
| BaseURL | 重建后自定（见 §1.3/1.4）；开发期本机 `http://<内网IP>:3000` |
| 响应包裹 | `{"code":0,"message":"ok","data":{}}`，成功恒为 code=0 |
| HTTP 状态码 | 200 照常返回业务响应（成败看 body.code）；401/429/500 属网关层 |
| 鉴权 | 除 ping/认证类全部 `Authorization: Bearer <accessToken>`；40100/40101 → 前端自动 refresh 重放一次 |
| 时间 | ISO 8601 **必带时区**（`2026-08-27T14:30:00+08:00`）；纯日期 `yyyy-MM-dd` 东八区 |
| ID/枚举 | 字符串 ID（推荐 UUID/ULID，禁自增数字直出）；枚举出网为字符串：dog/cat、male/female、walkDog/catPlay |
| 分页 | `?page=1&pageSize=20`（上限 100），响应 `data.list + total + page + pageSize` |
| 错误码分段 | `400xx 参数` `401xx 认证` `403xx 权限` `404xx 不存在` `429xx 限流` `500xx 服务端` |
| 请求体 | 仅解析 `application/json`（前端所有请求显式带 Content-Type，见 D5） |

### 4.2 接口总览（26 个）

| # | 方法 | 路径 | 说明 | 鉴权 | 优先级 | 状态 |
|---|---|---|---|---|---|---|
| 1 | GET | /api/v1/ping | 健康检查 | ❌ | P0 | 批次1·重建 |
| 2 | POST | /api/v1/auth/sms-code | 发验证码 | ❌ | P0 | 批次1·重建 |
| 3 | POST | /api/v1/auth/login | 登录换 token | ❌ | P0 | 批次1·重建 |
| 4 | POST | /api/v1/auth/refresh | 刷新 accessToken | ❌ | P0 | 批次1·重建 |
| 5 | POST | /api/v1/auth/logout | 登出（拉黑 refreshToken） | ✅ | P0 | 批次1·重建 |
| 6 | GET | /api/v1/users/me | 我的资料 | ✅ | P0 | 批次1·重建 |
| 7 | PATCH | /api/v1/users/me | 改昵称/头像 | ✅ | P0 | 批次1·重建 |
| 8 | GET | /api/v1/pets | 宠物列表 | ✅ | P0 | 批次1·重建 |
| 9 | POST | /api/v1/pets | 新增宠物 | ✅ | P0 | 批次1·重建 |
| 10 | GET | /api/v1/pets/{petId} | 宠物详情 | ✅ | P0 | 批次1·重建 |
| 11 | PATCH | /api/v1/pets/{petId} | 编辑宠物 | ✅ | P0 | 批次1·重建 |
| 12 | DELETE | /api/v1/pets/{petId} | 删除宠物（软删） | ✅ | P0 | 批次1·重建 |
| 13 | POST | /api/v1/upload | 图片上传 multipart | ✅ | P0 | 批次1·重建 |
| 14 | POST | /api/v1/exercise-records | 上报运动记录 | ✅ | P0 | 批次1·重建 |
| 15 | GET | /api/v1/exercise-records | 查询记录（分页） | ✅ | P0 | 批次1·重建 |
| 16 | GET | /api/v1/exercise-records/{id} | 记录详情（全量轨迹） | ✅ | P0 | 批次1·重建 |
| 17 | GET | /api/v1/checkins/calendar | 月历打卡数据 | ✅ | P0 | 批次1·重建 |
| 18 | GET | /api/v1/checkins/today | 今日打卡状态 | ✅ | P1 | 批次2·重建 |
| 19 | POST | /api/v1/checkins/makeup | 补签卡补签 | ✅ | P1 | 批次2·重建 |
| 20 | GET | /api/v1/stats/weekly | 周报聚合 | ✅ | P1 | 批次2·重建 |
| 21 | GET | /api/v1/stats/monthly | 月报聚合 | ✅ | P1 | 批次2·重建 |
| 22 | GET | /api/v1/ranking | 排行榜 | ✅ | P1 | 批次2·重建 |
| 23 | GET | /api/v1/badges | 徽章列表+解锁态 | ✅ | P1 | 批次2·重建 |
| 24 | — | /api/v1/family-groups/* | 家庭组 | ✅ | P2 | 未定稿 |
| 25 | GET | /api/v1/weather/current | 天气代理（密钥归边后） | ✅ | P2 | 未定稿 |
| 26 | GET | /api/v1/geo/reverse | 逆地理代理（同上） | ✅ | P2 | 未定稿 |

### 4.3 认证接口明细

**② POST /auth/sms-code** — 请求 `{phone}` → data: `{}`。限流：同号 60s 内一次（40103）；单号单日 10 条（42901）。**dev 万能码 8888，但仍须先发码**（不发码直接登录 40102）。测试号 13800138000。实现：dev 环境不接真短信——发码成功仅记录（控制台日志/内存 Map），登录时 `8888` 或内存中的码放行；真短信服务商（阿里/腾讯云，需签名+模板报备）上线前替换，dev 万能码保留。

**③ POST /auth/login** — 请求 `{phone, smsCode}` → data: `{accessToken, refreshToken, expiresIn(秒，**必须为数字**——旧服务曾发字符串见 D1), isNewUser, user:UserDTO}`。验证码 5 分钟有效、一次性；错误 40102。

**④ POST /auth/refresh** — 请求 `{refreshToken}` → 同 token 三件套（无 user）。失效 40104 → 前端清态回登录页。

**⑤ POST /auth/logout** — 空体。服务端作废当前 refreshToken（**refresh_tokens 表删除该行即可，无需 Redis**，见 §1.4），accessToken 自然到期。

### 4.4 用户 / 宠物 / 上传接口

**⑥⑦ /users/me**：GET → UserDTO；PATCH `{nickname?, avatarUrl?, isPublicRank?}` 至少一项，nickname 去空格后 1-12 字否则 40002。`isPublicRank=false` 后服务端在排行榜构建与读取双侧剔除该用户（构建缓存 ≤5 分钟内由读取侧兜底过滤，名次重排），前端"我的排名"区同步显示隐私提示。

**⑧ GET /pets**：分页可省（默认一页 100），创建时间正序（前端「第一只为默认宠物」依赖此序）。

**⑨ POST /pets**：name/species/breed/gender/weight/birthDate 必填，其余可选（含 ageYears、avatarUrl、allergies、chronicConditions、isNeutered、isVaccinated、emergencyContact）。校验 weight>0；品种白名单暂不强制；上限 20 只（40003）。

**⑩⑪⑫ 详情/PATCH/DELETE**：PATCH 字段均可选，回更新后 PetDTO；非本人宠物 40301；DELETE 软删，有关联记录也允许（历史保留），响应 `data:{}`。

**⑬ POST /upload**（multipart/form-data）：字段 `file`（jpg/png/webp）+ `businessType`（avatar≤2MB / walkPhoto≤1MB）→ `{url, fileSize}`。url 必须公网可直接访问（HTTPS）。错误 40006 类型不支持 / 40007 超限。存储介质自定，前端只认 URL。**已接真（2026-09-05）**：前端头像与出发照片均先传 ⑬；出发照片在 Live 上报 ⑭ 前上传，失败静默降级只发 null（不阻塞记录），重试凭 clientRecordId 缓存免重复上传。

### 4.5 运动记录接口（核心）

**⑭ POST /exercise-records** — 请求 = ExerciseRecordDTO 去 id/userId/createdAt，**clientRecordId 必填**。route 上限 5000 点（超出前端抽稀）。`startPhotoUrl` 为 ⑬ 返回的图床地址；本地路径绝不上网。
- **幂等**：同 clientRecordId 二次提交不重复入库，返回已有记录 + `duplicated:true`
- 校验：endTime>startTime（否则 40001）；duration 与起止差偏差>30% 采信客户端但打审计标记；route=[] 仅 catPlay 或 isManual 合法；宠物归属失败 40301

**⑮ GET /exercise-records** — Query：petId? / type? / startDate,endDate?(yyyy-MM-dd 闭区间东八区) / page,pageSize。list 内 route 抽稀（每 N=50 取 1 控流量）；排序 startTime 倒序。

**⑯ GET /exercise-records/{id}** — 完整 DTO 全量 route；查他人 40301。

### 4.6 打卡 / 统计 / 排行 / 徽章

**判定（服务端执行）**：当日存在任一条 `isCompleted && duration≥300s` 记录即打卡。⚠️ **不限运动类型**（猫玩达标也计入——否则猫主人永远打不了卡）。

**⑰ GET /checkins/calendar?year=&month=** → `{days:[CheckinDayDTO×当月每天], monthCheckedCount, streakDays}`（服务端返回完整当月数组）。

**⑱ GET /checkins/today** → `{isChecked, todayMinutes}`。

**⑲ POST /checkins/makeup** — 请求 `{date:yyyy-MM-dd}`（过去日期、未打过卡）→ `{CheckinDayDTO, signCardCount}` 余量扣 1。错误：40305 卡不足 / 40004 无需补签。

**⑳ GET /stats/weekly?date=** → `{weekStart, days:[{date,totalDurationSec,totalDistanceKm,recordCount}×7], summary:{totalDurationSec,totalDistanceKm,recordCount,checkedDays}}`（date 所在自然周，周一起点）。

**㉑ GET /stats/monthly?date=** → 同上按周聚合（weeks[] 替代 days[]，bucket 键=每周周一）。

**㉒ GET /ranking?type=weekly&scope=all** → `{type, metric:"minutes", updatedAt, list:[RankingItemDTO×前50], me:RankingItemDTO}`。type=weekly 滚动近 7 天 / monthly 自然月。**起步用 SQL 实时聚合即可**（用户量 < 千级毫无压力），量级上来再换 Redis ZSet 缓存（刷新 ≤5min）；防刷=打卡判定+记录合理性审计；用户数<榜长时空位留空。

**㉓ GET /badges** → `{list:[BadgeDTO], unlockedCount}`。解锁由服务端事件落库（首条记录、连续 7 天等），前端只展示。

### 4.7 DTO 定义

```jsonc
// UserDTO
{ "id":"u_01J8ZK...", "phone":"138****8000", "nickname":"铲屎官",
  "avatarUrl":null, "createdAt":"...",
  "totalExerciseCount":42, "streakDays":7, "signCardCount":3 }

// PetDTO（recommendedExerciseMinutes 服务端按公式计算下发，见 §2.3）
{ "id":"p_...", "name":"旺财", "species":"dog", "breed":"金毛寻回犬",
  "gender":"male", "ageYears":3, "birthDate":"2023-05-01", "weight":28.5,
  "avatarUrl":null, "allergies":["鸡肉"], "chronicConditions":[],
  "isNeutered":true, "isVaccinated":true, "emergencyContact":null,
  "recommendedExerciseMinutes":60 }

// ExerciseRecordDTO
{ "id":"r_...", "clientRecordId":"550e8400-...", "petId":"p_...", "userId":"u_...",
  "type":"walkDog", "startTime":"...", "endTime":"...",
  "duration":1860, "distance":2.35, "steps":4700,
  "route":[GeoPoint], "locationName":"上海市浦东新区",
  "startPhotoUrl":null, "isCompleted":true, "isManual":false, "createdAt":"..." }

// GeoPoint
{ "latitude":31.230416, "longitude":121.473701, "timestamp":"...", "accuracy":8.5 }

// CheckinDayDTO  { "date":"2026-08-01", "isChecked":true }
// RankingItemDTO { "rank":1, "userId":"u_...", "nickname":"铲屎官", "avatarUrl":null, "value":320, "isMe":false }
// BadgeDTO       { "id":"first_walk", "name":"初次出发", "emoji":"🐾", "description":"完成第一次遛狗", "isUnlocked":true, "unlockedAt":"..." }
```

### 4.8 旧服务联调偏差存档（D1-D5）

> 这些是与**旧服务**（代码已丢失）当年真机联调发现的偏差，前端已全部容错。**新后端直接按「契约要求」列实现**——本表仅作历史存档与前端容错逻辑的注解，切勿在新后端复刻旧偏差。

| # | 旧服务行为 | 契约要求（新后端按此实现） |
|---|---|---|
| D1 | expiresIn 回字符串 `"604800"` | 发数字 |
| D2 | 无效 token 回 40100 而非 40101 | 统一发 40101（前端兼容两者，不受影响） |
| D3 | PetDTO.ageYears 可为 null | 按 birthDate 派生后恒发数字 |
| D4 | 参数校验错误实发 40000 | 统一从 40001 起（前端已按 40000-40099 段兜底，不受影响） |
| D5 | 仅解析 application/json | 维持：仅 JSON；前端所有请求显式带 Content-Type |

### 4.9 后端重建冒烟清单（批次 1 验收标准）

按序走通即批次 1 完成（curl / Apifox / 真机任选，最后一项必须真机）：

1. `GET /api/v1/ping` → `{code:0, data:{service, time}}`
2. 发码后 60s 内重发 → 40103；dev 万能码 8888 可登录
3. 错码登录 → 40102；正确登录 → token 三件套（**expiresIn 为数字**）+ isNewUser 分流
4. refresh 轮换正常；失效 refresh → 40104；logout 后旧 refresh 不可用
5. 过期 access 调 `GET /users/me` → 前端透明刷新链路成功
6. 宠物 CRUD：建 → 列表（创建时间**正序**）→ 改 → 软删（关联记录保留）→ 越权 40301
7. `POST /upload`：avatar≤2MB / walkPhoto≤1MB；类型不符 40006、超限 40007；返回 URL 可公网访问
8. ⑭ 上报：重复 clientRecordId → duplicated:true 不重复入库；route=[] 仅 catPlay/isManual 合法；endTime>startTime 否则 40001
9. ⑮ 列表：分页 + petId/type/日期过滤 + startTime 倒序 + list 内 route 每 50 点抽稀
10. ⑯ 详情含全量 route；查他人 40301
11. ⑰ 打卡日历：days 恒为**当月完整天数**（前端按索引取值，短数组会崩页）；打卡判定**不限类型**（isCompleted + ≥300s）；streakDays 截至今天
12. 真机 Live 全流程：登录 → 加宠物 → 遛狗上报 → 日历亮灯 → 记录列表/详情正确

---

## 五、构建与发布规范

### 5.1 构建环境（本机锁定）

```
Flutter 3.27.4 · Dart 3.6.2 · Android SDK 34 · Java 17 (D:\JDK)
Gradle 8.3（默认缓存 D:\Android\gradle\wrapper\dists，勿用 D:\myprojects\gradle-cache 冗余副本）
AGP 8.1.1 · Kotlin 1.8.22 · Android Studio 2026.1.3
```

**不可删除/降级**（删了构建必挂）：gradle.properties 的 `org.gradle.java.home=D:/JDK` 与 `kotlin.compiler.execution.strategy=in-process`；settings.gradle 的阿里云镜像与 AGP 8.1.1。

### 5.2 构建命令（密钥值见 SECRETS.local，不入库）

```bash
cd D:\myprojects\chongdong_keep

# Live 模式 debug 包（连自建后端——地址按部署位置替换：本机/内网穿透/云服务器）
flutter build apk --debug \
  --dart-define=API_BASE_URL=http://<自建后端地址> \
  --dart-define=QWEATHER_KEY=<见SECRETS.local> \
  --dart-define=QWEATHER_HOST=<见SECRETS.local> \
  --dart-define=TENCENT_MAP_KEY=<见SECRETS.local>

# 临时对照旧服务验证行为（仅参考，勿长期依赖）
# --dart-define=API_BASE_URL=http://47.104.129.148

# Mock 模式（内置假后端，验证码 123456，不依赖任何服务器）
flutter run --dart-define=MOCK=1

# 不带任何参数 = 也进 Mock 模式（天气/地图未配 Key 时自动降级）
```

产物：`build\app\outputs\flutter-apk\app-debug.apk` → `adb install -r` 装机。

### 5.3 发布红线（不可违反）

1. Android 包名 `com.chongdong.chongdong_keep` 永不改（改了用户无法升级）
2. keystore 签名多地备份，丢失 = 全量用户重装
3. AndroidManifest 权限只增不删
4. versionCode 单调递增；versionName 主.次.修订
5. 已发布接口不做不兼容变更：不删字段/不改类型语义/不加必填入参；废弃字段标记 deprecated 保留一个大版本
6. 数据库变更必须迁移脚本进仓库（可追溯可回滚），禁止登 production 手改
7. 密钥永不入 Git/文档/群聊——只在 SECRETS.local 或密码管理工具

### 5.4 质量门禁（每次提交前）

**前端 `chongdong_keep`**：
- `dart analyze` 零问题
- `flutter test` 全绿（当前 80 用例）
- 改网络/模型相关必须补测试用例

**后端 `chongdong_server`（重建时同步建立）**：
- 新接口必须附 curl 自测样例（放 PR 描述或 README）
- 批次收尾跑一遍 §4.9 冒烟清单
- SQL 变更只走 migrations/ 脚本，禁止手改库

**通用**：commit 格式 `type(scope): 中文一句话`（feat/fix/refactor/docs/chore/test）；后端仓库 `.gitignore` 必含 `.env`、`uploads/`、`node_modules/`。

---

## 六、历史文档去向（2026-09-05 重构）

| 原文件 | 处理 |
|---|---|
| 宠物版Keep_PRD.md（v1.3） | 被 PRD.md 替代，删除 |
| 宠动Keep_项目交接文档.md | 有效内容并入本文（构建/红线），密钥移 SECRETS.local，删除 |
| 宠动Keep_前端开发计划.md | M1 已执行完毕，纯历史，删除 |
| 宠动Keep_前后端协作规范.md | 技术条款并入本文（§2.3/§四/§五），协作流程条款因单人模式失效，删除 |
| 宠动Keep_API接口契约_v0.1.md / api_contract.md | 全量并入 §四，删除（仓库 docs/ 副本同步清理） |
| PROGRESS.md / CHANGES.md | 合并重写为 PROGRESS.md，删除 CHANGES.md |
