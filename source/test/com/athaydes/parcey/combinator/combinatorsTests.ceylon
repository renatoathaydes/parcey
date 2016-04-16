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
    nonEmptySequenceOf
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

    expect(result).assignableTo(`ParseSuccess<{Character*}>`).with((result) {
        assertEquals(result.result.sequence(), ['a', ' ', 'b']);
    });
}

test
shared void sequenceOfShouldReportDeepestParserThatFails() {
    value parser = sequenceOf {
        character('a'), character('b'), character('c'), separatedBy(character('_'), integer(), 2)
    };

    expect(parser.parse("xyz")).assignableTo(`ParseError`).with((error) {
        assertEquals(expectThat(error.message, to(containSubsection(*"Unexpected 'xyz'"))), success);
        assertEquals(error.location, [1, 1]);
    });
    expect(parser.parse("abze")).assignableTo(`ParseError`).with((error) {
        assertEquals(expectThat(error.message, to(containSubsection(*"Unexpected 'ze'"))), success);
        assertEquals(error.location, [1, 3]);
    });
    expect(parser.parse("abcd")).assignableTo(`ParseError`).with((error) {
        assertEquals(expectThat(error.message, to(containSubsection(*"Unexpected 'd'"))), success);
        assertEquals(error.location, [1, 4]);
    });
    expect(parser.parse("abc1")).assignableTo(`ParseError`).with((error) {
        assertEquals(expectThat(error.message, to(containSubsection(*"Unexpected ''"))), success);
        assertEquals(error.location, [1, 5]);
    });
    expect(parser.parse("abc1_2")).assignableTo(`ParseSuccess<{Anything*}>`).with((result) {
        assertEquals(result.result.sequence(), ['a', 'b', 'c', 1, 2]);
    });
}

test shared void nonEmptySequenceOfFailsWithEmptyResult() {
    value parser = nonEmptySequenceOf { coalescedParser(integer()) };

    expect(parser.parse("")).assignableTo(`ParseError`);
    expect(parser.parse("x")).assignableTo(`ParseError`);
}

test shared void nonEmptySequenceOfAllowsNonEmptyResult()  {
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

    expect(parser.parse("xy")).assignableTo(error).with((error) {
        assertEquals(expectThat(error.message, to(
                containSubsection(*"Unexpected 'xy'"),
                containSubsection(*"Expecting 'a' or 'b' or 'h' or 'space'"))),
            success);
        assertEquals(error.location, [1, 1]);
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

    expect(parser.parse("c")).assignableTo(error).with((error) {
        assertEquals(expectThat(error.message, to(containSubsection(*"Unexpected 'c'"))), success);
        assertEquals(error.location, [1, 1]);
    });
}

test
shared void manyCombinatorSimpleTest() {
    expect(many(character('a')).parse("a")).assignableTo(`ParseSuccess<{Character*}>`).with((result) {
        assertEquals(result.result.sequence(), ['a']);
    });
    expect(many(character('a')).parse("aaa")).assignableTo(`ParseSuccess<{Character*}>`).with((result) {
        assertEquals(result.result.sequence(), ['a', 'a', 'a']);
    });
}

test
shared void manyCombinatorEmptyInputTest() {
    expect(many(character('a')).parse("")).assignableTo(`ParseSuccess<{Character*}>`).with((result) {
        assertEquals(result.result.sequence(), []);
    });
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
    expect(many(character('a'), 1).parse("a")).assignableTo(`ParseSuccess<{Character*}>`).with((result) {
        assertEquals(result.result.sequence(), ['a']);
    });
    expect(many(character('a'), 1).parse("aaa")).assignableTo(`ParseSuccess<{Character*}>`).with((result) {
        assertEquals(result.result.sequence(), ['a', 'a', 'a']);
    });
    expect(many(character('a'), 1).parse("b")).assignableTo(`ParseError`).with((error) {
        assertTrue(error.message.contains("Unexpected 'b'"));
        assertEquals(error.location, [1, 1]);
    });
}

test
shared void many1CombinatorTooShortInputTest() {
    expect(many(character('a'), 1).parse("b")).assignableTo(error);
}

test
shared void many1CombinatorDoesNotConsumeNextToken() {
    value consumer = CharacterConsumer("aab".iterator());
    consumer.startParser("");
    expect(many(character('a'), 1)
            .doParse(consumer)).assignableTo(`ParseSuccess<{Character*}>`).with((result) {
        assertEquals(result.result.sequence(), ['a', 'a']);
    });
    consumer.startParser("");
    assertEquals(consumer.next(), 'b');
}

test
shared void many3CombinatorTooShortInputTest() {
    expect(many(character('a'), 3).parse("")).assignableTo(error).with((error) {
        assertTrue(error.message.contains("Unexpected ''"));
        assertEquals(error.location, [1, 1]);
    });
    expect(many(character('a'), 3).parse("abc")).assignableTo(error).with((error) {
        assertTrue(error.message.contains("Unexpected 'bc'"));
        assertEquals(error.location, [1, 2]);
    });
    expect(many(character('a'), 3).parse("aab")).assignableTo(error).with((error) {
        assertTrue(error.message.contains("Unexpected 'b'"));
        assertEquals(error.location, [1, 3]);
    });
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
shared void manySequenceOfCombinationTest() {
    expect(many(sequenceOf { character('x'), skip(character(',')) }).parse("x,x,x!"))
        .assignableTo(`ParseSuccess<{Character*}>`).with((result1) {
        assertEquals(result1.result.sequence(), ['x', 'x']);
    });
}

test
shared void manySequenceOfManyCombinationTest() {
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
    expect(parser.parse("c")).assignableTo(`ParseSuccess<{Character*}>`).with((result) {
        assertEquals(result.result.sequence(), ['c']);
    });
    expect(parser.parse("  c   !!")).assignableTo(`ParseSuccess<{Character*}>`).with((result) {
        assertEquals(result.result.sequence(), ['c']);
    });
}

test shared void betweenTest() {
    value parser = between(character('b'), character('c'), character('a'));
    expect(parser.parse("bac")).assignableTo(`ParseSuccess<{Character*}>`).with((result) {
        assertEquals(result.result.sequence(), ['a']);
    });
    expect(parser.parse("baca")).assignableTo(`ParseSuccess<{Character*}>`).with((result) {
        assertEquals(result.result.sequence(), ['a']);
    });
}

test shared void betweenErrorTest() {
    value parser = between(character('['), character(']'), text("hello"));
    expect(parser.parse("[hello]")).assignableTo(`ParseSuccess<{String*}>`).with((result) {
        assertEquals(result.result.sequence(), ["hello"]);
    });
    expect(parser.parse("hello")).assignableTo(error).with((error) {
        assertEquals(expectThat(error.message, to(containSubsection(*"Unexpected 'hello'"))), success);
        assertEquals(expectThat(error.message, to(containSubsection(*"Expecting '['"))), success);
        assertEquals(error.location, [1, 1]);
    });
    expect(parser.parse("[hello")).assignableTo(error).with((error) {
        assertEquals(expectThat(error.message, to(containSubsection(*"Unexpected ''"))), success);
        assertEquals(expectThat(error.message, to(containSubsection(*"Expecting ']'"))), success);
        assertEquals(error.location, [1, 7]);
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
shared void separatedByTest() {
    value parser = separatedBy(character(','), integer());

    expect(parser.parse("")).assignableTo(`ParseSuccess<{Integer*}>`).with((result) {
        assertEquals(result.result.sequence(), []);
    });
    expect(parser.parse("1,2,")).assignableTo(`ParseSuccess<{Integer*}>`).with((result) {
        assertEquals(result.result.sequence(), [1, 2]);
    });
    expect(parser.parse("1")).assignableTo(`ParseSuccess<{Integer*}>`).with((result) {
        assertEquals(result.result.sequence(), [1]);
    });
    expect(parser.parse("1,2,3,4,5")).assignableTo(`ParseSuccess<{Integer*}>`).with((result) {
        assertEquals(result.result.sequence(), [1, 2, 3, 4, 5]);
    });
}

test
shared void separtedByMin3Test() {
    value parser = separatedBy(character(','), integer(), 3);

    expect(parser.parse("100,200,53")).assignableTo(`ParseSuccess<{Integer*}>`).with((result) {
        assertEquals(result.result.sequence(), [100, 200, 53]);
    });
    expect(parser.parse("1,2,3,4,5")).assignableTo(`ParseSuccess<{Integer*}>`).with((result) {
        assertEquals(result.result.sequence(), [1, 2, 3, 4, 5]);
    });
    expect(parser.parse("1")).assignableTo(`ParseError`).with((error) {
        assertEquals(expectThat(error.message, to(containSubsection(*"Unexpected ''"))), success);
        assertEquals(error.location, [1, 2]);
    });
    expect(parser.parse("1,2")).assignableTo(`ParseError`).with((error) {
        assertEquals(expectThat(error.message, to(containSubsection(*"Unexpected ''"))), success);
        assertEquals(error.location, [1, 4]);
    });
    expect(parser.parse("1,2,")).assignableTo(`ParseError`).with((error) {
        assertEquals(expectThat(error.message, to(containSubsection(*"Unexpected ''"))), success);
        assertEquals(error.location, [1, 5]);
    });
    expect(parser.parse("1,2,XYZ")).assignableTo(`ParseError`).with((error) {
        assertEquals(expectThat(error.message, to(containSubsection(*"Unexpected 'XYZ'"))), success);
        assertEquals(error.location, [1, 5]);
    });
}

test
shared void separatedByWithComplexCombinationTest() {
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
