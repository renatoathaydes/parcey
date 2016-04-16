import ceylon.test {
    test,
    assertEquals
}

import com.athaydes.parcey {
    digit,
    strParser,
    mapParser,
    coalescedParser,
    ParseSuccess,
    spaces,
    anyCharacter,
    ParseError,
    mapParsers,
    character,
    integer
}
import com.athaydes.parcey.combinator {
    many,
    separatedBy,
    either,
    sequenceOf
}
import com.athaydes.specks {
    success
}
import com.athaydes.specks.assertion {
    expectThat=expect
}
import com.athaydes.specks.matcher {
    containSubsection,
    to
}

import test.com.athaydes.parcey.combinator {
    expect
}

test shared void coalescedParserTest() {
    value maybeIntParser = mapParser(
        separatedBy(spaces(), strParser(many(digit(), 1))), parseInteger);

     value intParser = coalescedParser(maybeIntParser);

    expect(intParser.parse("")).ofType(`ParseSuccess<{Integer*}>`).with((result) {
        assertEquals(result.result.sequence(), []);
    });
    expect(intParser.parse("x")).ofType(`ParseSuccess<{Integer*}>`).with((result) {
        assertEquals(result.result.sequence(), []);
    });
    expect(intParser.parse("1")).ofType(`ParseSuccess<{Integer*}>`).with((result) {
        assertEquals(result.result.sequence(), [1]);
    });
    expect(intParser.parse("1 2 10 w z")).ofType(`ParseSuccess<{Integer*}>`).with((result) {
        assertEquals(result.result.sequence(), [1, 2, 10]);
    });
}

test shared void testMapParserWithThrowingConverter() {
    function filteringConverter(Character c) {
        "Actually, c needs to be between 1 and 9"
        assert (c in '1'..'9');
        return c.predecessor;
    }

    value parser = mapParser(many(anyCharacter()), filteringConverter);

    expect(parser.parse("456")).assignableTo(`ParseSuccess<{Character*}>`).with((result) {
        assertEquals(result.result.sequence(), "345".sequence());
    });

    expect(parser.parse("a2")).assignableTo(`ParseError`).with((error) {
        assertEquals(expectThat(error.message, to(containSubsection(*"Actually, c needs to be between 1 and 9"))), success);
        assertEquals(error.location, [1, 1]);
    });
}

test shared void testMapValueParserWithThrowingConverter() {
    value parser = mapParsers {
        parsers = {
            either { character('a'), character('b') },
            character('c')
        };
        function converter(Anything parsed) {
            "Only 'b' is accepted"
            assert (exists parsed, parsed == ['b']);
            return parsed;
        }
    };

    expect(parser.parse("ac")).assignableTo(`ParseError`).with((error) {
        assertEquals(expectThat(error.message, to(containSubsection(*"Only 'b' is accepted"))), success);
        assertEquals(error.location, [1, 1]);
    });
    expect(parser.parse("bc")).assignableTo(`ParseError`).with((error) {
        assertEquals(expectThat(error.message, to(containSubsection(*"Only 'b' is accepted"))), success);
        assertEquals(error.location, [1, 1]);
    });
}

test shared void testMapValueParserWithThrowingConverterErrorLocation() {
    value mapParserName = "try ac or bc, but only accept bc";
    value parser = sequenceOf {
        separatedBy(character('\n'), many(integer())),
        mapParsers {
            name = mapParserName;
            parsers = {
                either { character('a'), character('b') },
                character('c')
            };
            function converter(Anything parsed) {
                "Only 'b' is accepted"
                assert (exists parsed, parsed == ['b']);
                return parsed;
            }
        }
    };

    expect(parser.parse("123ac")).assignableTo(`ParseError`).with((error) {
        assertEquals(expectThat(error.message, to(
            containSubsection(*"Only 'b' is accepted"),
            containSubsection(*mapParserName))),
        success);
        assertEquals(error.location, [1, 4]);
    });
    expect(parser.parse("12\n345\n678bc")).assignableTo(`ParseError`).with((error) {
        assertEquals(expectThat(error.message, to(containSubsection(*"Only 'b' is accepted"))), success);
        assertEquals(error.location, [3, 4]);
    });
}
