import ceylon.language.meta {
    typeLiteral
}
import ceylon.test {
    test,
    assertEquals,
    fail,
    assertTrue
}

import com.athaydes.parcey {
    ParseResult,
    anyChar,
    ParseError,
    char,
    str,
    space,
    integer,
    spaces,
    chars,
    digit,
    coalescedParser,
    word,
    eof,
    CharacterConsumer
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

import test.com.athaydes.parcey {
    error
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
    
    expect(parser.parse("a"), void(ParseResult<{Character*}> result1) {
        assertEquals(result1.result.sequence(), ['a']);
    });
    
    expect(parser.parse("hi"), void(ParseResult<{Character+}> result2) {
        assertEquals(result2.result.sequence(), ['h', 'i']);
    });
    
    expect(parser.parse(" "), void(ParseResult<{Character*}> result3) {
        assertEquals(result3.result.sequence(), [' ']);
    });
}

test
shared void eitherCombinatorCanBacktrackOnce() {
    value parser = either {
        char('a'), char('b')
    };
    
    value result = parser.parse("b");
    
    if (is ParseResult<{Character*}> result) {
        assertEquals(result.result.sequence(), ['b']);
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
    } else {
        fail("Result was ``result``");
    }
}

test
shared void eitherCombinatorDoesNotConsumeNextToken() {
    value parser = either { str("ab"), str("ac") };
    value iterator = "ade".iterator();
    expect(parser.doParse(CharacterConsumer(iterator)), typeLiteral<String>());
    
    assertEquals(iterator.next(), 'e');
}

test
shared void manyCombinatorSimpleTest() {
    expect(many(char('a')).parse("aaa"), void(ParseResult<{Character*}> result) {
        assertEquals(result.result.sequence(), ['a', 'a', 'a']);
    });
}

test
shared void manyCombinatorEmptyInputTest() {
    expect(many(char('a')).parse("b"), void(ParseResult<{Character*}> result) {
        assertEquals(result.result.sequence(), []);
    });
}

test
shared void manyCombinatorDoesNotConsumeNextToken() {
    expect(many(char('a')).parse("aab"), void(ParseResult<{Character*}> result) {
        assertEquals(result.result.sequence(), ['a', 'a']);
    });
}

test
shared void manyCombinatorDoesNotConsumeNextTokenUsingMultiCharacterConsumer() {
    expect(many(str("abc")).parse("abcabcabcdef"), void(ParseResult<{String*}> result) {
        assertEquals(result.result.sequence(), ["abc", "abc", "abc"]);
    });
}

test
shared void many1CombinatorSimpleTest() {
    expect(many(char('a'), 1).parse("aaa"), void(ParseResult<{Character*}> result) {
        assertEquals(result.result.sequence(), ['a', 'a', 'a']);
    });
}

test
shared void many1CombinatorTooShortInputTest() {
    expect(many(char('a'), 1).parse("b"), error);
}

test
shared void many1CombinatorDoesNotConsumeNextToken() {
    value consumer = CharacterConsumer("aab".iterator());
    expect(many(char('a'), 1)
            .doParse(consumer), void(ParseResult<{Character*}> result) {
        assertEquals(result.result.sequence(), ['a', 'a']);
    });
    assertEquals(consumer.next(), 'b');
}

test
shared void many3CombinatorTooShortInputTest() {
    expect(many(char('a'), 3).parse("aab"), error);
}

test
shared void many3CombinatorDoesNotConsumeNextToken() {
    expect(seq({
        many(char('a'), 3), char('b')
    }).parse("aaaab"), void(ParseResult<{Character*}> result) {
        assertEquals(result.result.sequence(), ['a', 'a', 'a', 'a', 'b']);
    });
}

test
shared void manySeqCombinationTest() {
    expect(many(seq { char('x'), skip(char(',')) }).parse("x,x,x!"),
        void(ParseResult<{Character*}> result1) {
        assertEquals(result1.result.sequence(), ['x', 'x']);
    });
}

test
shared void manySeqManyCombinationTest() {
    expect(many(seq { skip(char('.')), many(char('x')) })
        .parse(".x.xxx.x!x"), void(ParseResult<{Character*}> result1) {
        assertEquals(result1.result.sequence(), ['x', 'x', 'x', 'x', 'x']);
    });
}
test
shared void skipManyCombinatorDoesNotConsumeNextTokenUsingMultiCharacterConsumer() {
    expect(skip(many(str("abc"))).parse("abcabcabcdef"),
        void(ParseResult<{Character*}> result) {
        assertEquals(result.result.sequence(), []);
    });
}

test
shared void skipManyCombinatorSimpleTest() {
    value result = skip(many(char('a'))).parse("aaa");
    
    if (is ParseResult<[]> result) {
        assertEquals(result.result, []);
    } else {
        fail("Result was ``result``");
    }
}

test
shared void skipManyCombinatorEmptyInputTest() {
    value result = skip(many(char('a'))).parse("b");
    
    if (is ParseResult<[]> result) {
        assertEquals(result.result, []);
    } else {
        fail("Result was ``result``");
    }
}

test
shared void skipManyCombinatorDoesNotConsumeNextToken() {
    value result1 = skip(many(char('a'))).parse("axy");
    if (is ParseResult<[]> result1) {
        assertEquals(result1.result.sequence(), []);
    } else {
        fail("Result was ``result1``");
    }
    
    value result = seq({skip(many(char('a'))), char('b')})
            .parse("aab");
    if (is ParseResult<{Character*}> result) {
        assertEquals(result.result.sequence(), ['b']);
    } else {
        fail("Result was ``result``");
    }
}

test
shared void skipMany1CombinatorSimpleTest() {
    value result = skip(many(char('a'), 1)).parse("aaa");
    
    if (is ParseResult<{Character*}> result) {
        assertEquals(result.result.sequence(), []);
    } else {
        fail("Result was ``result``");
    }
}

test
shared void skipmany1CombinatorTooShortInputTest() {
    value result = skip(many(char('a'), 1)).parse("b");
    
    expect(result, error);
}

test
shared void skipMany1CombinatorDoesNotConsumeNextToken() {
    value result = seq {
        skip(many(char('a'), 1)), char('b')
    }.parse("aab");
    
    expect(result, void(ParseResult<{Character*}> result) {
        assertEquals(result.result.sequence(), ['b']);
    });
}

test
shared void skipMany3CombinatorTooShortInputTest() {
    value result = skip(many(char('a'), 3)).parse("aab");
    
    expect(result, error);
}

test
shared void skipMany3CombinatorDoesNotConsumeNextToken() {
    value result = seq {
        skip(many(char('a'), 3)), char('b')
    }.parse("aaaab");
    
    if (is ParseResult<{Character*}> result) {
        assertEquals(result.result.sequence(), ['b']);
    } else {
        fail("Result was ``result``");
    }
}

test shared void optionSimpleTest() {
    value parser = option(char('a'));
    
    value result1 = parser.parse("");
    if (is ParseResult<{Character*}> result1) {
        assertEquals(result1.result, []);
    } else {
        fail("Result was ```result1``");
    }
    
    value result2 = parser.parse("a");
    if (is ParseResult<{Character*}> result2) {
        assertEquals(result2.result.sequence(), ['a']);
    } else {
        fail("Result was ```result2``");
    }
    
    value result3 = parser.parse("b");
    if (is ParseResult<{Character*}> result3) {
        assertEquals(result3.result, []);
    } else {
        fail("Result was ```result3``");
    }
}

test shared void aroundTest() {
    value parser = around(spaces(), char('c'));
    expect(parser.parse("c"), void(ParseResult<{Character*}> result) {
        assertEquals(result.result.sequence(), ['c']);
    });
    expect(parser.parse("  c   !!"), void(ParseResult<{Character*}> result) {
        assertEquals(result.result.sequence(), ['c']);
    });
}

test shared void optionMultivalueTest() {
    value parser = option(seq { str("hej"), str("bye") });
    
    value result1 = parser.parse("hejdå");
    if (is ParseResult<{String*}> result1) {
        assertEquals(result1.result.sequence(), []);
    } else {
        fail("Result was ```result1``");
    }
    
    value result2 = parser.parse("hejbye");
    if (is ParseResult<{String*}> result2) {
        assertEquals(result2.result.sequence(), ["hej", "bye"]);
    } else {
        fail("Result was ```result2``");
    }
    
    value result3 = parser.parse("hell");
    if (is ParseResult<{String*}> result3) {
        assertEquals(result3.result.sequence(), []);
    } else {
        fail("Result was ```result3``");
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
    expect(result3, error);
    
    value result4 = commaSeparated.parse("1,2");
    expect(result4, error);
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

test shared void errorMessageShouldComeFromDeepestParserAttempted() {
    value parser = seq {
        char('#'), many(digit()), either {
            seq { char('.'), word() },
            seq { char('!'), many(digit(), 1) }
        }, eof()
    };
    // make sure valid input passes
    expect(parser.parse("#123.hi"), typeLiteral<ParseResult<Anything>>());
    expect(parser.parse("#1!23"), typeLiteral<ParseResult<Anything>>());
    
    // error message should show the exact unexpected input
    expect(parser.parse("#1.4"), void(ParseError error) {
        assertTrue(error.message.contains("Unexpected '4'"), error.string);
    });
    expect(parser.parse("abc"), void(ParseError error) {
        assertTrue(error.message.contains("Unexpected 'abc'"), error.string);
    });
    expect(parser.parse("#1!hi"), void(ParseError error) {
        assertTrue(error.message.contains("Unexpected 'hi'"), error.string);
    });
    expect(parser.parse("#1!012ABC"), void(ParseError error) {
        assertTrue(error.message.contains("Unexpected 'ABC'"), error.string);
    });
    expect(parser.parse("#Fghijk"), void(ParseError error) {
        assertTrue(error.message.contains("Unexpected 'Fghijk'"), error.string);
    });
}
