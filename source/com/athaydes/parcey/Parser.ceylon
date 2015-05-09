import com.athaydes.parcey.combinator {
    either,
    parserChain,
    many
}

"An Object which has consumed a stream of characters."
shared interface HasConsumed {
    "All characters that have been consumed."
    shared formal Character[] consumed;
}

"[Row, Column] of the input that has been parsed."
shared alias ParsedLocation => [Integer, Integer];

"Result of parsing an invalid input."
shared class ParseError(
    shared String message,
    shared actual Character[] consumed)
        satisfies HasConsumed {
    string = "ParseError { message=``message``, consumed=``consumed`` }";
}

"Result of successfully parsing some input."
shared class ParseResult<out Result>(
    "Result of parsing the input."
    shared Result result,
    "Parsed location after parsing the input."
    shared ParsedLocation parseLocation,
    shared actual Character[] consumed,
    shared Character[] overConsumed = [])
        satisfies HasConsumed {
    
    string = "ParseResult { result=`` result else "null" ``, parsedLocation=``parseLocation``," +
            " consumed=``consumed`` }";
}

"A Parser which can parse a stream of Characters."
shared interface Parser<out Parsed> {
    
    doc ("Parse the given input. The input is only traversed once by using its iterator.
          The parsedLocation given is used only to keep track of how many characters have been parsed when using
          a chain of parsers.")
    see (`function parserChain`)
    shared default ParseResult<Parsed>|ParseError parse({Character*} input, ParsedLocation parsedLocation = [0, 0])
            => doParse(input.iterator(), parsedLocation);
    
    "Parses the contents given by the iterator. Normally, [[Parser.parse]] should just
     delegate to this method."
    shared formal ParseResult<Parsed>|ParseError doParse(Iterator<Character> input, ParsedLocation parsedLocation);
}

"Parser that expects an empty stream.
 
 It only succeeds if the input is empty."
shared object eof satisfies Parser<[]> {
    shared actual ParseResult<[]>|ParseError doParse(Iterator<Character> input, ParsedLocation parsedLocation) {
        value first = input.next();
        switch (first)
        case (is Finished) {
            return ParseResult([], parsedLocation, []);
        }
        case (is Character) {
            return ParseError("Expected '' but found ``first`` at ``location(parsedLocation)``", [first]);
        }
    }
}

"Parser for a single Character.
 
 It fails if the input is empty."
shared object anyChar satisfies Parser<Character[]> {
    shared actual ParseResult<Character[]>|ParseError doParse(Iterator<Character> input, ParsedLocation parsedLocation) {
        value first = input.next();
        if (is Character first) {
            value consumed = [first];
            return ParseResult(consumed, locationAfterParsing(consumed, parsedLocation), consumed);
        }
        return ParseError("Expected a char but found nothing at ``location(parsedLocation)``", []);
    }
}

"All Characters that are considered to be spaces, ie. \" \\f\\t\\r\\n\"."
shared [Character+] spaceChars = [' ', '\f', '\t', '\r', '\n'];

"A space parser. A space is defined by [[spaceChars]]."
shared Parser<Character[]> space = oneOf(*spaceChars);

"A latin letter. Must be one of 'A'..'Z' or 'a'..'z'.
 
 To obtain a parser for letters from specific languages, use combinators as in the following example:
 
     value swedishLetter = either(letter, oneOf('ö', 'ä', 'å', 'Ö', 'Ä', 'Å'));
 "
shared Parser<Character[]> letter
        = either(oneOf(*('A'..'Z')), oneOf(*('a'..'z')));

"Parser for one of the given characters.
 
 It fails if the input is empty."
shared Parser<Character[]> oneOf(Character+ chars)
        => OneOf(true, *chars);

"Parser for a single character.
 
 It fails if the input is empty."
shared Parser<Character[]> char(Character char)
        => oneOf(char);

"Parser for none of the given characters. It fails if the input is one of the given characters.
 
 It succeeds if the input is empty."
shared Parser<Character[]> noneOf(Character+ chars)
        => OneOf(false, *chars);

"Parser for a single digit (0..9).
 
 It fails if the input is empty."
shared Parser<Character[]> anyDigit
        = OneOf(true, *('0'..'9'));

"A word parser. A word is defined as a non-empty stream of continuous latin letters."
see(`value letter`)
shared Parser<String> word
        = convertParser(many(letter, 1), String);

"A String parser. A String is defined as a possibly empty stream of Characters
 without any spaces between them."
see (`value spaceChars`)
shared Parser<String> anyString
        = convertParser(many(noneOf(*spaceChars)), String);

"A String parser which parses only the given string."
shared Parser<String> string(String str)
        => object satisfies Parser<String> {
    shared actual ParseResult<String>|ParseError doParse(Iterator<Character> input, ParsedLocation parsedLocation) {
        if (str.empty) {
            if (is Character next = input.next()) {
                return ParseError("Expected '' but found '``next``' at ``location(parsedLocation)``", [next]);
            } else {
                return ParseResult("", parsedLocation, []);
            }
        } else {
            value consumed = StringBuilder();
            for (actual->expected in zipEntries(asIterable(input), str)) {
                consumed.appendCharacter(actual);
                if (actual != expected) {
                    return ParseError("Expected '``str``' but found '``consumed``' at ``location(parsedLocation)``", consumed.sequence());
                }
            }
            return ParseResult(str, locationAfterParsing(consumed, parsedLocation), consumed.sequence());
        }
    }
};

class OneOf(Boolean includingChars, Character+ chars) satisfies Parser<Character[]> {
    
    String expected = if (includingChars)
    then (if (chars.size == 1) then quote(chars.first) else "one of ``quote(chars)``")
    else (if (chars.size == 1) then "not ``quote(chars.first)``" else "none of ``quote(chars)``");
    
    shared actual ParseResult<Character[]>|ParseError doParse(Iterator<Character> input, ParsedLocation parsedLocation) {
        value first = input.next();
        switch (first)
        case (is Finished) {
            return ParseError("Expected ``expected`` but found nothing" +
                        " at ``location(parsedLocation)``", []);
        }
        case (is Character) {
            value consumed = [first];
            value boolFun = includingChars then identity<Boolean> else negate;
            if (boolFun(first in chars)) {
                return ParseResult(consumed, locationAfterParsing(consumed, parsedLocation), consumed);
            }
            return ParseError("Expected ``expected`` but found ``quote(first)``" +
                        " at ``location(parsedLocation)``", consumed);
        }
    }
}

String quote(Anything s)
        => if (is Object s) then "'``s``'" else "nothing";

Boolean negate(Boolean b)
        => !b;

String location(ParsedLocation parsedLocation)
        => "row ``parsedLocation[0]``, column ``parsedLocation[1]``";

ParsedLocation locationAfterParsing({Character*} parsed, ParsedLocation parsedLocation) {
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

"Given a `Parser<K>` *(p)* and a function T(K) *(f)*, return a `Parser<T>` which delegates the parsing
 to *p*, using *f* to convert the result from type *K* to *T*."
shared Parser<T> convertParser<K,T>(Parser<K> parser, T(K) converter)
        => object satisfies Parser<T> {
    shared actual ParseResult<T>|ParseError doParse(Iterator<Character> input, ParsedLocation parsedLocation) {
        value result = parser.doParse(input, parsedLocation);
        switch (result)
        case (is ParseResult<K>) {
            return ParseResult(converter(result.result), result.parseLocation, result.consumed, result.overConsumed);
        }
        case (is ParseError) {
            return result;
        }
    }
};

{T*} asIterable<T>(Iterator<T> iter)
        => object satisfies {T*} {
    iterator() => iter;
};
