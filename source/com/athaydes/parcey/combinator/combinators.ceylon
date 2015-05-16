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
see(`function seq1`)
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
                    consumed, parsedLocation);
            }
            case (is ParseResult<{Item*}>) {
                if (!current.overConsumed.empty) {
                    effectiveInput = chain(current.overConsumed, effectiveInput);
                }
                result = append(result, current, false);
            }
        }
        return result;
    }
};

"Creates a Parser that applies each of the given parsers in sequence, ensuring at least
 one [[Item]] is returned in the result.
 
 If any of the parsers fails, the chain is broken and a [[com.athaydes.parcey::ParseError]]
 is returned immediately."
see(`function seq`)
shared Parser<{Item+}> seq1<Item>({Parser<{Item*}>+} parsers, String name_ = "")
        => object satisfies Parser<{Item+}> {
    value delegate = seq(parsers, name_);
    name = delegate.name;
    shared actual ParseResult<{Item+}>|ParseError doParse(
        Iterator<Character> input,
        ParsedLocation parsedLocation,
        String? delegateName) {
            value result = delegate.doParse(input, parsedLocation);
            if (is ParseResult<{Item*}> result,
                is {Item+} res = result.result) {
                return ParseResult(res, result.parseLocation,
                    result.consumed, result.overConsumed);
            } else if (is ParseError result) {
                return result;
            } else {
                value consumed = result.consumed.append(result.overConsumed);
                return parseError("Empty result from ``name``",
                    consumed, parsedLocation);
            }
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
                        current.consumed, parsedLocation);
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

        function minMany(Iterator<Character> input, ParsedLocation parsedLocation)
                => seq({parser}.chain(parsers.take(minOccurrences - 1)), name)
                    .doParse(input, parsedLocation, name);
        
        shared actual ParseResult<{Item*}>|ParseError doParse(
            Iterator<Character> input,
            ParsedLocation parsedLocation,
            String? delegateName) {
            variable ParseResult<{Item*}> result = ParseResult([], parsedLocation, []);
            if (minOccurrences > 0) {
                value mandatoryResult = minMany(input, parsedLocation);
                if (is ParseError mandatoryResult) {
                    return mandatoryResult;
                } else {
                    result = mandatoryResult;
                }    
            }
            for (optional in parsers) {
                value location = locationAfterParsing(result.consumed, parsedLocation);
                value optionalResult = optional.doParse(
                    chain(result.overConsumed, input), location, name);
                
                switch (optionalResult)
                case (is ParseError) {
                    return ParseResult(result.result, result.parseLocation,
                        result.consumed, optionalResult.consumed);
                }
                case (is ParseResult<{Item*}>) {
                    result = append(result, optionalResult, false);
                    if (optionalResult.consumed.empty) {
                        // did not consume anything, stop or there will be an infinite loop
                        return ParseResult(result.result, result.parseLocation,
                            result.consumed, result.overConsumed);
                    }
                }
            }
            throw; // looping an infinite stream, so this will never be reached
        }
    };
}

"Creates a Parser that applies the given parser if it succeeds.
 
 In case of failure, this Parser backtracks and returns an empty result."
see (`function many`, `function either`)
shared Parser<{Item*}> option<Item>(Parser<{Item*}> parser) {
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

"Creates a Parser that applies the given parser multiple times, using the *skipped* separator parser
 in between applications, as many times as possible.
 
 For example, the following Parser will parse zero or more Integers separated by a comma
 and optional spaces:
 
     sepBy(around(spaces(), char(',')), integer());
     
 The [[minOcurrences|minOccurrences]] argument may specify the minimum number of times the given
 parser must succeed.
 
 Notice that if `minOccurrences <= 1`, then no separator is required in the input
 for this Parser to succeed.
 
 For example, given the following Parser:
 
     sepBy(char(':'), anyChar(), 1);
     
 The following are valid inputs:
 
 * a
 * b:c:d"
see(`function sepWith`)
shared Parser<{Item*}> sepBy<Item>(
    Parser<Anything> separator,
    Parser<{Item*}> parser,
    Integer minOccurrences = 0,
    String name_ = "") {
    function optionalIf(Boolean condition) {
        return condition then option<Item> else identity<Parser<{Item*}>>;
    }
    return optionalIf(minOccurrences <= 0)(seq {
        parser,
        optionalIf(minOccurrences == 1)(
            many(seq { skip(separator), parser }, minOccurrences - 1))
    });
}

"Creates a Parser that applies the given parser multiple times, using the separator parser
 in between applications, as many times as possible.
 
 For example, the following Parser will parse zero or more Integers separated by a comma
 and optional spaces:
 
     sepBy(around(spaces(), char(',')), integer());
     
 The [[minOcurrences|minOccurrences]] argument may specify the minimum number of times the given
 parser must succeed.
 
 Notice that if `minOccurrences <= 1`, then no separator is required in the input
 for this Parser to succeed.
 
 For example, given the following Parser:
 
     sepBy(char(':'), anyChar(), 1);
     
 The following are valid inputs:
 
 * a
 * b:c:d"
see(`function sepBy`)
shared Parser<{Item|Sep*}> sepWith<Item, Sep>(
    Parser<{Sep*}> separator,
    Parser<{Item*}> parser,
    Integer minOccurrences = 0,
    String name_ = "") {
    alias Val => Item|Sep;
    function optionalIf(Boolean condition) {
        return condition then option<Val> else identity<Parser<{Val*}>>;
    }
    return optionalIf(minOccurrences <= 0)(seq {
        parser,
        optionalIf(minOccurrences == 1)(
            many(seq { separator, parser }, minOccurrences - 1))
    });
}

"Creates a Parser that applies the given parsers but throws away their results,
 returning an [[Empty]] as its result if the parser succeeds."
see (`function many`, `function either`)
shared Parser<[]> skip(Parser<Anything> parser, String name_ = "") {
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
                    result.consumed, parsedLocation);
            }
            case (is ParseResult<Anything>) {
                return ParseResult([], result.parseLocation, result.consumed, result.overConsumed);
            }
        }
    };
}

"Surrounds the given parser with the surrounding parser.
 
 Example of Parser that parses words separated by commas and optional spaces:
 
     sepBy(around(spaces(), char(',')), word());"
see(`function sepBy`)
shared Parser<{Item*}> around<Item>(Parser<{Item*}> surrounding, Parser<{Item*}> parser)
        => seq { surrounding, parser, surrounding };
