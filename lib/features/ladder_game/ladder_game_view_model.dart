import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Participant {
  final String animalType;
  final String emoji;
  final Color color;
  String? customName;

  Participant({
    required this.animalType,
    required this.emoji,
    required this.color,
  });

  String get displayName => customName ?? '$animalType님';
}

/// 사다리의 가로/대각선 바 정보를 담는 클래스
class LadderBar {
  final double startYOffset; // -0.2 ~ 0.2 사이의 상대적 Y 오프셋
  final double endYOffset;
  final bool exists;

  LadderBar({
    this.startYOffset = 0,
    this.endYOffset = 0,
    this.exists = false,
  });
}

class LadderGameViewModel extends ChangeNotifier {
  int _playerCount;
  int get playerCount => _playerCount;

  bool _isShroudVisible; // 설정값: 가림막 사용 여부
  bool get isShroudVisible => _isShroudVisible;

  bool _isShroudActive = true; // 현재 게임에서의 가림막 활성 상태
  bool get isShroudActive => _isShroudActive;

  // 속도 단계 (1~5단계: 1단계=느림, 3단계=보통, 5단계=빠름)
  int _speedLevel = 3;
  int get speedLevel => _speedLevel;

  final List<Participant> _allAvailableParticipants = [
    Participant(animalType: '사자', emoji: '🦁', color: Colors.orangeAccent),
    Participant(animalType: '고양이', emoji: '🐱', color: Colors.pinkAccent),
    Participant(animalType: '곰', emoji: '🐻', color: Colors.brown),
    Participant(animalType: '강아지', emoji: '🐶', color: Colors.lightBlueAccent),
    Participant(animalType: '여우', emoji: '🦊', color: Colors.deepOrangeAccent),
    Participant(animalType: '토끼', emoji: '🐰', color: Colors.white70),
    Participant(animalType: '판다', emoji: '🐼', color: Colors.grey),
    Participant(animalType: '호랑이', emoji: '🐯', color: Colors.yellowAccent),
  ];

  List<Participant> _currentParticipants = [];
  List<Participant> get currentParticipants => _currentParticipants;

  List<String> _bottomResults = [];
  List<String> get bottomResults => _bottomResults;

  List<List<LadderBar>> _ladderBars = [];
  List<List<LadderBar>> get ladderBars => _ladderBars;

  int _sectionCount = 10;
  int get sectionCount => _sectionCount;

  LadderGameViewModel({int initialCount = 4, bool initialShroud = true})
    : _playerCount = initialCount,
      _isShroudVisible = initialShroud {
    _initData();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _playerCount = prefs.getInt('playerCount') ?? _playerCount;
    _isShroudVisible = prefs.getBool('useShroud') ?? _isShroudVisible;
    _speedLevel = prefs.getInt('speedLevel') ?? 3;
    _isShroudActive = _isShroudVisible; // 로드된 설정에 따라 초기 상태 결정
    _initData(); // 초기화 다시 수행 (로드된 데이터 기준)
    notifyListeners();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('playerCount', _playerCount);
    await prefs.setBool('useShroud', _isShroudVisible);
    await prefs.setInt('speedLevel', _speedLevel);
  }

  void _initData() {
    _currentParticipants = _allAvailableParticipants.take(_playerCount).toList();
    final random = Random();
    int winnerIdx = random.nextInt(_playerCount);
    _bottomResults = List.generate(_playerCount, (i) => i == winnerIdx ? '당첨!' : '통과');
    _generateLadder();
  }

  void setSectionCount(int count) {
    _sectionCount = count.clamp(5, 20);
    _generateLadder();
    notifyListeners();
  }

  void setPlayerCount(int count) {
    _playerCount = count;
    _initData();
    _saveSettings(); // 즉시 저장
    notifyListeners();
  }

  void setSpeedLevel(int level) {
    _speedLevel = level.clamp(1, 5);
    _saveSettings(); // 즉시 저장
    notifyListeners();
  }

  // 가림막 설정 토글 (설정 화면용)
  void toggleShroudSetting() {
    _isShroudVisible = !_isShroudVisible;
    _isShroudActive = _isShroudVisible;
    _saveSettings(); // 즉시 저장
    notifyListeners();
  }

  // 가림막 현재 가시성 조절 (게임 화면용)
  void setShroudActive(bool active) {
    _isShroudActive = active;
    notifyListeners();
  }

  // 가림막 상태를 설정값에 맞춰 초기화 (게임 리셋용)
  void resetShroud() {
    _isShroudActive = _isShroudVisible;
    notifyListeners();
  }

  void _generateLadder() {
    final random = Random();
    _ladderBars = List.generate(_playerCount - 1, (_) => List.generate(_sectionCount, (_) => LadderBar()));
    int targetCount = _sectionCount; 
    int currentCount = 0;
    int attempts = 0;
    const int maxAttempts = 1000;
    while (currentCount < targetCount && attempts < maxAttempts) {
      attempts++;
      int col = random.nextInt(_playerCount - 1);
      int row = random.nextInt(_sectionCount);
      if (row < 2) continue;
      if (_ladderBars[col][row].exists) continue;
      bool hasLeft = col > 0 && _ladderBars[col - 1][row].exists;
      bool hasRight = col < _playerCount - 2 && _ladderBars[col + 1][row].exists;
      if (!hasLeft && !hasRight) {
        double startY = (random.nextDouble() - 0.5) * 0.6;
        double endY = (random.nextDouble() - 0.5) * 0.6;
        _ladderBars[col][row] = LadderBar(exists: true, startYOffset: startY, endYOffset: endY);
        currentCount++;
      }
    }
  }

  void updateResult(int index, String text) {
    if (index >= 0 && index < _bottomResults.length) {
      _bottomResults[index] = text;
      notifyListeners();
    }
  }

  void refreshLadder() {
    _generateLadder();
    resetShroud(); // 섞을 때 가림막 초기화
    notifyListeners();
  }

  int getResultIndex(int startIdx) {
    if (_ladderBars.isEmpty) return startIdx;
    int currentIdx = startIdx;
    for (int j = 0; j < _sectionCount; j++) {
      if (currentIdx < _playerCount - 1 && _ladderBars[currentIdx][j].exists) {
        currentIdx++;
      } else if (currentIdx > 0 && _ladderBars[currentIdx - 1][j].exists) {
        currentIdx--;
      }
    }
    return currentIdx;
  }

  List<Offset> getPath(int startIdx, Size size) {
    final sectionWidth = size.width / (_playerCount + 1);
    final sectionHeight = size.height / (_sectionCount + 2);
    List<Offset> path = [];
    int currentIdx = startIdx;
    path.add(Offset(sectionWidth * (currentIdx + 1), sectionHeight * 0.5));
    for (int j = 0; j < _sectionCount; j++) {
      final yBase = sectionHeight * (j + 1.5);
      final currentX = sectionWidth * (currentIdx + 1);
      if (currentIdx < _playerCount - 1 && _ladderBars[currentIdx][j].exists) {
        final bar = _ladderBars[currentIdx][j];
        path.add(Offset(currentX, yBase + (bar.startYOffset * sectionHeight)));
        currentIdx++;
        path.add(Offset(sectionWidth * (currentIdx + 1), yBase + (bar.endYOffset * sectionHeight)));
      } else if (currentIdx > 0 && _ladderBars[currentIdx - 1][j].exists) {
        final bar = _ladderBars[currentIdx - 1][j];
        path.add(Offset(currentX, yBase + (bar.endYOffset * sectionHeight)));
        currentIdx--;
        path.add(Offset(sectionWidth * (currentIdx + 1), yBase + (bar.startYOffset * sectionHeight)));
      } else {
        path.add(Offset(currentX, yBase));
      }
    }
    path.add(Offset(sectionWidth * (currentIdx + 1), sectionHeight * (_sectionCount + 1.5)));
    return path;
  }
}
