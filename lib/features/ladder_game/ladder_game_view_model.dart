import 'dart:convert';
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
    this.customName,
  });

  String get displayName => customName ?? animalType;

  Map<String, dynamic> toJson() => {
    'animalType': animalType,
    'emoji': emoji,
    'color': color.value,
    'customName': customName,
  };

  factory Participant.fromJson(Map<String, dynamic> json) => Participant(
    animalType: json['animalType'],
    emoji: json['emoji'],
    color: Color(json['color']),
    customName: json['customName'],
  );
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

  // 팀 나누기 전용 설정
  int _teamCount = 2;
  int get teamCount => _teamCount;
  bool _hasTeamLeader = false;
  bool get hasTeamLeader => _hasTeamLeader;

  // 팀 컬러 팔레트 (최대 6팀)
  static const List<Color> teamColors = [
    Color(0xFFFF007F), // 핫핑크
    Color(0xFF00FFFF), // 시안
    Color(0xFFFFFF00), // 옐로우
    Color(0xFF7FFF00), // 라임
    Color(0xFFFF8C00), // 오렌지
    Color(0xFFBF00FF), // 퍼플
  ];

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

  List<Participant> get allAvailableParticipants => _allAvailableParticipants;

  List<Participant> _currentParticipants = [];
  List<Participant> get currentParticipants => _currentParticipants;

  List<String> _bottomResults = [];
  List<String> get bottomResults => _bottomResults;

  List<List<LadderBar>> _ladderBars = [];
  List<List<LadderBar>> get ladderBars => _ladderBars;

  int _sectionCount = 10;
  int get sectionCount => _sectionCount;

  LadderGameViewModel({int initialCount = 5}) : _playerCount = initialCount {
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
    } else if (mode == LadderGameMode.team) {
      _teamCount = 2;
      _penaltyCount = 2;
      _penaltyContents = ['1팀', '2팀'];
    } else if (mode == LadderGameMode.manual) {
      _penaltyCount = _playerCount;
      _penaltyContents = List.generate(_playerCount, (i) => '');
    }
    _generateResults();
    notifyListeners();
  }

  // 팀 나누기 전용: 팀 수 설정
  void setTeamCount(int count) {
    _teamCount = count.clamp(2, (_playerCount / 1).floor());
    _penaltyCount = _teamCount;
    // 팀 라벨 재구성
    _penaltyContents = List.generate(_teamCount, (i) => '${i + 1}팀');
    _generateResults();
    notifyListeners();
  }

  // 팀 나누기 전용: 팀장 유무 토글
  void setHasTeamLeader(bool value) {
    _hasTeamLeader = value;
    _generateResults();
    notifyListeners();
  }

  // 특정 참가자 아이콘 변경
  void changeParticipantAnimal(int index, Participant newAnimal) {
    if (index >= 0 && index < _currentParticipants.length) {
      _currentParticipants[index] = Participant(
        animalType: newAnimal.animalType,
        emoji: newAnimal.emoji,
        color: newAnimal.color,
        customName: _currentParticipants[index].customName,
      );
      notifyListeners();
    }
  }

  // 특정 참가자 커스텀 이름 변경
  void updateParticipantName(int index, String name) {
    if (index >= 0 && index < _currentParticipants.length) {
      _currentParticipants[index].customName = name.trim().isNotEmpty ? name.trim() : null;
      notifyListeners();
    }
  }

  void setPenaltyCount(int count) {
    _penaltyCount = count.clamp(1, _playerCount); // manual/team 모드를 위해 최대치를 _playerCount로 
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
    } else if (_currentMode == LadderGameMode.team) {
      defaultText = '';
      emoji = '팀';
    }

    if (_penaltyContents.length < _penaltyCount) {
      _penaltyContents.addAll(
        List.generate(
          _penaltyCount - _penaltyContents.length,
          (i) {
             if (_currentMode == LadderGameMode.team) return '${_penaltyContents.length + i + 1}팀';
             return defaultText.isEmpty ? '' : '$defaultText ${_penaltyContents.length + i + 1} $emoji';
          }
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

  // 모든 설정을 기본값(5명, 속도 3, 모드별 기본 내용 등)으로 초기화
  void resetSettings() {
    _playerCount = 5;
    _speedLevel = 3;
    _isShroudActive = true;
    _hasTeamLeader = false;
    _teamCount = 2;

    // 참가자 명단도 초기화 (명단 불러오기 등으로 바뀐 데이터 복원)
    _currentParticipants.clear();
    _initData(keepParticipants: false);
    
    // 현재 모드에 맞춰 데이터 재초기화
    setMode(_currentMode);
    _saveSettings();
    notifyListeners();
  }

  void _initData({bool keepParticipants = false}) {
    if (!keepParticipants) {
       List<Participant> newParticipants = [];
       for(int i=0; i<_playerCount; i++) {
           if (i < _currentParticipants.length) {
               newParticipants.add(_currentParticipants[i]);
           } else {
               newParticipants.add(Participant(
                   animalType: _allAvailableParticipants[i % _allAvailableParticipants.length].animalType,
                   emoji: _allAvailableParticipants[i % _allAvailableParticipants.length].emoji,
                   color: _allAvailableParticipants[i % _allAvailableParticipants.length].color,
               ));
           }
       }
       _currentParticipants = newParticipants;
    }

    if (_currentMode == LadderGameMode.manual) {
      _penaltyCount = _playerCount;
      if (_penaltyContents.length != _playerCount) {
        _penaltyContents = List.generate(_playerCount, (i) => '');
      }
    }
    _generateResults();
    _generateLadder();
  }

  Future<void> saveCurrentParticipants(String listName) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> savedNames = prefs.getStringList('savedLists') ?? [];
    if (!savedNames.contains(listName)) {
      savedNames.add(listName);
      await prefs.setStringList('savedLists', savedNames);
    }
    String jsonStr = jsonEncode(_currentParticipants.map((p) => p.toJson()).toList());
    await prefs.setString('list_$listName', jsonStr);
    notifyListeners();
  }

  Future<List<String>> getSavedLists() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('savedLists') ?? [];
  }

  Future<void> loadParticipantList(String listName) async {
    final prefs = await SharedPreferences.getInstance();
    String? jsonStr = prefs.getString('list_$listName');
    if (jsonStr != null) {
      List<dynamic> jsonList = jsonDecode(jsonStr);
      _currentParticipants = jsonList.map((j) => Participant.fromJson(j)).toList();
      _playerCount = _currentParticipants.length;
      setPlayerCount(_playerCount); // This will call _initData() and keep old sizes. But we want to overwrite it because we just loaded it.
    }
  }

  Future<void> deleteParticipantList(String listName) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> savedNames = prefs.getStringList('savedLists') ?? [];
    savedNames.remove(listName);
    await prefs.setStringList('savedLists', savedNames);
    await prefs.remove('list_$listName');
    notifyListeners();
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
      case LadderGameMode.team:
        // 팀 나누기: 홀수 처리는 앞 팀부터 1명씩 추가
        List<String> results = [];
        int baseSize = _playerCount ~/ _penaltyCount;
        int remainder = _playerCount % _penaltyCount;
        for (int i = 0; i < _penaltyCount; i++) {
          int teamSize = baseSize + (i < remainder ? 1 : 0);
          if (_hasTeamLeader) {
            // 팀장 1명 + 나머지는 팀원
            results.add('${i + 1}팀 팀장 👑');
            results.addAll(List.generate(teamSize - 1, (_) => '${i + 1}팀 팀원'));
          } else {
            results.addAll(List.generate(teamSize, (_) => '${i + 1}팀'));
          }
        }
        results.shuffle();
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
