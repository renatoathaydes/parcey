import ceylon.test {
    test,
    assertEquals,
    assertFalse,
    fail
}

import com.athaydes.parcey {
    anyChar,
    ParseResult,
    letter,
    ParseError,
    oneOf,
    noneOf,
    eof,
    space,
    spaceChars,
    anyStr,
    str,
    char,
    digit,
    word,
    spaces,
    chars,
    mapParser,
    strParser
}
import com.athaydes.parcey.combinator {
    ...
}

test
shared void testEof() {
    assert (is ParseResult<[]> result1 = eof().parse(""));
    assertEquals(result1.result.sequence(), []);
    assertEquals(result1.parseLocation, [0, 0]);
    assertEquals(result1.consumed, []);
    assertEquals(result1.overConsumed, []);
    
    assert (is ParseError result2 = eof().parse("a"));
    assertFalse(result2.message.empty);
    assertEquals(result2.consumed, ['a']);
}

test
shared void testAnyChar() {
    assert (is ParseResult<{Character*}> result1 = anyChar().parse("a"));
    assertEquals(result1.result, ['a']);
    assertEquals(result1.parseLocation, [0, 1]);
    assertEquals(result1.consumed, ['a']);
    assertEquals(result1.overConsumed, []);
    
    assert (is ParseResult<{Character*}> result2 = anyChar().parse("xyz"));
    assertEquals(result2.result, ['x']);
    assertEquals(result2.parseLocation, [0, 1]);
    assertEquals(result2.consumed, ['x']);
    assertEquals(result2.overConsumed, []);
    
    assert (is ParseError result3 = anyChar().parse(""));
    assertFalse(result3.message.empty);
    assertEquals(result3.consumed, []);
}

test
shared void testChars() {
    value parser = chars { 'a', 'b', 'c' };
    
    value result1 = parser.parse('a'..'z');
    
    if (is ParseResult<{Character+}> result1) {
        assertEquals(result1.result.sequence(), ['a', 'b', 'c']);
        assertEquals(result1.parseLocation, [0, 3]);
        assertEquals(result1.consumed, ['a', 'b', 'c']);
        assertEquals(result1.overConsumed, []);
    } else {
        fail("Result was ```result1``");
    }

    value result2 = parser.parse("abxy");
    if (is ParseError result2) {
        assertEquals(result2.consumed, ['a', 'b', 'x']);
        assertFalse(result2.message.empty);
    } else {
        fail("Result was ```result2``");
    }
}

test
shared void testLetter() {
    for (item in ('a'..'z').append('A'..'Z')) {
        assert (is ParseResult<{Character*}> result = letter().parse({ item }));
        assertEquals(result.result, [item]);
        assertEquals(result.parseLocation, [0, 1]);
        assertEquals(result.consumed, [item]);
        assertEquals(result.overConsumed, []);
    }
    for (item in ['\t', ' ', '?', '!', '%', '^', '&', '*']) {
        assert (is ParseError result = letter().parse({ item }));
        assertFalse(result.message.empty);
        assertEquals(result.consumed, [item]);
    }
}

test
shared void testSpace() {
    assert (is ParseError result1 = space().parse(""));
    assertFalse(result1.message.empty);
    assertEquals(result1.consumed, []);
    
    for (item in spaceChars) {
        value result = space().parse({ item });
        if (is ParseResult<{Character*}> result) {
            assertEquals(result.result, [item]);
            if (item == '\n') {
                assertEquals(result.parseLocation, [1, 0]);
            } else {
                assertEquals(result.parseLocation, [0, 1]);
            }
            assertEquals(result.consumed, [item]);
            assertEquals(result.overConsumed, []);
        } else {
            fail("Result was ```result``");
        }
    }
    
    assert (is ParseError result2 = space().parse("xy"));
    assertFalse(result2.message.empty);
    assertEquals(result2.consumed, ['x']);
}

test
shared void testAnyString() {
    assert (is ParseResult<{String*}> result1 = anyStr().parse(""));
    assertEquals(result1.result.sequence(), [""]);
    assertEquals(result1.parseLocation, [0, 0]);
    assertEquals(result1.consumed, []);
    assertEquals(result1.overConsumed, []);
    
    assert (is ParseResult<{String*}> result2 = anyStr().parse("a"));
    assertEquals(result2.result.sequence(), ["a"]);
    assertEquals(result2.parseLocation, [0, 1]);
    assertEquals(result2.consumed, ['a']);
    assertEquals(result2.overConsumed, []);
    
    assert (is ParseResult<{String*}> result3 = anyStr().parse("xyz abc"));
    assertEquals(result3.result.sequence(), ["xyz"]);
    assertEquals(result3.parseLocation, [0, 3]);
    assertEquals(result3.consumed, ['x', 'y', 'z']);
    assertEquals(result3.overConsumed, [' ']);
}

test
shared void testWord() {
    value result1 = word().parse("");
    if (is ParseError result1) {
        assertFalse(result1.message.empty);
        assertEquals(result1.consumed, []);
    } else {
        fail("Result was ```result1``");
    }
    
    value result2 = word().parse("a");
    if (is ParseResult<{String*}> result2) {
        assertEquals(result2.result.sequence(), ["a"]);
        assertEquals(result2.parseLocation, [0, 1]);
        assertEquals(result2.consumed, ['a']);
        assertEquals(result2.overConsumed, []);
    } else {
        fail("Result was ```result2``");
    }
    
    value result3 = word().parse("xyz abc");
    if (is ParseResult<{String*}> result3) {
        assertEquals(result3.result.sequence(), ["xyz"]);
        assertEquals(result3.parseLocation, [0, 3]);
        assertEquals(result3.consumed, ['x', 'y', 'z']);
        assertEquals(result3.overConsumed, [' ']);
    } else {
        fail("Result was ```result3``");
    }
    
    value result4 = word().parse("abcd123");
    if (is ParseResult<{String*}> result4) {
        assertEquals(result4.result.sequence(), ["abcd"]);
        assertEquals(result4.parseLocation, [0, 4]);
        assertEquals(result4.consumed, ['a', 'b', 'c', 'd']);
        assertEquals(result4.overConsumed, ['1']);
    } else {
        fail("Result was ```result4``");
    }
}

test
shared void testStr() {
    value result1 = str("").parse("");
    if (is ParseResult<{String+}> result1) {
        assertEquals(result1.result.sequence(), [""]);
        assertEquals(result1.parseLocation, [0, 0]);
        assertEquals(result1.consumed, []);
        assertEquals(result1.overConsumed, []);
    } else {
        fail("Result was ``result1``");
    }
    
    value result2 = str("a").parse("a");
    if (is ParseResult<{String+}> result2) {
        assertEquals(result2.result.sequence(), ["a"]);
        assertEquals(result2.parseLocation, [0, 1]);
        assertEquals(result2.consumed, ['a']);
        assertEquals(result2.overConsumed, []);
    } else {
        fail("Result was ``result2``");
    }
    
    value result3 = str("xyz").parse("xyz abc");
    if (is ParseResult<{String+}> result3) {
        assertEquals(result3.result.sequence(), ["xyz"]);
        assertEquals(result3.parseLocation, [0, 3]);
        assertEquals(result3.consumed, ['x', 'y', 'z']);
        assertEquals(result3.overConsumed, []);
    } else {
        fail("Result was ``result3``");
    }
    
    value result4 = str("xyz").parse("xyab");
    if (is ParseError result4) {
        assertFalse(result4.message.empty);
        assertEquals(result4.consumed, ['x', 'y', 'a']);
    } else {
        fail("Result was ``result4``");
    }
    
    value result5 = str("xyz").parse("abcxyz");
    if (is ParseError result5) {
        assertFalse(result5.message.empty);
        assertEquals(result5.consumed, ['a']);
    } else {
        fail("Result was ``result5``");
    }
}

test
shared void testStringDoesNotOverconsume() {
    value iterator = object satisfies Iterator<Character> {
        value chars = ['x', 'y', 'z'];
        variable Integer index = 0;
        shared actual Character next() {
            value char = chars[index++];
            if (exists char) {
                return char;
            } else {
                throw AssertionError("Overconsumed!");
            }
        }
    };
    value result = str("xyz").doParse(iterator, [4, 10], null);
    if (is ParseResult<{String+}> result) {
        assertEquals(result.result.sequence(), ["xyz"]);
        assertEquals(result.parseLocation, [4, 13]);
        assertEquals(result.consumed, ['x', 'y', 'z']);
        assertEquals(result.overConsumed, []);
    } else {
        fail("Result was ``result``");
    }
}

test
shared void testOneOf() {
    value parser = oneOf({ 'x', 'a' });
    
    value result1 = parser.parse("");
    if (is ParseError result1) {
        assertFalse(result1.message.empty);
        assertEquals(result1.consumed, []);
    } else {
        fail("Result was ``result1``");
    }
    
    for (item in ['x', 'a']) {
        value result = parser.parse({ item });
        if (is ParseResult<{Character*}> result) {
            assertEquals(result.result, [item]);
            assertEquals(result.parseLocation, [0, 1]);
            assertEquals(result.consumed, [item]);
            assertEquals(result.overConsumed, []);
        } else {
            fail("Result was ``result``");
        }
    }
    for (item in ('A'..'Z').append(['\t', ' ', '?', '!', '%', '^', '&', '*'])) {
        value result = parser.parse({ item });
        if (is ParseError result) {
            assertFalse(result.message.empty);
            assertEquals(result.consumed, [item]);
        } else {
            fail("Result was ``result``");
        }
    }
}

test
shared void testNoneOf() {
    value parser = noneOf({ 'x', 'a' });
    
    value result1 = parser.parse("");
    if (is ParseError result1) {
        assertFalse(result1.message.empty);
        assertEquals(result1.consumed, []);
    } else {
        fail("Result was ``result1``");
    }
    
    for (item in ['x', 'a']) {
        value result = parser.parse({ item });
        if (is ParseError result) {
            assertFalse(result.message.empty);
            assertEquals(result.consumed, [item]);
        } else {
            fail("Result was ``result``");
        }
    }
    for (item in ('A'..'Z').append(['\t', ' ', '?', '!', '%', '^', '&', '*'])) {
        value result = parser.parse({ item });
        if (is ParseResult<{Character*}> result) {
            assertEquals(result.result, [item]);
            assertEquals(result.parseLocation, [0, 1]);
            assertEquals(result.consumed, [item]);
            assertEquals(result.overConsumed, []);
        } else {
            fail("Result was ``result``");
        }
    }
}

test
shared void testDigit() {
    for (input in (0..9).map(Object.string)) {
        assert (is ParseResult<{Character*}> result = digit().parse(input));
        assertEquals(result.result, input.sequence());
        assertEquals(result.parseLocation, [0, 1]);
        assertEquals(result.consumed, input.sequence());
        assertEquals(result.overConsumed, []);
    }
    
    for (input in ["a", "b", "z", "#", "%", "~", "@", "hello", "#0", "!22"]) {
        assert (is ParseError result = digit().parse(input));
        assertFalse(result.message.empty);
        assertEquals(result.consumed, [input.first]);
    }
    
    assert (is ParseError result = digit().parse(""));
    assertFalse(result.message.empty);
    assertEquals(result.consumed, []);
}

test
shared void simpleCombinationTest() {
    value lowerCasedLetter = oneOf('a'..'z');
    value underscore = char('_');
    value identifier = seq({
        either { lowerCasedLetter, underscore },
        many(either { letter(), underscore })
    }, "identifier");
    
    for (input in ["a", "_", "_a", "___", "_x_y_z", "abc___", "__xx__"]) {
        value result = identifier.parse(input);
        if (is ParseResult<{Character*}> result) {
            assertEquals(result.result.sequence(), input.sequence());
            assertEquals(result.parseLocation, [0, input.size]);
            assertEquals(result.consumed, input.sequence());
            assertEquals(result.overConsumed, []);
        } else {
            fail("Result was ``result``");
        }
    }
    
    for (input in ["", " ", "1", "@"]) {
        value result = identifier.parse(input);
        if (is ParseError result) {
            assertFalse(result.message.empty);
            assertEquals(result.consumed, input.sequence());
        } else {
            fail("Result was ``result``");
        }
    }
    
    value result1 = identifier.parse("_abc ");
    if (is ParseResult<{Character*}> result1) {
        assertEquals(result1.result.sequence(), ['_', 'a', 'b', 'c']);
        assertEquals(result1.parseLocation, [0, 4]);
        assertEquals(result1.consumed, ['_', 'a', 'b', 'c']);
        assertEquals(result1.overConsumed, [' ']);
    } else {
        fail("Result was ``result1``");
    }
}

test
shared void complexCombinationTest() {
    interface CeylonElement {}
    class Identifier(shared String name) satisfies CeylonElement {
        string = "(id: ``name``)";
        equals(Object that) => if (is Identifier that) then this.name == that.name else false;
    }
    class Type(shared String name) satisfies CeylonElement {
        string = "(type: ``name``)";
        equals(Object that) => if (is Type that) then this.name == that.name else false;
    }
    class Arg(Type type, String name) {
        string = "{``type`` ``name``}";
        equals(Object that) => if (is Arg that)
        then this.name == that.name && this.type == that.type else false;
    }
    
    value capitalLetter = oneOf('A'..'Z');
    value lowerCasedLetter = oneOf('a'..'z');
    value underscore = char('_');
    value identifierStr = strParser(seq({
            either { lowerCasedLetter, underscore },
            many(either { letter(), underscore })
        }, "identifier"));
    value identifier = mapParser(identifierStr, Identifier);
    value typeStr = strParser(seq({
            capitalLetter,
            many(either { letter(), underscore })
        }, "type identifier"));
    value typeIdentifier = mapParser(typeStr, Type);
    value modifier = identifier;
    value argument = seq({
        typeIdentifier,
        spaces(1),
        identifier
    }, "argument");
    value argumentList = seq({
        skip(char('(')),
        sepBy(around(spaces(), char(',')), argument),
        skip(char(')'))
    }, "argument list");
    
    value ceylonFunctionSignature = seq {
        spaces(),
        many(seq { modifier, spaces(1) }),
        typeIdentifier,
        spaces(1),
        identifier,
        spaces(),
        argumentList
    };
    
    value result = ceylonFunctionSignature.parse(" String hi(Boolean b, Integer i) ");
    if (is ParseResult<{CeylonElement*}> result) {
        assertEquals(result.result.sequence(),
            [Type("String"), Identifier("hi"),
             Type("Boolean"), Identifier("b"),
             Type("Integer"), Identifier("i")]);
    } else {
        fail("Result was ``result``");
    }
}
