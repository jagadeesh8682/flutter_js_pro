import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_js_plus/js_plus.dart';

void main() {
  group('JsPlus', () {
    late JsPlus js;

    setUp(() {
      js = JsPlus();
    });

    tearDown(() {
      js.dispose();
    });

    test('evaluate simple arithmetic', () async {
      final result = await js.evaluate('1 + 2');
      expect(result, equals(3));
    });

    test('evaluate string expressions', () async {
      final result = await js.evaluate('"Hello" + " " + "World"');
      expect(result, equals('Hello World'));
    });

    test('evaluate boolean expressions', () async {
      final result = await js.evaluate('true && false');
      expect(result, equals(false));
    });

    test('evaluate with variables', () async {
      await js.evaluate('const x = 10;');
      final result = await js.evaluate('x * 2');
      expect(result, equals(20));
    });

    test('evaluate JavaScript objects', () async {
      final result = await js.evaluate('({a: 1, b: 2})');
      expect(result, isA<Map>());
      final map = result as Map;
      expect(map['a'], equals(1));
      expect(map['b'], equals(2));
    });

    test('evaluate JavaScript arrays', () async {
      final result = await js.evaluate('[1, 2, 3, 4, 5]');
      expect(result, isA<List>());
      final list = result as List;
      expect(list.length, equals(5));
      expect(list[0], equals(1));
      expect(list[4], equals(5));
    });

    test('evaluate null', () async {
      final result = await js.evaluate('null');
      expect(result, isNull);
    });

    test('evaluate undefined', () async {
      final result = await js.evaluate('undefined');
      // On web, undefined becomes null; on native it might be a string
      expect(result == null || result == 'undefined', isTrue);
    });

    test('evaluate complex expressions', () async {
      final result = await js.evaluate('''
        (function() {
          let sum = 0;
          for (let i = 1; i <= 10; i++) {
            sum += i;
          }
          return sum;
        })()
      ''');
      expect(result, equals(55));
    });

    test('error handling - throw exception', () async {
      expect(
        () => js.evaluate('throw new Error("Test error")'),
        throwsA(isA<JsEvaluationException>()),
      );
    });

    test('error handling - syntax error', () async {
      expect(
        () => js.evaluate('const x = ;'),
        throwsA(isA<JsEvaluationException>()),
      );
    });

    test('multiple evaluations share context', () async {
      await js.evaluate('const shared = "value";');
      final result1 = await js.evaluate('shared');
      final result2 = await js.evaluate('shared + "2"');
      
      expect(result1, equals('value'));
      expect(result2, equals('value2'));
    });

    test('evaluate Math functions', () async {
      final result = await js.evaluate('Math.max(1, 2, 3, 4, 5)');
      expect(result, equals(5));
    });

    test('evaluate JSON operations', () async {
      final result = await js.evaluate('''
        JSON.parse('{"key": "value"}')
      ''');
      expect(result, isA<Map>());
      final map = result as Map;
      expect(map['key'], equals('value'));
    });
  });

  group('JsTypeConversion', () {
    test('listToJsArray converts List to JS array string', () {
      final list = [1, 2, 3];
      final jsArray = JsTypeConversion.listToJsArray(list);
      expect(jsArray, equals('[1, 2, 3]'));
    });

    test('listToJsArray handles empty list', () {
      final list = <dynamic>[];
      final jsArray = JsTypeConversion.listToJsArray(list);
      expect(jsArray, equals('[]'));
    });

    test('listToJsArray handles strings', () {
      final list = ['a', 'b', 'c'];
      final jsArray = JsTypeConversion.listToJsArray(list);
      expect(jsArray, contains('"a"'));
      expect(jsArray, contains('"b"'));
      expect(jsArray, contains('"c"'));
    });

    test('mapToJsObject converts Map to JS object string', () {
      final map = {'a': 1, 'b': 2};
      final jsObj = JsTypeConversion.mapToJsObject(map);
      expect(jsObj, contains('"a"'));
      expect(jsObj, contains('"b"'));
      expect(jsObj, contains('1'));
      expect(jsObj, contains('2'));
    });

    test('mapToJsObject handles empty map', () {
      final map = <String, dynamic>{};
      final jsObj = JsTypeConversion.mapToJsObject(map);
      expect(jsObj, equals('{}'));
    });
  });
}

