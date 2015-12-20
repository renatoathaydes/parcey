shared class CharacterBuffer(Integer maxSize = 1024) {
	
	value newer = Array<Character>.ofSize(maxSize, '0');
	value older = Array<Character>.ofSize(maxSize, '0');
	
	value doubleSize = 2 * maxSize;
	
	"The real index we should be at if we didn't drop any characters"
	variable Integer currentIndex = -1;
	
	Integer backtrackBy(Integer count)
		=> currentIndex - count;
	
	Integer backtrackCountFor(Integer index) {
		value result = currentIndex - index;
		if (result > doubleSize) {
			throw  Exception("Unable to parse input as it requires backtracking further than allowed: '``maxSize``.'");
		}
		return result;
	}
	
	shared Character? getFromLast(Integer index)
			=> sublist(currentIndex - index, 1).first;
	
	shared Character? getFromFirst(Integer index)
        => sublist(index, 1).first;
	
	shared {Character*} take(Integer count)
			=> sublist(backtrackBy(count), count);
	
	shared {Character*} sublist(Integer from, Integer count) {
		value backtrackCount = backtrackCountFor(from);
		
		if (backtrackCount < 0) {
			return {};
		}

		value arrayIndex = backtrackBy(backtrackCount) % maxSize;
		
		if (backtrackCount >= maxSize) {
			value lower = older.sublistFrom(arrayIndex);
			return lower.chain(newer).take(count);
		} else {
			return newer.sublist(arrayIndex, arrayIndex + count - 1);
		}
	}

	shared void consume(Character char) {
		currentIndex += 1;
		value arrayIndex = currentIndex % maxSize;
		if (currentIndex > 0, arrayIndex == 0) { // restart
			newer.copyTo(older);
		}
		newer.set(arrayIndex, char);
	}
	
	shared void consumeAll({Character*} chars)
			=> chars.each(consume);
		
	shared Integer size => currentIndex + 1;
	
}
