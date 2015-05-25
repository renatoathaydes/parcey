import com.athaydes.parcey {
    Parser,
    ParseResult,
    ParseError
}
import com.athaydes.parcey.internal {
    chooseName,
    chain,
    append,
    simplePlural,
    parseError
}

"Creates a Parser that applies each of the given parsers in sequence.
 
 If any of the parsers fails, the chain is broken and a [[com.athaydes.parcey::ParseError]]
 is returned immediately.
 
 This is a very commonly-used Parser, hence its short name which stands for *sequence of Parsers*."
see(`function seq1`)
shared Parser<{Item*}> seq<Item>({Parser<{Item*}>+} parsers, String name_ = "")
        => object satisfies Parser<{Item*}> {
    name => chooseName(name_, parsers.map(Parser.name).interpose("->").fold("")(plus));
    shared actual ParseResult<{Item*}>|ParseError doParse(
        Iterator<Character> input,
        {Character*} consumed) {
        variable ParseResult<{Item*}> result = ParseResult({}, {}, {});
        variable Iterator<Character> effectiveInput = input;
        for (parser in parsers) {
            value current = parser.doParse(effectiveInput, {});
            switch (current)
            case (is ParseError) {
                return parseError(input, name_.empty then parser else this,
                    consumed.chain(result.consumed), current.consumed);
            }
            else {
                if (!current.overConsumed.empty) {
                    effectiveInput = chain(current.overConsumed, effectiveInput);
                }
                result = append(result, current, false);
            }
        }
        return ParseResult(result.result,
            consumed.chain(result.consumed),
            result.overConsumed);
    }
};

"Creates a Parser that applies each of the given parsers in sequence, ensuring at least
 one [[Item]] is returned in the result.
 
 If any of the parsers fails, the chain is broken and a [[com.athaydes.parcey::ParseError]]
 is returned immediately."
see(`function seq`)
shared Parser<{Item+}> seq1<Item>({Parser<{Item*}>+} parsers, String name_ = "")
        => object satisfies Parser<{Item+}> {
    value delegate = seq(parsers);
    name => chooseName(name_, delegate.name);
    shared actual ParseResult<{Item+}>|ParseError doParse(
        Iterator<Character> input,
        {Character*} consumed) {
            value result = delegate.doParse(input, consumed);
            if (is ParseResult<Anything> result,
                exists res = result.result.first) {
                return ParseResult({res}.chain(result.result.rest),
                    consumed.chain(result.consumed),
                    result.overConsumed);
            } else if (is ParseError result) {
                return result;
            } else { // not even one result found
                return parseError(input, this,
                    result.consumed, result.overConsumed);
            }
        }
    };

"Creates a Parser which attempts to parse input using the first of the given parsers, and in case it fails,
 attempts to use the next parser and so on until there is no more available parsers.
 
 If any Parser fails, the [[com.athaydes.parcey::HasConsumed.consumed]] stream from its result is chained to the actual input
 before being passed to the next parser, such that the next parser will 'see' exactly the same input as the previous Parser."
shared Parser<Item> either<Item>({Parser<Item>+} parsers, String name_ = "") {
    return object satisfies Parser<Item> {
        name => chooseName(name_, "either ``parsers.map(Parser.name).interpose(" or ").fold("")(plus)``");
        shared actual ParseResult<Item>|ParseError doParse(
            Iterator<Character> input,
            {Character*} consumed) {
            variable {{Character*}*} consumedPerParser = {};
            variable Iterator<Character> effectiveInput = input;
            for (parser in parsers) {
                value current = parser.doParse(effectiveInput, {});
                switch (current)
                case (is ParseError) {
                    consumedPerParser = consumedPerParser.chain { current.consumed };
                    effectiveInput = chain(current.consumed, effectiveInput);
                }
                else {
                    return ParseResult(current.result,
                        consumed.chain(current.consumed), current.overConsumed);
                }
            }
            
            value longestConsumed = [ for (c in consumedPerParser) [c, c.size] ]
                    .sort((first, sec) => sec[1] <=> first[1])
                    .first?.first else {};
            return parseError(input, this, consumed, longestConsumed);
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

        name => chooseName(name_, (minOccurrences <= 0 then "many" else "at least ``minOccurrences``")
            + " ``simplePlural("occurrence", minOccurrences)`` of ``parser.name``");

        function minMany(Iterator<Character> input)
                => seq({parser}.chain(parsers.take(minOccurrences - 1)))
                    .doParse(input, {});
        
        shared actual ParseResult<{Item*}>|ParseError doParse(
            Iterator<Character> input,
            {Character*} consumed) {
            variable ParseResult<{Item*}> result = ParseResult({}, {}, {});
            if (minOccurrences > 0) {
                value mandatoryResult = minMany(input);
                if (is ParseError mandatoryResult) {
                    return parseError(input, this, consumed, mandatoryResult.consumed);
                } else {
                    result = mandatoryResult;
                }    
            }
            for (optional in parsers) {
                value optionalResult = optional.doParse(
                    chain(result.overConsumed, input), {});
                switch (optionalResult)
                case (is ParseError) {
                    return ParseResult(result.result,
                        consumed.chain(result.consumed),
                        optionalResult.consumed);
                }
                else {
                    result = append(result, optionalResult, false);
                    if (optionalResult.consumed.empty) {
                        // did not consume anything, stop or there will be an infinite loop
                        return ParseResult(result.result,
                                consumed.chain(result.consumed),
                                result.overConsumed);
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
            {Character*} consumed) {
            value result = parser.doParse(input, consumed);
            switch (result)
            case (is ParseError) {
                return ParseResult({}, {}, result.consumed);
            }
            else {
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
    String name = "") {
    function optionalIf(Boolean condition)
            => condition then option<Item> else identity<Parser<{Item*}>>;
    
    return optionalIf(minOccurrences <= 0)(seq({
        parser,
        optionalIf(minOccurrences == 1)(
            many(seq { skip(separator), parser }, minOccurrences - 1))
    }, name));
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
    String name = "") {
    alias Val => Item|Sep;
    function optionalIf(Boolean condition) {
        return condition then option<Val> else identity<Parser<{Val*}>>;
    }
    return optionalIf(minOccurrences <= 0)(seq({
        parser,
        optionalIf(minOccurrences == 1)(
            many(seq { separator, parser }, minOccurrences - 1))
    }, name));
}

"Creates a Parser that applies the given parsers but throws away their results,
 returning an [[Empty]] as its result if the parser succeeds."
see (`function many`, `function either`)
shared Parser<[]> skip(Parser<Anything> parser, String name_ = "") {
    return object satisfies Parser<[]> {
        name => chooseName(name_, "to skip ``parser.name``");
        shared actual ParseResult<[]>|ParseError doParse(
            Iterator<Character> input,
            {Character*} consumed) {
            value result = parser.doParse(input, {});
            switch (result)
            case (is ParseError) {
                return parseError(input, this, consumed, result.consumed);
            }
            else {
                return ParseResult([], consumed.chain(result.consumed), result.overConsumed);
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
