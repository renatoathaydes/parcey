
"A Consumer of Characters.
 
 It keeps track of parser errors, parsing location etc. so that all
 state related to parsing input can be kept outside of Parsers themselves.
 
 It also allows Parsers to backtrack on errors."
shared class CharacterConsumer(Iterator<Character> input,
							   Integer maxBufferSize = 1024) {
    
    object errorManager {
        variable String? prevDeepestError = null;
        shared variable String? deepestError = null;
        
        variable Integer prevConsumedAtDeepestParserStart = 0;
        shared variable Integer consumedAtDeepestParserStart = 0;
        
        shared void startParser() {
            prevConsumedAtDeepestParserStart = consumedAtDeepestParserStart;
            prevDeepestError = deepestError;
        }
        
        shared void clearError() {
            consumedAtDeepestParserStart = prevConsumedAtDeepestParserStart;
            deepestError = prevDeepestError;
        }
        
        shared void setError(Integer current, String? error) {
            if (current > consumedAtDeepestParserStart) {
                consumedAtDeepestParserStart = current;
                deepestError = error;
            }
        }
        
    }
    
    value consumed = CharacterBuffer(maxBufferSize);
    
    variable Integer backtrackCount = -1;
    
    shared variable Integer consumedByLatestParser = 0;
    
    shared Integer consumedAtDeepestParserStart
            => errorManager.consumedAtDeepestParserStart;
    
    variable Integer consumedAtLatestParserStart = 0;
    
    variable String? latestParserStarted = null;
    
    shared String? deepestError => errorManager.deepestError;
    
    shared Character|Finished next() {
        Character|Finished char;
        if (backtrackCount >= 0) {
            char = consumed.getFromLast(backtrackCount) else finished;
            backtrackCount--;
            consumedByLatestParser++;
        } else {
            char = input.next();
            if (is Character char) {
                consumed.consume(char);
                consumedByLatestParser++;
            }
        }
        return char;
    }
    
    shared void startParser(String name) {
        consumedAtLatestParserStart = currentlyParsed();
        consumedByLatestParser = 0;
        latestParserStarted = name;
        errorManager.startParser();
    }
    
    shared void clearError() {
        errorManager.clearError();
    }
    
    shared String abort() {
        value current = consumedAtLatestParserStart;
        errorManager.setError(current, latestParserStarted);
        takeBack(consumedByLatestParser);
        return latestParserStarted else "Unknown Parser aborted";
    }
    
    shared void takeBack(Integer characterCount) {
        if (characterCount > 0) {
            backtrackCount += characterCount;
        }
    }
    
    shared {Character*} peek(Integer startIndex, Integer characterCount) {
        value characters = consumed.measure(startIndex, characterCount);
        value remaining = characterCount - characters.size;
        if (remaining > 0) {
            value extraCharacters = [ for (char in (1:remaining)
                .map((_) => input.next())) if (is Character char) char ];
            consumed.consumeAll(extraCharacters);
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
        value count = consumedByLatestParser - backtrackCount;
        return consumed.measure(firstIndex, count);
    }
    
    shared Integer currentlyParsed()
            => consumed.size - (backtrackCount + 1);
    
    shared ParsedLocation deepestParserStartLocation()
            => location(errorManager.consumedAtDeepestParserStart);
    
    shared ParsedLocation location(Integer characterCount = consumedAtLatestParserStart) {
        variable Integer row = 1;
        variable Integer col = 1;
        consumed.measure(0, characterCount).each((Character char) {
            if (char == '\n') {
                row++;
                col = 1;
            } else {
                col++;
            }
        });
        return [row, col];
    }
    
    shared actual String string {
        value partial = consumed.take(500);
        value tookAll = (partial.size == 500);
        return String((tookAll then "..." else "").chain(partial));
    }
    
}
