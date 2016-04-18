import com.athaydes.parcey {
    Parser,
    ParseSuccess,
    CharacterConsumer,
    ParseResult,
    ErrorMessage
}
import com.athaydes.parcey.internal {
    simplePlural
}

"Creates a Parser that applies each of the given parsers in sequence.

 If any of the parsers fails, the chain is broken and a [[com.athaydes.parcey::ParseError]]
 is returned immediately."
see(`function nonEmptySequenceOf`)
shared Parser<{Item*}> sequenceOf<Item>(
    "The parsers that form this sequence."
    {Parser<{Item*}>+} parsers,
    "The name of this sequence of parsers.

     If provided, this will be used in the error message reported by this parser,
     regardless of which of the [[parsers]] caused the error."
    String? name = null)
        => object satisfies Parser<{Item*}> {

    shared actual ParseResult<{Item*}> doParse(
        CharacterConsumer consumer) {
        value startPosition = consumer.currentlyParsed;
        variable {Item*} results = {};

        for (parser in parsers) {
            value outcome = parser.doParse(consumer);
            if (is ErrorMessage outcome) {
                if (exists overrideError = name) {
                    consumer.setErrorAt(startPosition, overrideError);
                    return overrideError;
                } else {
                    return outcome;
                }
            } else {
                results = results.chain(outcome.result);
            }
        }

        return ParseSuccess(results);
    }

};

"Creates a Parser that applies each of the given parsers in sequence, ensuring at least
 one [[Item]] is returned in the result.

 If any of the parsers fails, the chain is broken and a [[com.athaydes.parcey::ParseError]]
 is returned immediately."
see(`function sequenceOf`)
shared Parser<{Item+}> nonEmptySequenceOf<Item>(
    "The parsers that form this sequence."
    {Parser<{Item*}>+} parsers,
    "The name of this sequence of parsers.

     If provided, this will be used in the error message reported by this parser,
     regardless of which of the [[parsers]] caused the error."
    String? name = null)
        => object satisfies Parser<{Item+}> {
    value delegate = sequenceOf(parsers, name);

    shared actual ParseResult<{Item+}> doParse(
        CharacterConsumer consumer) {
            value startLocation = consumer.currentlyParsed;
            value result = delegate.doParse(consumer);
            if (is ParseSuccess<Anything> result,
                exists first = result.result.first) {
                return ParseSuccess({ first }.chain(result.result.rest));
            } else if (is ErrorMessage result) {
                return result;
            } else { // not even one result found
                consumer.moveBackTo(startLocation);
                return name else "nonEmptySequenceOf(result was empty)";
            }
        }
    };

"Creates a Parser which attempts to parse input using the first of the given parsers, and in case it fails,
 attempts to use the next parser and so on until there is no more available parsers.

 If any Parser fails, the [[com.athaydes.parcey::CharacterConsumer.consumed]] stream from its result is chained to the actual input
 before being passed to the next parser, such that the next parser will 'see' exactly the same input as the previous Parser."
shared Parser<Item> either<Item>(
    "The parsers which shall be tried."
    {Parser<Item>+} parsers,
    "The name of this parser combinator.

     If provided, this will be used in the error message reported by this parser,
     regardless of which of the [[parsers]] caused the error."
    String? name = null) {
    return object satisfies Parser<Item> {

        shared actual ParseResult<Item> doParse(
            CharacterConsumer consumer) {
            value startPosition = consumer.currentlyParsed;
            value result = {
                for (p in parsers)
                if (!is ErrorMessage outcome = p.doParse(consumer))
                outcome
            }.first;
            if (exists result) { // success
                consumer.cleanErrorsDeeperThan(startPosition);
                return result;
            } else { // failure
                return name else "either(all options failed)";
            }
        }
    };
}

"Creates a Parser that applies the given [[parser]] as many times as possible without failing,
 returning all results of each application.

 For this Parser to succeed, the given parser must succeed at least [[minOccurrences]] times."
see (`function skip`)
shared Parser<{Item*}> many<Item>(
    "The parser which may occur multiple times."
    Parser<{Item*}> parser,
    "Minimum number of times the [[parser]] must succeed for this Parser to succeed."
    Integer minOccurrences = 0,
    "The name of this parser combinator.

     If provided, this will be used in the error message reported by this parser
     instead of a general error which includes the error reported by the given [[parser]]."
    String? name = null) {

    value parsers = [parser].cycled;

    return object satisfies Parser<{Item*}> {

        function computeName(ErrorMessage error)
                => (minOccurrences <= 0 then "many" else "at least ``minOccurrences``")
                    + " ``simplePlural("occurrence", minOccurrences)`` of ``error``";

        shared actual ParseResult<{Item*}> doParse(
            CharacterConsumer consumer) {
            variable Integer startPosition = consumer.currentlyParsed;

            Anything() updatePosition = if (exists name)
                    then (() => startPosition)
                    else (() => consumer.currentlyParsed);

            value results = {
                for (p in parsers)
                    let (startLocation = updatePosition())
                    p.doParse(consumer)
            }.map((outcome) {
                if (is ErrorMessage outcome) {
                    return [false, outcome];
                } else {
                    return [!outcome.result.empty, outcome.result];
                }
            }).takeWhile((continue_result) => continue_result[0])
              .map((item) => item[1])
              .sequence();

            if (results.size < minOccurrences) { // failure
                if (exists name) {
                    consumer.setErrorAt(startPosition, name);
                    return name;
                } else {
                    return computeName("parsers");
                }
            } else { // success
                consumer.cleanErrorsDeeperThan(startPosition - 1);
                return ParseSuccess(expand {
                    for (r in results) if (!is ErrorMessage r) r
                });
            }

        }
    };
}

"Creates a Parser that applies the given parser only if it succeeds.

 In case of failure, this Parser backtracks and returns an empty result.

 Notice that this Parser never fails."
see (`function many`, `function either`)
shared Parser<{Item*}> option<Item>(
    "The optional parser"
    Parser<{Item*}> parser) {
    return object satisfies Parser<{Item*}> {
        shared actual ParseResult<{Item*}> doParse(
            CharacterConsumer consumer) {
            value startLocation = consumer.currentlyParsed;
            value result = parser.doParse(consumer);
            switch (result)
            case (is ErrorMessage) {
                consumer.moveBackTo(startLocation);
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
    "The parser for the separator"
    Parser<Anything> separator,
    "The parser for the text which should appear interleaved by [[separator]]s."
    Parser<{Item*}> parser,
    "The minimum number of times [[parser]] must succeed for this Parser to succeed."
    Integer minOccurrences = 0,
    "The name of this parser combinator.

     If provided, this will be used in the error message reported by this parser
     instead of a general error which includes the error reported by the given [[parser]]."
    String? name = null) {
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
shared Parser<{Item|Separator*}> separatedWith<Item, Separator>(
    "The parser for the separator"
    Parser<{Separator*}> separator,
    "The parser for the text which should appear interleaved with [[separator]]s."
    Parser<{Item*}> parser,
    "The minimum number of times [[parser]] must succeed for this Parser to succeed."
    Integer minOccurrences = 0,
    "The name of this parser combinator.

     If provided, this will be used in the error message reported by this parser
     instead of a general error containing which includes the error reported by the given [[parser]]."
    String? name = null) {
    alias Val => Item|Separator;
    function optionalIf(Boolean condition) {
        return condition then option<Val> else identity<Parser<{Val*}>>;
    }
    return optionalIf(minOccurrences <= 0)(sequenceOf({
        parser,
        optionalIf(minOccurrences == 1)(
            many(sequenceOf { separator, parser }, minOccurrences - 1))
    }, name));
}

"Creates a Parser that applies the given [[parser]] but throws away their results,
 returning an [[Empty]] as its result if the parser succeeds, or the error returned
 by [[parser]] if it fails."
see (`function many`, `function either`)
shared Parser<[]> skip(
    "The parser whose results should be discarded"
    Parser<Anything> parser,
    "The name of this parser combinator.

     If provided, this will be used in the error message reported by this parser
     instead of the error returned by [[parser]]."
    String? name = null) {
    return object satisfies Parser<[]> {
        shared actual ParseResult<[]> doParse(
            CharacterConsumer consumer) {
            value result = parser.doParse(consumer);
            switch (result)
            case (is ErrorMessage) {
                return name else result;
            }
            else {
                return ParseSuccess([]);
            }
        }
    };
}

"Surrounds the given parser with the [[surrounding]] parser.

 This example uses this Parser to parse words separated by commas and optional spaces:

     separatedBy(around(spaces(), character(',')), word());"
see(`function between`)
see(`function separatedBy`)
shared Parser<{Item*}> around<Item>(
    "The parser that should surround [[parser]]"
    Parser<{Item*}> surrounding,
    "A parser that is expected to be surrounded by [[surrounding]] parsers."
    Parser<{Item*}> parser)
        => sequenceOf { surrounding, parser, surrounding };

"Surrounds the given [[parser]] with [[left]] and [[right]] parsers,
 discarding their results.

 This example parses a word enclosed in parentheses, returning the word only:

     between(character('('), character(')'), word())"
see(`function around`)
see(`function separatedBy`)
shared Parser<{Item*}> between<Item>(
    "The parser to the left of [[parser]]. Its result is discarded."
	Parser<Anything> left,
    "The parser to the right of [[parser]]. Its result is discarded."
	Parser<Anything> right,
    "The parser that should appear between [[left]] and [[right]]"
    Parser<{Item*}> parser)
		=> sequenceOf { skip(left), parser, skip(right) };
