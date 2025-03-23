import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_rpg/models/oracle.dart';
import 'package:dart_rpg/models/journal_entry.dart';
import 'package:dart_rpg/screens/journal_entry_screen.dart';

void main() {
  group('OracleRoll in JournalEntry', () {
    test('OracleRoll creation and serialization', () {
      // Create an OracleRoll
      final oracleRoll = OracleRoll(
        oracleName: 'Test Oracle',
        oracleTable: 'Test Category',
        dice: [5],
        result: 'Test Result',
      );
      
      // Test properties
      expect(oracleRoll.oracleName, equals('Test Oracle'));
      expect(oracleRoll.oracleTable, equals('Test Category'));
      expect(oracleRoll.dice, equals([5]));
      expect(oracleRoll.result, equals('Test Result'));
      
      // Test serialization
      final json = oracleRoll.toJson();
      final fromJson = OracleRoll.fromJson(json);
      
      expect(fromJson.oracleName, equals(oracleRoll.oracleName));
      expect(fromJson.oracleTable, equals(oracleRoll.oracleTable));
      expect(fromJson.dice, equals(oracleRoll.dice));
      expect(fromJson.result, equals(oracleRoll.result));
    });
    
    test('OracleRoll with null oracleTable', () {
      // Create an OracleRoll with null oracleTable
      final oracleRoll = OracleRoll(
        oracleName: 'Test Oracle',
        oracleTable: null,
        dice: [5],
        result: 'Test Result',
      );
      
      // Test properties
      expect(oracleRoll.oracleName, equals('Test Oracle'));
      expect(oracleRoll.oracleTable, isNull);
      expect(oracleRoll.dice, equals([5]));
      expect(oracleRoll.result, equals('Test Result'));
      
      // Test serialization
      final json = oracleRoll.toJson();
      final fromJson = OracleRoll.fromJson(json);
      
      expect(fromJson.oracleName, equals(oracleRoll.oracleName));
      expect(fromJson.oracleTable, equals(oracleRoll.oracleTable));
      expect(fromJson.dice, equals(oracleRoll.dice));
      expect(fromJson.result, equals(oracleRoll.result));
    });
  });
  
  group('JournalEntry with OracleRolls', () {
    test('JournalEntry with multiple OracleRolls', () {
      // Create OracleRolls
      final oracleRoll1 = OracleRoll(
        oracleName: 'Oracle 1',
        oracleTable: 'Category 1',
        dice: [3],
        result: 'Result 1',
      );
      
      final oracleRoll2 = OracleRoll(
        oracleName: 'Oracle 2',
        oracleTable: null,
        dice: [6],
        result: 'Result 2',
      );
      
      // Create JournalEntry with OracleRolls
      final journalEntry = JournalEntry(
        content: 'Test content',
        oracleRolls: [oracleRoll1, oracleRoll2],
      );
      
      // Test properties
      expect(journalEntry.oracleRolls.length, equals(2));
      expect(journalEntry.oracleRolls[0].oracleName, equals('Oracle 1'));
      expect(journalEntry.oracleRolls[1].oracleName, equals('Oracle 2'));
      
      // Test serialization
      final json = journalEntry.toJson();
      final fromJson = JournalEntry.fromJson(json);
      
      expect(fromJson.oracleRolls.length, equals(2));
      expect(fromJson.oracleRolls[0].oracleName, equals('Oracle 1'));
      expect(fromJson.oracleRolls[0].oracleTable, equals('Category 1'));
      expect(fromJson.oracleRolls[1].oracleName, equals('Oracle 2'));
      expect(fromJson.oracleRolls[1].oracleTable, isNull);
    });
    
    test('JournalEntry backward compatibility with single oracleRoll', () {
      // Create OracleRoll
      final oracleRoll = OracleRoll(
        oracleName: 'Test Oracle',
        oracleTable: 'Test Category',
        dice: [5],
        result: 'Test Result',
      );
      
      // Create JournalEntry with single OracleRoll
      final journalEntry = JournalEntry(
        content: 'Test content',
      );
      
      // Set using the backward compatibility setter
      journalEntry.oracleRoll = oracleRoll;
      
      // Test properties
      expect(journalEntry.oracleRolls.length, equals(1));
      expect(journalEntry.oracleRoll, equals(oracleRoll));
      expect(journalEntry.oracleRoll?.oracleName, equals('Test Oracle'));
      
      // Test serialization
      final json = journalEntry.toJson();
      final fromJson = JournalEntry.fromJson(json);
      
      expect(fromJson.oracleRolls.length, equals(1));
      expect(fromJson.oracleRoll?.oracleName, equals('Test Oracle'));
    });
    
    test('attachOracleRoll adds to oracleRolls list', () {
      // Create JournalEntry
      final journalEntry = JournalEntry(
        content: 'Test content',
      );
      
      // Create OracleRolls
      final oracleRoll1 = OracleRoll(
        oracleName: 'Oracle 1',
        oracleTable: 'Category 1',
        dice: [3],
        result: 'Result 1',
      );
      
      final oracleRoll2 = OracleRoll(
        oracleName: 'Oracle 2',
        oracleTable: null,
        dice: [6],
        result: 'Result 2',
      );
      
      // Attach OracleRolls
      journalEntry.attachOracleRoll(oracleRoll1);
      journalEntry.attachOracleRoll(oracleRoll2);
      
      // Test properties
      expect(journalEntry.oracleRolls.length, equals(2));
      expect(journalEntry.oracleRolls[0].oracleName, equals('Oracle 1'));
      expect(journalEntry.oracleRolls[1].oracleName, equals('Oracle 2'));
    });
  });
}
