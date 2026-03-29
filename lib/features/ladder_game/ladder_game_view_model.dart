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

class LadderBar {
  final double startYOffset;
  final double endYOffset;
  final bool exists;

  LadderBar({this.startYOffset = 0, this.endYOffset = 0, this.exists = false});
}

class LadderGameViewModel extends ChangeNotifier {
  int _playerCount;
  int get playerCount => _playerCount;

  bool _isShroudActive = true; 
  bool get isShroudActive => _isShroudActive;

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
    Participant(animalType: '코알라', emoji: '🐨', color: Colors.greenAccent),
    Participant(animalType: '돼지', emoji: '🐷', color: Colors.pink),
    Participant(animalType: '개구리', emoji: '🐸', color: Colors.lightGreen),
    Participant(animalType: '원숭이', emoji: '🐵', color: Colors.brown),
    Participant(animalType: '닭', emoji: '🐔', color: Colors.redAccent),
    Participant(animalType: '펭귄', emoji: '🐧', color: Colors.blueGrey),
    Participant(animalType: '병아리', emoji: '🐤', color: Colors.yellow),
    Participant(animalType: '햄스터', emoji: '🐹', color: Colors.orange),
    Participant(animalType: '유니콘', emoji: '🦄', color: Colors.purpleAccent),
    Participant(animalType: '거북이', emoji: '🐢', color: Colors.green),
    Participant(animalType: '코끼리', emoji: '🐘', color: Colors.blueAccent),
    Participant(animalType: '용', emoji: '🐲', color: Colors.tealAccent),
  ];

  List<Participant> _currentParticipants = [];
  List<Participant> get currentParticipants => _currentParticipants;

  List<String> _bottomResults = [];
  List<String> get bottomResults => _bottomResults;

  List<List<LadderBar>> _ladderBars = [];
  List<List<LadderBar>> get ladderBars => _ladderBars;

  int _sectionCount = 10;
  int get sectionCount => _sectionCount;

  LadderGameViewModel({int initialCount = 4})
    : _playerCount = initialCount {
    _initData();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _playerCount = prefs.getInt('playerCount') ?? _playerCount;
    _speedLevel = prefs.getInt('speedLevel') ?? 3;
    _isShroudActive = true; 
    _initData();
    notifyListeners();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('playerCount', _playerCount);
    await prefs.setInt('speedLevel', _speedLevel);
  }

  void _initData() {
    _currentParticipants = _allAvailableParticipants.take(_playerCount).toList();
    _generateResults();
    _generateLadder();
  }

  void _generateResults() {
    final random = Random();
    int winnerIdx = random.nextInt(_playerCount);
    _bottomResults = List.generate(
      _playerCount,
      (i) => i == winnerIdx ? '당첨!' : '통과',
    );
    _bottomResults.shuffle(); // 생성 시 셔플 추가
  }

  void setSectionCount(int count) {
    _sectionCount = count.clamp(5, 100);
    _generateLadder();
    _generateResults(); // 설정 변경 시에도 결과 셔플
    notifyListeners();
  }

  void setPlayerCount(int count) {
    _playerCount = count;
    // 참가자 수 기반 가로선 기본값 동적 변경 (참가자 수 * 1.5 올림)
    _sectionCount = (count * 1.5).ceil().clamp(5, 100);
    _initData();
    _saveSettings();
    notifyListeners();
  }

  void setSpeedLevel(int level) {
    _speedLevel = level.clamp(1, 5);
    _saveSettings();
    notifyListeners();
  }

  void refreshLadder() {
    _generateLadder();
    _generateResults(); // 섞기 시 결과 셔플
    // _isShroudActive = true; // 가림막 상태 유지 (유저 요청)
    notifyListeners();
  }

  void toggleShroudActive() {
    _isShroudActive = !_isShroudActive;
    notifyListeners();
  }

  void setShroudActive(bool active) {
    _isShroudActive = active;
    notifyListeners();
  }

  void resetShroud() {
    _isShroudActive = true;
    notifyListeners();
  }

  void _generateLadder() {
    final random = Random();
    _ladderBars = List.generate(
      _playerCount - 1,
      (_) => List.generate(_sectionCount, (_) => LadderBar()),
    );
    int targetCount = _sectionCount;
    int currentCount = 0;
    int attempts = 0;
    const int maxAttempts = 1000;
    while (currentCount < targetCount && attempts < maxAttempts) {
      attempts++;
      int col = random.nextInt(_playerCount - 1);
      int row = random.nextInt(_sectionCount);
      // 상단(0)과 하단(_sectionCount-1) 영역 보호 (가로선 방지)
      if (row < 1 || row >= _sectionCount - 1) continue;
      if (_ladderBars[col][row].exists) continue;
      bool hasLeft = col > 0 && _ladderBars[col - 1][row].exists;
      bool hasRight =
          col < _playerCount - 2 && _ladderBars[col + 1][row].exists;
      if (!hasLeft && !hasRight) {
        double startY = (random.nextDouble() - 0.5) * 0.6;
        double endY = (random.nextDouble() - 0.5) * 0.6;
        _ladderBars[col][row] = LadderBar(
          exists: true,
          startYOffset: startY,
          endYOffset: endY,
        );
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
    final sectionHeight = size.height / (_sectionCount + 1);
    List<Offset> path = [];
    int currentIdx = startIdx;
    path.add(Offset(sectionWidth * (currentIdx + 1), 0));
    
    for (int j = 0; j < _sectionCount; j++) {
      final yBase = sectionHeight * (j + 1);
      final currentX = sectionWidth * (currentIdx + 1);
      if (currentIdx < _playerCount - 1 && _ladderBars[currentIdx][j].exists) {
        final bar = _ladderBars[currentIdx][j];
        path.add(Offset(currentX, yBase + (bar.startYOffset * sectionHeight)));
        currentIdx++;
        path.add(
          Offset(
            sectionWidth * (currentIdx + 1),
            yBase + (bar.endYOffset * sectionHeight),
          ),
        );
      } else if (currentIdx > 0 && _ladderBars[currentIdx - 1][j].exists) {
        final bar = _ladderBars[currentIdx - 1][j];
        path.add(Offset(currentX, yBase + (bar.endYOffset * sectionHeight)));
        currentIdx--;
        path.add(
          Offset(
            sectionWidth * (currentIdx + 1),
            yBase + (bar.startYOffset * sectionHeight),
          ),
        );
      } else {
        path.add(Offset(currentX, yBase));
      }
    }
    path.add(Offset(sectionWidth * (currentIdx + 1), size.height));
    return path;
  }
}
