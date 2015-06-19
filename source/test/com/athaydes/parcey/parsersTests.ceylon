import ceylon.language.meta {
    typeLiteral
}
import ceylon.language.meta.model {
    Type
}
import ceylon.test {
    test,
    assertEquals,
    assertTrue
}

import com.athaydes.parcey {
    anyChar,
    ParseSuccess,
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
    integer,
    CharacterConsumer,
    satisfy
}
import com.athaydes.parcey.combinator {
    ...
}

import test.com.athaydes.parcey.combinator {
    expect
}

shared Type<ParseError> error = typeLiteral<ParseError>();

test
shared void testEof() {
    expect(eof().parse(""), void(ParseSuccess<[]> result) {
            assertEquals(result.result.sequence(), []);
        });
    
    expect(eof().parse("a"), error);
}

test
shared void testAnyChar() {
    expect(anyChar().parse("a"), void(ParseSuccess<{Character*}> result) {
            assertEquals(result.result.sequence(), ['a']);
        });
    expect(anyChar().parse("xyz"), void(ParseSuccess<{Character*}> result) {
            assertEquals(result.result.sequence(), ['x']);
        });
    
    expect(anyChar().parse(""), error);
}

test
shared void testChars() {
    value parser = chars { 'a', 'b', 'c' };
    
    expect(parser.parse('a'..'z'), void(ParseSuccess<{Character+}> result) {
            assertEquals(result.result.sequence(), ['a', 'b', 'c']);
        });
    
    expect(parser.parse("abxy"), error);
}

test
shared void testLetter() {
    for (item in ('a'..'z').append('A'..'Z')) {
        expect(letter().parse({ item }), void(ParseSuccess<{Character*}> result) {
                assertEquals(result.result.sequence(), [item]);
            });
    }
    for (item in ['\t', ' ', '?', '!', '%', '^', '&', '*']) {
        expect(letter().parse({ item }), error);
    }
}

test
shared void testSatisfy() {
    value parser = seq { str("1"), satisfy((Character c) => c.letter) };
    
    expect(parser.parse("1a"), void(ParseSuccess<{Anything*}> result) {
        assertEquals(result.result.sequence(), ["1", 'a']);
    });
    expect(parser.parse("1Z"), void(ParseSuccess<{Anything*}> result) {
        assertEquals(result.result.sequence(), ["1", 'Z']);
    });
    expect(parser.parse("1ä"), void(ParseSuccess<{Anything*}> result) {
        assertEquals(result.result.sequence(), ["1", 'ä']);
    });
    expect(parser.parse("11"), error);
    expect(parser.parse("1@"), error);
}

test
shared void testSpace() {
    expect(space().parse(""), error);
    
    for (item in spaceChars) {
        expect(space().parse({ item }), void(ParseSuccess<{Character*}> result) {
                assertEquals(result.result.sequence(), [item]);
            });
    }
    
    expect(space().parse("xy"), error);
}

test
shared void testAnyString() {
    expect(anyStr().parse(""), void(ParseSuccess<{String*}> result1) {
            assertEquals(result1.result.sequence(), [""]);
        });
    
    expect(anyStr().parse("a"), void(ParseSuccess<{String*}> result2) {
            assertEquals(result2.result.sequence(), ["a"]);
        });
    
    expect(anyStr().parse("xyz abc"), void(ParseSuccess<{String*}> result3) {
            assertEquals(result3.result.sequence(), ["xyz"]);
        });
}

test
shared void testWord() {
    expect(word().parse(""), error);
    
    expect(word().parse("a"), void(ParseSuccess<{String*}> result2) {
            assertEquals(result2.result.sequence(), ["a"]);
        });
    
    expect(word().parse("xyz abc"), void(ParseSuccess<{String*}> result3) {
            assertEquals(result3.result.sequence(), ["xyz"]);
        });
    
    expect(word().parse("abcd123"), void(ParseSuccess<{String*}> result4) {
            assertEquals(result4.result.sequence(), ["abcd"]);
        });
}

test
shared void testStr() {
    expect(str("").parse(""), void(ParseSuccess<{String+}> result1) {
            assertEquals(result1.result.sequence(), [""]);
        });
    
    expect(str("a").parse("a"), void(ParseSuccess<{String+}> result2) {
            assertEquals(result2.result.sequence(), ["a"]);
        });
    
    expect(str("xyz").parse("xyz abc"), void(ParseSuccess<{String+}> result3) {
            assertEquals(result3.result.sequence(), ["xyz"]);
        });
    
    expect(str("xyz").parse("xyab"), error);
    
    expect(str("xyz").parse("abcxyz"), error);
    
    expect(str("ab").parse(""), error);
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
    expect(str("xyz").doParse(CharacterConsumer(iterator)),
        void(ParseSuccess<{String+}> result) {
            assertEquals(result.result.sequence(), ["xyz"]);
        });
}

test
shared void testOneOf() {
    value parser = oneOf({ 'x', 'a' });
    
    expect(parser.parse(""), error);
    
    for (item in ['x', 'a']) {
        expect(parser.parse({ item }), void(ParseSuccess<{Character*}> result) {
                assertEquals(result.result.sequence(), [item]);
            });
    }
    for (item in ('A'..'Z').append(['\t', ' ', '?', '!', '%', '^', '&', '*'])) {
        expect(parser.parse({ item }), error);
    }
}

test
shared void testNoneOf() {
    value parser = noneOf({ 'x', 'a' });
    
    expect(parser.parse(""), error);
    
    for (item in ['x', 'a']) {
        expect(parser.parse({ item }), error);
    }
    for (item in ('A'..'Z').append(['\t', ' ', '?', '!', '%', '^', '&', '*'])) {
        expect(parser.parse({ item }), void(ParseSuccess<{Character*}> result) {
                assertEquals(result.result.sequence(), [item]);
            });
    }
}

test
shared void testDigit() {
    for (input in (0..9).map(Object.string)) {
        expect(digit().parse(input), void(ParseSuccess<{Character*}> result) {
                assertEquals(result.result.sequence(), input.sequence());
            });
    }
    
    for (input in ["a", "b", "z", "#", "%", "~", "@", "hello", "#0", "!22"]) {
        expect(digit().parse(input), error);
    }
    
    expect(digit().parse(""), error);
}

test
shared void testInteger() {
    expect(integer().parse(""), typeLiteral<ParseError>());
    for (input in (0..9).map(Object.string)) {
        expect(integer().parse(input), void(ParseSuccess<{Integer*}> result) {
                assertEquals(result.result.sequence(), [parseInteger(input)]);
            });
    }
    for (input in (-1 .. -9).map(Object.string)) {
        expect(integer().parse(input), void(ParseSuccess<{Integer*}> result) {
                assertEquals(result.result.sequence(), [parseInteger(input)]);
            });
    }
    expect(integer().parse("9876543210"), void(ParseSuccess<{Integer*}> result) {
            assertEquals(result.result.sequence(), [9876543210]);
        });
    expect(integer().parse(runtime.maxIntegerValue.string),
        typeLiteral<ParseSuccess<{Integer*}>>());
    expect(integer().parse(runtime.minIntegerValue.string),
        typeLiteral<ParseSuccess<{Integer*}>>());
    expect(integer().parse("000450abcd"),
        void(ParseSuccess<{Integer*}> result) {
            assertEquals(result.result.sequence(), [450]);
        });
    expect(integer().parse(['9'].cycled.take(100)),
        void(ParseError error) {
            value location = error.location;
            assertTrue(location.last < 25,
                "Parsed too many digits before overflowing: ``location``");
        });
}

test
shared void canBacktrackAcrossManyParsers() {
    value parser = seq {
        option(seq { skip(char('.')), strParser(many(digit(), 1)) }),
        str(".x")
    };
    
    expect(parser.parse(".x"), void(ParseSuccess<{String*}> result) {
        assertEquals(result.result.sequence(), [".x"]);
    });
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
        expect(identifier.parse(input), void(ParseSuccess<{Character*}> result) {
                assertEquals(result.result.sequence(), input.sequence());
            });
    }
    
    for (input in ["", " ", "1", "@"]) {
        expect(identifier.parse(input), error);
    }
    
    expect(identifier.parse("_abc "), void(ParseSuccess<{Character*}> result1) {
            assertEquals(result1.result.sequence(), ['_', 'a', 'b', 'c']);
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
        void(ParseSuccess<{CeylonElement*}> result) {
            assertEquals(result.result.sequence(), [
                    Type("String"), Identifier("hi"),
                    Type("Boolean"), Identifier("b"),
                    Type("Integer"), Identifier("i")
                ]);
        });
}
