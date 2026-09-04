# 宠动Keep 🐾

和宝贝一起运动打卡、养成健康习惯的宠物运动 App（Flutter）。

选择要一起运动的宠物，GPS 自动记录遛狗路线、距离与时长；运动满 5 分钟即打卡成功，可生成分享卡片、查看打卡日历、周报与徽章，还能根据天气判断今天适不适合出门。

> 双模式运行：默认内置 Mock 假后端；通过 `--dart-define=API_BASE_URL=...` 连接真实后端（登录/宠物/运动记录/打卡日历走服务端，本地 `shared_preferences` 作缓存兜底）。产品/技术/进度文档见 `D:\myprojects` 下的 PRD.md / SPEC.md / PROGRESS.md。

## 功能特性

- 🐕 **多宠物档案**：狗/猫、品种、年龄、体重、绝育/疫苗、过敏源、紧急联系人等
- 🗺️ **GPS 遛宠追踪**：实时路线（腾讯地图 WebView，WGS-84→GCJ-02 显示纠偏）、距离、时长，自动过滤 GPS 漂移点；弱信号/定位异常横幅提醒
- 🔙 **中断恢复**：运动中每 10 秒落盘快照，APP 被杀/闪退后重启弹「继续 / 结束保存 / 放弃」
- ✅ **运动打卡**：满 5 分钟判定成功（不限遛狗/猫玩），打卡日历 / 连续天数 / 徽章成就
- ☀️ **天气建议**：和风天气实况 + 遛宠适宜度与预警提示（未配 Key 时用模拟数据）
- 📶 **弱网兜底**：运动记录带幂等键上报，失败进入会话内退避重试队列，切回前台自动补传
- 🚨 **健康安全**：症状自查分级、附近宠物医院（腾讯 POI 真实搜索）、紧急联系人一键拨打
- 📊 **周报统计**：每周运动量汇总
- 🎴 **分享卡片**：生成运动成果卡片并分享
- 👨‍👩‍👧 **家庭组 / 排行榜 / 路线收藏** 等页面

## 技术栈

| 分类 | 选型 |
| --- | --- |
| 框架 | Flutter（Dart SDK ^3.6.2），Material |
| 状态管理 | provider |
| 网络 | http（ApiClient 统一信封/鉴权刷新/重试） |
| 定位 | geolocator + permission_handler |
| 地图 | 腾讯地图 WebService API + webview_flutter 展示 |
| 天气 | 和风天气 API |
| 存储 | shared_preferences |

## 项目结构

```
lib/
├── main.dart                 # 入口：Provider(AppState) → 登录页/主页（含前台恢复补传）
├── models/                   # user / pet / exercise_record / walk_session 模型
│   └── dto/                 # 线上 DTO（wire 枚举映射等）
├── network/                  # ApiClient / Transport / TokenStore / ApiException
├── repositories/             # auth / user / pet / record 仓库（M1-M3 已接）
├── services/
│   ├── api_config.dart       # Mock/Live 开关与密钥（--dart-define 注入，不入库）
│   ├── app_state.dart        # 全局状态：登录、宠物CRUD、运动记录、打卡、上传重试
│   ├── mock/                 # 内置契约一致的假后端（MockTransport）
│   ├── storage_service.dart  # shared_preferences 本地持久化（含遛狗会话快照）
│   ├── map_service.dart      # GPS追踪、距离计算、漂移过滤、逆地理、附近医院POI
│   └── weather_service.dart  # 和风天气 + 遛宠建议
├── utils/                    # coord_convert(WGS84→GCJ02) / iso_time / uuid
├── theme/                    # 颜色与主题
├── widgets/                  # 地图轨迹 / 附近医院 / 共享UI组件
└── pages/
    ├── main_page.dart        # 底部5 Tab：首页/运动/商城/消息/我的
    ├── walk/walk_page.dart   # 核心：遛狗追踪流程（中断恢复/弱信号提示）
    └── ...                   # 登录、健康安全、徽章、日历、周报、分享卡等
```

## 快速开始

```bash
flutter pub get

# API 密钥通过 --dart-define 注入（也可只注入其中一部分）
flutter run \
  --dart-define=QWEATHER_KEY=你的和风天气Key \
  --dart-define=QWEATHER_HOST=你的和风天气专属Host \
  --dart-define=TENCENT_MAP_KEY=你的腾讯地图Key
```

- **不注入任何 Key 也能跑**：天气显示模拟数据，地图逆解析显示“当前位置”，其余功能不受影响。
- Android 端定位、相机等权限已在 `android/app/src/main/AndroidManifest.xml` 中声明，首次使用会动态请求。

## 已知限制 / Roadmap

- [ ] 锁屏/切后台后 GPS 追踪会中断（尚未实现前台 Service 保活；进程被杀已可通过快照恢复）
- [ ] 步数按距离估算（0.5m/步），非传感器真实计步
- [ ] “消息” Tab 与商城页为占位实现
- [ ] 排行榜、家庭组、周报聚合等 M4 页面仍为本地/模拟数据（后端接口 P1 待开发）
- [ ] 出发照片仅存本机，尚走对象存储上传链路

## 安全说明

API 密钥一律通过 `--dart-define` 在编译期注入，不要提交到仓库。若密钥曾经硬编码泄露过，请到对应平台（和风天气控制台 / 腾讯位置服务控制台）重置。
