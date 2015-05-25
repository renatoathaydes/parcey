import com.athaydes.parcey.combinator {
    either,
    seq,
    many,
    skip,
    seq1
}
import com.athaydes.parcey.internal {
    parseError,
    chooseName,
    quote,
    asIterable,
    negate
}

"An Object which has consumed a stream of characters."
shared interface HasConsumed {
    "All characters that have been consumed."
    shared formal {Character*} consumed;
    
    shared actual default String string {
       value partial = consumed.take(500);
       value tookAll = (partial.size == 500);
       return String(partial.chain(tookAll then "" else "..."));
    }

}

"[Row, Column] of the input that has been parsed."
shared alias ParsedLocation => [Integer, Integer];

"Result of parsing an invalid input."
shared final class ParseError(
    shared String() message,
    shared actual {Character*} consumed,
    shared ParsedLocation location)
        satisfies HasConsumed {
    string => "ParseError { message=``message()``, consumed=``super.string``" +
            " location=``location``";
}

"Result of successfully parsing some input."
shared final class ParseResult<out Result>(
    "Result of parsing the input."
    shared Result result,
    shared actual {Character*} consumed,
    "All characters that have been consumed but must be 'given back' to any
     consumer that runs after this."
    shared {Character*} overConsumed = {})
        satisfies HasConsumed {
    
    string => "ParseResult { result=`` result else "null" ``," +
            " consumed=``super.string``, overConsumed=``overConsumed`` }";
}

"A Parser which can parse a stream of Characters."
shared interface Parser<out Parsed> {
    
    "The name of this Parser. This is used to improve error messages but may be empty."
    shared formal String name;
    
    "Parse the given input. The input is only traversed once by using its iterator.
          The parsedLocation given is used only to keep track of how many characters have been parsed when using
          a chain of parsers."
    see (`function seq`)
    shared default ParseResult<Parsed>|ParseError parse(
        {Character*} input)
            => doParse(input.iterator(), {});
    
    "Parses the contents given by the iterator. Normally, [[Parser.parse]] should just
     delegate to this method."
    shared formal ParseResult<Parsed>|ParseError doParse(
        Iterator<Character> input,
        {Character*} consumed);
}

"Parser that expects an empty stream.
 
 It only succeeds if the input is empty."
shared Parser<[]> eof(String name = "")
        => mapValueParser(str("", chooseName(name, "EOF")),
    ({String+} _) => []);

"Parser for a single Character.
 
 It fails if the input is empty."
shared Parser<{Character+}> anyChar(String name_ = "")
        => object satisfies Parser<{Character+}> {
    name => chooseName(name_, "any character");
    shared actual ParseResult<{Character+}>|ParseError doParse(
        Iterator<Character> input,
        {Character*} consumed) {
        value first = input.next();
        if (is Character first) {
            value result = { first };
            return ParseResult(result, consumed.chain(result), {});
        }
        return parseError(input, this, consumed, {});
    }
};

"All Characters that are considered to be spaces, ie. \" \\f\\t\\r\\n\"."
shared [Character+] spaceChars = [' ', '\f', '\t', '\r', '\n'];

"A space parser. A space is defined by [[spaceChars]]."
shared Parser<{Character+}> space(String name = "")
        => oneOf(spaceChars, chooseName(name, "space"));

"A space Parser which consumes as many spaces as possible, discarding its results
 and returning an [[Empty]] as a result in case it succeeds."
see(`function space`)
shared Parser<[]> spaces(Integer minOccurrences = 0, String name = "")
        => skip(many(space(), minOccurrences), name);

"A latin letter. Must be one of 'A'..'Z' or 'a'..'z'.
 
 To obtain a parser for letters from specific languages, use combinators as in the following example:
 
     value swedishLetter = either(letter, oneOf('ö', 'ä', 'å', 'Ö', 'Ä', 'Å'));
 "
shared Parser<{Character+}> letter(String name = "")
        => either({ oneOf('A'..'Z'), oneOf('a'..'z') },
    chooseName(name, "letter"));

"Parser for one of the given characters.
 
 It fails if the input is empty."
shared Parser<{Character+}> oneOf({Character+} chars, String name = "")
        => OneOf(chooseName(name, "one of ``chars``"), true, chars);

"Parser for a single character.
 
 It fails if the input is empty."
shared Parser<{Character+}> char(Character char, String name = "")
        => OneOf(chooseName(name, quote(char)), true, { char });

"Parser for a sequence of characters.
 
 This parser is similar to the [[str]] parser, but returns a sequence
 of Characters instead of a String and does not accept empty Strings."
see(`function char`, `function str`)
shared Parser<{Character+}> chars({Character+} chars, String name = "")
        => seq1(chars.map(char));

"Parser for none of the given characters. It fails if the input is one of the given characters.
 
 It succeeds if the input is empty."
shared Parser<{Character+}> noneOf({Character+} chars, String name = "")
        => OneOf(chooseName(name, "none of ``chars``"), false, chars);

"Parser for a single digit (0..9).
 
 It fails if the input is empty."
shared Parser<{Character+}> digit(String name = "")
        => OneOf(chooseName(name, "digit"), true, '0'..'9');

"A word parser. A word is defined as a non-empty stream of continuous latin letters."
see (`function letter`)
shared Parser<{String+}> word(String name = "")
        => strParser(many(letter(), 1, chooseName(name, "word")));

"A String parser. A String is defined as a possibly empty stream of Characters
 without any spaces between them."
see (`value spaceChars`)
shared Parser<{String+}> anyStr(String name = "")
        => strParser(many(noneOf(spaceChars), 0, chooseName(name, "any String")));

"A String parser which parses only the given string."
shared Parser<{String+}> str(String text, String name_ = "")
        => object satisfies Parser<{String+}> {
    name = chooseName(name_, "string ``quote(text)``");
    shared actual ParseResult<{String+}>|ParseError doParse(
        Iterator<Character> input,
        {Character*} consumed) {
        if (text.empty) {
            if (is Character next = input.next()) {
                return parseError(input, this, consumed, { next });
            } else {
                return ParseResult({ text }, consumed, {});
            }
        } else {
            value consuming = StringBuilder();
            function fail() => parseError(input, this, consumed, consuming);
            for (expected->actual in zipEntries(text, asIterable(input))) {
                consuming.appendCharacter(actual);
                if (actual != expected) {
                    return fail();
                }
            }
            if (consuming.size < text.size) {
                return fail();
            }
            return ParseResult({ text }, consumed.chain(consuming), {});
        }
    }
};

"An Integer Parser.
 
 The expected input format is given by this regular expression: `([+-])?d+`. 
 
 Upon parsing some input, a [[ParseError]] is returned:
 
 * if not even one digit is found.
 * if the sequence of digits cannot be represented as an Integer due to overflow."
see (`function mapValueParser`)
shared Parser<{Integer+}> integer(String name_ = "") {
    return object satisfies Parser<{Integer+}> {
        name => chooseName(name_, "integer");
        
        function validFirst(Character c)
                => c.digit || c in ['+', '-'];
        
        function asInteger(Character c, Boolean negative)
                => (negative then -1 else 1) * (c.integer - 48);
        
        shared actual ParseResult<{Integer+}>|ParseError doParse(
            Iterator<Character> input,
            {Character*} consumed) {
            value first = input.next();
            Boolean hasSign;
            Boolean negative;
            value consuming = StringBuilder();
            if (is Character first) {
                consuming.appendCharacter(first);
                if (validFirst(first)) {
                    hasSign = !first.digit;
                    negative = hasSign && first == '-';
                } else {
                    return parseError(input, this, consumed, { first });
                }
            } else {
                return parseError(input, this, consumed, {});
            }
            value maxConsumeLength = runtime.maxIntegerValue.string.size +
                    (hasSign then 1 else 0);
            variable Character[] overConsumed = [];
            for (next in asIterable(input)) {
                if (next.digit) {
                    consuming.appendCharacter(next);
                    if (consuming.size > maxConsumeLength) {
                        return parseError(input, this, consumed, consuming);
                    }
                } else {
                    overConsumed = [next];
                    break;
                }
            }
            value digits = hasSign then consuming.rest else consuming;
            if (digits.empty) {
                return parseError(input, this, consumed, consuming);
            }
            variable Integer result = 0;
            value overflowGuard = negative
                    then Integer.largerThan else Integer.smallerThan;
            for (exponent->next in digits.reversed.indexed) {
                value current = result;
                result += asInteger(next, negative) * 10^exponent;
                if (overflowGuard(result)(current)) {
                    return parseError(input, this, consumed, consuming);
                }
            }
            return ParseResult({ result },
                consumed.chain(consuming), overConsumed);
        }
    };
}

class OneOf(shared actual String name, Boolean includingChars, {Character+} chars)
        satisfies Parser<{Character+}> {
    shared actual ParseResult<{Character+}>|ParseError doParse(
        Iterator<Character> input,
        {Character*} consumed) {
        value first = input.next();
        switch (first)
        case (is Finished) {
            return parseError(input, this, consumed, {});
        }
        case (is Character) {
            value consuming = { first };
            value boolFun = includingChars then identity<Boolean> else negate;
            if (boolFun(first in chars)) {
                return ParseResult(consuming, consumed.chain(consuming));
            }
            return parseError(input, this, consumed, consuming);
        }
    }
}
