import com.athaydes.parcey {
    Parser,
    ParseResult,
    ParseError,
    ParsedLocation
}

"Creates a Parser that applies each of the given parsers in sequence.
 
 If any of the parser fails, the chain is broken and a [[com.athaydes.parcey::ParseError]] is returned with
 the whole input that has been consumed by all parsers."
shared Parser<{Item*}> parserChain<Item>(Parser<{Item*}>+ parsers)
        => object satisfies Parser<{Item*}> {
    shared actual ParseResult<{Item*}>|ParseError doParse(Iterator<Character> input, ParsedLocation parsedLocation) {
        variable ParseResult<{Item*}> result = ParseResult([], parsedLocation, []);
        variable Iterator<Character> effectiveInput = input;
        for (parser in parsers) {
            value current = parser.doParse(effectiveInput, result.parseLocation);
            switch (current)
            case (is ParseError) {
                return ParseError(current.message, result.consumed.append(current.consumed));
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
shared Parser<Item> either<Item>(Parser<Item>+ parsers) {
    return object satisfies Parser<Item> {
        
        shared actual ParseResult<Item>|ParseError doParse(Iterator<Character> input, ParsedLocation parsedLocation) {
            variable ParseError error;
            variable Iterator<Character> effectiveInput = input;
            for (parser in parsers) {
                value current = parser.doParse(effectiveInput, parsedLocation);
                switch (current)
                case (is ParseError) {
                    error = current;
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
see (`function skipMany`)
shared Parser<{Item*}> many<Item>(Parser<{Item*}> parser, Integer minOccurrences = 0) {
    value parsers = [parser].cycled;
    return object satisfies Parser<{Item*}> {
        shared actual ParseResult<{Item*}>|ParseError doParse(Iterator<Character> input, ParsedLocation parsedLocation) {
            variable ParseResult<{Item*}> result = ParseResult([], parsedLocation, []);
            for (parser in parsers) {
                value current = parser.doParse(input, result.parseLocation);
                switch (current)
                case (is ParseError) {
                    if (result.result.size >= minOccurrences) {
                        return ParseResult(result.result, result.parseLocation,
                            result.consumed, current.consumed);
                    } else {
                        return ParseError(current.message, result.consumed.append(current.consumed));
                    }
                }
                case (is ParseResult<{Item*}>) {
                    result = append(result, current, true);
                    if (current.consumed.empty) {
                        // did not consume anything, stop or there will be an infinite loop
                        return current;
                    }
                }
            }
            throw; // parsers is an infinite stream, so this will never be reached
        }
    };
}

"Creates a Parser that applies the given parser as many times as possible without failing,
 but discards the result.
 
 For this Parser to succeed, the given parser must succeed at least 'minOcurrences' times."
see (`function many`)
shared Parser<[]> skipMany<Item>(Parser<Item> parser, Integer minOccurrences = 0) {
    value parsers = [parser].cycled;
    return object satisfies Parser<[]> {
        shared actual ParseResult<[]>|ParseError doParse(Iterator<Character> input, ParsedLocation parsedLocation) {
            variable ParseResult<[]> result = ParseResult([], parsedLocation, []);
            for (parser in parsers) {
                value current = parser.doParse(input, result.parseLocation);
                switch (current)
                case (is ParseError) {
                    if (result.consumed.size >= minOccurrences) {
                        return ParseResult([],
                            result.parseLocation,
                            result.consumed,
                            current.consumed);
                    } else {
                        return ParseError(current.message,
                            result.consumed.append(current.consumed));
                    }
                }
                case (is ParseResult<Item>) {
                    if (current.consumed.empty) {
                        // did not consume anything, stop or there will be an infinite loop
                        return ParseResult([], result.parseLocation, result.consumed);
                    } else {
                        result = appendStreams(result, current);
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
shared Parser<{Item*}> option<Item>(Parser<{Item*}>+ parsers) {
    value parser = parserChain(*parsers);
    return object satisfies Parser<{Item*}> {
        shared actual ParseResult<{Item*}> doParse(Iterator<Character> input, ParsedLocation parsedLocation) {
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

ParseResult<Item> appendStreams<Item>(
    ParseResult<Item> first,
    ParseResult<Anything> second)
        => ParseResult(
    first.result,
    second.parseLocation,
    first.consumed.append(second.consumed));

ParseResult<{Item*}> append<Item>(
    ParseResult<{Item*}> first,
    ParseResult<{Item*}> second,
    Boolean appendConsumedStreams)
        => ParseResult(
    first.result.chain(second.result),
    second.parseLocation,
    appendConsumedStreams then first.consumed.append(second.consumed) else second.consumed);

Iterator<Character> chain(Character[] consumed, Iterator<Character> rest)
        => object satisfies Iterator<Character> {
    
    value firstIter = consumed.iterator();
    
    shared actual Character|Finished next()
            => if (is Character item = firstIter.next()) then item else rest.next();
};
