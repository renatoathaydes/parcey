import ceylon.collection {
    TreeMap
}

"A Consumer of Characters.

 It keeps track of parser errors, parsing location etc. so that all
 state related to parsing input can be kept outside of Parsers themselves.

 It also allows Parsers to backtrack on errors."
shared class CharacterConsumer(Iterator<Character> input,
							   Integer maxBufferSize = 1024) {

    object errorManager {

        value errorByPosition = TreeMap<Integer, ErrorMessage>(increasing);

        shared String? deepestError() => errorByPosition.last?.item;

        shared Integer deepestErrorPosition() => errorByPosition.last?.key else 0;

        shared void setError(Integer currentPosition, String error) {
            errorByPosition.put(currentPosition, error);
        }

        shared void forgetUpTo(Integer position) {
            errorByPosition.filterKeys(position.smallerThan).each(void (entry) {
                errorByPosition.remove(entry.key);
            });
        }

    }

    value consumed = CharacterBuffer(maxBufferSize);

    variable Integer backtrackCount = -1;

    shared variable Integer consumedByLatestParser = 0;

    shared Integer consumedAtDeepestError()
            => errorManager.deepestErrorPosition();

    variable Integer consumedAtLatestParserStart = 0;

    variable String? latestParserStarted = null;

    shared String? deepestError => errorManager.deepestError();

    shared Character|Finished next() {
        "Tried to consume input without starting a parser"
        assert(latestParserStarted exists);

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

    "Start a Parser.

     Only recognizers should call this method, not combinators or helper functions."
    shared void startParser(String name) {
        consumedByLatestParser = 0;
        consumedAtLatestParserStart = currentlyParsed();
        latestParserStarted = name;
    }

    "Aborts the latest parser started, returning its name to be used in the error message.

     Only recognizers should call this method, not combinators or helper functions."
    shared String abort() {
        "Aborted without starting any Parser"
        assert(exists currentParser = latestParserStarted);
        latestParserStarted = null;
        errorManager.setError(consumedAtLatestParserStart, currentParser);
        takeBack(consumedByLatestParser);
        consumedByLatestParser = 0;
        return currentParser;
    }

    void startFromBeginning() {
        backtrackCount = consumed.size - 1;
        errorManager.forgetUpTo(0);
    }

    "Take back the given number of characters, pretending they were never consumed.

     If [[characterCount]] is 0 or negative, this call has no effect.

     Normally, Combinators call this method to allow the next parser to start again from a previous
     position of the input."
    shared void takeBack(Integer characterCount) {
        if (characterCount > currentlyParsed()) {
            startFromBeginning();
        } else if (characterCount > 0) {
            backtrackCount += characterCount;
            errorManager.forgetUpTo(currentlyParsed());
        }
    }

    "Move back to the position where the number of characters consumed was equal to the given amount.

     If [[charactersConsumed]] is larger than the number of characters already consumed, this call has
     no effect.

     Normally, Combinators call this method to allow the next parser to start again from a previous
     position of the input."
    shared void moveBackTo(Integer charactersConsumed) {
        if (charactersConsumed <= 0) {
            startFromBeginning();
        } else {
            value currentIndex = currentlyParsed();
            if (charactersConsumed < currentIndex) {
                backtrackCount = consumed.size - charactersConsumed - 1;
                errorManager.forgetUpTo(currentlyParsed());
            }
        }
    }

    "Peek the characters starting at [[startIndex]] without removing them (for the purposes of parsing)
     from the input.

     Notice that, obviously, the input might still need to be read if the characters in the requested
     range have not been parsed yet."
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

    "Returns the characters consumed by the latest Parser."
    shared {Character*} latestConsumed() {
        value firstIndex = consumed.size - consumedByLatestParser;
        value count = consumedByLatestParser - backtrackCount;
        return consumed.measure(firstIndex, count);
    }

    "Returns the number of characters consumed.

     If [[CharacterConsumer.moveBackTo]] or [[CharacterConsumer.takeBack]] are called, then this
     method will return a value that is different from the number of characters actually consumed from the
     input."
    shared Integer currentlyParsed()
            => consumed.size - (backtrackCount + 1);

    shared ParsedLocation deepestErrorLocation()
            => location(errorManager.deepestErrorPosition());

    "Location as [row, col] at the given character count.

     This is an expensive operation because every character consumed up to the [[characterCount]]
     must be checked, so avoid calling this method directly (it should only be called when an error is
     displayed for the user, normally)."
    shared ParsedLocation location(Integer characterCount = currentlyParsed()) {
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
