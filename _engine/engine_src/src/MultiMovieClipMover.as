package
{
	// NOTE: TODO: WARNING: this is copied from Matching plain style
	// cuz im being lazy
	// need to put it in a loacation and use the same code for both
	// making some changes, use this file and make plain matching work with it
	import com.gskinner.motion.GTween;
	import flash.display.BitmapData;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.geom.Matrix;
	// re-name to page switcher or something?
	public class MultiMovieClipMover extends EventDispatcher
	{
		protected var _x:Number, _y:Number, _width:Number, _height:Number;
		protected var _tweenDistanceX:Number;
		protected var _tweenDistanceY:Number;
		protected var _bitmap:BitmapData;
		protected var _parent:Sprite;
		protected var _background:MovieClip;
		protected var _clip:MovieClip;
		protected var _tween:GTween;
		public function makeTween(destinationX:Number,y:Number,width:Number,height:Number,tweenDistanceX:Number, tweenDistanceY:Number, parent:Sprite):void
		{
			_x = destinationX;
			_y = y;
			_width = width;
			_height = height;
			_tweenDistanceX = tweenDistanceX;
			_tweenDistanceY = tweenDistanceY;
			_parent = parent;
			_bitmap = new BitmapData(_width,_height, true, 0x00000000);
		}
		public function addTweenClips(clips:Array):void
		{
			for(var i:int =0; i< clips.length; i++)
			{
				var matrix:Matrix = new Matrix(1,0,0,1,clips[i].x,clips[i].y);
				_bitmap.draw(clips[i],matrix,null,"normal");
			}
		}
		public function doTween(duration:Number = 0.6, customEase:Function = null):void
		{
			_clip = new MovieClip();
			_parent.addChild(_clip);
			_clip.x = _x - _tweenDistanceX;
			_clip.y = _y - _tweenDistanceY;;
			_clip.graphics.beginBitmapFill(_bitmap);
			_clip.graphics.drawRect(0,0,_width,_height);
			if(customEase == null)
			{
				_tween = new GTween(_clip, duration, { x: _x, y: _y });
				_tween.dispatchEvents = true;
			}
			else
			{
				_tween = new GTween(_clip, duration, { x: _x, y: _y }, {ease:customEase});
				_tween.dispatchEvents = true;
			}
			_tween.addEventListener(Event.COMPLETE, tweenComplete, false,0, true);
		}
		protected function tweenComplete(e:Event):void
		{
			dispatchEvent(new Event(Event.COMPLETE));
		}
		public function destory():void
		{
			_parent.removeChild(_clip);
			_clip = null;
			_bitmap = null;
		}
	}
}