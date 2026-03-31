import 'package:audioplayers/audioplayers.dart';

class SoundManager {
  static final SoundManager _instance = SoundManager._internal();
  factory SoundManager() => _instance;
  SoundManager._internal();

  final AudioPlayer _tickPlayer = AudioPlayer();
  final AudioPlayer _sparkPlayer = AudioPlayer();
  final AudioPlayer _fanfarePlayer = AudioPlayer();
  // 결과 공개 효과음 (tick 사운드를 빠르게 재사용)
  final AudioPlayer _popPlayer = AudioPlayer();
  // 팀 결과 / 전환 효과음
  final AudioPlayer _wooshPlayer = AudioPlayer();

  Future<void> init() async {
    await _tickPlayer.setSource(AssetSource('audio/tick.wav'));
    await _tickPlayer.setPlayerMode(PlayerMode.lowLatency);
    await _sparkPlayer.setSource(AssetSource('audio/spark.wav'));
    await _sparkPlayer.setPlayerMode(PlayerMode.lowLatency);
    await _fanfarePlayer.setSource(AssetSource('audio/fanfare.wav'));
    // pop: spark 사운드를 빠르게 재사용
    await _popPlayer.setSource(AssetSource('audio/spark.wav'));
    await _popPlayer.setPlayerMode(PlayerMode.lowLatency);
    // woosh: tick 사운드를 재사용
    await _wooshPlayer.setSource(AssetSource('audio/tick.wav'));
    await _wooshPlayer.setPlayerMode(PlayerMode.lowLatency);
  }

  void playTick() {
    _tickPlayer.stop().then((_) => _tickPlayer.resume());
  }

  void playSpark() {
    _sparkPlayer.stop().then((_) => _sparkPlayer.resume());
  }

  void playFanfare() {
    _fanfarePlayer.stop().then((_) => _fanfarePlayer.resume());
  }

  /// 결과 카드 등장 시 짧은 팡! 효과
  void playPop() {
    _popPlayer.stop().then((_) => _popPlayer.resume());
  }

  /// 팀 나누기 결과 카드 전환 효과
  void playWoosh() {
    _wooshPlayer.stop().then((_) => _wooshPlayer.resume());
  }
}
