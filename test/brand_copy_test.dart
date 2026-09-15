import 'package:flutter_test/flutter_test.dart';
import 'package:chongdong_keep/utils/brand_copy.dart';

/// 品牌守护测试（D2-4）：文案库每一条都要过 DESIGN_SYSTEM.md §6.2 / §8.1 标尺。
void main() {
  // emoji 粗匹配：常用符号区 + 补充平面（与 §6.2 审计命令同口径）
  final emoji = RegExp(r'[\u{1F000}-\u{1FFFF}\u{2600}-\u{27BF}]', unicode: true);
  const brandSet = {'🐾', '💗', '🥺', '🌸', '🎉'};

  group('BrandCopy 品牌标尺', () {
    test('每条 ≤ 1 个语气符（§6.2-4 密度上限）', () {
      for (final line in BrandCopy.allLines) {
        final count = emoji.allMatches(line).length;
        expect(count, lessThanOrEqualTo(1), reason: '超密度: $line');
      }
    });

    test('语气符只用品牌集 🐾💗🥺🌸🎉，禁 ✅❌⭐ 等功能感符号（§6.2-3）', () {
      for (final line in BrandCopy.allLines) {
        for (final m in emoji.allMatches(line)) {
          expect(brandSet.contains(m.group(0)), isTrue,
              reason: '板外 emoji ${m.group(0)} in: $line');
        }
      }
    });

    test('不命令、不指责（§8.1-1/2）', () {
      final banned = RegExp('请|必须|不要|错误|不正确|无效|有误');
      for (final line in BrandCopy.allLines) {
        expect(banned.hasMatch(line), isFalse, reason: '命令/指责词: $line');
      }
    });
  });

  group('BrandCopy 取用行为', () {
    test('pick 确定性：同种子同结果，且落在池内', () {
      const pool = ['a', 'b', 'c'];
      expect(BrandCopy.pick(pool, seed: 4), BrandCopy.pick(pool, seed: 4));
      expect(BrandCopy.pick(pool, seed: 4), 'b');
      expect(BrandCopy.pick(pool, seed: -1), 'b'); // 负种子取绝对值
      expect(pool, contains(BrandCopy.pick(pool)));
    });

    test('daySeed 同一天恒定、隔天变化', () {
      final d1 = DateTime(2026, 9, 15, 8);
      final d2 = DateTime(2026, 9, 15, 23);
      final d3 = DateTime(2026, 9, 16, 1);
      expect(BrandCopy.daySeed(d1), BrandCopy.daySeed(d2));
      expect(BrandCopy.daySeed(d3), BrandCopy.daySeed(d1) + 1);
    });

    test('占位符全部替换，不泄漏花括号', () {
      for (var s = 0; s < 8; s++) {
        expect(BrandCopy.recordSavedShort(3, seed: s), isNot(contains('{')));
        expect(BrandCopy.recordSavedShort(3, seed: s), contains('3'));
        expect(BrandCopy.makeupSuccess(2, seed: s), isNot(contains('{')));
        expect(BrandCopy.makeupSuccess(2, seed: s), contains('2'));
        expect(BrandCopy.streakLine(5, seed: s), isNot(contains('{')));
        expect(BrandCopy.streakLine(5, seed: s), contains('5'));
      }
    });

    test('连胜：0 天鼓励、里程碑专属、其余通用', () {
      expect(BrandCopy.streakZeroPool, contains(BrandCopy.streakLine(0)));
      expect(BrandCopy.streakLine(7), BrandCopy.streakMilestones[7]);
      expect(BrandCopy.streakLine(30), BrandCopy.streakMilestones[30]);
      expect(BrandCopy.streakLine(8, seed: 0), contains('8'));
    });
  });
}
