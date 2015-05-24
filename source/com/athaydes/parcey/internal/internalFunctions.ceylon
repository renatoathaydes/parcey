import com.athaydes.parcey {
    ParsedLocation,
    ParseError,
    ParseResult,
    Parser
}

shared {T*} asIterable<T>(Iterator<T> iter)
        => object satisfies {T*} {
    iterator() => iter;
};

shared String chooseName(String name, String default)
        => "(``name.empty then default else name``)";

String unexpected(Iterator<Character> input, {Character*} consumed) {
    value last = consumed.last?.string else "";
    value next = String(asIterable(input).take(10));
    return "``quote(last)`` in ``quote(last + next)``";
}

shared ParseError parseError(
    Iterator<Character> iterator,
    Parser<Anything> parser,
    {Character*} consumed) {
        value location = locationAfterParsing(consumed);
        return ParseError(()
            => "``readableLocation(location)``
                Unexpected ``unexpected(iterator, consumed)``
                Expecting ``parser.name``", consumed, location);
    }

shared ParseResult<{Item*}> append<Item>(
    ParseResult<{Item*}> first,
    ParseResult<{Item*}> second,
    Boolean appendOverconsumed)
        => ParseResult(
        first.result.chain(second.result),
        first.consumed.chain(second.consumed),
        appendOverconsumed then first.overConsumed.chain(second.overConsumed) else second.overConsumed);

shared Iterator<Character> chain({Character*} consumed, Iterator<Character> rest)
        => object satisfies Iterator<Character> {
    
    value firstIter = consumed.iterator();
    
    shared actual Character|Finished next()
            => if (is Character item = firstIter.next()) then item else rest.next();
};

shared String quote(Anything s)
        => if (is Object s) then "'``s``'" else "nothing";

shared Boolean negate(Boolean b)
        => !b;

"Returns a String showing the location with 1-based indexes."
shared String readableLocation(ParsedLocation parsedLocation)
        => "line ``parsedLocation[0]``, column ``parsedLocation[1]``";

shared ParsedLocation addColumnsToLocation(Integer columns, ParsedLocation location)
        => [location[0], location[1] + columns];

shared ParsedLocation addLocations(ParsedLocation first, ParsedLocation second)
        => [first[0] + second[0], first[1] + second[1]];

shared ParsedLocation locationAfterParsing({Character*} consumed) {
    variable Integer row = 1;
    variable Integer column = 0;
    for (char in consumed) {
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
