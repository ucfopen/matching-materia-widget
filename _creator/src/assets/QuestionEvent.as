package creators.matching.assets
{
	import flash.events.Event;
	public class QuestionEvent extends Event
	{
		public var qType:String;
		public var qData:*;
		public static const QUESTION_EVENT:String 	= "questionEvent";
		public static const QUESTION_DELETE:String 	= "questionDelete";
		public static const EDIT_END:String			= "editEnd";
		public static const CHECK_SELF:String		= "checkSelf";
		public function QuestionEvent(type:String, qType:String, qData:*, bubbles:Boolean=true, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			this.qType = qType;
			this.qData = qData;
		}
		override public function clone():Event
		{
			return new QuestionEvent(type, qType, qData);
		}
	}
}