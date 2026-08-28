import 'package:chongdong_keep/models/exercise_record.dart';
import 'package:chongdong_keep/network/api_client.dart';
import 'package:chongdong_keep/network/api_exception.dart';
import 'package:chongdong_keep/network/token_store.dart';
import 'package:chongdong_keep/repositories/auth_repository.dart';
import 'package:chongdong_keep/repositories/record_repository.dart';
import 'package:chongdong_keep/services/mock/mock_transport.dart';
import 'package:chongdong_keep/utils/iso_time.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<(ApiClient, TokenStore, MockTransport)> _stack() async {
  SharedPreferences.setMockInitialValues({});
  final store = TokenStore(prefs: SharedPreferences.getInstance());
  final transport = MockTransport(delay: Duration.zero);
  return (ApiClient(transport, store), store, transport);
}

Future<void> _loginAs(ApiClient client, TokenStore store, String phone) async {
  final auth = AuthRepository(client, store);
  await auth.sendSmsCode(phone);
  await auth.login(phone, MockTransport.fixedSmsCode);
}

Map<String, dynamic> _body({
  String crid = 'crid-a',
  String petId = 'p_1001',
  String type = 'walkDog',
  DateTime? start,
  int durationSec = 600,
  List route = const [],
  bool isManual = false,
}) {
  final s = start ?? DateTime.now();
  return {
    'clientRecordId': crid,
    'petId': petId,
    'type': type,
    'startTime': formatIsoWithOffset(s),
    'endTime':
        formatIsoWithOffset(s.add(Duration(seconds: durationSec))),
    'duration': durationSec,
    'distance': 1.0,
    'steps': 2000,
    'route': route,
    'isManual': isManual,
  };
}

List<Map<String, dynamic>> _routeOf(int n) => [
      for (var i = 0; i < n; i++)
        {
          'latitude': 30.5 + i * 0.0001,
          'longitude': 114.3,
          'timestamp': formatIsoWithOffset(
              DateTime.now().subtract(Duration(seconds: n - i))),
        },
    ];

void main() {
  ExerciseRecord mkLocal({String crid = 'c1'}) => ExerciseRecord(
      id: 'l1',
      clientRecordId: crid,
      petId: 'p_1001',
      userId: 'u_1001',
      type: ExerciseType.walkDog,
      startTime: DateTime.now().subtract(const Duration(minutes: 10)),
      endTime: DateTime.now(),
      duration: const Duration(seconds: 600),
      route: [
        GeoPoint(
            latitude: 30.5, longitude: 114.3, timestamp: DateTime.now())
      ]);

  test('匿名上报 → 40101 原样上抛（不触发刷新/登出）', () async {
    final (client, _, _) = await _stack();
    await expectLater(
      RecordRepository(client).createRecord(mkLocal()),
      throwsA(isA<ApiException>()
          .having((e) => e.code, 'code', kCodeAccessExpired)),
    );
  });

  test('上报成功：服务端 id + 回显幂等键；同键重放 → duplicated 且不翻倍', () async {
    final (client, store, _) = await _stack();
    final records = RecordRepository(client);
    await _loginAs(client, store, '13800008000');

    final created = await records.createRecord(mkLocal(crid: 'crid-a'));
    expect(created.id, startsWith('r_'));
    expect(created.clientRecordId, 'crid-a');

    // 弱网重试：同一 clientRecordId 再交 → 幂等回既有行
    final raw = await client.post('/api/v1/exercise-records', body: _body());
    expect(raw['data']['duplicated'], isTrue);
    expect((raw['data'] as Map)['id'], created.id);

    final list = await records.fetchRecords();
    expect(list.length, 1);
    expect(list.first.id, created.id);
  });

  test('校验：缺幂等键/起止倒置/遛狗无轨迹 → 40001；他人宠物 → 40301', () async {
    final (client, store, _) = await _stack();
    await _loginAs(client, store, '13800008000');

    final missingKey = await client.post('/api/v1/exercise-records',
        body: _body()..remove('clientRecordId'));
    expect(missingKey['code'], kCodeParamInvalid);

    final now = DateTime.now();
    final reversed = await client.post('/api/v1/exercise-records', body: {
      ..._body(),
      'startTime': formatIsoWithOffset(now),
      'endTime': formatIsoWithOffset(now.subtract(const Duration(minutes: 5))),
    });
    expect(reversed['code'], kCodeParamInvalid);

    final noRoute = await client.post(
        '/api/v1/exercise-records', body: _body(route: []));
    expect(noRoute['code'], kCodeParamInvalid);

    // 猫玩 / 手动记录允许空轨迹
    final catOk = await client.post('/api/v1/exercise-records',
        body: _body(crid: 'crid-cat', type: 'catPlay', route: []));
    expect(catOk['code'], 0);
    final manualOk = await client.post('/api/v1/exercise-records',
        body: _body(crid: 'crid-manual', route: [], isManual: true));
    expect(manualOk['code'], 0);

    // B 用户上报到 A 的宠物 → 40301
    await _loginAs(client, store, '13900009000');
    final stolen = await client.post('/api/v1/exercise-records',
        body: _body(crid: 'crid-steal', petId: 'p_1001', route: _routeOf(1)));
    expect(stolen['code'], kCodeNotOwner);
  });

  test('列表：startTime 倒序 + petId 过滤 + 列表轨迹抽稀', () async {
    final (client, store, _) = await _stack();
    final records = RecordRepository(client);
    await _loginAs(client, store, '13800008000');

    final now = DateTime.now();
    await client.post('/api/v1/exercise-records',
        body: _body(
            crid: 'c-old', start: now.subtract(const Duration(days: 2)), route: _routeOf(1)));
    await client.post('/api/v1/exercise-records',
        body: _body(crid: 'c-big', start: now.subtract(const Duration(days: 1)), route: _routeOf(120)));
    await client.post('/api/v1/exercise-records',
        body: _body(crid: 'c-new', type: 'catPlay', route: []));
    // c-new 是此刻（catPlay 无 petId 过滤仍是 p_1001），倒序应排最前

    final all = await records.fetchRecords();
    expect(all.map((r) => r.clientRecordId), ['c-new', 'c-big', 'c-old']);
    // 120 点列表回包抽稀为 3 点（每 50 取 1）
    final big = all.firstWhere((r) => r.clientRecordId == 'c-big');
    expect(big.route.length, 3);

    final onlyCat = await records.fetchRecords(type: ExerciseType.catPlay);
    expect(onlyCat.map((r) => r.clientRecordId), ['c-new']);
  });

  test('日历 ⑰：≥300 秒才亮、猫玩同样计入、monthCheckedCount/streak 正确', () async {
    final (client, store, _) = await _stack();
    final records = RecordRepository(client);
    await _loginAs(client, store, '13800008000');

    final now = DateTime.now();
    // 今天：遛狗 600s（打卡）+ 猫玩 299s（不足 5 分钟，不打卡）
    await client.post('/api/v1/exercise-records',
        body: _body(crid: 'd0-walk', start: now.subtract(const Duration(hours: 3)), route: _routeOf(1)));
    await client.post('/api/v1/exercise-records',
        body: _body(
            crid: 'd0-cat', type: 'catPlay', durationSec: 299, route: const []));
    // 昨天：猫玩 400s —— 契约 §4.7 不限类型，同样计入打卡
    await client.post('/api/v1/exercise-records',
        body: _body(
            crid: 'd1-cat',
            type: 'catPlay',
            durationSec: 400,
            start: now.subtract(const Duration(days: 1, hours: 2)),
            route: const []));
    // 前天：500s 但 isCompleted=false → 不算
    await client.post('/api/v1/exercise-records',
        body: {
          ..._body(
              crid: 'd2-incomplete',
              start: now.subtract(const Duration(days: 2, hours: 2)),
              route: _routeOf(1)),
          'isCompleted': false,
        });

    final cal = await records.fetchCalendar(now.year, now.month);
    final today = cal.firstWhere((c) =>
        c.date.year == now.year &&
        c.date.month == now.month &&
        c.date.day == now.day);
    final yesterday = cal.firstWhere((c) =>
        c.date.year == now.year &&
        c.date.month == now.month &&
        c.date.day == now.subtract(const Duration(days: 1)).day);
    expect(today.isChecked, isTrue);
    expect(yesterday.isChecked, isTrue, reason: '猫玩达标同样计入（不限类型）');

    final raw = await client.get('/api/v1/checkins/calendar',
        query: {'year': '${now.year}', 'month': '${now.month}'});
    expect(raw['data']['monthCheckedCount'], 2);
    expect(raw['data']['streakDays'], 2, reason: '今天+昨天连续，前天未完成断链');
  });

  test('分页：page/pageSize 生效且 total 为全量', () async {
    final (client, store, _) = await _stack();
    await _loginAs(client, store, '13800008000');
    final now = DateTime.now();
    for (var i = 0; i < 5; i++) {
      await client.post('/api/v1/exercise-records',
          body: _body(
              crid: 'p-$i',
              start: now.subtract(Duration(minutes: 10 * i + 1)),
              route: _routeOf(1)));
    }
    final page2 = await client.get('/api/v1/exercise-records',
        query: {'page': '2', 'pageSize': '2'});
    final data = page2['data'] as Map;
    expect(data['total'], 5);
    expect((data['list'] as List).length, 2);
    // 倒序第二页 = 第 3、4 新的记录
    expect((data['list'] as List).map((e) => e['clientRecordId']),
        ['p-2', 'p-3']);
  });
}
