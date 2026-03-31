import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ladder_game_mode.dart';

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

  String get displayName => customName ?? animalType;
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

  LadderGameMode _currentMode = LadderGameMode.penalty;
  LadderGameMode get currentMode => _currentMode;

  int _penaltyCount = 1;
  int get penaltyCount => _penaltyCount;

  List<String> _penaltyContents = ['벌칙 💀'];
  List<String> get penaltyContents => _penaltyContents;

  bool _isShroudActive = true;
  bool get isShroudActive => _isShroudActive;

  int _speedLevel = 3;
  int get speedLevel => _speedLevel;

  final List<Participant> _allAvailableParticipants = [
    Participant(animalType: '사자', emoji: '🦁', color: Colors.orangeAccent),
    Participant(animalType: '고양이', emoji: '🐱', color: Colors.pinkAccent),
    Participant(animalType: '소', emoji: '🐮', color: Colors.brown),
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
    Participant(animalType: '병아리', emoji: '🐥', color: Colors.yellow),
    Participant(animalType: '햄스터', emoji: '🐹', color: Colors.orange),
    Participant(animalType: '유니콘', emoji: '🦄', color: Colors.purpleAccent),
    Participant(animalType: '거북이', emoji: '🐢', color: Colors.green),
    Participant(animalType: '코끼리', emoji: '🐘', color: Colors.blueAccent),
    Participant(animalType: '말', emoji: '🐴', color: Colors.tealAccent),
  ];

  List<Participant> _currentParticipants = [];
  List<Participant> get currentParticipants => _currentParticipants;

  List<String> _bottomResults = [];
  List<String> get bottomResults => _bottomResults;

  List<List<LadderBar>> _ladderBars = [];
  List<List<LadderBar>> get ladderBars => _ladderBars;

  int _sectionCount = 10;
  int get sectionCount => _sectionCount;

  LadderGameViewModel({int initialCount = 4}) : _playerCount = initialCount {
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

  void setMode(LadderGameMode mode) {
    _currentMode = mode;
    // 모드 변경 시 초기화
    if (mode == LadderGameMode.penalty) {
      _penaltyCount = 1;
      _penaltyContents = ['벌칙 💀'];
    } else if (mode == LadderGameMode.win) {
      _penaltyCount = 1;
      _penaltyContents = ['당첨 🎁'];
    } else if (mode == LadderGameMode.treat) {
      _penaltyCount = 1;
      _penaltyContents = ['내가 쏜다! ☕'];
    } else if (mode == LadderGameMode.manual) {
      _penaltyCount = _playerCount;
      _penaltyContents = List.generate(_playerCount, (i) => '');
    }
    _generateResults();
    notifyListeners();
  }

  void setPenaltyCount(int count) {
    _penaltyCount = count.clamp(1, _playerCount); // manual 모드를 위해 최대치를 _playerCount로 변경
    // 내용 리스트 길이 조정
    String defaultText = '벌칙';
    String emoji = '💀';
    
    if (_currentMode == LadderGameMode.win) {
      defaultText = '당첨';
      emoji = '🎁';
    } else if (_currentMode == LadderGameMode.treat) {
      defaultText = '내가 쏜다!';
      emoji = '☕';
    } else if (_currentMode == LadderGameMode.manual) {
      defaultText = '';
      emoji = '';
    }

    if (_penaltyContents.length < _penaltyCount) {
      _penaltyContents.addAll(
        List.generate(
          _penaltyCount - _penaltyContents.length,
          (i) => defaultText.isEmpty ? '' : '$defaultText ${_penaltyContents.length + i + 1} $emoji',
        ),
      );
    } else if (_penaltyContents.length > _penaltyCount) {
      _penaltyContents = _penaltyContents.sublist(0, _penaltyCount);
    }
    _generateResults();
    notifyListeners();
  }

  void setAllPenalties(List<String> contents) {
    _penaltyContents = List.from(contents);
    _penaltyCount = _penaltyContents.length;
    _generateResults();
    notifyListeners();
  }

  void updatePenaltyContent(int index, String content) {
    if (index >= 0 && index < _penaltyContents.length) {
      _penaltyContents[index] = content;
      _generateResults();
      notifyListeners();
    }
  }

  void _initData() {
    _currentParticipants =
        _allAvailableParticipants.take(_playerCount).toList();
    if (_currentMode == LadderGameMode.manual) {
      _penaltyCount = _playerCount;
      if (_penaltyContents.length != _playerCount) {
        _penaltyContents = List.generate(_playerCount, (i) => '');
      }
    }
    _generateResults();
    _generateLadder();
  }

  void _generateResults() {
    final random = Random();
    // 모드별 결과 텍스트 생성
    switch (_currentMode) {
      case LadderGameMode.penalty:
        // 설정된 벌칙자 수만큼 벌칙 내용을 배치하고 나머지는 '통과'
        List<String> results = List.generate(_playerCount, (i) => '통과 ✨');
        List<int> indices = List.generate(_playerCount, (i) => i);
        indices.shuffle();

        for (int i = 0; i < _penaltyCount; i++) {
          results[indices[i]] = _penaltyContents[i];
        }
        _bottomResults = results;
        return;

      case LadderGameMode.win:
        // 설정된 당첨자 수만큼 당첨 내용을 배치하고 나머지는 '꽝'
        List<String> results = List.generate(_playerCount, (i) => '꽝 😢');
        List<int> indices = List.generate(_playerCount, (i) => i);
        indices.shuffle();

        for (int i = 0; i < _penaltyCount; i++) {
          results[indices[i]] = _penaltyContents[i];
        }
        _bottomResults = results;
        return;

      case LadderGameMode.treat:
        // 설정된 결제자 수만큼 내용을 배치하고 나머지는 '얻어먹기'
        List<String> results = List.generate(_playerCount, (i) => '얻어먹기 😋');
        List<int> indices = List.generate(_playerCount, (i) => i);
        indices.shuffle();

        for (int i = 0; i < _penaltyCount; i++) {
          results[indices[i]] = _penaltyContents[i];
        }
        _bottomResults = results;
        return;

      case LadderGameMode.order:
        List<String> results = List.generate(_playerCount, (i) => '${i + 1}번째');
        results.shuffle(); // 순서 결과를 무작위로 섞음
        _bottomResults = results;
        return;
      case LadderGameMode.manual:
        // 직접 입력 모드: 입력된 내용을 그대로 사용 (길이가 부족하면 빈 문자열 채움)
        List<String> results = List.from(_penaltyContents);
        while (results.length < _playerCount) {
          results.add('');
        }
        if (results.length > _playerCount) {
          results = results.sublist(0, _playerCount);
        }
        _bottomResults = results;
        break;
    }

    if (_currentMode != LadderGameMode.order) {
      _bottomResults.shuffle();
    }
  }

  void setSectionCount(int count) {
    _sectionCount = count.clamp(5, 100);
    _generateLadder();
    notifyListeners();
  }

  void setPlayerCount(int count) {
    _playerCount = count;
    _sectionCount = (count * 1.5).ceil().clamp(5, 100);
    // 인원 변경 시 벌칙자 수 유효성 검사
    if (_currentMode == LadderGameMode.manual) {
      _penaltyCount = _playerCount;
      // 직접 입력 모드에서는 인원수만큼 컨트롤러/내용이 필요함
      if (_penaltyContents.length < _playerCount) {
        _penaltyContents.addAll(List.generate(_playerCount - _penaltyContents.length, (_) => ''));
      } else if (_penaltyContents.length > _playerCount) {
        _penaltyContents = _penaltyContents.sublist(0, _playerCount);
      }
    } else {
      if (_penaltyCount >= _playerCount) {
        _penaltyCount = _playerCount - 1;
        if (_penaltyCount < 1) _penaltyCount = 1;
        _penaltyContents = _penaltyContents.sublist(0, _penaltyCount);
      }
    }
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
    _generateResults();
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
