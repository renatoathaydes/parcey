import com.athaydes.parcey {
    Parser,
    ParseResult,
    ParseError,
    ParsedLocation
}
import com.athaydes.parcey.internal {
    chooseName,
    chain,
    append,
    simplePlural,
    parseError,
    locationAfterParsing
}

"Creates a Parser that applies each of the given parsers in sequence.
 
 If any of the parsers fails, the chain is broken and a [[com.athaydes.parcey::ParseError]]
 is returned immediately.
 
 This is a very commonly-used Parser, hence its short name which stands for *sequence of Parsers*."
shared Parser<{Item*}> seq<Item>({Parser<{Item*}>+} parsers, String name_ = "")
        => object satisfies Parser<{Item*}> {
    name = chooseName(name_, parsers.map(Parser.name).interpose("->").fold("")(plus));
    shared actual ParseResult<{Item*}>|ParseError doParse(
        Iterator<Character> input,
        ParsedLocation parsedLocation,
        String? delegateName) {
        variable ParseResult<{Item*}> result = ParseResult([], parsedLocation, []);
        variable Iterator<Character> effectiveInput = input;
        for (parser in parsers) {
            value current = parser.doParse(effectiveInput,
                locationAfterParsing(result.consumed, parsedLocation));
            switch (current)
            case (is ParseError) {
                value consumed = result.consumed.append(current.consumed);
                return parseError("Expected ``delegateName else parser.name`` but found '``String(current.consumed)``'",
                    locationAfterParsing(result.consumed, parsedLocation), consumed);
            }
            case (is ParseResult<{Item*}>) {
                if (!current.overConsumed.empty) {
                    effectiveInput = chain(current.overConsumed, effectiveInput);
                }
                result = append(result, current, true);
            }
        }
        return result;
    }
};

"Creates a Parser which attempts to parse input using the first of the given parsers, and in case it fails,
 attempts to use the next parser and so on until there is no more available parsers.
 
 If any Parser fails, the [[com.athaydes.parcey::HasConsumed.consumed]] stream from its result is chained to the actual input
 before being passed to the next parser, such that the next parser will 'see' exactly the same input as the previous Parser."
shared Parser<Item> either<Item>({Parser<Item>+} parsers, String name_ = "") {
    return object satisfies Parser<Item> {
        name = chooseName(name_, "either ``parsers.map(Parser.name).interpose(" or ").fold("")(plus)``");
        shared actual ParseResult<Item>|ParseError doParse(
            Iterator<Character> input,
            ParsedLocation parsedLocation,
            String? delegateName) {
            variable ParseError error;
            variable Iterator<Character> effectiveInput = input;
            for (parser in parsers) {
                value current = parser.doParse(effectiveInput, parsedLocation);
                switch (current)
                case (is ParseError) {
                    error = parseError("Expected '``delegateName else name``' but found '``String(current.consumed)``'",
                        parsedLocation, current.consumed);
                    effectiveInput = chain(error.consumed, effectiveInput);
                }
                case (is ParseResult<Item>) {
                    return current;
                }
            }
            return error;
        }
    };
}

"Creates a Parser that applies the given parser as many times as possible without failing,
 returning all results of each application.
 
 For this Parser to succeed, the given parser must succeed at least 'minOcurrences' times."
see (`function skip`)
shared Parser<{Item*}> many<Item>(Parser<{Item*}> parser, Integer minOccurrences = 0, String name_ = "") {
    value parsers = [parser].cycled;
    return object satisfies Parser<{Item*}> {

        name = chooseName(name_, (minOccurrences <= 0 then "many" else "at least ``minOccurrences``")
            + " ``simplePlural("occurrence", minOccurrences)`` of ``parser.name``");

        shared actual ParseResult<{Item*}>|ParseError doParse(
            Iterator<Character> input,
            ParsedLocation parsedLocation,
            String? delegateName) {
            variable Integer passes = 0;
            variable ParseResult<{Item*}> result = ParseResult([], parsedLocation, []);
            for (parser in parsers) {
                value location = locationAfterParsing(result.consumed, parsedLocation);
                value current = parser.doParse(input, location);
                switch (current)
                case (is ParseError) {
                    if (passes >= minOccurrences) {
                        return ParseResult(result.result, result.parseLocation,
                            result.consumed, current.consumed);
                    } else {
                        return parseError("Expected ``delegateName else parser.name`` but was ``current.consumed``",
                            location, result.consumed.append(current.consumed));
                    }
                }
                case (is ParseResult<{Item*}>) {
                    result = append(result, current, true);
                    if (current.consumed.empty) {
                        // did not consume anything, stop or there will be an infinite loop
                        return ParseResult(result.result, result.parseLocation, result.consumed, result.overConsumed);
                    }
                    passes++;
                }
            }
            throw; // parsers is an infinite stream, so this will never be reached
        }
    };
}

"Creates a Parser that applies the given parsers only if all of them succeed.
 
 If any Parser fails, the parser backtracks and returns an empty result."
see (`function many`, `function either`)
shared Parser<{Item*}> option<Item>({Parser<{Item*}>+} parsers) {
    value parser = seq<Item>(parsers);
    return object satisfies Parser<{Item*}> {
        name = "option"; // this parser cannot produce errors so a name is unnecessary
        shared actual ParseResult<{Item*}> doParse(
            Iterator<Character> input,
            ParsedLocation parsedLocation,
            String? delegateName) {
            value result = parser.doParse(input, parsedLocation);
            switch (result)
            case (is ParseError) {
                return ParseResult([], parsedLocation, [], result.consumed);
            }
            case (is ParseResult<{Item*}>) {
                return result;
            }
        }
    };
}

"Creates a Parser that applies the given parser followed by the *skipped* separator parser
 as many times as possible.
 
 For example, the following Parser will parse a row of zero or more Integers separated by a comma
 and optional spaces:
 
     sepBy(seq { spaces(), char(','), spaces() }, integer());"
shared Parser<{Item*}> sepBy<Item>(
    Parser<{Anything*}> separator,
    Parser<{Item*}> parser,
    Integer minOccurrences = 0)
        => let (lastItemParser = (minOccurrences == 0)
            then option<Item> else (({Parser<{Item*}>+} p) => p.first))
    seq {
        many(seq { parser, skip(separator) }, minOccurrences - 1),
        lastItemParser({ parser })
    };

"Creates a Parser that applies the given parsers but throws away their results,
 returning an [[Empty]] as its result if the parser succeeds."
see (`function many`, `function either`)
shared Parser<[]> skip<Item>(Parser<{Item*}> parser, String name_ = "") {
    return object satisfies Parser<[]> {
        name = chooseName(name_, "to skip ``parser.name``");
        shared actual ParseResult<[]>|ParseError doParse(
            Iterator<Character> input,
            ParsedLocation parsedLocation,
            String? delegateName) {
            value result = parser.doParse(input, parsedLocation);
            switch (result)
            case (is ParseError) {
                return parseError("Expected ``delegateName else name`` but was ``result.consumed``",
                    parsedLocation, result.consumed);
            }
            case (is ParseResult<{Item*}>) {
                return ParseResult([], result.parseLocation, result.consumed, result.overConsumed);
            }
        }
    };
}
