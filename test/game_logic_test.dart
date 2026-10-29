import 'package:flutter_test/flutter_test.dart';
import 'package:opendart/models/throw_record.dart';
import 'package:opendart/utils/score_validator.dart';
import 'package:opendart/utils/checkout_helper.dart';
import 'package:opendart/services/game_service.dart';
import 'package:opendart/models/combo_result.dart';

ThrowRecord _makeThrow({
  required int rawValue,
  required String type,
  int round = 1,
  int dart = 1,
  bool isBust = false,
}) {
  return ThrowRecord(
    id: 'test_${rawValue}_$type',
    gameId: 'game1',
    playerId: 'player1',
    round: round,
    dartNumber: dart,
    scoreValue: MultiplierType.computeScore(rawValue, type),
    rawValue: rawValue,
    multiplierType: type,
    isBust: isBust,
    createdAt: DateTime.now(),
  );
}

void main() {
  group('ScoreValidator — computeScore', () {
    test('single sector', () {
      expect(ScoreValidator.computeScore(20, MultiplierType.single), 20);
      expect(ScoreValidator.computeScore(1, MultiplierType.single), 1);
    });

    test('double sector', () {
      expect(ScoreValidator.computeScore(20, MultiplierType.double_), 40);
      expect(ScoreValidator.computeScore(10, MultiplierType.double_), 20);
    });

    test('triple sector', () {
      expect(ScoreValidator.computeScore(20, MultiplierType.triple), 60);
      expect(ScoreValidator.computeScore(19, MultiplierType.triple), 57);
    });

    test('bull scores 50', () {
      expect(ScoreValidator.computeScore(25, MultiplierType.bull), 50);
    });

    test('outer bull scores 25', () {
      expect(ScoreValidator.computeScore(25, MultiplierType.outerBull), 25);
    });

    test('miss scores 0', () {
      expect(ScoreValidator.computeScore(0, MultiplierType.miss), 0);
    });

    test('invalid sector returns null', () {
      expect(ScoreValidator.computeScore(21, MultiplierType.single), null);
      expect(ScoreValidator.computeScore(0, MultiplierType.single), null);
    });
  });

  group('ScoreValidator — bust detection (doubleOut)', () {
    test('goes negative → bust', () {
      final r = ScoreValidator.checkBust(
        remaining: 10,
        scoreValue: 15,
        multiplierType: MultiplierType.single,
        doubleOut: true,
      );
      expect(r.isBust, true);
      expect(r.newRemaining, 10); // restored
    });

    test('leaves exactly 1 → bust', () {
      final r = ScoreValidator.checkBust(
        remaining: 3,
        scoreValue: 2,
        multiplierType: MultiplierType.single,
        doubleOut: true,
      );
      expect(r.isBust, true);
    });

    test('reaches 0 with single → bust (doubleOut)', () {
      final r = ScoreValidator.checkBust(
        remaining: 20,
        scoreValue: 20,
        multiplierType: MultiplierType.single,
        doubleOut: true,
      );
      expect(r.isBust, true);
    });

    test('reaches 0 with double → not bust', () {
      final r = ScoreValidator.checkBust(
        remaining: 40,
        scoreValue: 40,
        multiplierType: MultiplierType.double_,
        doubleOut: true,
      );
      expect(r.isBust, false);
      expect(r.newRemaining, 0);
    });

    test('reaches 0 with bull → not bust', () {
      final r = ScoreValidator.checkBust(
        remaining: 50,
        scoreValue: 50,
        multiplierType: MultiplierType.bull,
        doubleOut: true,
      );
      expect(r.isBust, false);
      expect(r.newRemaining, 0);
    });

    test('normal subtraction — no bust', () {
      final r = ScoreValidator.checkBust(
        remaining: 100,
        scoreValue: 60,
        multiplierType: MultiplierType.triple,
        doubleOut: true,
      );
      expect(r.isBust, false);
      expect(r.newRemaining, 40);
    });
  });

  group('ScoreValidator — winning throw', () {
    test('zero remaining + double → win', () {
      expect(
        ScoreValidator.isWinningThrow(
          newRemaining: 0,
          multiplierType: MultiplierType.double_,
          doubleOut: true,
        ),
        true,
      );
    });

    test('zero remaining + bull → win', () {
      expect(
        ScoreValidator.isWinningThrow(
          newRemaining: 0,
          multiplierType: MultiplierType.bull,
          doubleOut: true,
        ),
        true,
      );
    });

    test('zero remaining + single → no win (doubleOut)', () {
      expect(
        ScoreValidator.isWinningThrow(
          newRemaining: 0,
          multiplierType: MultiplierType.single,
          doubleOut: true,
        ),
        false,
      );
    });

    test('non-zero remaining → no win', () {
      expect(
        ScoreValidator.isWinningThrow(
          newRemaining: 2,
          multiplierType: MultiplierType.double_,
          doubleOut: true,
        ),
        false,
      );
    });
  });

  group('CheckoutHelper', () {
    test('D20 = 40', () {
      expect(CheckoutHelper.getSuggestion(40), ['D20']);
    });

    test('Bull = S10 D20', () {
      expect(CheckoutHelper.getSuggestion(50), ['S10', 'D20']);
    });

    test('170 = T20 T20 Bull', () {
      expect(CheckoutHelper.getSuggestion(170), ['T20', 'T20', 'Bull']);
    });

    test('100 = T20 D20', () {
      expect(CheckoutHelper.getSuggestion(100), ['T20', 'D20']);
    });

    test ('all suggestions are arithmetically correct, getSuggestion returns null and hasCheckout returns false for impossible scores', () {
      for (int i = 1; i < 171; i++) {
        List<String>? output = CheckoutHelper.getSuggestion(i);
        bool checkoutAvailable = CheckoutHelper.hasCheckout(i);
        if (i == 1 || i == 159 || i == 162 || i == 163 || i == 165 || i == 166 || i == 168 || i == 169) {
          expect(output, null);
          expect(checkoutAvailable, false);
        } else if (output != null) {
          int sum = 0;
          for (var element in output) {
            if (element == 'Bull') {
              sum += 50;
            } else if (element == 'Outer') {
              sum += 25;
            } else {
              final type = element[0];
              if (type == 'S') {
                sum += int.parse((element.substring(1)));
              } else if (type == 'D') {
                sum += 2 * int.parse(element.substring(1));
              } else if (type == 'T') {
                sum += 3 * int.parse(element.substring(1));
              }
            }
          }
          expect(i, sum);
          expect(checkoutAvailable, true);
        } else {
          fail('null checkout suggestion despite possible score, $i');
        }
      }
    });
  });

  group('GameService — combo detection', () {
    test('zone mastery: all 3 darts same sector', () {
      final throws = [
        _makeThrow(rawValue: 20, type: MultiplierType.single, dart: 1),
        _makeThrow(rawValue: 20, type: MultiplierType.double_, dart: 2),
        _makeThrow(rawValue: 20, type: MultiplierType.triple, dart: 3),
      ];
      final combo = GameService.evaluateCombos(
        currentTurnThrows: throws,
        previousTurnScore: null,
        streakCount: 0,
      );
      expect(combo, isNotNull);
      expect(combo!.type, ComboResult.zoneMastery().type);
    });

    test('consecutive doubles: 2 doubles in one turn', () {
      final throws = [
        _makeThrow(rawValue: 10, type: MultiplierType.double_, dart: 1),
        _makeThrow(rawValue: 15, type: MultiplierType.double_, dart: 2),
        _makeThrow(rawValue: 5, type: MultiplierType.single, dart: 3),
      ];
      final combo = GameService.evaluateCombos(
        currentTurnThrows: throws,
        previousTurnScore: null,
        streakCount: 0,
      );
      expect(combo, isNotNull);
      expect(combo!.type, 'consecutive_doubles');
    });

    test('exact match: same total as previous player', () {
      final throws = [
        _makeThrow(rawValue: 20, type: MultiplierType.triple, dart: 1), // 60
        _makeThrow(rawValue: 5, type: MultiplierType.single, dart: 2),  // 5
      ];
      final combo = GameService.evaluateCombos(
        currentTurnThrows: throws,
        previousTurnScore: 65, // 60 + 5
        streakCount: 0,
      );
      expect(combo, isNotNull);
      expect(combo!.type, 'exact_match');
    });

    test('no combo: regular turn', () {
      final throws = [
        _makeThrow(rawValue: 5, type: MultiplierType.single, dart: 1),
        _makeThrow(rawValue: 7, type: MultiplierType.single, dart: 2),
        _makeThrow(rawValue: 3, type: MultiplierType.single, dart: 3),
      ];
      final combo = GameService.evaluateCombos(
        currentTurnThrows: throws,
        previousTurnScore: 100,
        streakCount: 0,
      );
      expect(combo, isNull);
    });

    test('streak: 3+ turns >= 60', () {
      final throws = [
        _makeThrow(rawValue: 20, type: MultiplierType.triple, dart: 1), // 60
      ];
      final combo = GameService.evaluateCombos(
        currentTurnThrows: throws,
        previousTurnScore: null,
        streakCount: 3, // already at 3
      );
      expect(combo, isNotNull);
      expect(combo!.type, 'streak');
    });
  });

  group('GameService — turn total', () {
    test('sums non-bust throws', () {
      final throws = [
        _makeThrow(rawValue: 20, type: MultiplierType.triple), // 60
        _makeThrow(rawValue: 19, type: MultiplierType.triple), // 57
        _makeThrow(rawValue: 20, type: MultiplierType.triple), // 60 → 180 total
      ];
      expect(GameService.turnTotal(throws), 177); // 60+57+60
    });

    test('excludes busted throws', () {
      final throws = [
        _makeThrow(rawValue: 20, type: MultiplierType.single), // 20
        _makeThrow(rawValue: 5, type: MultiplierType.single, isBust: true),
      ];
      expect(GameService.turnTotal(throws), 20);
    });
  });

  group('GameService — streak tracking', () {
    test('increments when turn >= threshold', () {
      expect(GameService.updateStreak(2, 60), 3);
      expect(GameService.updateStreak(0, 80), 1);
    });

    test('resets when turn < threshold', () {
      expect(GameService.updateStreak(5, 40), 0);
      expect(GameService.updateStreak(0, 59), 0);
    });
  });
}
