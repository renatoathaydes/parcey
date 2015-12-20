import ceylon.test {
	testExecutor,
	test
}

import com.athaydes.parcey {
	CharacterBuffer
}
import com.athaydes.specks {
	SpecksTestExecutor,
	Specification,
	feature,
	forAll,
	randomIntegers
}
import com.athaydes.specks.assertion {
	expect
}
import com.athaydes.specks.matcher {
	equalTo,
	sameAs,
	toBe
}
testExecutor(`class SpecksTestExecutor`)
shared class CharacterBufferSpec() {
	
	test
	shared Specification simpleProperties() => Specification {
		feature {
			description = "getFromFirst() and getFromLast() should handle a single character";
			(Character c) {
				value buffer = CharacterBuffer(50);
				buffer.consume(c);
				return [buffer, c];
			};
			
			examples = [ ['a'], [' '] ];
			
			(CharacterBuffer buffer, Character c)
					=> expect(buffer.size, equalTo(1)),
			(CharacterBuffer buffer, Character c)
					=> expect(buffer.getFromFirst(0), sameAs(c)),
			(CharacterBuffer buffer, Character c)
					=> expect(buffer.getFromLast(0), sameAs(c))
		},
		forAll {
			description = "size of a buffer depends only on the characters it consumed in total,
			               not the actual buffer size";
			generators = [ () => randomIntegers(100, 0, 1k) ];
			assertion = (Integer n) {
				 value buffer = CharacterBuffer();
				 buffer.consumeAll({'a'}.cycled.take(n));
				 return expect(buffer.size, toBe(equalTo(n)));
			};
		}
	};
	
	test
	shared Specification canAccessCharacterRangesWithFullArrays() => Specification {
		feature {
			(Integer fromIndex, Integer length, String expected) {
				value inputString = "01234567890123456789";
				value buffer = CharacterBuffer { maxSize = 5; };
				buffer.consumeAll(inputString);
				value result = buffer.measure(fromIndex, length).sequence();
				return [result, expected.sequence()];
			};
			
			examples = [
				[20, 10, ""],
				[19, 1, "9"],
				[18, 1, "8"],
				[19, 2, "9"],
				[18, 10, "89"],
				[10, 5, "01234"],
				[10, 10, "0123456789"],
				[10, 1k, "0123456789"],
				[14, 4, "4567"]
			];
			
			(Character[] result, Character[] expected)
					=> expect(result, sameAs(expected))
		}
	};

	test
	shared Specification canAccessCharacterRangesWithPartiallyFullNewerArray() => Specification {
		feature {
			(Integer fromIndex, Integer length, String expected) {
				value inputString = "012345";
				value buffer = CharacterBuffer { maxSize = 10; };
				buffer.consumeAll(inputString);
				value result = buffer.measure(fromIndex, length).sequence();
				return [result, expected.sequence()];
			};
			
			examples = [
				[0, 1, "0"],
				[0, 0, ""],
				[0, 2, "01"],
				[0, 3, "012"],
				[0, 6, "012345"],
				[0, 7, "012345"],
				[1, 1, "1"],
				[1, 3, "123"],
				[1, 100, "12345"],
				[1, 3, "123"],
				[4, 4, "45"],
				[5, 1, "5"],
				[6, 2, ""],
				[10, 3, ""]
			];
			
			(Character[] result, Character[] expected)
					=> expect(result, sameAs(expected))
		}
	};

	test
	shared Specification canAccessCharacterRangesWithPartiallyFullOlderArray() => Specification {
		feature {
			(Integer fromIndex, Integer length, String expected) {
				value inputString = "0123456";
				value buffer = CharacterBuffer { maxSize = 5; };
				buffer.consumeAll(inputString);
				value result = buffer.measure(fromIndex, length).sequence();
				return [result, expected.sequence()];
			};
			
			examples = [
				[0, 1, "0"],
				[0, 0, ""],
				[0, 2, "01"],
				[0, 3, "012"],
				[0, 7, "0123456"],
				[0, 8, "0123456"],
				[1, 1, "1"],
				[1, 3, "123"],
				[1, 100, "123456"],
				[1, 3, "123"],
				[4, 4, "456"],
				[5, 2, "56"],
				[6, 1, "6"],
				[6, 2, "6"],
				[7, 2, ""],
				[10, 3, ""]
			];
			
			(Character[] result, Character[] expected)
					=> expect(result, sameAs(expected))
		}
	};
	
}