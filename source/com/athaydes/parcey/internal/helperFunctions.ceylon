import com.athaydes.parcey {
    ParsedLocation,
    ParseError,
    ParseResult
}

shared {T*} asIterable<T>(Iterator<T> iter)
        => object satisfies {T*} {
    iterator() => iter;
};

shared String chooseName(String name, String default)
        => name.empty then default else name;

shared ParseError parseError(
    String parserName,
    ParsedLocation parsedLocation,
    Character[] consumed,
    Character[] overConsumed)
        => ParseError("Expected ``parserName`` but found ``quote(String(overConsumed))`` at ``location(parsedLocation)``",
        consumed, overConsumed);

shared ParseResult<Item> appendStreams<Item>(
    ParseResult<Item> first,
    ParseResult<Anything> second)
        => ParseResult(
        first.result,
        second.parseLocation,
        first.consumed.append(second.consumed));

shared ParseResult<{Item*}> append<Item>(
    ParseResult<{Item*}> first,
    ParseResult<{Item*}> second,
    Boolean appendConsumedStreams)
        => ParseResult(
        first.result.chain(second.result),
        second.parseLocation,
        appendConsumedStreams then first.consumed.append(second.consumed) else second.consumed,
        second.overConsumed);

shared Iterator<Character> chain(Character[] consumed, Iterator<Character> rest)
        => object satisfies Iterator<Character> {
    
    value firstIter = consumed.iterator();
    
    shared actual Character|Finished next()
            => if (is Character item = firstIter.next()) then item else rest.next();
};

shared String quote(Anything s)
        => if (is Object s) then "'``s``'" else "nothing";

shared Boolean negate(Boolean b)
        => !b;

shared String location(ParsedLocation parsedLocation)
        => "row ``parsedLocation[0]``, column ``parsedLocation[1]``";

shared ParsedLocation locationAfterParsing({Character*} parsed, ParsedLocation parsedLocation) {
    variable Integer row = parsedLocation[0];
    variable Integer column = parsedLocation[1];
    for (char in parsed) {
        if (char == '\n') {
            row++;
            column = 0;
        } else {
            column++;
        }
    }
    return [row, column];
}

shared String simplePlural(String word, Integer count)
        => word + (count != 1 then "s" else "");
