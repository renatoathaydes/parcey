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
    anyCharacter,
    ParseSuccess,
    letter,
    ParseError,
    oneOf,
    noneOf,
    endOfInput,
    space,
    spaceChars,
    anyString,
    text,
    character,
    digit,
    word,
    spaces,
    characters,
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
    expect(endOfInput().parse("")).assignableTo(`ParseSuccess<[]>`).with((result) {
        assertEquals(result.result.sequence(), []);
    });
    
    expect(endOfInput().parse("a")).assignableTo(error);
}

test
shared void testAnyChar() {
    expect(anyCharacter().parse("a")).assignableTo(`ParseSuccess<{Character*}>`).with((result) {
        assertEquals(result.result.sequence(), ['a']);
    });
    expect(anyCharacter().parse("xyz")).assignableTo(`ParseSuccess<{Character*}>`).with((result) {
        assertEquals(result.result.sequence(), ['x']);
    });
    
    expect(anyCharacter().parse("")).assignableTo(error);
}

test
shared void testChars() {
    value parser = characters { 'a', 'b', 'c' };
    
    expect(parser.parse('a'..'z')).assignableTo(`ParseSuccess<{Character+}>`).with((result) {
        assertEquals(result.result.sequence(), ['a', 'b', 'c']);
    });
    
    expect(parser.parse("abxy")).assignableTo(error);
}

test
shared void testLetter() {
    for (item in ('a'..'z').append('A'..'Z')) {
        expect(letter().parse({ item })).assignableTo(`ParseSuccess<{Character*}>`).with((result) {
                assertEquals(result.result.sequence(), [item]);
            });
    }
    for (item in ['\t', ' ', '?', '!', '%', '^', '&', '*']) {
        expect(letter().parse({ item })).assignableTo(error);
    }
}

test
shared void testSatisfy() {
    value parser = sequenceOf { text("1"), satisfy((Character c) => c.letter) };
    
    expect(parser.parse("1a")).assignableTo(`ParseSuccess<{Anything*}>`).with((result) {
        assertEquals(result.result.sequence(), ["1", 'a']);
    });
    expect(parser.parse("1Z")).assignableTo(`ParseSuccess<{Anything*}>`).with((result) {
        assertEquals(result.result.sequence(), ["1", 'Z']);
    });
    expect(parser.parse("1ä")).assignableTo(`ParseSuccess<{Anything*}>`).with((result) {
        assertEquals(result.result.sequence(), ["1", 'ä']);
    });
    expect(parser.parse("11")).assignableTo(error);
    expect(parser.parse("1@")).assignableTo(error);
}

test
shared void testSpace() {
    expect(space().parse("")).assignableTo(error);
    
    for (item in spaceChars) {
        expect(space().parse({ item })).assignableTo(`ParseSuccess<{Character*}>`).with((result) {
                assertEquals(result.result.sequence(), [item]);
            });
    }
    
    expect(space().parse("xy")).assignableTo(error);
}

test
shared void testAnyString() {
    expect(anyString().parse("")).assignableTo(`ParseSuccess<{String*}>`).with((result1) {
            assertEquals(result1.result.sequence(), [""]);
        });
    
    expect(anyString().parse("a")).assignableTo(`ParseSuccess<{String*}>`).with((result2) {
            assertEquals(result2.result.sequence(), ["a"]);
        });
    
    expect(anyString().parse("xyz abc")).assignableTo(`ParseSuccess<{String*}>`).with((result3) {
            assertEquals(result3.result.sequence(), ["xyz"]);
        });
}

test
shared void testWord() {
    expect(word().parse("")).assignableTo(error);
    
    expect(word().parse("a")).assignableTo(`ParseSuccess<{String*}>`).with((result2) {
            assertEquals(result2.result.sequence(), ["a"]);
        });
    
    expect(word().parse("xyz abc")).assignableTo(`ParseSuccess<{String*}>`).with((result3) {
            assertEquals(result3.result.sequence(), ["xyz"]);
        });
    
    expect(word().parse("abcd123")).assignableTo(`ParseSuccess<{String*}>`).with((result4) {
            assertEquals(result4.result.sequence(), ["abcd"]);
        });
}

test
shared void testStr() {
    expect(text("").parse("")).assignableTo(`ParseSuccess<{String+}>`).with((result1) {
            assertEquals(result1.result.sequence(), [""]);
        });
    
    expect(text("a").parse("a")).assignableTo(`ParseSuccess<{String+}>`).with((result2) {
            assertEquals(result2.result.sequence(), ["a"]);
        });
    
    expect(text("xyz").parse("xyz abc")).assignableTo(`ParseSuccess<{String+}>`).with((result3) {
            assertEquals(result3.result.sequence(), ["xyz"]);
        });
    
    expect(text("").parse("abc")).assignableTo(`ParseSuccess<{String+}>`).with((result) {
            assertEquals(result.result.sequence(), [""]);
        });
    
    expect(text("xyz").parse("xyab")).assignableTo(error);
    
    expect(text("xyz").parse("abcxyz")).assignableTo(error);
    
    expect(text("ab").parse("")).assignableTo(error);
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
    expect(text("xyz").doParse(CharacterConsumer(iterator)))
    	.assignableTo(`ParseSuccess<{String+}>`).with((result) {
            assertEquals(result.result.sequence(), ["xyz"]);
        });
}

test
shared void testOneOf() {
    value parser = oneOf({ 'x', 'a' });
    
    expect(parser.parse("")).assignableTo(error);
    
    for (item in ['x', 'a']) {
        expect(parser.parse({ item })).assignableTo(`ParseSuccess<{Character*}>`).with((result) {
                assertEquals(result.result.sequence(), [item]);
            });
    }
    for (item in ('A'..'Z').append(['\t', ' ', '?', '!', '%', '^', '&', '*'])) {
        expect(parser.parse({ item })).assignableTo(error);
    }
}

test
shared void testNoneOf() {
    value parser = noneOf({ 'x', 'a' });
    
    expect(parser.parse("")).assignableTo(error);
    
    for (item in ['x', 'a']) {
        expect(parser.parse({ item })).assignableTo(error);
    }
    for (item in ('A'..'Z').append(['\t', ' ', '?', '!', '%', '^', '&', '*'])) {
        expect(parser.parse({ item })).assignableTo(`ParseSuccess<{Character*}>`).with((result) {
                assertEquals(result.result.sequence(), [item]);
            });
    }
}

test
shared void testDigit() {
    for (input in (0..9).map(Object.string)) {
        expect(digit().parse(input)).assignableTo(`ParseSuccess<{Character*}>`).with((result) {
                assertEquals(result.result.sequence(), input.sequence());
            });
    }
    
    for (input in ["a", "b", "z", "#", "%", "~", "@", "hello", "#0", "!22"]) {
        expect(digit().parse(input)).assignableTo(error);
    }
    
    expect(digit().parse("")).assignableTo(error);
}

test
shared void testInteger() {
    expect(integer().parse("")).assignableTo(error);
    
    for (input in (0..9).map(Object.string)) {
        expect(integer().parse(input)).assignableTo(`ParseSuccess<{Integer*}>`).with((result) {
                assertEquals(result.result.sequence(), [parseInteger(input)]);
            });
    }
    for (input in (-1 .. -9).map(Object.string)) {
        expect(integer().parse(input)).assignableTo(`ParseSuccess<{Integer*}>`).with((result) {
                assertEquals(result.result.sequence(), [parseInteger(input)]);
            });
    }
    expect(integer().parse("9876543210")).assignableTo(`ParseSuccess<{Integer*}>`).with((result) {
            assertEquals(result.result.sequence(), [9876543210]);
        });
    expect(integer().parse(runtime.maxIntegerValue.string))
    	.assignableTo(typeLiteral<ParseSuccess<{Integer*}>>());
    expect(integer().parse(runtime.minIntegerValue.string))
        .assignableTo(typeLiteral<ParseSuccess<{Integer*}>>());
    expect(integer().parse("000450abcd"))
        .assignableTo(`ParseSuccess<{Integer*}>`).with((result) {
            assertEquals(result.result.sequence(), [450]);
        });
    expect(integer().parse(['9'].cycled.take(100)))
    	.assignableTo(`ParseError`).with((error) {
            value location = error.location;
            assertTrue(location.last < 25,
                "Parsed too many digits before overflowing: ``location``");
        });
}

test
shared void canBacktrackAcrossManyParsers() {
    value parser = sequenceOf {
        option(sequenceOf { skip(character('.')), strParser(many(digit(), 1)) }),
        text(".x")
    };
    
    expect(parser.parse(".x")).assignableTo(`ParseSuccess<{String*}>`).with((result) {
        assertEquals(result.result.sequence(), [".x"]);
    });
}

test
shared void simpleCombinationTest() {
    value lowerCasedLetter = oneOf('a'..'z');
    value underscore = character('_');
    value identifier = sequenceOf({
            either { lowerCasedLetter, underscore },
            many(either { letter(), underscore })
        }, "identifier");
    
    for (input in ["a", "_", "_a", "___", "_x_y_z", "abc___", "__xx__"]) {
        expect(identifier.parse(input)).assignableTo(`ParseSuccess<{Character*}>`).with((result) {
                assertEquals(result.result.sequence(), input.sequence());
            });
    }
    
    for (input in ["", " ", "1", "@"]) {
        expect(identifier.parse(input)).assignableTo(error);
    }
    
    expect(identifier.parse("_abc ")).assignableTo(`ParseSuccess<{Character*}>`).with((result1) {
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
    value underscore = character('_');
    value identifierStr = strParser(sequenceOf({
                either { lowerCasedLetter, underscore },
                many(either { letter(), underscore })
            }, "identifier"));
    value identifier = mapParser(identifierStr, Identifier);
    value typeStr = strParser(sequenceOf({
                capitalLetter,
                many(either { letter(), underscore })
            }, "type identifier"));
    value typeIdentifier = mapParser(typeStr, Type);
    value modifier = identifier;
    value argument = sequenceOf({
            typeIdentifier,
            spaces(1),
            identifier
        }, "argument");
    value argumentList = sequenceOf({
            skip(character('(')),
            separatedBy(around(spaces(), character(',')), argument),
            skip(character(')'))
        }, "argument list");
    
    value ceylonFunctionSignature = sequenceOf {
        spaces(),
        many(sequenceOf { modifier, spaces(1) }),
        typeIdentifier,
        spaces(1),
        identifier,
        spaces(),
        argumentList
    };
    
    expect(ceylonFunctionSignature.parse(" String hi(Boolean b, Integer i) "))
        .assignableTo(`ParseSuccess<{CeylonElement*}>`).with((result) {
            assertEquals(result.result.sequence(), [
                    Type("String"), Identifier("hi"),
                    Type("Boolean"), Identifier("b"),
                    Type("Integer"), Identifier("i")
                ]);
        });
}

