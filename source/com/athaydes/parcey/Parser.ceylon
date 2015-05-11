import com.athaydes.parcey.combinator {
    either,
    parserChain,
    many
}
import com.athaydes.parcey.internal {
    locationAfterParsing,
    parseError,
    chooseName,
    quote,
    asIterable,
    negate
}

"An Object which has consumed a stream of characters."
shared interface HasConsumed {
    "All characters that have been consumed."
    shared formal Character[] consumed;
    
    "All characters that have been consumed but must be 'given back' to any
     consumer that runs after this."
    shared formal Character[] overConsumed;
}

"[Row, Column] of the input that has been parsed."
shared alias ParsedLocation => [Integer, Integer];

"Result of parsing an invalid input."
shared class ParseError(
    shared String message,
    shared actual Character[] consumed,
    shared actual Character[] overConsumed)
        satisfies HasConsumed {
    string = "ParseError { message=``message``, consumed=``consumed``, overConsumed=``overConsumed`` }";
}

"Result of successfully parsing some input."
shared class ParseResult<out Result>(
    "Result of parsing the input."
    shared Result result,
    "Parsed location after parsing the input."
    shared ParsedLocation parseLocation,
    shared actual Character[] consumed,
    shared actual Character[] overConsumed = [])
        satisfies HasConsumed {
    
    string = "ParseResult { result=`` result else "null" ``, parsedLocation=``parseLocation``," +
            " consumed=``consumed``, overConsumed=``overConsumed`` }";
}

"A Parser which can parse a stream of Characters."
shared interface Parser<out Parsed> {
    
    "The name of this Parser. This is used to improve error messages but may be empty."
    shared formal String name;
    
    "Parse the given input. The input is only traversed once by using its iterator.
          The parsedLocation given is used only to keep track of how many characters have been parsed when using
          a chain of parsers."
    see (`function parserChain`)
    shared default ParseResult<Parsed>|ParseError parse(
        {Character*} input,
        ParsedLocation parsedLocation = [0, 0])
            => doParse(input.iterator(), parsedLocation);
    
    "Parses the contents given by the iterator. Normally, [[Parser.parse]] should just
     delegate to this method."
    shared formal ParseResult<Parsed>|ParseError doParse(
        Iterator<Character> input,
        ParsedLocation parsedLocation,
        String? delegateName = null);
}

"Parser that expects an empty stream.
 
 It only succeeds if the input is empty."
shared Parser<[]> eof(String name_ = "")
        => object satisfies Parser<[]> {
    name => chooseName(name_, "EOF");
    shared actual ParseResult<[]>|ParseError doParse(
        Iterator<Character> input,
        ParsedLocation parsedLocation,
        String? delegateName) {
        value first = input.next();
        switch (first)
        case (is Finished) {
            return ParseResult([], parsedLocation, []);
        }
        case (is Character) {
            return parseError(delegateName else name, parsedLocation, [first], []);
        }
    }
};

"Parser for a single Character.
 
 It fails if the input is empty."
shared Parser<Character[]> anyChar(String name_ = "")
        => object satisfies Parser<Character[]> {
    name => chooseName(name_, "any character");
    shared actual ParseResult<Character[]>|ParseError doParse(
        Iterator<Character> input,
        ParsedLocation parsedLocation,
        String? delegateName) {
        value first = input.next();
        if (is Character first) {
            value consumed = [first];
            return ParseResult(consumed, locationAfterParsing(consumed, parsedLocation), consumed);
        }
        return parseError(delegateName else name, parsedLocation, [], []);
    }
};

"All Characters that are considered to be spaces, ie. \" \\f\\t\\r\\n\"."
shared [Character+] spaceChars = [' ', '\f', '\t', '\r', '\n'];

"A space parser. A space is defined by [[spaceChars]]."
shared Parser<Character[]> space(String name = "")
        => oneOf(spaceChars, chooseName(name, "space"));

"A latin letter. Must be one of 'A'..'Z' or 'a'..'z'.
 
 To obtain a parser for letters from specific languages, use combinators as in the following example:
 
     value swedishLetter = either(letter, oneOf('ö', 'ä', 'å', 'Ö', 'Ä', 'Å'));
 "
shared Parser<Character[]> letter(String name = "")
        => either({ oneOf('A'..'Z'), oneOf('a'..'z') },
    chooseName(name, "letter"));

"Parser for one of the given characters.
 
 It fails if the input is empty."
shared Parser<Character[]> oneOf({Character+} chars, String name = "")
        => OneOf(chooseName(name, "one of ``chars``"), true, chars);

"Parser for a single character.
 
 It fails if the input is empty."
shared Parser<Character[]> char(Character char, String name = "")
        => oneOf({ char }, chooseName(name, quote(char)));

"Parser for none of the given characters. It fails if the input is one of the given characters.
 
 It succeeds if the input is empty."
shared Parser<Character[]> noneOf({Character+} chars, String name = "")
        => OneOf(chooseName(name, "none of ``chars``"), false, chars);

"Parser for a single digit (0..9).
 
 It fails if the input is empty."
shared Parser<Character[]> anyDigit(String name = "")
        => OneOf(chooseName(name, "digit"), true, '0'..'9');

"A word parser. A word is defined as a non-empty stream of continuous latin letters."
see (`function letter`)
shared Parser<{String*}> word(String name = "")
        => convertParser(many(letter(), 1, chooseName(name, "word")), String);

"A String parser. A String is defined as a possibly empty stream of Characters
 without any spaces between them."
see (`value spaceChars`)
shared Parser<{String*}> anyString(String name = "")
        => convertParser(many(noneOf(spaceChars), 0, chooseName(name, "any String")), String);

"A String parser which parses only the given string."
shared Parser<String> string(String str, String name_ = "")
        => object satisfies Parser<String> {
    name = chooseName(name_, "string ``quote(str)``");
    shared actual ParseResult<String>|ParseError doParse(
        Iterator<Character> input,
        ParsedLocation parsedLocation,
        String? delegateName) {
        if (str.empty) {
            if (is Character next = input.next()) {
                return parseError(name, parsedLocation, [next], []);
            } else {
                return ParseResult("", parsedLocation, []);
            }
        } else {
            value consumed = StringBuilder();
            for (expected->actual in zipEntries(str, asIterable(input))) {
                consumed.appendCharacter(actual);
                if (actual != expected) {
                    return parseError(delegateName else name,
                        parsedLocation, consumed.sequence(), []);
                }
            }
            return ParseResult(str, locationAfterParsing(consumed, parsedLocation), consumed.sequence());
        }
    }
};

class OneOf(shared actual String name, Boolean includingChars, {Character+} chars)
        satisfies Parser<Character[]> {
    shared actual ParseResult<Character[]>|ParseError doParse(
        Iterator<Character> input,
        ParsedLocation parsedLocation,
        String? delegateName) {
        value first = input.next();
        switch (first)
        case (is Finished) {
            return parseError(delegateName else name, parsedLocation, [], []);
        }
        case (is Character) {
            value consumed = [first];
            value boolFun = includingChars then identity<Boolean> else negate;
            if (boolFun(first in chars)) {
                return ParseResult(consumed, locationAfterParsing(consumed, parsedLocation), consumed);
            }
            return parseError(delegateName else name, parsedLocation, consumed, []);
        }
    }
}

"Given a parser *(p)* and a function T(K) *(f)*, return a new parser which delegates the parsing
 to *p*, using *f* to convert the result from type *K* to *T*."
shared Parser<{To*}> convertParser<From,To>(Parser<From> parser, To(From) converter)
        => object satisfies Parser<{To*}> {
    name = parser.name;
    shared actual ParseResult<{To*}>|ParseError doParse(
        Iterator<Character> input,
        ParsedLocation parsedLocation,
        String? delegateName) {
        value result = parser.doParse(input, parsedLocation);
        switch (result)
        case (is ParseResult<From>) {
            return ParseResult({ converter(result.result) }, result.parseLocation, result.consumed, result.overConsumed);
        }
        case (is ParseError) {
            return parseError(delegateName else name,
                parsedLocation, result.consumed, result.overConsumed);
        }
    }
};

"Converts a Parser of Characters to a String Parser."
see(`function convertParser`)
shared Parser<{String*}> stringParser(Parser<{Character*}> parser)
        => convertParser(parser, String);

shared Result({Arg*}) toOne<Result, Arg>(Result(Arg) fun) {
    return function ({Arg*} args) {
        assert (exists first = args.first);
        return fun(first);
    };
}
