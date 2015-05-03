import com.athaydes.parcey.combinator {
    either,
    parserChain,
    many
}

"An Object which has consumed a stream of characters."
shared interface HasConsumed {
    "All characters that have been successfully consumed.
     
     When a chain of consumers is used, this should include only the input consumed
     by the last consumer in the chain."
    shared formal Character[] consumedOk;
    "All characters that have been consumed but failed to be processed."
    shared formal Character[] consumedFailed;
}

"Result of parsing an invalid input."
shared class ParseError(
    shared String message,
    shared actual Character[] consumedFailed)
        satisfies HasConsumed {
    
    consumedOk = [];
    
    string = "ParseError { message=``message``, consumedFailed=``consumedFailed`` }";
}

"Result of successfully parsing some input."
shared class ParseResult<out Result>(
    "Result of parsing the input."
    shared Result result,
    "Index of the next character that should be parsed from the input stream."
    shared Integer parsedIndex,
    shared actual Character[] consumedOk,
    shared actual Character[] consumedFailed = [])
        satisfies HasConsumed {
    
    string = "ParseResult { result=`` result else "null" ``, parsedIndex=``parsedIndex``," +
            " consumedOk=``consumedOk``, consumedFailed=``consumedFailed`` }";
}

"A Parser which can parse a stream of Characters."
shared interface Parser<out Parsed> {
    
    doc("Parse the given input. The input is only traversed once by using its iterator.
         The parsedIndex given is used only to keep track of how many characters have been parsed when using
         a chain of parsers.")
    see(`function parserChain`)
    shared default ParseResult<Parsed>|ParseError parse({Character*} input, Integer parsedIndex = 0)
            => doParse(input.iterator(), parsedIndex);
    
    "Parses the contents given by the iterator. Normally, [[Parser.parse]] should just
     delegate to this method."
    shared formal ParseResult<Parsed>|ParseError doParse(Iterator<Character> input, Integer parsedIndex);
}

"Parser that expects an empty stream.
 
 It only succeeds if the input is empty."
shared object eof satisfies Parser<String[]> {
    shared actual ParseResult<String[]>|ParseError doParse(Iterator<Character> input, Integer parsedIndex) {
        value first = input.next();
        if (is Finished first) {
            return ParseResult([], parsedIndex, []);
        }
        return ParseError("Expected EOF but found ``first`` at index ``parsedIndex``", []);
    }
}

"Parser for a single Character.
 
 It fails if the input is empty."
shared object char satisfies Parser<String[]> {
    shared actual ParseResult<String[]>|ParseError doParse(Iterator<Character> input, Integer parsedIndex) {
        value first = input.next();
        if (is Character first) {
            return ParseResult([first.string], parsedIndex + 1, [first]);
        }
        return ParseError("Expected a char but found nothing at index ``parsedIndex``", []);
    }
}

"All Characters that are considered to be spaces, ie. \" \\f\\t\\r\\n\"."
shared [Character+] spaceChars = [' ', '\f', '\t', '\r', '\n'];

"A space parser. A space is defined by [[spaceChars]]."
shared Parser<{String*}> space = oneOf(*spaceChars);

"A latin letter. Must be one of 'A'..'Z' or 'a'..'z'.
 
 To obtain a parser for letters from specific languages, use combinators as in the following example:
 
     value swedishLetter = either(letter, oneOf('ö', 'ä', 'å', 'Ö', 'Ä', 'Å'));
 "
shared Parser<{String*}> letter = either(oneOf(*('A'..'Z')), oneOf(*('a'..'z')));

"Parser for one of the given characters.
 
 It fails if the input is empty."
shared Parser<String[]> oneOf(Character+ chars)
        => OneOf(true, *chars);

"Parser for none of the given characters. It fails if the input is one of the given characters.
 
 It succeeds if the input is empty."
shared Parser<String[]> noneOf(Character+ chars)
        => OneOf(false, *chars);

"A String parser. A String is considered to be any possibly empty stream of Characters
 without any spaces between them."
see(`value spaceChars`)
shared Parser<String> string = object satisfies Parser<String> {
    value delegate = many(noneOf(*spaceChars));
    shared actual ParseResult<String>|ParseError doParse(Iterator<Character> input, Integer parsedIndex) {
        value result = delegate.doParse(input, parsedIndex);
        if (is ParseResult<{String*}> result) {
            return ParseResult(result.result.fold("")(plus<String>), result.parsedIndex, result.consumedOk, result.consumedFailed);
        } else {
            return result;
        }
    }
};

class OneOf(Boolean include, Character+ chars) satisfies Parser<String[]> {
    shared actual ParseResult<String[]>|ParseError doParse(Iterator<Character> input, Integer parsedIndex) {
        value first = input.next();
        value consumed = if (is Character first) then [first] else [];
        value boolFun = include then identity<Boolean> else negate;
        if (boolFun(first in chars)) {
            return ParseResult(first is Finished then [] else [first.string], parsedIndex + consumed.size, consumed);
        }
        return ParseError("Expected `` include then "" else "n" ``one of ``quote(chars)`` but found ``quote(first)``" +
                    " at index ``parsedIndex``", consumed);
    }
}

String quote(Anything s)
        => if (is Object s) then "'``s``'" else "nothing";

Boolean negate(Boolean b)
        => !b;
