import com.athaydes.parcey {
    Parser,
    ParseResult,
    ParseError,
    CharacterConsumer,
    ParseOutcome
}
import com.athaydes.parcey.internal {
    chooseName,
    simplePlural,
    computeParserName
}

"Creates a Parser that applies each of the given parsers in sequence.
 
 If any of the parsers fails, the chain is broken and a [[com.athaydes.parcey::ParseError]]
 is returned immediately.
 
 This is a very commonly-used Parser, hence its short name which stands for *sequence of Parsers*."
see(`function seq1`)
shared Parser<{Item*}> seq<Item>({Parser<{Item*}>+} parsers, String name_ = "")
        => object satisfies Parser<{Item*}> {
    
    name = chooseName(name_, computeParserName(parsers, "->"));
            
    shared actual ParseOutcome<{Item*}> doParse(
        CharacterConsumer consumer) {
        value startPosition = consumer.currentlyParsed();
        variable Parser<{Item*}>? badParser = null;
        function setBadParser(Parser<{Item*}> parser) {
            badParser = parser;
            return null;
        }
        value results = expand({ 
            for (p in parsers)
            if (!is String outcome = p.doParse(consumer))
            then outcome.result else setBadParser(p)
        }.takeWhile((result) => result exists)
                .coalesced).sequence();
        if (exists failedParser = badParser) {
            consumer.moveBackTo(startPosition);
            return failedParser.name;
        } else {
            return ParseResult(results);
        }
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
    name = chooseName(name_, () => delegate.name);
    shared actual ParseOutcome<{Item+}> doParse(
        CharacterConsumer consumer) {
            value startLocation = consumer.currentlyParsed();
            value result = delegate.doParse(consumer);
            if (is ParseResult<Anything> result,
                exists first = result.result.first) {
                return ParseResult({ first }.chain(result.result.rest));
            } else if (is ParseError result) {
                return result;
            } else { // not even one result found
                consumer.moveBackTo(startLocation);
                return name;
            }
        }
    };

"Creates a Parser which attempts to parse input using the first of the given parsers, and in case it fails,
 attempts to use the next parser and so on until there is no more available parsers.
 
 If any Parser fails, the [[com.athaydes.parcey::CharacterConsumer.consumed]] stream from its result is chained to the actual input
 before being passed to the next parser, such that the next parser will 'see' exactly the same input as the previous Parser."
shared Parser<Item> either<Item>({Parser<Item>+} parsers, String name_ = "") {
    return object satisfies Parser<Item> {
        
        name = chooseName(name_, computeParserName(parsers, " or "));
        
        shared actual ParseOutcome<Item> doParse(
            CharacterConsumer consumer) {
            value result = {
                for (p in parsers)
                if (!is String outcome = p.doParse(consumer))
                then outcome else null
            }.filter((item) => item exists).first;
            return if (exists result)
            then result else name;
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

        function computeName()
                => (minOccurrences <= 0 then "many" else "at least ``minOccurrences``")
            + " ``simplePlural("occurrence", minOccurrences)`` of ``parser.name``";

        name = chooseName(name_, computeName);

        shared actual ParseOutcome<{Item*}> doParse(
            CharacterConsumer consumer) {
            value startLocation = consumer.currentlyParsed();
            value results = {
                for (p in parsers) p.doParse(consumer)
             }.takeWhile((result) {
                 return if (!is String result, !result.result.empty)
                 then true else false;
             }).sequence();
             if (results.size < minOccurrences) {
                 consumer.moveBackTo(startLocation);
                 return name;
             } else {
                 return ParseResult(expand {
                     for (r in results) if (!is String r) r.result
                 });
             }
        }
    };
}

"Creates a Parser that applies the given parser only if it succeeds.
 
 In case of failure, this Parser backtracks and returns an empty result."
see (`function many`, `function either`)
shared Parser<{Item*}> option<Item>(Parser<{Item*}> parser) {
    return object satisfies Parser<{Item*}> {
        name = "(option ``parser.name``)";
        shared actual ParseOutcome<{Item*}> doParse(
            CharacterConsumer consumer) {
            value startLocation = consumer.currentlyParsed();
            value result = parser.doParse(consumer);
            switch (result)
            case (is String) {
                consumer.moveBackTo(startLocation);
                return ParseResult({});
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
        name = chooseName(name_, () => "to skip ``parser.name``");
        shared actual ParseOutcome<[]> doParse(
            CharacterConsumer consumer) {
            value result = parser.doParse(consumer);
            switch (result)
            case (is String) {
                return result;
            }
            else {
                return ParseResult([]);
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
