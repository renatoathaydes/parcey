import com.athaydes.parcey.combinator {
    sequenceOf
}
import com.athaydes.parcey.internal {
    parseError
}

"[Row, Column] of the input that has been parsed."
shared alias ParsedLocation => [Integer, Integer];

"An error message."
shared alias ErrorMessage => String;

"The result of parsing some input, which may or may not be successful."
shared alias ParseResult<out Parsed>
        => ParseSuccess<Parsed>|ErrorMessage;

"Result of parsing some invalid input."
shared final class ParseError(
    shared String message,
    shared ParsedLocation location) {
    string => "ParseError { message=``message``, location=``location``";
}

"Result of successfully parsing some input."
shared final class ParseSuccess<out Result>(
    "Result of parsing the input."
    shared Result result) {
    string => "ParseSuccess { result=``result else "null"`` }";
}

"A Parser which can parse a stream of Characters.
 
 Parsers are stateless, hence can be safely shared even between different Threads.
 All state is kept in [[CharacterConsumer]], which
 can be passed in from a previous parsing process with the [[Parser.doParse]] method."
shared interface Parser<out Parsed> {
    
    "The name of this Parser. This is used to improve error messages but may be empty."
    shared formal String name;
    
    "Parse the given input. The input is only traversed once by using its iterator."
    see (`function sequenceOf`)
    shared default ParseSuccess<Parsed>|ParseError parse({Character*} input) {
        value consumer = input is List<Anything>
        	then CharacterConsumer(input.iterator(),
            		if (input.size > 512M) then 256M else
            		if (input.size > 10) then input.size / 2 else input.size)
        	else CharacterConsumer(input.iterator());
        
        value result = doParse(consumer);
        switch(result)
        case (is ErrorMessage) {
            return parseError(consumer, result);
        } else {
            return result;
        }
    }
    
    "Parses the input provided by the [[consumer|consumer]]."
    shared formal ParseResult<Parsed> doParse(
        "A consumer of Characters which provides Parsers with input, keeping
         state related to the current parsing process."
        CharacterConsumer consumer);

}
