import 'dart:convert';
import 'package:http/http.dart' as http;

import 'api_config.dart';

/// 天气数据模型
class WeatherData {
  final String cityName;
  final int temperature;
  final String condition;
  final String conditionIcon;
  final int humidity;
  final int windSpeed;
  final bool isGoodForWalk;
  final String walkAdvice;
  final WeatherWarning? warning;

  WeatherData({
    required this.cityName,
    required this.temperature,
    required this.condition,
    required this.conditionIcon,
    required this.humidity,
    required this.windSpeed,
    required this.isGoodForWalk,
    required this.walkAdvice,
    this.warning,
  });
}

/// 天气预警
class WeatherWarning {
  final String type; // rain, heat, cold, haze, storm
  final String title;
  final String advice;

  WeatherWarning({required this.type, required this.title, required this.advice});
}

/// 和风天气服务
class WeatherService {
  /// 获取当前位置天气
  static Future<WeatherData?> getWeatherByLocation(double lat, double lon) async {
    if (!ApiConfig.hasQweather) {
      return _getMockWeather();
    }

    try {
      // 直接用经纬度查询天气（跳过地理编码API，免费版不支持）
      final weatherRes = await http.get(Uri.parse(
        '${ApiConfig.qweatherHost}/v7/weather/now?location=$lon,$lat&key=${ApiConfig.qweatherKey}',
      ));

      if (weatherRes.statusCode == 200) {
        final data = json.decode(weatherRes.body);
        if (data['code'] != '200') {
          return _getMockWeather();
        }
        final now = data['now'];
        final temp = int.tryParse(now['temp'] ?? '20') ?? 20;
        final icon = now['icon'] ?? '100';
        final text = now['text'] ?? '晴';
        final humidity = int.tryParse(now['humidity'] ?? '50') ?? 50;
        final windScale = int.tryParse(now['windScale'] ?? '2') ?? 2;

        // 用腾讯地图逆地址解析获取城市名
        String cityName = '当前位置';
        try {
          final mapRes = await http.get(Uri.parse(
            'https://apis.map.qq.com/ws/geocoder/v1/?location=$lat,$lon&key=${ApiConfig.tencentMapKey}&output=json',
          ));
          if (mapRes.statusCode == 200) {
            final mapData = json.decode(mapRes.body);
            if (mapData['status'] == 0 && mapData['result'] != null) {
              final addr = mapData['result']['address_component'];
              cityName = addr['city'] ?? addr['district'] ?? '当前位置';
            }
          }
        } catch (_) {}

        // 判断是否适合遛狗
        final isGood = _isGoodForWalk(temp, text, windScale);
        final advice = _getWalkAdvice(temp, text, windScale);
        final warning = _getWarning(temp, text);

        return WeatherData(
          cityName: cityName,
          temperature: temp,
          condition: text,
          conditionIcon: _getWeatherIcon(icon),
          humidity: humidity,
          windSpeed: windScale,
          isGoodForWalk: isGood,
          walkAdvice: advice,
          warning: warning,
        );
      }
      return _getMockWeather();
    } catch (e) {
      return _getMockWeather();
    }
  }

  /// 判断是否适合遛狗
  static bool _isGoodForWalk(int temp, String condition, int windScale) {
    if (temp > 33 || temp < -5) return false;
    if (condition.contains('暴雨') || condition.contains('大雪') || condition.contains('雷')) return false;
    if (windScale >= 6) return false;
    return true;
  }

  /// 生成遛狗建议文案
  static String _getWalkAdvice(int temp, String condition, int windScale) {
    if (temp > 33) return '今天好热，短时间散步就好，多喝水';
    if (temp > 28) return '天气较热，避开中午时段，早晚遛更舒服';
    if (temp < -5) return '太冷了，尽量短时间外出，穿好衣服';
    if (temp < 5) return '天气寒冷，出门注意保暖';
    if (condition.contains('暴雨')) return '暴雨天不建议外出，在家玩耍也能打卡';
    if (condition.contains('雨')) return '下雨了，带好雨具或在家陪宝贝玩';
    if (condition.contains('雪')) return '下雪天路面滑，注意安全';
    if (condition.contains('雷')) return '雷暴天气，请待在室内';
    if (windScale >= 6) return '风太大了，建议改天再遛';
    if (condition.contains('晴') && temp >= 15 && temp <= 28) return '天气不错，适合带宝贝出门运动';
    return '天气正常，适合出门运动';
  }

  /// 获取天气预警
  static WeatherWarning? _getWarning(int temp, String condition) {
    if (temp > 35) {
      return WeatherWarning(type: 'heat', title: '高温预警', advice: '高温天易中暑，短鼻犬（法斗/巴哥）严禁剧烈运动');
    }
    if (temp < -8) {
      return WeatherWarning(type: 'cold', title: '寒潮预警', advice: '注意保暖，短毛犬建议穿衣服');
    }
    if (condition.contains('暴雨')) {
      return WeatherWarning(type: 'rain', title: '暴雨预警', advice: '建议在家运动，逗猫棒/拔河都算打卡');
    }
    if (condition.contains('雷')) {
      return WeatherWarning(type: 'storm', title: '雷暴预警', advice: '请待在室内，不要外出');
    }
    if (condition.contains('霾') || condition.contains('雾')) {
      return WeatherWarning(type: 'haze', title: '雾霾预警', advice: '空气差，减少外出时间');
    }
    return null;
  }

  /// 和风天气图标代码转emoji
  static String _getWeatherIcon(String code) {
    final iconMap = {
      '100': '☀️', '101': '🌤️', '102': '⛅', '103': '🌥️', '104': '☁️',
      '300': '🌧️', '301': '🌧️', '302': '⛈️', '303': '⛈️', '304': '⛈️',
      '305': '🌧️', '306': '🌧️', '307': '🌧️', '308': '🌧️', '309': '🌦️',
      '400': '❄️', '401': '🌨️', '402': '🌨️', '403': '🌨️', '404': '🌨️',
      '500': '🌫️', '501': '🌫️', '502': '🌫️', '503': '🏜️', '504': '🏜️',
    };
    return iconMap[code] ?? '🌤️';
  }

  /// 模拟天气数据（未配置API Key时使用）
  static WeatherData _getMockWeather() {
    final hour = DateTime.now().hour;
    final isDay = hour >= 6 && hour < 18;
    return WeatherData(
      cityName: '北京',
      temperature: isDay ? 26 : 18,
      condition: '晴',
      conditionIcon: isDay ? '☀️' : '🌙',
      humidity: 45,
      windSpeed: 2,
      isGoodForWalk: true,
      walkAdvice: '天气不错，适合带宝贝出门运动',
    );
  }
}
