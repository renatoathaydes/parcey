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
        => "(``name.empty then default else name``)";

shared ParseError parseError(
    String errorMessage,
    {Character*} consumed,
    ParsedLocation parsedLocation)
        => ParseError(() => "``errorMessage`` at ``location(locationAfterParsing(consumed, parsedLocation))``", consumed);

shared ParseResult<Item> appendStreams<Item>(
    ParseResult<Item> first,
    ParseResult<Anything> second)
        => ParseResult(
        first.result,
        second.parseLocation,
        first.consumed.chain(second.consumed));

shared ParseResult<{Item*}> append<Item>(
    ParseResult<{Item*}> first,
    ParseResult<{Item*}> second,
    Boolean appendOverconsumed,
    ParsedLocation? newLocation = null)
        => ParseResult(
        first.result.chain(second.result),
        newLocation else second.parseLocation,
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
shared String location(ParsedLocation parsedLocation)
        => "row ``parsedLocation[0] + 1``, column ``parsedLocation[1]``";

shared ParsedLocation addColumnsToLocation(Integer columns, ParsedLocation location)
        => [location[0], location[1] + columns];

shared ParsedLocation addLocations(ParsedLocation first, ParsedLocation second)
        => [first[0] + second[0], first[1] + second[1]];

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
