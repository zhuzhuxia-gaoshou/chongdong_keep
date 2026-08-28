# 宠动Keep · API 接口契约 v0.2

> **状态**: 🟡 草稿（待双方联席会议逐条过审后升级为 v1.0）
> **起草**: 前端负责人，2026-08-27　**v0.2 修订**: 2026-08-28 联调实测对齐
> **上位规范**: 《宠动Keep_前后端协作规范.md》第四章。本契约与其冲突时以规范为准。
> **版本说明**: URL 路径版本 `/api/v1` 是**接口版本**（转正式后不再破坏性变更）；本文档顶部版本号是**契约文档版本**（v0.x 阶段可自由修订，转 v1.0 后走变更流程）。

---

## 〇、存放与协作方式（先读）

- **在线源**：Apifox 项目（谁建、链接贴这里：`______`）。Mock 与调试以它为准。
- **快照文件**：本文件的 markdown 拷贝放入 **后端仓库 `chongdong_server/docs/api_contract.md`**。此后所有修改一律走 Pull Request、评审人设为对方——用 Git 原生实现「契约先行」：**没合入的改动不存在，合入了才允许写代码**。
- 每个接口标注两列：`优先级`（P0 首批 / P1 其次 / P2 规划）与`状态`（草稿 → 已确认 → 后端已实现 → 前端已对接）。

---

## 一、全局约定

| 项 | 约定 |
|---|---|
| BaseURL | dev=`http://47.104.129.148`（**仅 HTTP、裸 IP**，前端已对该 IP 开明文白名单；test=`____` prod=`____`，上线必须 HTTPS+域名） |
| 响应包裹 | `{"code":0,"message":"ok","data":{}}`，成功恒为 `code=0` |
| HTTP 状态码 | 200 业务响应照常返回（成败看 body.code）；401/429/500 属网关层信号 |
| 鉴权 | 除 `ping`、认证类外全部需要 `Authorization: Bearer <accessToken>`；收到 `code=40101` 时前端自动 refresh 并重放一次 |
| 时间 | ISO 8601 **必带时区**，如 `2026-08-27T14:30:00+08:00`；纯日期字段格式 `yyyy-MM-dd`（按东八区） |
| ID / 枚举 | 字符串 ID；枚举出网为字符串：物种 `"dog"/"cat"`，性别 `"male"/"female"`，运动类型 `"walkDog"/"catPlay"` |
| 分页 | `?page=1&pageSize=20`（默认 20、上限 100），响应 `data.list + total + page + pageSize` |
| 错误码 | `400xx 参数` `401xx 认证` `403xx 权限` `404xx 不存在` `429xx 限流` `500xx 服务端` |

---

## 二、接口总览

| # | 方法 | 路径 | 说明 | 鉴权 | 优先级 | 状态 |
|---|---|---|---|---|---|---|
| 1 | GET | `/api/v1/ping` | 健康检查 | ❌ | P0 | 后端已实现 |
| 2 | POST | `/api/v1/auth/sms-code` | 发送短信验证码 | ❌ | P0 | 后端已实现 |
| 3 | POST | `/api/v1/auth/login` | 登录（换 token 对） | ❌ | P0 | 后端已实现 |
| 4 | POST | `/api/v1/auth/refresh` | 刷新 accessToken | ❌ | P0 | 后端已实现 |
| 5 | POST | `/api/v1/auth/logout` | 登出（作废 refreshToken） | ✅ | P0 | 草稿 |
| 6 | GET | `/api/v1/users/me` | 我的资料 | ✅ | P0 | 后端已实现 |
| 7 | PATCH | `/api/v1/users/me` | 改昵称/头像 | ✅ | P0 | 草稿 |
| 8 | GET | `/api/v1/pets` | 宠物列表 | ✅ | P0 | 后端已实现 |
| 9 | POST | `/api/v1/pets` | 新增宠物 | ✅ | P0 | 草稿 |
| 10 | GET | `/api/v1/pets/{petId}` | 宠物详情 | ✅ | P0 | 草稿 |
| 11 | PATCH | `/api/v1/pets/{petId}` | 编辑宠物 | ✅ | P0 | 草稿 |
| 12 | DELETE | `/api/v1/pets/{petId}` | 删除宠物（软删除） | ✅ | P0 | 草稿 |
| 13 | POST | `/api/v1/upload` | 图片上传（multipart） | ✅ | P0 | 草稿 |
| 14 | POST | `/api/v1/exercise-records` | 上报一条完整运动记录 | ✅ | P0 | 前端已对接（Mock 已实现，待后端 ⑭ 落地） |
| 15 | GET | `/api/v1/exercise-records` | 查询运动记录（分页） | ✅ | P0 | 前端已对接 |
| 16 | GET | `/api/v1/exercise-records/{id}` | 记录详情（含全量轨迹） | ✅ | P0 | 草稿 |
| 17 | GET | `/api/v1/checkins/calendar` | 月历打卡数据 | ✅ | P0 | 前端已对接（Mock 已实现，待后端 ⑰ 落地） |
| 18 | GET | `/api/v1/checkins/today` | 今日打卡状态 | ✅ | P1 | 草稿 |
| 19 | POST | `/api/v1/checkins/makeup` | 使用补签卡补签 | ✅ | P1 | 草稿 |
| 20 | GET | `/api/v1/stats/weekly` | 周报聚合 | ✅ | P1 | 草稿 |
| 21 | GET | `/api/v1/stats/monthly` | 月报聚合 | ✅ | P1 | 草稿 |
| 22 | GET | `/api/v1/ranking` | 排行榜 | ✅ | P1 | 草稿 |
| 23 | GET | `/api/v1/badges` | 徽章列表+解锁态 | ✅ | P1 | 草稿 |
| 24 | POST/GET… | `/api/v1/family-groups/*` | 家庭组 | ✅ | P2 | ⬜ 未定稿 |
| 25 | GET | `/api/v1/weather/current` | 天气代理（密钥归边后） | ✅ | P2 | ⬜ 未定稿 |
| 26 | GET | `/api/v1/geo/reverse` | 逆地理代理（同上） | ✅ | P2 | ⬜ 未定稿 |

---

## 三、数据结构（DTO）

> 所有接口的入参出参均由以下 DTO 组装。字段名前后端一致；`?` 表示可空可省略。

### UserDTO

```jsonc
{
  "id": "u_01J8ZK...",           // string，服务端生成
  "phone": "138****8000",        // 返回统一脱敏（见开放问题#1）
  "nickname": "铲屎官",
  "avatarUrl": null,
  "createdAt": "2026-08-27T10:00:00+08:00",
  "totalExerciseCount": 42,      // 服务端统计，不接受客户端上报
  "streakDays": 7,               // 连续打卡天数，服务端计算
  "signCardCount": 3             // 补签卡余量，初始 3
}
```

### PetDTO

```jsonc
{
  "id": "p_01J8ZK...",
  "name": "旺财",
  "species": "dog",              // dog | cat
  "breed": "金毛寻回犬",
  "gender": "male",              // male | female
  "ageYears": 3,
  "birthDate": "2023-05-01",     // 日期字符串
  "weight": 28.5,                // kg
  "avatarUrl": null,
  "allergies": ["鸡肉"],
  "chronicConditions": [],
  "isNeutered": true,
  "isVaccinated": true,
  "emergencyContact": null,
  "recommendedExerciseMinutes": 60   // ← 服务端按下列公式计算下发：
  // cat: 15+(age<2?15:(age>7?-5:0))；
  // dog 且品种名含 柯基/法斗/吉娃娃: age<1?20:(age>8?15:30)；
  // dog 且含 金毛/拉布拉多/边牧: age<1?40:(age>8?30:60)；
  // 其他狗: age<1?25:(age>8?20:40)。与前端现有 getter 保持一致，两侧不可各自私改。
}
```

### ExerciseRecordDTO

```jsonc
{
  "id": "r_01J8ZK...",           // 服务端 ID（App 内展示/查询用它）
  "clientRecordId": "550e8400-...", // 客户端生成 UUID，幂等键（见 3.5）
  "petId": "p_...",
  "userId": "u_...",
  "type": "walkDog",             // walkDog | catPlay
  "startTime": "...", "endTime": "...",
  "duration": 1860,              // 秒
  "distance": 2.35,              // 公里，两位小数
  "steps": 4700,                 // 过渡期=distance×1000÷0.5，客户端算好上报
  "route": [ /* GeoPoint[] */ ],
  "locationName": "上海市浦东新区",
  "startPhotoUrl": null,         // 注意：本地模型的 startPhotoPath 在 API 层换名为 startPhotoUrl
  "isCompleted": true,
  "isManual": false,
  "createdAt": "..."
}
```

### GeoPoint

```jsonc
{
  "latitude": 31.230416,         // WGS-84，保留 6 位小数
  "longitude": 121.473701,
  "timestamp": "...",
  "accuracy": 8.5                // 米，可空
}
```

### CheckinDayDTO · RankingItemDTO · BadgeDTO

```jsonc
// CheckinDayDTO
{ "date": "2026-08-01", "isChecked": true }

// RankingItemDTO
{ "rank": 1, "userId": "u_...", "nickname": "铲屎官", "avatarUrl": null,
  "value": 320,                  // 口径见开放问题#2，暂定=周期内运动总分钟数
  "isMe": false }

// BadgeDTO
{ "id": "first_walk", "name": "初次出发", "emoji": "🐾",
  "description": "完成第一次遛狗", "isUnlocked": true,
  "unlockedAt": "..." }
```

---

## 四、接口明细

### 4.1 系统

**① GET /api/v1/ping**（免鉴权）
→ `data`: `{"service":"chongdong-api","time":"2026-08-27T14:30:00+08:00"}`
用途：前端连通性诊断与环境显示。

### 4.2 认证

**② POST /api/v1/auth/sms-code**

```jsonc
// 请求
{ "phone": "13800138000" }
// 响应 data: {}
```
规则：同号 60 秒内限发一次（40103）；单号单日上限 10 条（42901）。

**开放问题#5 已拍板（2026-08-28 后端落地）**：dev 环境支持**万能验证码 `8888`**，
但**仍需先调 ② 发码**（不发码直接登录返回 40102，联调实测）。测试账号：`13800138000`。
Mock 假后端不受此影响，仍用固定码 `123456`。

**③ POST /api/v1/auth/login**
```jsonc
// 请求
{ "phone": "13800138000", "smsCode": "483921" }
// 响应 data
{ "accessToken": "eyJhbGciOi...", "refreshToken": "eyJhbGciOi...",
  "expiresIn": 604800,            // 秒
  "isNewUser": true, "user": { UserDTO } }
```
错误：`40102` 验证码错误或过期。验证码有效期 5 分钟、一次性使用。

**④ POST /api/v1/auth/refresh**
```jsonc
// 请求 { "refreshToken": "..." }
// 响应 data 同登录的 token 三件套（不含 user/isNewUser）
```
错误：`40104` refreshToken 无效或过期 → 前端清本地态回登录页。

**⑤ POST /api/v1/auth/logout**
请求体空即可。语义：服务端将当前 refreshToken 拉黑（Redis），accessToken 自然到期。

### 4.3 用户

**⑥ GET /api/v1/users/me** → `data: UserDTO`

**⑦ PATCH /api/v1/users/me**
```jsonc
// 请求（均可选，至少传一项）
{ "nickname": "新昵称", "avatarUrl": "https://..." }
// 响应 data: UserDTO
```
约束：nickname 非空、去首尾空格后 1–12 字符，否则 `40002`。

### 4.4 宠物

**⑧ GET /api/v1/pets**（分页参数可省，默认一页 100）→ `data: { list: PetDTO[], total, page, pageSize }`
排序：创建时间正序（与前端当前"第一只为默认宠物"的行为一致）。

**⑨ POST /api/v1/pets**
```jsonc
// 请求（name/species/breed/gender/weight/birthDate 必填，其余可选）
{ "name": "旺财", "species": "dog", "breed": "金毛寻回犬", "gender": "male",
  "birthDate": "2023-05-01", "ageYears": 3, "weight": 28.5,
  "avatarUrl": null, "allergies": [], "chronicConditions": [],
  "isNeutered": false, "isVaccinated": true, "emergencyContact": null }
// 响应 data: PetDTO
```
校验：weight > 0；品种白名单校验**暂不强制**（开放问题#6）；单用户上限 20 只（`40003` 超限）。

**⑩⑪⑫ 详情 / PATCH / DELETE**
- PATCH 同 POST 字段、均可选；响应更新后的 PetDTO；非本人宠物 → `40301`。
- DELETE 为**软删除**；已有关联运动记录时同样允许删，记录保留（供历史周报），宠物列表不再出现。响应 `data: {}`。

### 4.5 文件上传

**⑬ POST /api/v1/upload**（multipart/form-data）

| 表单字段 | 说明 |
|---|---|
| `file` | 二进制，jpg/png/webp |
| `businessType` | `avatar`（≤2MB）/ `walkPhoto`（≤1MB） |

→ `data: { "url": "https://cdn.example.com/xxx.jpg", "fileSize": 102400 }`
错误：`40006` 类型不支持、`40007` 超大小上限。URL 必须可直接公网访问（HTTPS）。存储介质（COS/本地盘/MinIO）由后端自定，**前端只认返回的 URL**。

### 4.6 运动记录

**⑭ POST /api/v1/exercise-records**

```jsonc
// 请求（ExerciseRecordDTO 去掉 id/userId/createdAt）
{
  "clientRecordId": "550e8400-e29b-...",   // 必填，客户端 UUID
  "petId": "p_...", "type": "walkDog",
  "startTime": "...", "endTime": "...", "duration": 1860,
  "distance": 2.35, "steps": 4700,
  "locationName": "上海市浦东新区", "startPhotoUrl": null,
  "isCompleted": true, "isManual": false,
  "route": [ {GeoPoint}, ... ]             // 上限 5000 点，超出前端负责抽稀
}
// 响应 data: ExerciseRecordDTO（含服务端 id 与回显的 clientRecordId）
```

**关键规则——幂等**：网络重试导致同一 `clientRecordId` 二次提交时，服务端**不重复入库**，直接返回已有记录（`code=0`，响应附加 `"duplicated": true` 标记）。这解决弱网下"一条运动变两条"的经典问题，前端每次保存必须带上它。

校验：`endTime > startTime`（否则 40001）；`duration` 与起止差值偏差 >30% 时服务端**采信客户端值但打审计标记**（不计错）；`route=[]` 仅当 `type=catPlay` 或 `isManual=true` 合法；宠物归属校验失败 → `40301`。

**⑮ GET /api/v1/exercise-records**

| Query | 说明 |
|---|---|
| `petId` | 可选，不传=我的全部宠物 |
| `type` | 可选 walkDog/catPlay |
| `startDate` / `endDate` | 可选，`yyyy-MM-dd`，闭区间、按东八区 |
| `page` / `pageSize` | 默认 20 |

响应 `list` 内的 `route` **只含每第 N 个点（建议 N=50，具体见联调实测）以控流量**；要看全量轨迹调 ⑯ 详情接口。排序 startTime 倒序。

**⑯ GET /api/v1/exercise-records/{id}** → 完整 DTO 含全量 route。查他人记录 → `40301`。

### 4.7 打卡

判定规则（服务端执行）：**当日存在任一条 `isCompleted && duration≥300秒` 的记录即视为打卡**。

> ⚠️ v0.2 修订（2026-08-28，M3 前端对接时发现）：原写 `type=walkDog` 有误——产品既有语义与猫玩页文案「满5分钟即算今日打卡成功」均按**不限运动类型**判定，遛狗和猫玩达标都计入打卡。前端 `countsAsCheckIn = isCompleted && duration.inSeconds>=300` 已按不限类型实现。**请后端 ⑭/⑰ 打卡判定不要加 `type` 过滤**，否则猫主人永远打不了卡。若产品确要改为「仅遛狗」，需先改猫玩页文案再双确认。

**⑰ GET /api/v1/checkins/calendar?year=2026&month=8**
```jsonc
// 响应 data
{ "days": [ {CheckinDayDTO} × 当月每天 ],
  "monthCheckedCount": 18,
  "streakDays": 7 }               // 截至今天的连续打卡天数
```

**⑱ GET /api/v1/checkins/today** → `data: { "isChecked": true, "todayMinutes": 35 }`

**⑲ POST /api/v1/checkins/makeup**
```jsonc
// 请求 { "date": "2026-08-20" }   // 过去的日期，不能晚于今天，不能已打过卡
// 响应 data: { CheckinDayDTO, "signCardCount": 2 }   // 余量扣 1
```
错误：`40305` 补签卡不足、`40004` 该日无需补签（当日已自然打卡/日期无效）。

### 4.8 统计报表

**⑳ GET /api/v1/stats/weekly?date=2026-08-27**（date 所在自然周，周一为起点）
```jsonc
// 响应 data
{ "weekStart": "2026-08-24",
  "days": [ { "date": "2026-08-24", "totalDurationSec": 3600,
              "totalDistanceKm": 3.2, "recordCount": 2 } × 7 ],
  "summary": { "totalDurationSec": 10800, "totalDistanceKm": 11.8,
               "recordCount": 6, "checkedDays": 5 } }
```

**㉑ GET /api/v1/stats/monthly?date=2026-08-27** → 结构同上按周聚合（4–5 个 bucket）：`weeks[]` 替代 `days[]`，bucket 键取每周周一日期。

> 过渡期提示：这两项 P1。若后端未就绪而前端急需，可先用 ⑮ 的记录在前端本地聚合渲染，后端就绪后切过来——不阻塞联调主链路。

### 4.9 排行榜

**㉒ GET /api/v1/ranking?type=weekly&scope=all**

| Query | 取值 |
|---|---|
| `type` | `weekly`（默认，滚动近7天）/ `monthly`（自然月，暂定，见开放问题#2） |
| `scope` | v0.1 仅 `all`（全体用户）；好友圈待社交关系上线后追加 |

```jsonc
// 响应 data
{ "type": "weekly", "metric": "minutes", "updatedAt": "...",
  "list": [ {RankingItemDTO} × 前50 ],
  "me": {RankingItemDTO}          // 我的名次（不在前50也有）
}
```
实现要求：榜单放 Redis ZSet，缓存刷新周期 ≤5 分钟；防刷依赖打卡判定 + 运动记录合理性审计。零用户保护期：用户数 < 榜长时空位留空即可。

### 4.10 徽章

**㉓ GET /api/v1/badges** → `data: { "list": [BadgeDTO × n], "unlockedCount": 4 }`
解锁时机由服务端在相关事件（完成首条记录、连续7天打卡等）落库；前端不做解锁判断，只展示。首批徽章清单从前端硬编码版平移，明细由后端建 `badges` 配置表并在 Apifox 附样例。

### 4.11 家庭组（P2 · 未定稿）

只立骨架不定字段，防止现在过度设计：组创建/邀请码加入/成员角色（owner·member）/宠物关联到组/组内查看彼此打卡。**定稿条件**：P0/P1 联调完成后单独开一次设计讨论，产出 v0.2。

### 4.12 第三方能力代理（P2 · 密钥归边后启用）

| 接口 | 用途 |
|---|---|
| `GET /api/v1/weather/current?latitude=&longitude=` | 后端持和风 Key 转发，响应结构对齐前端现有 WeatherService 输出，前端删掉直连代码 |
| `GET /api/v1/geo/reverse?latitude=&longitude=` | 逆地理，返回 `{"locationName":"..."}` |

启用即代表 APP 彻底不再持有第三方密钥（配合规范 4.9 / 6.2 的密钥轮换计划）。

---

## 五、联调节奏对照（与规范第十节 #9 一致）

| 里程碑 | 后端交付 | 前端对应改造 |
|---|---|---|
| M1 | ①②③④⑤⑥⑦ | 删掉壳子登录 → 短信登录 + JWT 存储/自动续期 + 个人资料编辑接 ⑬⑦ |
| M2 | ⑧⑨⑩⑪⑫ + ⑬ | 添加/编辑宠物页接真实接口，宠物改为拉云端 |
| M3 | ⑭⑮⑯⑰ | 遛狗结束上报（带幂等键）、首页打卡进度与日历改读服务端 |
| M4 | ⑱⑲⑳㉑㉒㉓ | 周报切服务端聚合、排行榜/徽章摘除模拟数据 |

每个里程碑验收 = 冒烟清单（规范 8.3）相应段落通过 + 契约状态列更新。

---

## 六、开放问题（首次会议逐条拍板，拍完移入正文并升版本号）

| # | 问题 | 前端倾向 |
|---|---|---|
| 1 | 手机号返回是否脱敏（影响展示场景不多） | 脱敏，安全默认 |
| 2 | 排行榜口径：总时长 vs 总距离 vs 综合分；monthly 取自然月还是滚动30天 | 总时长（直观且好解释给用户） |
| 3 | 运动中是否周期性增量同步轨迹（牵涉后台保活二期） | v0.1 结束一次性上报，够用 |
| 4 | 已产生的本地历史记录要不要上传合并到服务端账号 | 不迁，新账号从零开始（产品叙事更干净） |
| 5 | 测试环境脱离真短信的方案：固定万能码 or 白名单手机号 | 万能码仅编译进 dev/test 包 |
| 6 | 品种是否强制 30 品种白名单校验 | 暂不强制，等管理后台品种库 |
| 7 | 全部"今日/本周/本月"统计确认按东八区自然日切分 | 是 |
| 8 | Apifox 项目建立人与管理员归属 | 后端建，两人均为管理员 |

---

## 变更记录

| 版本 | 日期 | 内容 | 提出 |
|---|---|---|---|
| v0.1 | 2026-08-27 | 初稿：26 个接口骨架，P0 共 17 个详定义，含幂等上报、打卡规则、DTO 基线、8 个开放问题 | 前端负责人 |
| v0.2 | 2026-08-28 | 联调实测对齐：① 填入 dev BaseURL（裸 http，前端已开明文白名单）；② 开放问题#5 拍板——dev 万能码 `8888`（需先发码），测试号 `13800138000`；③ 状态列标记 7 个已实现接口；④ 记录三处后端偏差（见下），前端已全部容错 | 前端负责人 |
| v0.2a | 2026-08-28 | M3 前端对接：⑭（clientRecordId 幂等 + 5000 点抽稀）/⑮（分页+列表抽稀）/⑰（月历）前端已接通，Mock 已同步实现三接口语义；**§4.7 打卡判定纠错为不限类型**（见该节警示框），请后端实现时注意 | 前端负责人 |

### 联调实测偏差（v0.2，待后端修正或双方确认改契约）

| # | 现象 | 契约期望 | 后端实际 | 前端处置 |
|---|---|---|---|---|
| D1 | 登录/刷新回包 `expiresIn` | number（秒） | **字符串** `"604800"` | 已容错解析（字符串/数字均可），**建议后端改发数字** |
| D2 | 无效/损坏 token 的鉴权错误码 | `40101` | `40100` "unauthorized" | 前端已将 40100 同样纳入刷新重放链路；**过期 token 是否回 40101 仍待实测确认**（access TTL 实测约 10 分钟） |
| D3 | PetDTO `ageYears` | int | 可为 `null` | 前端降级为 0；但 0 会带偏推荐运动量公式，**请后端按 birthDate 派生后恒发数字** |
| D4 | 参数校验错误码 | `40001` 起 | 实发 **`40000`**（如"手机号格式不正确"） | 契约 §一 写的是 400xx 分段但没定 40000；前端已按 40000–40099 段兜底展示后端中文 message。**建议后端统一用 40001**，或把 40000 正式纳入契约 |
| D5 | 请求体编码 | — | 后端 Express **仅解析 `application/json`**；无头/`text/plain` 一律判参数缺失 | 前端已在传输层为所有 JSON 请求补 `Content-Type: application/json; charset=utf-8`（此前真机登录 40000 即因缺此头）。**提醒**：后端若将来支持表单/其他编码需另议 |
