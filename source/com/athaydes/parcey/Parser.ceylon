import com.athaydes.parcey.combinator {
    seq
}
import com.athaydes.parcey.internal {
    parseError
}

"A Consumer of streams of Characters."
shared class CharacterConsumer(shared Iterator<Character> input) {
    
    value consumed = StringBuilder();
    
    value internalLocation = Array { 1, 1 };
    
    function row() => internalLocation[0] else 0;
    
    function col() => internalLocation[1] else 0;
    
    variable Integer backtrackCount = -1;

    shared variable Integer consumedByLatestParser = 0;
    
    variable String? errorName = null;

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
    
    shared void startParser() {
        if (errorName is Null) {
            updateLocation(latestConsumed());
        }
        consumedByLatestParser = 0;
        errorName = null;
    }
    
    void updateLocation({Character*} characters) {
        for (Character char in characters) {
            if (char == '\n') {
                internalLocation.set(0, row() + 1);
                internalLocation.set(1, 1);
            } else {
                internalLocation.set(1, col() + 1);
            }
        }
    }
    
    shared String abort(String error) {
        errorName = error;
        takeBack(consumedByLatestParser);
        return error;
    }
    
    shared void takeBack(Integer characterCount) {
        if (characterCount > 0) {
            backtrackCount += characterCount;
        }
    }
    
    shared {Character*} latestConsumed() {
        value firstIndex = consumed.size - consumedByLatestParser;
        value lastIndex = firstIndex + consumedByLatestParser - (backtrackCount + 2);
        return consumed[firstIndex..lastIndex];
    }
    
    shared ParsedLocation location()
        => [row(), col()];
    
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
