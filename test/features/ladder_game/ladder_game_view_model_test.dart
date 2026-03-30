import 'package:flutter_test/flutter_test.dart';
import 'package:ladder_game/features/ladder_game/ladder_game_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('LadderGameViewModel Tests', () {
    test('Initialization sets correct player count and generates ladder', () {
      final viewModel = LadderGameViewModel();
      expect(viewModel.playerCount, 4);
      expect(viewModel.currentParticipants.length, 4);
      expect(viewModel.bottomResults.length, 4);
      expect(viewModel.ladderBars.length, 3); // 4 players = 3 gaps
    });

    test('setPlayerCount updates data correctly', () {
      final viewModel = LadderGameViewModel();
      viewModel.setPlayerCount(6);
      expect(viewModel.playerCount, 6);
      expect(viewModel.ladderBars.length, 5);
    });

    test('getResultIndex returns a valid index within range', () {
      final viewModel = LadderGameViewModel();
      for (int i = 0; i < viewModel.playerCount; i++) {
        final resultIdx = viewModel.getResultIndex(i);
        expect(resultIdx, greaterThanOrEqualTo(0));
        expect(resultIdx, lessThan(viewModel.playerCount));
      }
    });

    test('Ladder generation avoids overlapping bars in adjacent columns', () {
      final viewModel = LadderGameViewModel();
      final bars = viewModel.ladderBars;
      
      for (int i = 1; i < bars.length; i++) {
        for (int j = 0; j < viewModel.sectionCount; j++) {
          if (bars[i][j].exists) {
            // 인접한 칸(좌측)에 다리가 없어야 함
            expect(bars[i-1][j].exists, isFalse);
          }
        }
      }
    });
  });
}
