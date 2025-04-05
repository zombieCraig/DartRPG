import 'package:flutter_test/flutter_test.dart';
import 'package:dart_rpg/models/journal_entry.dart';
import 'package:dart_rpg/models/character.dart';

// This test focuses on the logic for updating the journal entry when momentum is burned
// We can't directly test the MoveDialog class since it uses Flutter widgets,
// but we can test the logic for updating the journal entry

void main() {
  group('Journal entry update when burning momentum', () {
    test('Journal entry should be updated with new outcome after burning momentum', () {
      // Create a test journal entry
      final journalEntry = JournalEntry(content: 'Test journal entry');
      
      // Create a test move roll with a miss outcome
      final moveRoll = MoveRoll(
        moveName: 'Face Danger',
        stat: 'Edge',
        statValue: 2,
        actionDie: 1,
        challengeDice: [5, 6],
        outcome: 'miss',
        rollType: 'action_roll',
      );
      
      // Add the move roll to the journal entry
      journalEntry.attachMoveRoll(moveRoll);
      
      // Verify the initial state
      expect(journalEntry.moveRolls.length, equals(1));
      expect(journalEntry.moveRolls[0].outcome, equals('miss'));
      
      // Simulate burning momentum by updating the move roll outcome and setting momentumBurned flag
      moveRoll.outcome = 'strong hit';
      moveRoll.momentumBurned = true;
      
      // Simulate the onMoveRollAdded callback being called again with the updated move roll
      // In the real implementation, this would be done by the MoveDialog class
      journalEntry.attachMoveRoll(moveRoll);
      
      // Verify that the journal entry now has two move rolls
      expect(journalEntry.moveRolls.length, equals(2));
      
      // Verify that the most recent move roll has the updated outcome
      expect(journalEntry.moveRolls[1].outcome, equals('strong hit'));
      
      // Verify that the momentumBurned flag is set to true
      expect(journalEntry.moveRolls[1].momentumBurned, isTrue);
      
      // Verify that the formatted text includes the "Momentum Burned" note
      expect(journalEntry.moveRolls[1].getFormattedText(), contains('Momentum Burned'));
    });
    
    test('Character momentum should be reset after burning momentum', () {
      // Create a test character
      final character = Character.createMainCharacter('Test Character');
      
      // Set initial momentum
      character.momentum = 8;
      character.momentumReset = 2;
      
      // Verify initial state
      expect(character.momentum, equals(8));
      
      // Simulate burning momentum
      character.burnMomentum();
      
      // Verify that momentum has been reset
      expect(character.momentum, equals(2));
    });
    
    test('MoveRoll getFormattedText should reflect the updated outcome and momentum burned status', () {
      // Create a test move roll with a miss outcome
      final moveRoll = MoveRoll(
        moveName: 'Face Danger',
        stat: 'Edge',
        statValue: 2,
        actionDie: 1,
        challengeDice: [5, 6],
        outcome: 'miss',
        rollType: 'action_roll',
      );
      
      // Verify initial formatted text
      expect(moveRoll.getFormattedText(), equals('[Face Danger - Miss]'));
      
      // Simulate burning momentum by updating the outcome
      moveRoll.outcome = 'weak hit';
      moveRoll.momentumBurned = true;
      
      // Verify updated formatted text includes momentum burned note
      expect(moveRoll.getFormattedText(), equals('[Face Danger - Weak Hit (Momentum Burned)]'));
      
      // Reset momentum burned flag
      moveRoll.momentumBurned = false;
      
      // Update to strong hit without burning momentum
      moveRoll.outcome = 'strong hit';
      
      // Verify updated formatted text without momentum burned note
      expect(moveRoll.getFormattedText(), equals('[Face Danger - Strong Hit]'));
      
      // Set momentum burned flag again
      moveRoll.momentumBurned = true;
      
      // Verify formatted text with momentum burned note
      expect(moveRoll.getFormattedText(), equals('[Face Danger - Strong Hit (Momentum Burned)]'));
    });
  });
}
