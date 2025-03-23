import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_rpg/widgets/journal/rich_text_editor.dart';

void main() {
  group('RichTextEditor', () {
    group('insertTextAtCursor', () {
      test('inserts text at cursor position', () {
        final controller = TextEditingController(text: 'Hello world');
        controller.selection = const TextSelection.collapsed(offset: 5); // Cursor after "Hello"
        
        RichTextEditor.insertTextAtCursor(controller, ' beautiful');
        
        expect(controller.text, equals('Hello beautiful world'));
        expect(controller.selection.baseOffset, equals(15)); // Cursor after "Hello beautiful"
        expect(controller.selection.extentOffset, equals(15));
        expect(controller.selection.isCollapsed, isTrue);
      });
      
      test('replaces selected text', () {
        final controller = TextEditingController(text: 'Hello world');
        controller.selection = const TextSelection(baseOffset: 6, extentOffset: 11); // "world" selected
        
        RichTextEditor.insertTextAtCursor(controller, 'everyone');
        
        expect(controller.text, equals('Hello everyone'));
        expect(controller.selection.baseOffset, equals(14)); // Cursor after "Hello everyone"
        expect(controller.selection.extentOffset, equals(14));
        expect(controller.selection.isCollapsed, isTrue);
      });
      
      test('appends text when no valid selection', () {
        final controller = TextEditingController(text: 'Hello world');
        // Create an invalid selection by setting it to null first
        controller.selection = const TextSelection.collapsed(offset: -1);
        
        RichTextEditor.insertTextAtCursor(controller, '!');
        
        expect(controller.text, equals('Hello world!'));
        expect(controller.selection.baseOffset, equals(12)); // Cursor at the end
        expect(controller.selection.extentOffset, equals(12));
        expect(controller.selection.isCollapsed, isTrue);
      });
      
      test('inserts text at beginning of document', () {
        final controller = TextEditingController(text: 'Hello world');
        controller.selection = const TextSelection.collapsed(offset: 0); // Cursor at beginning
        
        RichTextEditor.insertTextAtCursor(controller, 'Greetings! ');
        
        expect(controller.text, equals('Greetings! Hello world'));
        expect(controller.selection.baseOffset, equals(11)); // Cursor after "Greetings! "
        expect(controller.selection.extentOffset, equals(11));
        expect(controller.selection.isCollapsed, isTrue);
      });
      
      test('inserts text at end of document', () {
        final controller = TextEditingController(text: 'Hello world');
        controller.selection = const TextSelection.collapsed(offset: 11); // Cursor at end
        
        RichTextEditor.insertTextAtCursor(controller, '!');
        
        expect(controller.text, equals('Hello world!'));
        expect(controller.selection.baseOffset, equals(12)); // Cursor after "!"
        expect(controller.selection.extentOffset, equals(12));
        expect(controller.selection.isCollapsed, isTrue);
      });
      
      test('handles empty document', () {
        final controller = TextEditingController(text: '');
        controller.selection = const TextSelection.collapsed(offset: 0); // Cursor at beginning
        
        RichTextEditor.insertTextAtCursor(controller, 'Hello world');
        
        expect(controller.text, equals('Hello world'));
        expect(controller.selection.baseOffset, equals(11)); // Cursor at end
        expect(controller.selection.extentOffset, equals(11));
        expect(controller.selection.isCollapsed, isTrue);
      });
      
      test('handles multi-line text', () {
        final controller = TextEditingController(text: 'Line 1\nLine 2\nLine 3');
        controller.selection = const TextSelection.collapsed(offset: 7); // Cursor after "Line 1\n"
        
        RichTextEditor.insertTextAtCursor(controller, 'New ');
        
        expect(controller.text, equals('Line 1\nNew Line 2\nLine 3'));
        expect(controller.selection.baseOffset, equals(11)); // Cursor after "Line 1\nNew "
        expect(controller.selection.extentOffset, equals(11));
        expect(controller.selection.isCollapsed, isTrue);
      });
    });
  });
}
