import com.athaydes.parcey {
    Parser,
    ParseResult,
    ParseError
}

"Creates a Parser that applies each of the given parsers in sequence."
shared Parser<{Item*}> parserChain<Item>(Parser<{Item*}>+ parsers)
        => object satisfies Parser<{Item*}> {
        shared actual ParseResult<{Item*}>|ParseError doParse(Iterator<Character> input, Integer parsedIndex) {
            variable ParseResult<{Item*}> result = ParseResult({}, parsedIndex, []);
            for (parser in parsers) {
                value nextInput = chain(result.consumedFailed, input);
                value current = parser.doParse(nextInput, result.parsedIndex);
                switch (current)
                case (is ParseError) {
                    return current;
                }
                case (is ParseResult<{Item*}>) {
                    result = append(result, current, false);
                }
            }
            return result;
        }
    };

"Creates a Parser which attempts to parse input using the first of the given parsers, and in case it fails,
 attempts to use the next parser and so on until there is no more available parsers.
 
 If a Parser fails, the [[com.athaydes.parcey::HasConsumed.consumedFailed]] stream from its result is chained to the actual input
 before being passed to the next parser, such that the next parser will 'see' exactly the same input as the previous Parser."
shared Parser<{Item*}> either<Item>(Parser<{Item*}>+ parsers) {
    return object satisfies Parser<{Item*}> {
        
        shared actual ParseResult<{Item*}>|ParseError doParse(Iterator<Character> input, Integer parsedIndex) {
            variable ParseError error;
            variable Iterator<Character> effectiveInput = input;
            for (parser in parsers) {
                value current = parser.doParse(effectiveInput, parsedIndex);
                switch (current)
                case (is ParseError) {
                    error = current;
                    effectiveInput = chain(error.consumedFailed, effectiveInput);
                }
                case (is ParseResult<{Item*}>) {
                    return current;
                }
            }
            return error;
        }
    };
}

"Creates a Parser that applies the given parser as many times as possible without failing.
 
 For this Parser to succeed, the given parser must succeed at least 'minOcurrences' times."
shared Parser<{Item*}> many<Item>(Parser<{Item*}> parser, Integer minOccurrences = 0) {
    value parsers = [parser].cycled;
    return object satisfies Parser<{Item*}> {
        shared actual ParseResult<{Item*}>|ParseError doParse(Iterator<Character> input, Integer parsedIndex) {
            variable ParseResult<{Item*}> result = ParseResult({}, parsedIndex, []);
            for (parser in parsers) {
                value current = parser.doParse(input, result.parsedIndex);
                switch (current)
                case (is ParseError) {
                    if (result.result.size >= minOccurrences) {
                        return ParseResult(result.result,
                            result.parsedIndex,
                            result.consumedOk.append(current.consumedOk),
                            result.consumedFailed.append(current.consumedFailed));
                    } else {
                        return current;
                    }
                }
                case (is ParseResult<{Item*}>) {
                    result = append(result, current, true);
                    if (current.consumedOk.empty) { // did not consume anything
                        return result;
                    }
                }
            }
            throw; // parsers is an infinite stream, so this will never be reached
        }
    };
}

ParseResult<{Item*}> append<Item>(
    ParseResult<{Item*}> first,
    ParseResult<{Item*}> second,
    Boolean appendConsumedStreams)
        => ParseResult(
    first.result.chain(second.result),
    second.parsedIndex,
    appendConsumedStreams then first.consumedOk.append(second.consumedOk) else second.consumedOk,
    appendConsumedStreams then first.consumedFailed.append(second.consumedFailed) else second.consumedFailed);

Iterator<Character> chain(Character[] consumed, Iterator<Character> rest)
        => object satisfies Iterator<Character> {
    
    value firstIter = consumed.iterator();
    
    shared actual Character|Finished next()
            => if (is Character item = firstIter.next()) then item else rest.next();
};
