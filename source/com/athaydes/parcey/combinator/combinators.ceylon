import com.athaydes.parcey {
    Parser,
    ParseSuccess,
    ParseError,
    CharacterConsumer,
    ParseResult,
    ErrorMessage
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
see(`function nonEmptySequenceOf`)
shared Parser<{Item*}> sequenceOf<Item>({Parser<{Item*}>+} parsers, String name_ = "")
        => object satisfies Parser<{Item*}> {
    
    name = chooseName(name_, computeParserName(parsers, "->"));
            
    shared actual ParseResult<{Item*}> doParse(
        CharacterConsumer consumer) {
        value startPosition = consumer.currentlyParsed();
        variable Parser<{Item*}>? badParser = null;
        function setBadParser(Parser<{Item*}> parser) {
            badParser = parser;
            return null;
        }
        value results = expand({ 
            for (p in parsers)
            if (!is ErrorMessage outcome = p.doParse(consumer))
            then outcome.result else setBadParser(p)
        }.takeWhile((result) => result exists)
                .coalesced).sequence();
        if (exists failedParser = badParser) {
            consumer.moveBackTo(startPosition);
            return failedParser.name;
        } else {
            return ParseSuccess(results);
        }
    }
    
};

"Creates a Parser that applies each of the given parsers in sequence, ensuring at least
 one [[Item]] is returned in the result.
 
 If any of the parsers fails, the chain is broken and a [[com.athaydes.parcey::ParseError]]
 is returned immediately."
see(`function sequenceOf`)
shared Parser<{Item+}> nonEmptySequenceOf<Item>({Parser<{Item*}>+} parsers, String name_ = "")
        => object satisfies Parser<{Item+}> {
    value delegate = sequenceOf(parsers);
    name = chooseName(name_, () => delegate.name);
    shared actual ParseResult<{Item+}> doParse(
        CharacterConsumer consumer) {
            value startLocation = consumer.currentlyParsed();
            value result = delegate.doParse(consumer);
            if (is ParseSuccess<Anything> result,
                exists first = result.result.first) {
                return ParseSuccess({ first }.chain(result.result.rest));
            } else if (is ErrorMessage result) {
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
        
        shared actual ParseResult<Item> doParse(
            CharacterConsumer consumer) {
            value result = {
                for (p in parsers)
                if (!is ErrorMessage outcome = p.doParse(consumer))
                then outcome else null
            }.filter((item) => item exists).first;
            if (exists result) {
                consumer.clearError();
                return result;
            } else {
                return name;
            }
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

        shared actual ParseResult<{Item*}> doParse(
            CharacterConsumer consumer) {
            value startLocation = consumer.currentlyParsed();
            value results = {
                for (p in parsers) p.doParse(consumer)
             }.takeWhile((result) {
                 return if (!is ErrorMessage result, !result.result.empty)
                 then true else false;
             }).sequence();
             if (results.size < minOccurrences) {
                 consumer.moveBackTo(startLocation);
                 return name;
             } else {
                 consumer.clearError();
                 return ParseSuccess(expand {
                     for (r in results) if (!is ErrorMessage r) r.result
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
        shared actual ParseResult<{Item*}> doParse(
            CharacterConsumer consumer) {
            value startLocation = consumer.currentlyParsed();
            value result = parser.doParse(consumer);
            switch (result)
            case (is ErrorMessage) {
                consumer.moveBackTo(startLocation);
                consumer.clearError();
                return ParseSuccess({});
            }
            else {
                return result;
            }
        }
    };
}

"Creates a Parser that applies the given parser multiple times, using the *skipped* separator parser
 in between applications, as many times as possible, discarding the separator.
 
 For example, the following Parser will parse zero or more Integers separated by a comma
 and optional spaces:
 
     separatedBy(around(spaces(), character(',')), integer());
     
 The [[minOcurrences|minOccurrences]] argument may specify the minimum number of times the given
 parser must succeed.
 
 Notice that if `minOccurrences <= 1`, then no separator is required in the input
 for this Parser to succeed.
 
 For example, given the following Parser:
 
     separatedBy(character(':'), anyCharacter(), 1);
     
 The following are valid inputs:
 
 * a
 * b:c:d"
see(`function separatedWith`)
shared Parser<{Item*}> separatedBy<Item>(
    Parser<Anything> separator,
    Parser<{Item*}> parser,
    Integer minOccurrences = 0,
    String name = "") {
    function optionalIf(Boolean condition)
            => condition then option<Item> else identity<Parser<{Item*}>>;
    
    return optionalIf(minOccurrences <= 0)(sequenceOf({
        parser,
        optionalIf(minOccurrences == 1)(
            many(sequenceOf { skip(separator), parser }, minOccurrences - 1))
    }, name));
}

"Creates a Parser that applies the given parser multiple times, using the separator parser
 in between applications, as many times as possible, keeping the separator in the result.
 
 For example, the following Parser will parse zero or more Integers separated by a comma
 and optional spaces:
 
     separatedWith(around(spaces(), character(',')), integer());
     
 The [[minOcurrences|minOccurrences]] argument may specify the minimum number of times the given
 parser must succeed.
 
 Notice that if `minOccurrences <= 1`, then no separator is required in the input
 for this Parser to succeed.
 
 For example, given the following Parser:
 
     separatedWith(character(':'), anyCharacter(), 1);
     
 The following are valid inputs:
 
 * a
 * b:c:d"
see(`function separatedBy`)
shared Parser<{Item|Sep*}> separatedWith<Item, Sep>(
    Parser<{Sep*}> separator,
    Parser<{Item*}> parser,
    Integer minOccurrences = 0,
    String name = "") {
    alias Val => Item|Sep;
    function optionalIf(Boolean condition) {
        return condition then option<Val> else identity<Parser<{Val*}>>;
    }
    return optionalIf(minOccurrences <= 0)(sequenceOf({
        parser,
        optionalIf(minOccurrences == 1)(
            many(sequenceOf { separator, parser }, minOccurrences - 1))
    }, name));
}

"Creates a Parser that applies the given parsers but throws away their results,
 returning an [[Empty]] as its result if the parser succeeds."
see (`function many`, `function either`)
shared Parser<[]> skip(Parser<Anything> parser, String name_ = "") {
    return object satisfies Parser<[]> {
        name = chooseName(name_, () => "to skip ``parser.name``");
        shared actual ParseResult<[]> doParse(
            CharacterConsumer consumer) {
            value result = parser.doParse(consumer);
            switch (result)
            case (is ErrorMessage) {
                return result;
            }
            else {
                return ParseSuccess([]);
            }
        }
    };
}

"Surrounds the given parser with the [[surrounding]] parser.
 
 Example of Parser that parses words separated by commas and optional spaces:
 
     separatedBy(around(spaces(), character(',')), word());"
see(`function separatedBy`)
shared Parser<{Item*}> around<Item>(Parser<{Item*}> surrounding, Parser<{Item*}> parser)
        => sequenceOf { surrounding, parser, surrounding };

"Surrounds the given parser with [[leftBracket]] and [[rightBracket]] parsers,
 discarding their results.
 
 This example parses word enclosed in parentheses, returning the word only:
 
     bracket(word(), character('('), character(')'))"
see(`function around`)
see(`function separatedBy`)
shared Parser<{Item*}> bracket<Item>(
	Parser<{Item*}> parser,
	Parser<{Item*}> leftBracket,
	Parser<{Item*}> rightBracket)
		=> sequenceOf { skip(leftBracket), parser, skip(rightBracket) };
