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
 
 If any of the parser fails, the chain is broken and a [[com.athaydes.parcey::ParseError]] is returned with
 the whole input that has been consumed by all parsers."
shared Parser<{Item*}> parserChain<Item>({Parser<{Item*}>+} parsers, String name_ = "")
        => object satisfies Parser<{Item*}> {
    name = chooseName(name_, parsers.map(Parser.name).interpose("->").fold("")(plus));
    shared actual ParseResult<{Item*}>|ParseError doParse(
        Iterator<Character> input,
        ParsedLocation parsedLocation,
        String? delegateName) {
        variable ParseResult<{Item*}> result = ParseResult([], parsedLocation, []);
        variable Iterator<Character> effectiveInput = input;
        for (parser in parsers) {
            value location = locationAfterParsing(result.consumed, parsedLocation);
            value current = parser.doParse(effectiveInput, location,
                delegateName else parser.name);
            switch (current)
            case (is ParseError) {
                return parseError(delegateName else parser.name, location,
                    result.consumed.append(current.consumed), current.overConsumed);
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
        name = chooseName(name_, parsers.last.name);
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
                    error = parseError(delegateName else parser.name, parsedLocation, current.consumed, []);
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

        name = chooseName(name_, (minOccurrences == 0 then "many" else "at least ``minOccurrences``")
            + " ``simplePlural("occurrence", minOccurrences)`` of ``parser.name``");

        shared actual ParseResult<{Item*}>|ParseError doParse(
            Iterator<Character> input,
            ParsedLocation parsedLocation,
            String? delegateName) {
            variable ParseResult<{Item*}> result = ParseResult([], parsedLocation, []);
            for (parser in parsers) {
                value location = locationAfterParsing(result.consumed, parsedLocation);
                value current = parser.doParse(input, location);
                switch (current)
                case (is ParseError) {
                    if (result.consumed.size >= minOccurrences) {
                        return ParseResult(result.result, result.parseLocation,
                            result.consumed, current.consumed);
                    } else {
                        return parseError(delegateName else parser.name, location,
                            result.consumed.append(current.consumed), current.consumed);
                    }
                }
                case (is ParseResult<{Item*}>) {
                    result = append(result, current, true);
                    if (current.consumed.empty) {
                        // did not consume anything, stop or there will be an infinite loop
                        return ParseResult(result.result, result.parseLocation, result.consumed, result.overConsumed);
                    }
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
    value parser = parserChain<Item>(parsers);
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

"Creates a Parser that applies the given parsers only if all of them succeed.
 
 If any Parser fails, the parser backtracks and returns an empty result."
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
                return parseError(name, parsedLocation, result.consumed, result.overConsumed);
            }
            case (is ParseResult<{Item*}>) {
                return ParseResult([], result.parseLocation, result.consumed, result.overConsumed);
            }
        }
    };
}
