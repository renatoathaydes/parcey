import ceylon.test {
    test,
    assertEquals,
    fail,
    assertTrue
}

import com.athaydes.parcey {
    ParseSuccess,
    anyCharacter,
    ParseError,
    character,
    text,
    space,
    integer,
    spaces,
    characters,
    digit,
    coalescedParser,
    word,
    endOfInput,
    CharacterConsumer
}
import com.athaydes.parcey.combinator {
    either,
    sequenceOf,
    many,
    option,
    skip,
    separatedBy,
    around,
    between,
    nonEmptySequenceOf,
    optionDefault
}
import com.athaydes.specks {
    success
}
import com.athaydes.specks.assertion {
    expectThat=expect
}
import com.athaydes.specks.matcher {
    to,
    containSubsection
}

import test.com.athaydes.parcey {
    error
}

test
shared void canParseNonStableStream() {
    value parser = sequenceOf {
        anyCharacter(), character(' '), anyCharacter()
    };

    value result = parser.parse(object satisfies Iterable<Character> {
            value data = { 'a', ' ', 'b' }.iterator();
            iterator() => data;
        });

    if (is ParseSuccess<{Character*}> result) {
        assertEquals(result.result.sequence(), ['a', ' ', 'b']);
    } else {
        fail("Result was ``result``");
    }
}

test shared void seq1FailsWithEmptyResult() {
    value parser = nonEmptySequenceOf { coalescedParser(integer()) };

    expect(parser.parse("")).assignableTo(`ParseError`);
    expect(parser.parse("x")).assignableTo(`ParseError`);
}

test shared void seq1AllowsNonEmptyResult()  {
    value parser = nonEmptySequenceOf { coalescedParser(integer()) };

    expect(parser.parse("33")).assignableTo(`ParseSuccess<{Integer*}>`).with((result) {
        assertEquals(result.result.sequence(), [33]);
    });
}

test
shared void eitherCombinatorCanParseAllAlternatives() {
    value parser = either {
        character('a'), character('b'), characters(['h', 'i']), space()
    };

    expect(parser.parse("a")).assignableTo(`ParseSuccess<{Character*}>`).with((result1) {
        assertEquals(result1.result.sequence(), ['a']);
    });

    expect(parser.parse("b")).assignableTo(`ParseSuccess<{Character*}>`).with((result1) {
        assertEquals(result1.result.sequence(), ['b']);
    });

    expect(parser.parse("hi")).assignableTo(`ParseSuccess<{Character+}>`).with((result2) {
        assertEquals(result2.result.sequence(), ['h', 'i']);
    });

    expect(parser.parse(" ")).assignableTo(`ParseSuccess<{Character*}>`).with((result3) {
        assertEquals(result3.result.sequence(), [' ']);
    });
}

test
shared void eitherCombinatorCanBacktrackOnce() {
    value parser = either {
        character('a'), character('b')
    };

    value result = parser.parse("b");

    if (is ParseSuccess<{Character*}> result) {
        assertEquals(result.result.sequence(), ['b']);
    } else {
        fail("Result was ``result``");
    }
}

test
shared void eitherCombinatorCanBacktrackTwice() {
    value parser = either {
        character('a'), character('b'), character('c')
    };

    value result = parser.parse("c");

    if (is ParseSuccess<{Character*}> result) {
        assertEquals(result.result.sequence(), ['c']);
    } else {
        fail("Result was ``result``");
    }
}

test
shared void eitherCombinatorCanBacktrackThrice() {
    value parser = either {
        text("abcd"), text("abcef"), text("abceg")
    };

    value result = parser.parse("abcegh");

    if (is ParseSuccess<{String+}> result) {
        assertEquals(result.result.sequence(), ["abceg"]);
    } else {
        fail("Result was ``result``");
    }
}

test
shared void eitherCombinatorDoesNotConsumeNextToken() {
    value parser = either { text("ab"), text("ac") };
    value iterator = "ade".iterator();
    expect(parser.doParse(CharacterConsumer(iterator))).assignableTo(`String`);

    assertEquals(iterator.next(), 'e');
}

test
shared void eitherCombinatorProducesExpectedErrorMessage() {
    value parser = either {
        character('a'), character('b')
    };

    expect(parser.parse("c")).assignableTo(`ParseError`).with((error) {
        assertEquals(expectThat(error.message, to(containSubsection(*"Unexpected 'c'"))), success);
        assertEquals(error.location, [1, 1]);
    });
}

test
shared void manyCombinatorSimpleTest() {
    expect(many(character('a')).parse("aaa")).assignableTo(`ParseSuccess<{Character*}>`).with((result) {
        assertEquals(result.result.sequence(), ['a', 'a', 'a']);
    });
}

test
shared void manyCombinatorEmptyInputTest() {
    expect(many(character('a')).parse("b")).assignableTo(`ParseSuccess<{Character*}>`).with((result) {
        assertEquals(result.result.sequence(), []);
    });
}

test
shared void manyCombinatorDoesNotConsumeNextToken() {
    expect(many(character('a')).parse("aab")).assignableTo(`ParseSuccess<{Character*}>`).with((result) {
        assertEquals(result.result.sequence(), ['a', 'a']);
    });
}

test
shared void manyCombinatorDoesNotConsumeNextTokenUsingMultiCharacterConsumer() {
    expect(many(text("abc")).parse("abcabcabcdef")).assignableTo(`ParseSuccess<{String*}>`).with((result) {
        assertEquals(result.result.sequence(), ["abc", "abc", "abc"]);
    });
}

test
shared void many1CombinatorSimpleTest() {
    expect(many(character('a'), 1).parse("aaa")).assignableTo(`ParseSuccess<{Character*}>`).with((result) {
        assertEquals(result.result.sequence(), ['a', 'a', 'a']);
    });
}

test
shared void many1CombinatorTooShortInputTest() {
    expect(many(character('a'), 1).parse("b")).assignableTo(error);
}

test
shared void many1CombinatorDoesNotConsumeNextToken() {
    value consumer = CharacterConsumer("aab".iterator());
    expect(many(character('a'), 1)
            .doParse(consumer)).assignableTo(`ParseSuccess<{Character*}>`).with((result) {
        assertEquals(result.result.sequence(), ['a', 'a']);
    });
    assertEquals(consumer.next(), 'b');
}

test
shared void many3CombinatorTooShortInputTest() {
    expect(many(character('a'), 3).parse("aab")).assignableTo(error);
}

test
shared void many3CombinatorDoesNotConsumeNextToken() {
    expect(sequenceOf({
        many(character('a'), 3), character('b')
    }).parse("aaaab")).assignableTo(`ParseSuccess<{Character*}>`).with((result) {
        assertEquals(result.result.sequence(), ['a', 'a', 'a', 'a', 'b']);
    });
}

test
shared void manySeqCombinationTest() {
    expect(many(sequenceOf { character('x'), skip(character(',')) }).parse("x,x,x!"))
        .assignableTo(`ParseSuccess<{Character*}>`).with((result1) {
        assertEquals(result1.result.sequence(), ['x', 'x']);
    });
}

test
shared void manySeqManyCombinationTest() {
    expect(many(sequenceOf { skip(character('.')), many(character('x')) })
        .parse(".x.xxx.x!x")).assignableTo(`ParseSuccess<{Character*}>`).with((result1) {
        assertEquals(result1.result.sequence(), ['x', 'x', 'x', 'x', 'x']);
    });
}
test
shared void skipManyCombinatorDoesNotConsumeNextTokenUsingMultiCharacterConsumer() {
    expect(skip(many(text("abc"))).parse("abcabcabcdef"))
        .assignableTo(`ParseSuccess<{Character*}>`).with((result) {
        	assertEquals(result.result.sequence(), []);
    	});
}

test
shared void skipManyCombinatorSimpleTest() {
    value result = skip(many(character('a'))).parse("aaa");

    if (is ParseSuccess<[]> result) {
        assertEquals(result.result, []);
    } else {
        fail("Result was ``result``");
    }
}

test
shared void skipManyCombinatorEmptyInputTest() {
    value result = skip(many(character('a'))).parse("b");

    if (is ParseSuccess<[]> result) {
        assertEquals(result.result, []);
    } else {
        fail("Result was ``result``");
    }
}

test
shared void skipManyCombinatorDoesNotConsumeNextToken() {
    value result1 = skip(many(character('a'))).parse("axy");
    if (is ParseSuccess<[]> result1) {
        assertEquals(result1.result.sequence(), []);
    } else {
        fail("Result was ``result1``");
    }

    value result = sequenceOf({skip(many(character('a'))), character('b')})
            .parse("aab");
    if (is ParseSuccess<{Character*}> result) {
        assertEquals(result.result.sequence(), ['b']);
    } else {
        fail("Result was ``result``");
    }
}

test
shared void skipMany1CombinatorSimpleTest() {
    value result = skip(many(character('a'), 1)).parse("aaa");

    if (is ParseSuccess<{Character*}> result) {
        assertEquals(result.result.sequence(), []);
    } else {
        fail("Result was ``result``");
    }
}

test
shared void skipmany1CombinatorTooShortInputTest() {
    value result = skip(many(character('a'), 1)).parse("b");

    expect(result).assignableTo(error);
}

test
shared void skipMany1CombinatorDoesNotConsumeNextToken() {
    value result = sequenceOf {
        skip(many(character('a'), 1)), character('b')
    }.parse("aab");

    expect(result).assignableTo(`ParseSuccess<{Character*}>`).with((result) {
        assertEquals(result.result.sequence(), ['b']);
    });
}

test
shared void skipMany3CombinatorTooShortInputTest() {
    value result = skip(many(character('a'), 3)).parse("aab");

    expect(result).assignableTo(error);
}

test
shared void skipMany3CombinatorDoesNotConsumeNextToken() {
    value result = sequenceOf {
        skip(many(character('a'), 3)), character('b')
    }.parse("aaaab");

    if (is ParseSuccess<{Character*}> result) {
        assertEquals(result.result.sequence(), ['b']);
    } else {
        fail("Result was ``result``");
    }
}

test shared void optionSimpleTest() {
    value parser = option(character('a'));

    value result1 = parser.parse("");
    if (is ParseSuccess<{Character*}> result1) {
        assertEquals(result1.result, []);
    } else {
        fail("Result was ```result1``");
    }

    value result2 = parser.parse("a");
    if (is ParseSuccess<{Character*}> result2) {
        assertEquals(result2.result.sequence(), ['a']);
    } else {
        fail("Result was ```result2``");
    }

    value result3 = parser.parse("b");
    if (is ParseSuccess<{Character*}> result3) {
        assertEquals(result3.result, []);
    } else {
        fail("Result was ```result3``");
    }
}

test shared void aroundTest() {
    value parser = around(spaces(), character('c'));
    expect(parser.parse("c")).assignableTo(`ParseSuccess<[Character*]>`).with((result) {
        assertEquals(result.result.sequence(), ['c']);
    });
    expect(parser.parse("  c   !!")).assignableTo(`ParseSuccess<[Character*]>`).with((result) {
        assertEquals(result.result.sequence(), ['c']);
    });
}

test shared void betweenTest() {
    value parser = between(character('a'), character('b'), character('c'));
    expect(parser.parse("bac")).assignableTo(`ParseSuccess<[Character*]>`).with((result) {
        assertEquals(result.result.sequence(), ['a']);
    });
    expect(parser.parse("baca")).assignableTo(`ParseSuccess<[Character*]>`).with((result) {
        assertEquals(result.result.sequence(), ['a']);
    });
}

test shared void optionMultivalueTest() {
    value parser = option(sequenceOf { text("hej"), text("bye") });

    value result1 = parser.parse("hejdå");
    if (is ParseSuccess<{String*}> result1) {
        assertEquals(result1.result.sequence(), []);
    } else {
        fail("Result was ```result1``");
    }

    value result2 = parser.parse("hejbye");
    if (is ParseSuccess<{String*}> result2) {
        assertEquals(result2.result.sequence(), ["hej", "bye"]);
    } else {
        fail("Result was ```result2``");
    }

    value result3 = parser.parse("hell");
    if (is ParseSuccess<{String*}> result3) {
        assertEquals(result3.result.sequence(), []);
    } else {
        fail("Result was ```result3``");
    }
}

test
shared void optionDefaultTest() {
	value parser = optionDefault(many(text("foo"), 1), "moo");
	
	value result1 = parser.parse("foo");
	if (is ParseSuccess<{String+}> result1) {
		assertEquals(result1.result.sequence(), ["foo"]);
	} else {
		fail("Result was ```result1``");
	}
	
	value result2 = parser.parse("foofoo");
	if (is ParseSuccess<{String+}> result2) {
		assertEquals(result2.result.sequence(), ["foo", "foo"]);
	} else {
		fail("Result was ```result2``");
	}
	
	value result3 = parser.parse("bar");
	if (is ParseSuccess<{String+}> result3) {
		assertEquals(result3.result.sequence(), ["moo"]);
	} else {
		fail("Result was ```result3``");
	}
}

test
shared void sepByTest() {
    value commaSeparated = separatedBy(character(','), integer());

    value result1 = commaSeparated.parse("");
    if (is ParseSuccess<{Integer*}> result1) {
        assertEquals(result1.result.sequence(), []);
    } else {
        fail("Result was ``result1``");
    }

    value result2 = commaSeparated.parse("1,2,");
    if (is ParseSuccess<{Integer*}> result2) {
        assertEquals(result2.result.sequence(), [1, 2]);
    } else {
        fail("Result was ``result2``");
    }

    value result3 = commaSeparated.parse("1");
    if (is ParseSuccess<{Integer*}> result3) {
        assertEquals(result3.result.sequence(), [1]);
    } else {
        fail("Result was ``result3``");
    }

    value result4 = commaSeparated.parse("1,2,3,4,5");
    if (is ParseSuccess<{Integer*}> result4) {
        assertEquals(result4.result.sequence(), [1, 2, 3, 4, 5]);
    } else {
        fail("Result was ``result4``");
    }
}

test
shared void sepByMin3Test() {
    value commaSeparated = separatedBy(character(','), integer(), 3);

    value result1 = commaSeparated.parse("100,200,53");
    if (is ParseSuccess<{Integer*}> result1) {
        assertEquals(result1.result.sequence(), [100, 200, 53]);
    } else {
        fail("Result was ``result1``");
    }

    value result2 = commaSeparated.parse("1,2,3,4,5");
    if (is ParseSuccess<{Integer*}> result2) {
        assertEquals(result2.result.sequence(), [1, 2, 3, 4, 5]);
    } else {
        fail("Result was ``result2``");
    }
    value result3 = commaSeparated.parse("1");
    expect(result3).assignableTo(error);

    value result4 = commaSeparated.parse("1,2");
    expect(result4).assignableTo(error);
}

test
shared void sepByWithComplexCombinationTest() {
    value args = sequenceOf {
        skip(character('(')),
        separatedBy(around(spaces(), character(',')),
            either { text("shared"), text("actual") }),
        skip(character(')'))
    };

    value result1 = args.parse("()");
    if (is ParseSuccess<{String*}> result1) {
        assertEquals(result1.result.sequence(), []);
    } else {
        fail("Result was ``result1``");
    }

    value result2 = args.parse("(shared)");
    if (is ParseSuccess<{String*}> result2) {
        assertEquals(result2.result.sequence(), ["shared"]);
    } else {
        fail("Result was ``result2``");
    }

    value result3 = args.parse("(shared, actual)");
    if (is ParseSuccess<{String*}> result3) {
        assertEquals(result3.result.sequence(), ["shared", "actual"]);
    } else {
        fail("Result was ``result3``");
    }

    value result4 = args.parse("(shared   ,    actual,shared)");
    if (is ParseSuccess<{String*}> result4) {
        assertEquals(result4.result.sequence(), ["shared", "actual", "shared"]);
    } else {
        fail("Result was ``result4``");
    }
}

test shared void errorMessageShouldComeFromDeepestParserAttempted() {
    value parser = sequenceOf {
        character('#'), many(digit()), either {
            sequenceOf { character('.'), word() },
            sequenceOf { character('!'), many(digit(), 1) }
        }, endOfInput()
    };
    // make sure valid input passes
    expect(parser.parse("#123.hi")).assignableTo(`ParseSuccess<Anything>`);
    expect(parser.parse("#1!23")).assignableTo(`ParseSuccess<Anything>`);

    // error message should show the exact unexpected input
    expect(parser.parse("#1.4")).assignableTo(`ParseError`).with((error) {
        assertTrue(error.message.contains("Unexpected '4'"));
        assertEquals(error.location, [1, 4]);
    });
    expect(parser.parse("abc")).assignableTo(`ParseError`).with((error) {
        assertTrue(error.message.contains("Unexpected 'abc'"));
        assertEquals(error.location, [1, 1]);
    });
    expect(parser.parse("#1!hi")).assignableTo(`ParseError`).with((error) {
        assertTrue(error.message.contains("Unexpected 'hi'"));
        assertEquals(error.location, [1, 4]);
    });
    expect(parser.parse("#1!012ABC")).assignableTo(`ParseError`).with((error) {
        assertTrue(error.message.contains("Unexpected 'ABC'"));
        assertEquals(error.location, [1, 7]);
    });
    expect(parser.parse("#Fghijk")).assignableTo(`ParseError`).with((error) {
        assertTrue(error.message.contains("Unexpected 'Fghijk'"));
        assertEquals(error.location, [1, 2]);
    });
}
