package {
	public class MiddleSquareRNG{

		public static function randomNumber(n:Number):Number{
			return middleTen(n*n);
		}
		private static function middleTen(n:Number):Number{
			// make the number n into a 10 digit number
			var numOfDigits:int = numDigits(n);
			var extraDigits:Number = numOfDigits - 10;
			if(extraDigits <= 0) return n;
			var numDigitsBefore:Number = Math.ceil(extraDigits/2);
			var numDigitsAfter:Number = Math.floor(extraDigits/2);
			n = removeDigitsAfter(n,numDigitsAfter, numOfDigits);
			n = removeDigitsBefore(n,numDigitsBefore);
			return n;
		}
		private static function numDigits(n:Number):Number
		{
			var count:int = 1;
			while( n > 9){
				count++;
				n /= 10;
			}
			return count;
		}
		private static function removeDigitsBefore(num:Number, numDigits:Number):Number
		{
			var i:int;
			for(i=0; i< numDigits; i++){
				num/=10;
			}
			return Math.floor(num);
		}
		private static function removeDigitsAfter(num:Number, numDigits:Number, numTotal:Number):Number{
			var i:int;
			var newNum:Number = num;
			var count:int = 0;
			for(i=numTotal; i > numDigits; i--){
				newNum/= 10;
				count++;
			}
			newNum = Math.floor(newNum);
			for(i=0; i<count; i++){
				newNum *= 10;
			}
			return num - newNum;
		}
	}
}