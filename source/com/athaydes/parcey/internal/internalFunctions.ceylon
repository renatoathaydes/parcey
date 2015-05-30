import com.athaydes.parcey {
    ParsedLocation,
    CharacterConsumer,
    ParseError
}

shared {Character*} asIterable(CharacterConsumer consumer)
        => object satisfies {Character*} {
    iterator() => object satisfies Iterator<Character> {
        next = consumer.next;
    };
};

String inBrackets(String text)
        => if (text.startsWith("(") &&
    text.endsWith(")")) then text else "(``text``)";

shared String chooseName(String name, String default)
        => inBrackets(name.empty then default else name);

String unexpected(CharacterConsumer consumer) {
    value next = String(asIterable(consumer).take(10));
    value end = consumer.next() is Finished then "" else "...";
    return quote(next + end);
}

shared ParseError parseError(CharacterConsumer consumer, String name) {
    value message = "(``readableLocation(consumer.location())``)
                     Unexpected ``unexpected(consumer)``
                     Expecting ``name``";
    return ParseError(message, consumer.location());
}

shared String quote(Anything s)
        => if (is Object s) then "'``s``'" else "nothing";

shared Boolean negate(Boolean b)
        => !b;

"Returns a String showing the location with 1-based indexes."
shared String readableLocation(ParsedLocation parsedLocation)
        => "line ``parsedLocation[0]``, column ``parsedLocation[1]``";

shared String simplePlural(String word, Integer count)
        => word + (count != 1 then "s" else "");
