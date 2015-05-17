import ceylon.test {
    test,
    assertEquals,
    assertFalse
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
    strParser,
    integer
}
import com.athaydes.parcey.combinator {
    ...
}
import test.com.athaydes.parcey.combinator {
    expect
}

test
shared void testEof() {
    expect(eof().parse(""), void(ParseResult<[]> result) {
            assertEquals(result.result.sequence(), []);
            assertEquals(result.parseLocation, [0, 0]);
            assertEquals(result.consumed, []);
            assertEquals(result.overConsumed, []);
        });
    
    expect(eof().parse("a"), void(ParseError result) {
            assertFalse(result.message.empty);
            assertEquals(result.consumed, ['a']);
        });
}

test
shared void testAnyChar() {
    expect(anyChar().parse("a"), void(ParseResult<{Character*}> result) {
            assertEquals(result.result, ['a']);
            assertEquals(result.parseLocation, [0, 1]);
            assertEquals(result.consumed, ['a']);
            assertEquals(result.overConsumed, []);
        });
    expect(anyChar().parse("xyz"), void(ParseResult<{Character*}> result) {
            assertEquals(result.result, ['x']);
            assertEquals(result.parseLocation, [0, 1]);
            assertEquals(result.consumed, ['x']);
            assertEquals(result.overConsumed, []);
        });
    
    expect(anyChar().parse(""), void(ParseError result3) {
            assertFalse(result3.message.empty);
            assertEquals(result3.consumed, []);
        });
}

test
shared void testChars() {
    value parser = chars { 'a', 'b', 'c' };
    
    expect(parser.parse('a'..'z'), void(ParseResult<{Character+}> result) {
            assertEquals(result.result.sequence(), ['a', 'b', 'c']);
            assertEquals(result.parseLocation, [0, 3]);
            assertEquals(result.consumed, ['a', 'b', 'c']);
            assertEquals(result.overConsumed, []);
        });
    
    expect(parser.parse("abxy"), void(ParseError result2) {
            assertEquals(result2.consumed, ['a', 'b', 'x']);
            assertFalse(result2.message.empty);
        });
}

test
shared void testLetter() {
    for (item in ('a'..'z').append('A'..'Z')) {
        expect(letter().parse({ item }), void(ParseResult<{Character*}> result) {
                assertEquals(result.result, [item]);
                assertEquals(result.parseLocation, [0, 1]);
                assertEquals(result.consumed, [item]);
                assertEquals(result.overConsumed, []);
            });
    }
    for (item in ['\t', ' ', '?', '!', '%', '^', '&', '*']) {
        expect(letter().parse({ item }), void(ParseError result) {
                assertFalse(result.message.empty);
                assertEquals(result.consumed, [item]);
            });
    }
}

test
shared void testSpace() {
    expect(space().parse(""), void(ParseError result1) {
            assertFalse(result1.message.empty);
            assertEquals(result1.consumed, []);
        });
    
    for (item in spaceChars) {
        expect(space().parse({ item }), void(ParseResult<{Character*}> result) {
                assertEquals(result.result, [item]);
                if (item == '\n') {
                    assertEquals(result.parseLocation, [1, 0]);
                } else {
                    assertEquals(result.parseLocation, [0, 1]);
                }
                assertEquals(result.consumed, [item]);
                assertEquals(result.overConsumed, []);
            });
    }
    
    expect(space().parse("xy"), void(ParseError result2) {
            assertFalse(result2.message.empty);
            assertEquals(result2.consumed, ['x']);
        });
}

test
shared void testAnyString() {
    expect(anyStr().parse(""), void(ParseResult<{String*}> result1) {
            assertEquals(result1.result.sequence(), [""]);
            assertEquals(result1.parseLocation, [0, 0]);
            assertEquals(result1.consumed, []);
            assertEquals(result1.overConsumed, []);
        });
    
    expect(anyStr().parse("a"), void(ParseResult<{String*}> result2) {
            assertEquals(result2.result.sequence(), ["a"]);
            assertEquals(result2.parseLocation, [0, 1]);
            assertEquals(result2.consumed, ['a']);
            assertEquals(result2.overConsumed, []);
        });
    
    expect(anyStr().parse("xyz abc"), void(ParseResult<{String*}> result3) {
            assertEquals(result3.result.sequence(), ["xyz"]);
            assertEquals(result3.parseLocation, [0, 3]);
            assertEquals(result3.consumed, ['x', 'y', 'z']);
            assertEquals(result3.overConsumed, [' ']);
        });
}

test
shared void testWord() {
    expect(word().parse(""), void(ParseError result1) {
            assertFalse(result1.message.empty);
            assertEquals(result1.consumed, []);
        });
    
    expect(word().parse("a"), void(ParseResult<{String*}> result2) {
            assertEquals(result2.result.sequence(), ["a"]);
            assertEquals(result2.parseLocation, [0, 1]);
            assertEquals(result2.consumed, ['a']);
            assertEquals(result2.overConsumed, []);
        });
    
    expect(word().parse("xyz abc"), void(ParseResult<{String*}> result3) {
            assertEquals(result3.result.sequence(), ["xyz"]);
            assertEquals(result3.parseLocation, [0, 3]);
            assertEquals(result3.consumed, ['x', 'y', 'z']);
            assertEquals(result3.overConsumed, [' ']);
        });
    
    expect(word().parse("abcd123"), void(ParseResult<{String*}> result4) {
            assertEquals(result4.result.sequence(), ["abcd"]);
            assertEquals(result4.parseLocation, [0, 4]);
            assertEquals(result4.consumed, ['a', 'b', 'c', 'd']);
            assertEquals(result4.overConsumed, ['1']);
        });
}

test
shared void testStr() {
    expect(str("").parse(""), void(ParseResult<{String+}> result1) {
            assertEquals(result1.result.sequence(), [""]);
            assertEquals(result1.parseLocation, [0, 0]);
            assertEquals(result1.consumed, []);
            assertEquals(result1.overConsumed, []);
        });
    
    expect(str("a").parse("a"), void(ParseResult<{String+}> result2) {
            assertEquals(result2.result.sequence(), ["a"]);
            assertEquals(result2.parseLocation, [0, 1]);
            assertEquals(result2.consumed, ['a']);
            assertEquals(result2.overConsumed, []);
        });
    
    expect(str("xyz").parse("xyz abc"), void(ParseResult<{String+}> result3) {
            assertEquals(result3.result.sequence(), ["xyz"]);
            assertEquals(result3.parseLocation, [0, 3]);
            assertEquals(result3.consumed, ['x', 'y', 'z']);
            assertEquals(result3.overConsumed, []);
        });
    
    expect(str("xyz").parse("xyab"), void(ParseError result4) {
            assertFalse(result4.message.empty);
            assertEquals(result4.consumed, ['x', 'y', 'a']);
        });
    
    expect(str("xyz").parse("abcxyz"), void(ParseError result5) {
            assertFalse(result5.message.empty);
            assertEquals(result5.consumed, ['a']);
        });
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
    expect(str("xyz").doParse(iterator, [4, 10]), void(ParseResult<{String+}> result) {
            assertEquals(result.result.sequence(), ["xyz"]);
            assertEquals(result.parseLocation, [4, 13]);
            assertEquals(result.consumed, ['x', 'y', 'z']);
            assertEquals(result.overConsumed, []);
        });
}

test
shared void testOneOf() {
    value parser = oneOf({ 'x', 'a' });
    
    expect(parser.parse(""), void(ParseError result1) {
            assertFalse(result1.message.empty);
            assertEquals(result1.consumed, []);
        });
    
    for (item in ['x', 'a']) {
        expect(parser.parse({ item }), void(ParseResult<{Character*}> result) {
                assertEquals(result.result, [item]);
                assertEquals(result.parseLocation, [0, 1]);
                assertEquals(result.consumed, [item]);
                assertEquals(result.overConsumed, []);
            });
    }
    for (item in ('A'..'Z').append(['\t', ' ', '?', '!', '%', '^', '&', '*'])) {
        expect(parser.parse({ item }), void(ParseError result) {
                assertFalse(result.message.empty);
                assertEquals(result.consumed, [item]);
            });
    }
}

test
shared void testNoneOf() {
    value parser = noneOf({ 'x', 'a' });
    
    expect(parser.parse(""), void(ParseError result1) {
            assertFalse(result1.message.empty);
            assertEquals(result1.consumed, []);
        });
    
    for (item in ['x', 'a']) {
        expect(parser.parse({ item }), void(ParseError result) {
                assertFalse(result.message.empty);
                assertEquals(result.consumed, [item]);
            });
    }
    for (item in ('A'..'Z').append(['\t', ' ', '?', '!', '%', '^', '&', '*'])) {
        expect(parser.parse({ item }), void(ParseResult<{Character*}> result) {
                assertEquals(result.result, [item]);
                assertEquals(result.parseLocation, [0, 1]);
                assertEquals(result.consumed, [item]);
                assertEquals(result.overConsumed, []);
            });
    }
}

test
shared void testDigit() {
    for (input in (0..9).map(Object.string)) {
        expect(digit().parse(input), void(ParseResult<{Character*}> result) {
                assertEquals(result.result, input.sequence());
                assertEquals(result.parseLocation, [0, 1]);
                assertEquals(result.consumed, input.sequence());
                assertEquals(result.overConsumed, []);
            });
    }
    
    for (input in ["a", "b", "z", "#", "%", "~", "@", "hello", "#0", "!22"]) {
        expect(digit().parse(input), void(ParseError result) {
                assertFalse(result.message.empty);
                assertEquals(result.consumed, [input.first]);
            });
    }
    
    expect(digit().parse(""), void(ParseError result) {
            assertFalse(result.message.empty);
            assertEquals(result.consumed, []);
        });
}

test
shared void testInteger() {
    // TODO
    integer().parse("");
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
        expect(identifier.parse(input), void(ParseResult<{Character*}> result) {
                assertEquals(result.result.sequence(), input.sequence());
                assertEquals(result.parseLocation, [0, input.size]);
                assertEquals(result.consumed, input.sequence());
                assertEquals(result.overConsumed, []);
            });
    }
    
    for (input in ["", " ", "1", "@"]) {
        expect(identifier.parse(input), void(ParseError result) {
                assertFalse(result.message.empty);
                assertEquals(result.consumed, input.sequence());
            });
    }
    
    expect(identifier.parse("_abc "), void(ParseResult<{Character*}> result1) {
            assertEquals(result1.result.sequence(), ['_', 'a', 'b', 'c']);
            assertEquals(result1.parseLocation, [0, 4]);
            assertEquals(result1.consumed, ['_', 'a', 'b', 'c']);
            assertEquals(result1.overConsumed, [' ']);
        });
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
        then this.name==that.name && this.type==that.type else false;
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
    
    expect(ceylonFunctionSignature.parse(" String hi(Boolean b, Integer i) "),
        void(ParseResult<{CeylonElement*}> result) {
            assertEquals(result.result.sequence(), [
                    Type("String"), Identifier("hi"),
                    Type("Boolean"), Identifier("b"),
                    Type("Integer"), Identifier("i")
                ]);
        });
}
