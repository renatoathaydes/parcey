import com.athaydes.parcey.combinator {
    seq1,
    many,
    skip
}
import com.athaydes.parcey.internal {
    asIterable,
    chooseName,
    quote,
    negate
}

"Parser that expects an empty stream.
 
 It only succeeds if the input is empty."
shared Parser<[]> eof(String name = "")
        => mapValueParser(str("", chooseName(name, () => "EOF")),
    ({String+} _) => []);

"Parser for a single Character.
 
 It fails if the input is empty."
shared Parser<{Character+}> anyChar(String name_ = "")
        => object satisfies Parser<{Character+}> {
    name = chooseName(name_, () => "any character");
    shared actual ParseResult<{Character+}> doParse(
        CharacterConsumer consumer) {
        consumer.startParser(name);
        value first = consumer.next();
        if (is Character first) {
            return ParseSuccess({ first });
        } else {
            return consumer.abort();
        }
    }

};

"All Characters that are considered to be spaces, ie. \" \\f\\t\\r\\n\"."
shared [Character+] spaceChars = [' ', '\f', '\t', '\r', '\n'];

"A space parser. A space is defined by [[spaceChars]]."
shared Parser<{Character+}> space(String name = "")
        => oneOf(spaceChars, chooseName(name, () => "space"));

"A space Parser which consumes as many spaces as possible, discarding its results
 and returning an [[Empty]] as a result in case it succeeds."
see(`function space`)
shared Parser<[]> spaces(Integer minOccurrences = 0, String name = "")
        => skip(many(space(), minOccurrences), chooseName(name, () => "spaces"));

"A latin letter. Must be one of 'A'..'Z' or 'a'..'z'.
 
 To obtain a parser for letters from specific languages, use combinators as in the following example:
 
     value swedishLetter = either(letter, oneOf('ö', 'ä', 'å', 'Ö', 'Ä', 'Å'));
 "
shared Parser<{Character+}> letter(String name = "")
        => oneOf(('A'..'Z').chain('a'..'z'), chooseName(name, () => "letter"));

"Parser for one of the given characters.
 
 It fails if the input is empty."
shared Parser<{Character+}> oneOf({Character+} chars, String name = "")
        => OneOf(chooseName(name, () => "one of ``chars``"), true, chars);

"Parser for a single character.
 
 It fails if the input is empty."
shared Parser<{Character+}> char(Character char, String name_ = "")
        => object satisfies Parser<{Character+}> {
            name = chooseName(name_, () => char.string);
            
            value goodResult = ParseSuccess({ char });
            
            shared actual ParseResult<{Character+}> doParse(CharacterConsumer consumer) {
                consumer.startParser(name);
                if (is Character next = consumer.next(), next == char) {
                    return goodResult;
                } else {
                    return consumer.abort();
                }
            }
            
};

"Parser for a sequence of characters.
 
 This parser is similar to the [[str]] parser, but returns a sequence
 of Characters instead of a String and does not accept empty Strings."
see(`function char`, `function str`)
shared Parser<{Character+}> chars({Character+} characters, String name = "")
        => seq1(characters.map(char));

"Parser for none of the given characters. It fails if the input is one of the given characters.
 
 It fails if the input is empty."
shared Parser<{Character+}> noneOf({Character+} chars, String name = "")
        => OneOf(chooseName(name, () => "none of ``chars``"), false, chars);

"Parser for a single digit (as defined by [[Character.digit]]).
 
 It fails if the input is empty."
shared Parser<{Character+}> digit(String name_ = "")
        => object satisfies Parser<{Character+}> {
    name = chooseName(name_, () => "digit");
    
    shared actual ParseResult<{Character+}> doParse(CharacterConsumer consumer) {
        consumer.startParser(name);
        if (is Character next = consumer.next(), next.digit) {
            return ParseSuccess({ next });
        } else {
            return consumer.abort();
        }
    }
    
};

"A word parser. A word is defined as a non-empty stream of continuous latin letters."
see (`function letter`)
shared Parser<{String+}> word(String name = "")
        => strParser(many(letter(), 1, chooseName(name, () => "word")));

"A String parser. A String is defined as a possibly empty stream of Characters
 without any spaces between them."
see (`value spaceChars`)
shared Parser<{String+}> anyStr(String name = "")
        => strParser(many(noneOf(spaceChars), 0, chooseName(name, () => "any String")));

"A String parser which parses only the given string."
shared Parser<{String+}> str(String text, String name_ = "")
        => object satisfies Parser<{String+}> {
    name = chooseName(name_, () => "string ``quote(text)``");
    
    value goodResult = ParseSuccess({ text });
    
    shared actual ParseResult<{String+}> doParse(
        CharacterConsumer consumer) {
        consumer.startParser(name);
        if (text.empty) {
            if (is Character next = consumer.next()) {
                return consumer.abort();
            } else {
                return goodResult;
            }
        } else {
            for (expected->actual in zipEntries(text, asIterable(consumer))) {
                if (actual != expected) {
                    return consumer.abort();
                }
            }
            if (consumer.consumedByLatestParser < text.size) {
                return consumer.abort();
            } else {
                return goodResult;
            }
        }
    }
    
};

"An Integer Parser.
 
 The expected input format is given by this regular expression: `([+-])?d+`. 
 
 Upon parsing some input, a [[ParseError]] is returned:
 
 * if not even one digit is found.
 * if the sequence of digits cannot be represented as a Ceylon Integer due to overflow."
see (`function mapValueParser`)
shared Parser<{Integer+}> integer(String name_ = "") {
    return object satisfies Parser<{Integer+}> {
        name = chooseName(name_, () => "integer");
        
        function validDigit(Character c)
                => '0' <= c <= '9';
        
        function asInteger(Character? c, Boolean negative)
                => (negative then -1 else 1) * ((c?.integer else '0'.integer) - 48);
        
        shared actual ParseResult<{Integer+}> doParse(
            CharacterConsumer consumer) {
            consumer.startParser(name);
            value first = consumer.next();
            Boolean hasSign;
            Boolean negative;
            value digits = StringBuilder();
            if (is Character first) {
                value digit = validDigit(first);
                hasSign = first in ['+', '-'];
                if (digit || hasSign) {
                    negative = (first == '-');
                    if (!hasSign) {
                        digits.appendCharacter(first);
                    }
                } else {
                    return consumer.abort();
                }
            } else {
                return consumer.abort();
            }
            value maxConsumeLength = runtime.maxIntegerValue.string.size +
                    (hasSign then 1 else 0);
            for (next in asIterable(consumer)) {
                if (validDigit(next)) {
                    if (digits.size >= maxConsumeLength) {
                        return consumer.abort();
                    }
                    digits.appendCharacter(next);
                } else {
                    consumer.takeBack(1);
                    break;
                }
            }
            if (digits.empty) {
                return consumer.abort();
            }
            variable Integer result = 0;
            value overflowGuard = negative
                then Integer.largerThan
                else Integer.smallerThan;
            while (!digits.empty) {
                value current = result;
                value exponent = digits.size - 1;
                result += asInteger(digits.first, negative)
                        * 10^exponent;
                if (overflowGuard(result)(current)) {
                    return consumer.abort();
                }
                digits.deleteInitial(1);
            }
            return ParseSuccess({ result });
        }
    };
}

class OneOf(shared actual String name, Boolean includingChars, {Character+} chars)
        satisfies Parser<{Character+}> {
    shared actual ParseResult<{Character+}> doParse(
        CharacterConsumer consumer) {
        consumer.startParser(name);
        value first = consumer.next();
        switch (first)
        case (is Finished) {
            return consumer.abort();
        }
        case (is Character) {
            value boolFun = includingChars then identity<Boolean> else negate;
            if (!boolFun(first in chars)) {
                return consumer.abort();
            } else {
                return ParseSuccess({ first });
            }
        }
    }
    
}
