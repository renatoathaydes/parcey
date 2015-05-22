import ceylon.test {
    test,
    assertEquals,
    fail,
    assertFalse
}

import com.athaydes.parcey {
    ParseResult,
    anyChar,
    ParseError,
    char,
    str,
    space,
    noneOf,
    spaceChars,
    integer,
    spaces,
    chars,
    digit,
    coalescedParser
}
import com.athaydes.parcey.combinator {
    either,
    seq,
    many,
    option,
    skip,
    sepBy,
    around,
    seq1
}
import ceylon.language.meta {
    typeLiteral
}

test
shared void canParseNonStableStream() {
    value parser = seq {
        anyChar(), char(' '), anyChar()
    };
    
    value result = parser.parse(object satisfies Iterable<Character> {
            value data = { 'a', ' ', 'b' }.iterator();
            iterator() => data;
        });
    
    if (is ParseResult<{Character*}> result) {
        assertEquals(result.result.sequence(), ['a', ' ', 'b']);
        assertEquals(result.parseLocation, [0, 3]);
    } else {
        fail("Result was ``result``");
    }
}

test shared void seq1FailsWithEmptyResult() {
    value parser = seq1 { coalescedParser(integer()) };
    
    expect(parser.parse(""), typeLiteral<ParseError>());
    expect(parser.parse("x"), typeLiteral<ParseError>());
}

test shared void seq1AllowsNonEmptyResult()  {
    value parser = seq1 { coalescedParser(integer()) };
    
    expect(parser.parse("33"), void(ParseResult<{Integer*}> result) {
        assertEquals(result.result.sequence(), [33]);
    });
}

test
shared void eitherCombinatorCanParseAllAlternatives() {
    value parser = either {
        char('a'), chars(['h', 'i']), space()
    };
    
    value result1 = parser.parse("a");
    if (is ParseResult<{Character*}> result1) {
        assertEquals(result1.result, ['a']);
        assertEquals(result1.parseLocation, [0, 1]);
    } else {
        fail("Result was ``result1``");
    }
    
    value result2 = parser.parse("hi");
    if (is ParseResult<{Character+}> result2) {
        assertEquals(result2.result.sequence(), ['h', 'i']);
        assertEquals(result2.parseLocation, [0, 2]);
    } else {
        fail("Result was ``result2``");
    }
    
    value result3 = parser.parse(" ");
    if (is ParseResult<{Character*}> result3) {
        assertEquals(result3.result, [' ']);
        assertEquals(result3.parseLocation, [0, 1]);
    } else {
        fail("Result was ``result3``");
    }
}

test
shared void eitherCombinatorCanBacktrackOnce() {
    value parser = either {
        char('a'), char('b')
    };
    
    value result = parser.parse("b");
    
    if (is ParseResult<{Character*}> result) {
        assertEquals(result.result.sequence(), ['b']);
        assertEquals(result.parseLocation, [0, 1]);
    } else {
        fail("Result was ``result``");
    }
}

test
shared void eitherCombinatorCanBacktrackTwice() {
    value parser = either {
        char('a'), char('b'), char('c')
    };
    
    value result = parser.parse("c");
    
    if (is ParseResult<{Character*}> result) {
        assertEquals(result.result.sequence(), ['c']);
        assertEquals(result.parseLocation, [0, 1]);
    } else {
        fail("Result was ``result``");
    }
}

test
shared void eitherCombinatorCanBacktrackThrice() {
    value parser = either {
        str("abcd"), str("abcef"), str("abceg")
    };
    
    value result = parser.parse("abcegh");
    
    if (is ParseResult<{String+}> result) {
        assertEquals(result.result.sequence(), ["abceg"]);
        assertEquals(result.parseLocation, [0, 5]);
        assertEquals(result.overConsumed.sequence(), []);
    } else {
        fail("Result was ``result``");
    }
}

test
shared void eitherCombinatorDoesNotConsumeNextToken() {
    value parser = either { str("ab"), str("ac") };
    
    value result = parser.parse("ade");
    
    if (is ParseError result) {
        assertEquals(result.consumed.sequence(), ['a', 'd']);
        assertFalse(result.message().empty);
    } else {
        fail("Result was ``result``");
    }
}

test
shared void manyCombinatorSimpleTest() {
    value result = many(char('a')).parse("aaa");
    
    if (is ParseResult<{Character*}> result) {
        assertEquals(result.result.sequence(), ['a', 'a', 'a']);
        assertEquals(result.parseLocation, [0, 3]);
        assertEquals(result.consumed.sequence(), ['a', 'a', 'a']);
        assertEquals(result.overConsumed.sequence(), []);
    } else {
        fail("Result was ``result``");
    }
}

test
shared void manyCombinatorEmptyInputTest() {
    value result = many(char('a')).parse("b");
    
    if (is ParseResult<{Character*}> result) {
        assertEquals(result.result.sequence(), []);
        assertEquals(result.parseLocation, [0, 0]);
        assertEquals(result.consumed.sequence(), []);
        assertEquals(result.overConsumed.sequence(), ['b']);
    } else {
        fail("Result was ``result``");
    }
}

test
shared void manyCombinatorDoesNotConsumeNextToken() {
    value result = many(char('a')).parse("aab");
    
    if (is ParseResult<{Character*}> result) {
        assertEquals(result.result.sequence(), ['a', 'a']);
        assertEquals(result.parseLocation, [0, 2]);
        assertEquals(result.consumed.sequence(), ['a', 'a']);
        assertEquals(result.overConsumed.sequence(), ['b']);
    } else {
        fail("Result was ``result``");
    }
}

test
shared void manyCombinatorDoesNotConsumeNextTokenUsingMultiCharacterConsumer() {
    value result = many(str("abc")).parse("abcabcabcdef");
    
    if (is ParseResult<{String*}> result) {
        assertEquals(result.result.sequence(), ["abc", "abc", "abc"]);
        assertEquals(result.parseLocation, [0, 9]);
        assertEquals(result.consumed.sequence(), ['a', 'b', 'c', 'a', 'b', 'c', 'a', 'b', 'c']);
        assertEquals(result.overConsumed.sequence(), ['d']);
    } else {
        fail("Result was ``result``");
    }
}

test
shared void many1CombinatorSimpleTest() {
    value result = many(char('a'), 1).parse("aaa");
    
    if (is ParseResult<{Character*}> result) {
        assertEquals(result.result.sequence(), ['a', 'a', 'a']);
        assertEquals(result.parseLocation, [0, 3]);
        assertEquals(result.consumed.sequence(), ['a', 'a', 'a']);
        assertEquals(result.overConsumed.sequence(), []);
    } else {
        fail("Result was ``result``");
    }
}

test
shared void many1CombinatorTooShortInputTest() {
    value result = many(char('a'), 1).parse("b");
    
    if (is ParseError result) {
        assertEquals(result.consumed.sequence(), ['b']);
        assertFalse(result.message().empty);
    } else {
        fail("Result was ``result``");
    }
}

test
shared void many1CombinatorDoesNotConsumeNextToken() {
    value result = seq { many(char('a'), 1), char('b') }
            .parse("aab");
    
    if (is ParseResult<{Character*}> result) {
        assertEquals(result.result.sequence(), ['a', 'a', 'b']);
        assertEquals(result.parseLocation, [0, 3]);
        assertEquals(result.consumed.sequence(), ['a', 'a', 'b']);
        assertEquals(result.overConsumed.sequence(), []);
    } else {
        fail("Result was ``result``");
    }
}

test
shared void many3CombinatorTooShortInputTest() {
    value result = many(char('a'), 3).parse("aab");
    
    if (is ParseError result) {
        assertEquals(result.consumed.sequence(), ['a', 'a', 'b']);
        assertFalse(result.message().empty);
    } else {
        fail("Result was ``result``");
    }
}

test
shared void many3CombinatorDoesNotConsumeNextToken() {
    value result = seq({
        many(char('a'), 3), char('b')
    }).parse("aaaab");
    
    if (is ParseResult<{Character*}> result) {
        assertEquals(result.result.sequence(), ['a', 'a', 'a', 'a', 'b']);
        assertEquals(result.parseLocation, [0, 5]);
        assertEquals(result.consumed.sequence(), ['a', 'a', 'a', 'a', 'b']);
        assertEquals(result.overConsumed.sequence(), []);
    } else {
        fail("Result was ``result``");
    }
}

test
shared void manySeqCombinationTest() {
    value manySeq = many(seq { char('x'), skip(char(',')) });
    
    value result1 = manySeq.parse("x,x,x!");
    if (is ParseResult<{Character*}> result1) {
        assertEquals(result1.result.sequence(), ['x', 'x']);
        assertEquals(result1.parseLocation, [0, 4]);
        assertEquals(result1.consumed.sequence(), ['x', ',', 'x', ',']);
        assertEquals(result1.overConsumed.sequence(), ['x', '!']);
    } else {
        fail("Result was ``result1``");
    }
}

test
shared void manySeqManyCombinationTest() {
    value parser = many(seq { skip(char('.')), many(char('x')) });
    
    value result1 = parser.parse(".x.xxx..x!x");
    if (is ParseResult<{Character*}> result1) {
        assertEquals(result1.result.sequence(), ['x', 'x', 'x', 'x', 'x']);
        assertEquals(result1.parseLocation, [0, 9]);
        assertEquals(result1.consumed.sequence(), ['.', 'x', '.', 'x', 'x', 'x', '.', '.', 'x']);
        assertEquals(result1.overConsumed.sequence(), ['!']);
    } else {
        fail("Result was ``result1``");
    }
}
test
shared void skipManyCombinatorDoesNotConsumeNextTokenUsingMultiCharacterConsumer() {
    value result = skip(many(str("abc"))).parse("abcabcabcdef");
    
    if (is ParseResult<{Character*}> result) {
        assertEquals(result.result.sequence(), []);
        assertEquals(result.parseLocation, [0, 9]);
        assertEquals(result.consumed.sequence(), ['a', 'b', 'c', 'a', 'b', 'c', 'a', 'b', 'c']);
        assertEquals(result.overConsumed.sequence(), ['d']);
    } else {
        fail("Result was ``result``");
    }
}

test
shared void skipManyCombinatorSimpleTest() {
    value result = skip(many(char('a'))).parse("aaa");
    
    if (is ParseResult<[]> result) {
        assertEquals(result.result, []);
        assertEquals(result.parseLocation, [0, 3]);
        assertEquals(result.consumed.sequence(), ['a', 'a', 'a']);
        assertEquals(result.overConsumed.sequence(), []);
    } else {
        fail("Result was ``result``");
    }
}

test
shared void skipManyCombinatorEmptyInputTest() {
    value result = skip(many(char('a'))).parse("b");
    
    if (is ParseResult<[]> result) {
        assertEquals(result.result, []);
        assertEquals(result.parseLocation, [0, 0]);
        assertEquals(result.consumed.sequence(), []);
        assertEquals(result.overConsumed.sequence(), ['b']);
    } else {
        fail("Result was ``result``");
    }
}

test
shared void skipManyCombinatorDoesNotConsumeNextToken() {
    value result1 = skip(many(char('a'))).parse("axy");
    if (is ParseResult<[]> result1) {
        assertEquals(result1.result.sequence(), []);
        assertEquals(result1.parseLocation, [0, 1]);
        assertEquals(result1.consumed.sequence(), ['a']);
        assertEquals(result1.overConsumed.sequence(), ['x']);
    } else {
        fail("Result was ``result1``");
    }
    
    value result = seq({skip(many(char('a'))), char('b')})
            .parse("aab");
    if (is ParseResult<{Character*}> result) {
        assertEquals(result.result, ['b']);
        assertEquals(result.parseLocation, [0, 3]);
        assertEquals(result.consumed.sequence(), ['a', 'a', 'b']);
        assertEquals(result.overConsumed.sequence(), []);
    } else {
        fail("Result was ``result``");
    }
}

test
shared void skipMany1CombinatorSimpleTest() {
    value result = skip(many(char('a'), 1)).parse("aaa");
    
    if (is ParseResult<{Character*}> result) {
        assertEquals(result.result.sequence(), []);
        assertEquals(result.parseLocation, [0, 3]);
        assertEquals(result.consumed.sequence(), ['a', 'a', 'a']);
        assertEquals(result.overConsumed.sequence(), []);
    } else {
        fail("Result was ``result``");
    }
}

test
shared void skipmany1CombinatorTooShortInputTest() {
    value result = skip(many(char('a'), 1)).parse("b");
    
    if (is ParseError result) {
        assertEquals(result.consumed.sequence(), ['b']);
        assertFalse(result.message().empty);
    } else {
        fail("Result was ``result``");
    }
}

test
shared void skipMany1CombinatorDoesNotConsumeNextToken() {
    value result = seq {
        skip(many(char('a'), 1)), char('b')
    }.parse("aab");
    
    if (is ParseResult<{Character*}> result) {
        assertEquals(result.result.sequence(), ['b']);
        assertEquals(result.parseLocation, [0, 3]);
        assertEquals(result.consumed.sequence(), ['a', 'a', 'b']);
        assertEquals(result.overConsumed.sequence(), []);
    } else {
        fail("Result was ``result``");
    }
}

test
shared void skipMany3CombinatorTooShortInputTest() {
    value result = skip(many(char('a'), 3)).parse("aab");
    
    if (is ParseError result) {
        assertEquals(result.consumed.sequence(), ['a', 'a', 'b']);
        assertFalse(result.message().empty);
    } else {
        fail("Result was ``result``");
    }
}

test
shared void skipMany3CombinatorDoesNotConsumeNextToken() {
    value result = seq {
        skip(many(char('a'), 3)), char('b')
    }.parse("aaaab");
    
    if (is ParseResult<{Character*}> result) {
        assertEquals(result.result.sequence(), ['b']);
        assertEquals(result.parseLocation, [0, 5]);
        assertEquals(result.consumed.sequence(), ['a', 'a', 'a', 'a', 'b']);
        assertEquals(result.overConsumed.sequence(), []);
    } else {
        fail("Result was ``result``");
    }
}

test shared void optionSimpleTest() {
    value parser = option(char('a'));
    
    value result1 = parser.parse("");
    if (is ParseResult<{Character*}> result1) {
        assertEquals(result1.result, []);
        assertEquals(result1.parseLocation, [0, 0]);
        assertEquals(result1.consumed.sequence(), []);
        assertEquals(result1.overConsumed.sequence(), []);
    } else {
        fail("Result was ```result1``");
    }
    
    value result2 = parser.parse("a");
    if (is ParseResult<{Character*}> result2) {
        assertEquals(result2.result, ['a']);
        assertEquals(result2.parseLocation, [0, 1]);
        assertEquals(result2.consumed.sequence(), ['a']);
        assertEquals(result2.overConsumed.sequence(), []);
    } else {
        fail("Result was ```result2``");
    }
    
    value result3 = parser.parse("b");
    if (is ParseResult<{Character*}> result3) {
        assertEquals(result3.result, []);
        assertEquals(result3.parseLocation, [0, 0]);
        assertEquals(result3.consumed.sequence(), []);
        assertEquals(result3.overConsumed.sequence(), ['b']);
    } else {
        fail("Result was ```result3``");
    }
}

test shared void aroundTest() {
    value parser = around(spaces(), char('c'));
    expect(parser.parse("c"), void(ParseResult<{Character*}> result) {
        assertEquals(result.result.sequence(), ['c']);
        assertEquals(result.parseLocation, [0, 1]);
        assertEquals(result.consumed.sequence(), ['c']);
        assertEquals(result.overConsumed.sequence(), []);
    });
    expect(parser.parse("  c   !!"), void(ParseResult<{Character*}> result) {
        assertEquals(result.result.sequence(), ['c']);
        assertEquals(result.parseLocation, [0, 6]);
        assertEquals(result.consumed.sequence(), [' ', ' ', 'c', ' ', ' ', ' ' ]);
        assertEquals(result.overConsumed.sequence(), ['!']);
    });
}

test shared void optionMultivalueTest() {
    value parser = option(seq { str("hej"), str("bye") });
    
    value result1 = parser.parse("hejdå");
    if (is ParseResult<{String*}> result1) {
        assertEquals(result1.result.sequence(), []);
        assertEquals(result1.parseLocation, [0, 0]);
        assertEquals(result1.consumed.sequence(), []);
        assertEquals(result1.overConsumed.sequence(), ['h', 'e', 'j', 'd']);
    } else {
        fail("Result was ```result1``");
    }
    
    value result2 = parser.parse("hejbye");
    if (is ParseResult<{String*}> result2) {
        assertEquals(result2.result.sequence(), ["hej", "bye"]);
        assertEquals(result2.parseLocation, [0, 6]);
        assertEquals(result2.consumed.sequence(), ['h', 'e', 'j', 'b', 'y', 'e']);
        assertEquals(result2.overConsumed.sequence(), []);
    } else {
        fail("Result was ```result2``");
    }
    
    value result3 = parser.parse("hell");
    if (is ParseResult<{String*}> result3) {
        assertEquals(result3.result.sequence(), []);
        assertEquals(result3.parseLocation, [0, 0]);
        assertEquals(result3.consumed.sequence(), []);
        assertEquals(result3.overConsumed.sequence(), ['h', 'e', 'l']);
    } else {
        fail("Result was ```result3``");
    }
}

test
shared void parserChainSimpleTest() {
    for (index->singleParser in [char('a'), many(noneOf(spaceChars)), space()].indexed) {
        for (input in ["", "0", "\n", " ", "a", "abc", "123", " xxx yyy"]) {
            value result1 = singleParser.parse(input);
            value result2 = seq({singleParser}).parse(input);
            value errorMessage = "Parser index: ``index``, Input: ``input``";
            assertResultsEqual(result1, result2, errorMessage);
            assertParseLocationsEqual(result1, result2, errorMessage);
        }
    }
}

test
shared void parserChain2ParsersTest() {
    for (index->parserPair in [[char('a'), char(' ')], [many(noneOf(spaceChars)), char(' ')], [space(), chars(['x', 'x', 'm'])]].indexed) {
        for (input in ["", "0", "\n", " ", "a", "a b c", "123", " abc", " xxx yyy"]) {
            value result1 = parserPair[0].parse(input);
            value nonParsed = input.sublistFrom(result1.consumed.size);
            value x = String(nonParsed);
            value result2 = parserPair[1].parse(x);
            value totalResult = seq(parserPair).parse(input);
            value expectedResult = findExpectedResult(result1, result2);
            value errorMessage = "Parser index: ``index``, Input: '``input``'";
            assertResultsEqual(totalResult, expectedResult, errorMessage);
        }
    }
}

test
shared void parserChainParsedLocationColumnTest() {
    value parser = seq {
        char('a'), char('b'), either { char('c'), char('d') }, str("xyz")
    };
    
    for ([input, expected] in [["a", [1, 1]], ["abx", [1, 3]], ["abcd", [1, 4]], ["abcxym", [1, 6]]]) {
        value result = parser.parse(input);
        if (is ParseError result) {
            assertEquals(extractLocation(result.message()), expected, result.message());
        } else {
            fail("Result for input ``input`` was ``result``");
        }    
    }
}

test
shared void parserChainParsedLocationRowTest() {
    value parser = seq {
        sepBy(spaces(), seq { str("hello"), digit() }, 4)
    };
    
    for ([input, expected] in [["hello1\nhello2\nhellow", [3, 6]], ["hello2\nbye", [2, 1]]]) {
        value result = parser.parse(input);
        if (is ParseError result) {
            assertEquals(extractLocation(result.message()), expected, result.message());
        } else {
            fail("Result for input ``input`` was ``result``");
        }    
    }
}

test
shared void sepByTest() {
    value commaSeparated = sepBy(char(','), integer());
    
    value result1 = commaSeparated.parse("");
    if (is ParseResult<{Integer*}> result1) {
        assertEquals(result1.result.sequence(), []);
    } else {
        fail("Result was ``result1``");
    }
    
    value result2 = commaSeparated.parse("1,2,");
    if (is ParseResult<{Integer*}> result2) {
        assertEquals(result2.result.sequence(), [1, 2]);
        assertEquals(result2.consumed.sequence(), ['1', ',', '2']);
        assertEquals(result2.overConsumed.sequence(), [',']);
    } else {
        fail("Result was ``result2``");
    }
    
    value result3 = commaSeparated.parse("1");
    if (is ParseResult<{Integer*}> result3) {
        assertEquals(result3.result.sequence(), [1]);
    } else {
        fail("Result was ``result3``");
    }
    
    value result4 = commaSeparated.parse("1,2,3,4,5");
    if (is ParseResult<{Integer*}> result4) {
        assertEquals(result4.result.sequence(), [1, 2, 3, 4, 5]);
    } else {
        fail("Result was ``result4``");
    }
}

test
shared void sepByMin3Test() {
    value commaSeparated = sepBy(char(','), integer(), 3);
    
    value result1 = commaSeparated.parse("100,200,53");
    if (is ParseResult<{Integer*}> result1) {
        assertEquals(result1.result.sequence(), [100, 200, 53]);
    } else {
        fail("Result was ``result1``");
    }
    
    value result2 = commaSeparated.parse("1,2,3,4,5");
    if (is ParseResult<{Integer*}> result2) {
        assertEquals(result2.result.sequence(), [1, 2, 3, 4, 5]);
    } else {
        fail("Result was ``result2``");
    }
    value result3 = commaSeparated.parse("1");
    if (is ParseError result3) {
        assertFalse(result3.message().empty);
    } else {
        fail("Result was ``result3``");
    }
    value result4 = commaSeparated.parse("1,2");
    if (is ParseError result4) {
        assertFalse(result4.message().empty);
    } else {
        fail("Result was ``result4``");
    }
}

test
shared void sepByWithComplexCombinationTest() {
    value args = seq {
        skip(char('(')),
        sepBy(around(spaces(), char(',')),
            either { str("shared"), str("actual") }),
        skip(char(')'))
    };
    
    value result1 = args.parse("()");
    if (is ParseResult<{String*}> result1) {
        assertEquals(result1.result.sequence(), []);
    } else {
        fail("Result was ``result1``");
    }
    
    value result2 = args.parse("(shared)");
    if (is ParseResult<{String*}> result2) {
        assertEquals(result2.result.sequence(), ["shared"]);
    } else {
        fail("Result was ``result2``");
    }
    
    value result3 = args.parse("(shared, actual)");
    if (is ParseResult<{String*}> result3) {
        assertEquals(result3.result.sequence(), ["shared", "actual"]);
    } else {
        fail("Result was ``result3``");
    }
    
    value result4 = args.parse("(shared   ,    actual,shared)");
    if (is ParseResult<{String*}> result4) {
        assertEquals(result4.result.sequence(), ["shared", "actual", "shared"]);
    } else {
        fail("Result was ``result4``");
    }
}
