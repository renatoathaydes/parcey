import com.athaydes.parcey.combinator {
    seq
}
import com.athaydes.parcey.internal {
    parseError
}

"A Consumer of streams of Characters."
shared class CharacterConsumer(Iterator<Character> input) {
    
    value consumed = StringBuilder();
    
    variable Integer backtrackCount = -1;

    shared variable Integer consumedByLatestParser = 0;
    
    variable Integer consumedAtLatestParserStart = 0;
    
    variable String? latestParserStarted = null;

    shared Character|Finished next() {
        Character|Finished char;
        if (backtrackCount >= 0) {
            char = consumed.getFromLast(backtrackCount) else finished;
            backtrackCount--;
            consumedByLatestParser++;
        } else {
            char = input.next();
            if (is Character char) {
                consumed.appendCharacter(char);
                consumedByLatestParser++;
            }
        }
        return char;
    }
    
    shared void startParser(String name) {
        consumedAtLatestParserStart = currentlyParsed();
        consumedByLatestParser = 0;
        latestParserStarted = name;
    }
    
    shared String abort() {
        takeBack(consumedByLatestParser);
        return latestParserStarted else "Unknown Parser aborted";
    }
    
    shared void takeBack(Integer characterCount) {
        if (characterCount > 0) {
            backtrackCount += characterCount;
        }
    }

    shared {Character*} peekFromLatestStart(Integer characterCount) {
        value characters = consumed[consumedAtLatestParserStart:characterCount];
        value remaining = characterCount - characters.size;
        if (remaining > 0) {
            value extraCharacters = [ for (char in (1:remaining)
                    .map((_) => input.next())) if (is Character char) char ];
            consumed.append(String(extraCharacters));
            backtrackCount += extraCharacters.size;
            return characters.chain(extraCharacters);
        } else {
            return String(characters);
        }
    }
    
    shared void moveBackTo(Integer charactersConsumed) {
        backtrackCount = consumed.size - charactersConsumed - 1;
    }
    
    shared {Character*} latestConsumed() {
        value firstIndex = consumed.size - consumedByLatestParser;
        value lastIndex = firstIndex + consumedByLatestParser - (backtrackCount + 2);
        return consumed[firstIndex..lastIndex];
    }
    
    shared Integer currentlyParsed()
            => consumed.size - (backtrackCount + 1);
    
    shared ParsedLocation location() {
        variable Integer row = 1;
        variable Integer col = 1;
        for (Character char in consumed[0:consumedAtLatestParserStart]) {
            if (char == '\n') {
                row++;
                col = 1;
            } else {
                col++;
            }
        }
        return [row, col];
    }
    
    shared actual String string {
       value partial = consumed.take(500);
       value tookAll = (partial.size == 500);
       return String(partial.chain(tookAll then "..." else ""));
    }

}

"[Row, Column] of the input that has been parsed."
shared alias ParsedLocation => [Integer, Integer];

shared alias ParseOutcome<out Parsed>
        => ParseResult<Parsed>|String;

"Result of parsing an invalid input."
shared final class ParseError(
    shared String message,
    shared ParsedLocation location) {
    string => "ParseError { message=``message``, location=``location``";
}

"Result of successfully parsing some input."
shared final class ParseResult<out Result>(
    "Result of parsing the input."
    shared Result result) {
    string => "ParseResult { result=``result else "null"`` }";
}

"A Parser which can parse a stream of Characters."
shared interface Parser<out Parsed> {
    
    "The name of this Parser. This is used to improve error messages but may be empty."
    shared formal String name;
    
    "Parse the given input. The input is only traversed once by using its iterator."
    see (`function seq`)
    shared default ParseResult<Parsed>|ParseError parse({Character*} input) {
        value consumer = CharacterConsumer(input.iterator());
        value result = doParse(consumer);
        switch(result)
        case (is String) {
            return parseError(consumer, result);
        } else {
            return result;
        }
    }
    
    "Parses the contents given by the iterator."
    shared formal ParseOutcome<Parsed> doParse(
        CharacterConsumer consumer);

}
