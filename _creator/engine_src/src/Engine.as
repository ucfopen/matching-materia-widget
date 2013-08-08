/* See the file "LICENSE.txt" for the full license governing this code. */
package
{
import flash.display.DisplayObject;
import flash.display.MovieClip;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.filters.DropShadowFilter;
import flash.geom.ColorTransform;
import flash.net.SharedObject;
import flash.text.TextField;
import flash.text.TextFormat;
import nm.gameServ.engines.EngineCore;
import nm.ui.ScrollClip;
// NOTE: this will not run on its own extend it, and give values to the main movie clip elements
	//Dimensions: 800x620
public class Engine extends EngineCore
{
	// constants for telling which side of a match a clip is
	protected static const LEFT:int = 0;
	protected static const RIGHT:int = 1;
	protected static const NONE:int = 2;
	protected static const QUESTIONS_PER_PAGE:int = 5;
	protected static const TWEEN_DISTANCE:Number = 1200.0;
	protected static const LINE_COLOR:Number = 0xFFCC66; // the line color used in a few places
	protected static const LINE_COLOR_ACTIVE:Number = 0xFFFFFF;
	protected static const BOX_MARGIN:Number = 9;
	protected static const MATCH_END_POINT_X_OFFSET:Number = 10;
	protected static const MAX_MATCH_FONT_SIZE:Number = 26;
	protected static const MIN_MATCH_FONT_SIZE:Number = 12;
	protected static const TEXT_PADDING:Number = 10;
	// 1 happens on mouse click
	protected var _matchSelection1Index:int = -1;
	protected var _matchSelection1Side:int = NONE;
	// 2 happens on mouse over
	protected var _matchSelection2Index:int = -1;
	protected var _matchSelection2Side:int = NONE;
	// here are the elements in the main movie clip
	// extend this class, and give values to these movie clips to make a matching game
	protected var _matchingItemsArea:MovieClip;
	protected var _titleText:TextField;
	protected var _previousPageButton:MovieClip;
	protected var _nextPageButton:MovieClip;
	protected var _progressText:TextField;
	protected var _pageText:TextField;
	protected var _doneButton:MovieClip;
	protected var _background:MovieClip;
	// parallel arrays of the matches we have
	protected var _leftSideTexts:Array; // 2d array -> left sides text grouped by pages
	protected var _rightSideTexts:Array; // 2d array -> rights sides text grouped by pages
	protected var _leftSideQuestionIds:Array;
	// NOTE: this is currently not the text, it is indexes to text in _rightSideTexts
	protected var _scrambledRightSideTexts:Array; // scrambled right sides, to make it a game
	protected var _userMatchesLeftToRight:Array // indices of left side matches store indices to
												//  right side matches
	protected var _curQuestionPage:int; // the current page we are on
	protected var _isCaseSensitive:Boolean;
	// The main screen contains all of the clips for the game, except the boxes that are matched
	// the boxes are added dynamically to tween them in and out, and to adjust how many of them there are
	protected var _mainScreenMovieClip:MovieClip;
	protected var _curMatchDrawingClip:MovieClip; // drawing the current match the user is making
	// vars to hold clips for the matching items we tween on to stage
	protected var _curMatchDrawingClips:Array = [];// movie clips to draw the matches on
	protected var _curLeftSideMatchingBoxes:Array = []; // array of matching movie clips
	protected var _curRightSideMatchingBoxes:Array = []; // array of movie clps
	protected var _curLeftMatchingLineEndPoints:Array = []; // array of the endpoint movie clips
	protected var _curRightMatchingLineEndPoints:Array = []; // array of the endpoint movie clips
	// vars to hold the clips we are tweening off
	protected var _oldMatchDrawingClips:Array = [];// movie clips to draw the matches on
	protected var _oldLeftSideMatchingBoxes:Array = []; // array of matching movie clips
	protected var _oldRightSideMatchingBoxes:Array = []; // array of movie clps
	protected var _oldLeftMatchingLineEndPoints:Array = []; // array of the endpoint movie clips
	protected var _oldRightMatchingLineEndPoints:Array = []; // array of the endpoint movie clips
	// vars for storing the clicked on matches
	// these are used to match based on clicking one element from each side
	protected var _leftMatchClicked:int = -1;
	protected var _rightMatchClicked:int = -1;
	protected var _curItemHeight:Number; // the height of the matching boxes for the current page
	protected var user_so:Object;
	protected var _currentlySwitchingPages:Boolean = false;
	protected var _tweenOffTweener:MultiMovieClipMover;
	protected var _tweenOnTweener:MultiMovieClipMover;
	// used to 'cancel' the next mouse up -> used when the user uses the scrollbars
	// when they use scrollbars, they are probably just looking at text, not selecting matches
	protected var _nextMouseupWontSelect:Boolean = false;
	public function Engine():void
	{
	}
	/**
	* Called at the start of the game to set up the game.
	*/
	protected override function startEngine():void
	{
		// initiate the engine with MovieClips and stuff from the .fla file
		var b:MainScreen = new MainScreen();
		addChild(b);
		_mainScreenMovieClip = b;
		_matchingItemsArea = _mainScreenMovieClip.matchingItemsArea;
		_titleText = _mainScreenMovieClip.titleText;
		_previousPageButton = _mainScreenMovieClip.previousPageButton;
		_nextPageButton = _mainScreenMovieClip.nextPageButton;
		_progressText = _mainScreenMovieClip.progressText;
		_doneButton = _mainScreenMovieClip.doneButton;
		_pageText = _mainScreenMovieClip.pageText;
		_pageText.selectable = false;
		_background = _mainScreenMovieClip.background;
		super.startEngine();
		// get the qset
		// get the question layout
		initGameContent();
		initUIElements();
		// display the first set of questions
		_curQuestionPage = 0;
		showQuestionPage(_curQuestionPage, -1.0);
		// event listeners to respond to user input
		stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp, false, 0, true);
		stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove, false, 0, true);
		updateButtonStatus();
	}
	protected function initUIElements():void
	{
		_matchingItemsArea.visible = false;
		_titleText.text = inst.name;
		(_previousPageButton.buttonText as TextField).text = "< Previous";
		(_previousPageButton.buttonText as TextField).embedFonts = true;
		(_previousPageButton.buttonText as TextField).selectable = false;
		_previousPageButton.addEventListener(MouseEvent.MOUSE_UP, buttonPress, false, 0, true);
		_previousPageButton.mouseChildren = false;
		makeClipIntoButton(_previousPageButton);
		_nextPageButton.buttonText.text = "Next >";
		(_nextPageButton.buttonText as TextField).embedFonts = true;
		(_nextPageButton.buttonText as TextField).selectable = false;
		_nextPageButton.addEventListener(MouseEvent.MOUSE_UP, buttonPress, false, 0, true);
		_nextPageButton.mouseChildren = false;
		makeClipIntoButton(_nextPageButton);
		_progressText.text = getProgressString();
		_progressText.selectable = false;
		_background.addEventListener(MouseEvent.CLICK, clickOnBackground, false, 0, true);
		_doneButton.addEventListener(MouseEvent.MOUSE_UP, buttonPress, false, 0, true);
		makeClipIntoButton(_doneButton);
		_curMatchDrawingClip = new MovieClip();
		_curMatchDrawingClip.x=0; _curMatchDrawingClip.y = 0;
		_curMatchDrawingClip.mouseEnabled = false;
		addChild(_curMatchDrawingClip);
		updatePageNumString();
	}
	protected function getProgressString():String
	{
		return numQuestionsAnswered() + " / " + numQuestionsTotal() + " Questions Answered"
	}
	protected function updatePageNumString():void
	{
		_pageText.text = "Page " + numCurPage() + " / " + numPageTotal();
	}
	protected function numCurPage():int {
		return _curQuestionPage + 1;
	}
	protected function numPageTotal():int {
		return Math.ceil(EngineCore.qSetData.items[0].items.length / QUESTIONS_PER_PAGE);
	}
	protected function makeClipIntoButton(buttonMovieClip:MovieClip):void
	{
		buttonMovieClip.addEventListener(MouseEvent.MOUSE_OVER, mouseOverButton, false,0, true);
		buttonMovieClip.addEventListener(MouseEvent.MOUSE_OUT, mouseOutButton, false, 0, true);
		buttonMovieClip.buttonMode = true;
	}
	protected function clearButtonEvents(buttonMovieClip:MovieClip):void
	{
		buttonMovieClip.removeEventListener(MouseEvent.MOUSE_OVER, mouseOverButton);
		buttonMovieClip.removeEventListener(MouseEvent.MOUSE_OUT, mouseOutButton);
	}
	protected function clickOnBackground(e:Event):void {
		deselectClips()
	}
	// deselect question/answer clips
	protected function deselectClips():void {
		_leftMatchClicked = -1;
		_rightMatchClicked = -1;
		checkForClickedMatches();
		checkForClickedMatches();
		updateMatchingEndpointDots()
		updateButtonStatus()
	}
	// show that the button is mouseovered
	protected function mouseOverButton(e:Event):void
	{
		// prevent highlighting when the button is on on the same side as the currently selected one
		var index:Array = []
		var side:int = getLeftOrRight(e.currentTarget as MovieClip, index);
		if(side != _matchSelection1Side && e.currentTarget.enabled == true)
		{
			var c:ColorTransform = new ColorTransform(.9,.9,.9);
			(e.currentTarget as MovieClip).transform.colorTransform = c;
			if( (_leftMatchClicked == -1 && _rightMatchClicked == -1) || (_leftMatchClicked != -1 && side == RIGHT) || (_rightMatchClicked != -1 && side == LEFT) )
			{
				setMouseOverBoxColor(e.currentTarget as MovieClip)
			}
		}
		// if this is a 2nd selection draw the line
		if(_leftMatchClicked!= -1 || _rightMatchClicked != -1)
		{
			var ep:MovieClip
			var mb:MovieClip
			var ep2:MovieClip
			if(side ==  RIGHT && _leftMatchClicked!= -1 )
			{
				ep = _curLeftMatchingLineEndPoints[_leftMatchClicked];
				ep2 = _curRightMatchingLineEndPoints[index[0]];
				drawMatchingLine(_curMatchDrawingClip, ep.x + ep.width/2, ep.y + ep.height/2, ep2.x + ep2.width/2, ep2.y + ep2.height/2)
			}
			else if(side == LEFT && _rightMatchClicked != -1)
			{
				ep = _curRightMatchingLineEndPoints[_rightMatchClicked];
				ep2 = _curLeftMatchingLineEndPoints[index[0]];
				drawMatchingLine(_curMatchDrawingClip, ep.x + ep.width/2, ep.y + ep.height/2, ep2.x + ep2.width/2, ep2.y + ep2.height/2)
			}
			else{
				_curMatchDrawingClip.graphics.clear()
			}
		}
	}
	protected function setMouseOverBoxColor(mc:MovieClip):void
	{
		if (mc.matchingBox != null) {
			mc.matchingBox.gotoAndStop(3);
		}
	}
	protected function setMouseOutBoxColor(mc:MovieClip):void
	{
		if (mc.matchingBox != null) {
			if(isBoxMatched(mc))
			{
				mc.matchingBox.gotoAndStop(2);
			}
			else if(isBoxClicked(mc))
			{
				mc.matchingBox.gotoAndStop(3);
			}
			else
			{
				mc.matchingBox.gotoAndStop(1);
			}
		}
	}
	// check if a box moviec clip is part of a match
	protected function isBoxMatched(mc:MovieClip):Boolean
	{
		var i:int;
		for(i=0; i< _userMatchesLeftToRight[_curQuestionPage].length; i++)
		{
			if(_userMatchesLeftToRight[_curQuestionPage][i] != -1)
			{
				if(_curLeftSideMatchingBoxes[i] == mc ||
					_curRightSideMatchingBoxes[_userMatchesLeftToRight[_curQuestionPage][i]] == mc)
				{
					return true;
				}
			}
		}
		return false;
	}
	protected function isBoxClicked(mc:MovieClip):Boolean
	{
		if (_leftMatchClicked != -1 &&_curLeftSideMatchingBoxes[_leftMatchClicked] == mc)
		{
			return true;
		}
		else if(_rightMatchClicked != -1 && _curRightSideMatchingBoxes[_rightMatchClicked] == mc)
		{
			return true;
		}
		return false;
	}
	// show that the button is mouse-outed
	protected function mouseOutButton(e:Event):void
	{
		if( e.currentTarget.enabled == true)
		{
			var index:Array = []
			var side:int = getLeftOrRight(e.currentTarget as MovieClip, index);
			// dont change colors if the current item is selected
			if(side == _matchSelection1Side && _matchSelection1Index == index[0]) return
			var c:ColorTransform = new ColorTransform();
			(e.currentTarget as MovieClip).transform.colorTransform = c;
			setMouseOutBoxColor(e.currentTarget as MovieClip)
		}
		if(_leftMatchClicked != -1 || _rightMatchClicked != -1)		_curMatchDrawingClip.graphics.clear()
	}
	// a button has been pressed
	protected function buttonPress(e:Event):void
	{
		var success:Boolean;
		switch( e.currentTarget)
		{
			case _previousPageButton:
				if( ! showQuestionPage(--_curQuestionPage, 1.0))
				{
					_curQuestionPage++;
				}
				break;
			case _nextPageButton:
				if(! showQuestionPage(++_curQuestionPage, -1.0))
				{
					_curQuestionPage--;
				}
				break;
			case _doneButton:
				gameOver();
				break;
			default:
				break;
		}
		updatePageNumString()
		updateButtonStatus();
	}
	// enable/ disable the done button, and next/ previous buttons depending on the state of the game
	protected function updateButtonStatus():void
	{
		if( numQuestionsAnswered() == numQuestionsTotal() )
		{
			enableButton(_doneButton);
		}
		else
		{
			disableButton(_doneButton);
		}
		if(_curQuestionPage == 0)
		{
			disableButton(_previousPageButton);
		}
		else
		{
			enableButton(_previousPageButton);
		}
		if(_curQuestionPage+1 >= numQuestionPages())
		{
			disableButton(_nextPageButton);
		}
		else
		{
			enableButton(_nextPageButton);
		}
		if (_userMatchesLeftToRight[_curQuestionPage].length == curPageMatchTotals())
		{
			setButtonReady(_nextPageButton);
		}
		else {
			setButtonNotReady(_nextPageButton);
		}
		setButtonNotReady(_previousPageButton);
	}
	protected function setButtonReady(mc:MovieClip):void
	{
		if (mc.enabled)
		{
			mc.gotoAndStop(2);
		}
	}
	protected function setButtonNotReady(mc:MovieClip):void
	{
		mc.gotoAndStop(1);
	}
	protected function curPageMatchTotals():int
	{
		var numAnswered:int =0;
		for( var j:int =0; j< _userMatchesLeftToRight[_curQuestionPage].length; j++)
		{
			if(_userMatchesLeftToRight[_curQuestionPage][j] != -1)
			{
				numAnswered++;
			}
		}
		return numAnswered;
	}
	protected function enableButton(mc:MovieClip):void
	{
		const ENABLED_ALPHA:Number = 1.0;
		mc.enabled = true;
		mc.alpha = ENABLED_ALPHA;
	}
	protected function disableButton(mc:MovieClip):void
	{
		const DISABLED_ALPHA:Number = 0.3;
		mc.transform.colorTransform = new ColorTransform();
		mc.enabled = false;
		mc.alpha = DISABLED_ALPHA;
	}
	protected function numQuestionsAnswered():int
	{
		var numAnswered:int =0;
		for(var i:int =0; i< _userMatchesLeftToRight.length; i++)
		{
			for( var j:int =0; j< _userMatchesLeftToRight[i].length; j++)
			{
				if(_userMatchesLeftToRight[i][j] != -1)
				{
					numAnswered++;
				}
			}
		}
		return numAnswered;
	}
	protected function numQuestionsTotal():int
	{
		var numTotal:int =0;
		for(var i:int =0; i< _userMatchesLeftToRight.length; i++)
		{
			numTotal += _userMatchesLeftToRight[i].length;
		}
		return numTotal;
	}
	protected function numQuestionPages():int
	{
		return _leftSideTexts.length;
	}
	/**
	 * Show the given page of questions.
	 * Tween the old questions off, and the new questions on.
	 */
	protected function showQuestionPage(questionPageIndex:int, dir:Number = 1.0):Boolean
	{
		if( _currentlySwitchingPages == true)
		{
			return false;
		}
		if(questionPageIndex < 0)
		{
			return false;
		}
		if(questionPageIndex >= _leftSideTexts.length)
		{
			return false;
		}
		// this will be set back to true in a tweenOff tween
		_currentlySwitchingPages = true;
		// add the matching boxes
		_oldLeftSideMatchingBoxes = _curLeftSideMatchingBoxes;
		_oldRightSideMatchingBoxes = _curRightSideMatchingBoxes;
		_oldLeftMatchingLineEndPoints = _curLeftMatchingLineEndPoints;
		_oldRightMatchingLineEndPoints = _curRightMatchingLineEndPoints;
		_oldMatchDrawingClips = _curMatchDrawingClips;
		// tween em off
		if(_tweenOffTweener == null)
		{
			_tweenOffTweener = new MultiMovieClipMover();
		}
		_tweenOffTweener.makeTween(dir*TWEEN_DISTANCE,0,widget.width, widget.height ,dir*TWEEN_DISTANCE, 0, this);
		_tweenOffTweener.addTweenClips(_oldLeftSideMatchingBoxes);
		_tweenOffTweener.addTweenClips(_oldRightSideMatchingBoxes);
		_tweenOffTweener.addTweenClips(_oldLeftMatchingLineEndPoints);
		_tweenOffTweener.addTweenClips(_oldRightMatchingLineEndPoints);
		_tweenOffTweener.addTweenClips(_oldMatchDrawingClips);
		_tweenOffTweener.addEventListener(Event.COMPLETE, tweenOffComplete, false, 0, true);
		_tweenOffTweener.doTween(0.7, customTween);
		// the tweening off will make a bitmap copy, so we can remove these here
		destroyLeftMatchingBoxes(_curLeftSideMatchingBoxes);
		destroyRightMatchingBoxes(_curRightSideMatchingBoxes);
		destroyLeftMatchingLineEndPoints(_curLeftMatchingLineEndPoints);
		destroyRightMatchingLineEndPoitns(_curRightMatchingLineEndPoints);
		removeMovieClips(_oldMatchDrawingClips);
		_curItemHeight = _matchingItemsArea.height/ (_leftSideTexts[questionPageIndex].length) - BOX_MARGIN;
		_curLeftSideMatchingBoxes = addMatchingBoxes(_leftSideTexts[questionPageIndex], _matchingItemsArea, dir, true);
		var rightSideTexts:Array = [];
		var i:int;
		for(i=0; i< _rightSideTexts[questionPageIndex].length; i++)
		{
			rightSideTexts.push(_rightSideTexts[questionPageIndex][_scrambledRightSideTexts[questionPageIndex][i]]);
		}
		_curRightSideMatchingBoxes = addMatchingBoxes( rightSideTexts, _matchingItemsArea, dir, false);
		_curLeftMatchingLineEndPoints = addLeftMatchingLineEndPoints(_curLeftSideMatchingBoxes);
		_curRightMatchingLineEndPoints = addRightMatchingLineEndPoints(_curRightSideMatchingBoxes);
		_curMatchDrawingClips = [];
		for( i = 0; i< _curLeftSideMatchingBoxes.length; i++)
		{
			var m:MovieClip = new MovieClip();
			_curMatchDrawingClips.push(m);
			m.y = 0;
			m.mouseEnabled = false;
			m.x = 0;
			addChild(m);
		}
		// add the stored matches
		for(i=0; i< _userMatchesLeftToRight[_curQuestionPage].length; i++)
		{
			if(_userMatchesLeftToRight[_curQuestionPage][i] != -1)
			{
				addMatch( i, _userMatchesLeftToRight[_curQuestionPage][i], 0/*TWEEN_DISTANCE*dir*/);
			}
		}
		updateButtonStatus();
		// tween em on
		if(_tweenOnTweener == null)
		{
			_tweenOnTweener = new MultiMovieClipMover();
		}
		_tweenOnTweener.makeTween(0,0, widget.width, widget.height, dir*TWEEN_DISTANCE, 0, this);
		_tweenOnTweener.addTweenClips(_curLeftSideMatchingBoxes);
		_tweenOnTweener.addTweenClips(_curRightSideMatchingBoxes);
		_tweenOnTweener.addTweenClips(_curRightMatchingLineEndPoints);
		_tweenOnTweener.addTweenClips(_curLeftMatchingLineEndPoints);
		_tweenOnTweener.addTweenClips(_curMatchDrawingClips);
		_tweenOnTweener.addEventListener(Event.COMPLETE, tweenOnComplete, false, 0, true);
		_tweenOnTweener.doTween(0.7, customTween);
		hideCurrentClips();
		// keed this in front
		setChildIndex(_curMatchDrawingClip, numChildren-1);
		deselectClips();
		return true;
	}
	protected function tweenOffComplete(e:Event):void
	{
		_tweenOffTweener.removeEventListener(Event.COMPLETE, tweenOffComplete);
		_tweenOffTweener.destory();
	}
	protected function tweenOnComplete(e:Event):void
	{
		_tweenOnTweener.removeEventListener(Event.COMPLETE, tweenOnComplete);
		// need to show the actual clips
		_tweenOnTweener.destory();
		_currentlySwitchingPages = false;
		showCurrentClips();
	}
	protected function showClips(clips:Array, show:Boolean):void
	{
		for(var i:int=0; i< clips.length; i++)
		{
			clips[i].visible = show;
		}
	}
	protected function hideCurrentClips():void
	{
		showClips(_curLeftSideMatchingBoxes,false);
		showClips(_curRightSideMatchingBoxes,false);
		showClips(_curRightMatchingLineEndPoints,false);
		showClips(_curLeftMatchingLineEndPoints,false);
		showClips(_curMatchDrawingClips,false);
	}
	protected function showCurrentClips():void
	{
		showClips(_curLeftSideMatchingBoxes,true);
		showClips(_curRightSideMatchingBoxes,true);
		showClips(_curRightMatchingLineEndPoints,true);
		showClips(_curLeftMatchingLineEndPoints,true);
		showClips(_curMatchDrawingClips,true);
	}
	protected function removeMovieClips(clips:Array):void
	{
		for(var i:int =0; i< clips.length; i++)
		{
			removeChild(clips[i]);
		}
	}
	protected function addMatchingBoxes(strings:Array, matchingAreaSize:MovieClip, dir:Number, leftSide:Boolean):Array
	{
		var matchingBoxClips:Array = [];
		var curY:Number = matchingAreaSize.y;
		// the x position will change depending of if this is a left or right match
		var itemX:Number = 0;
		if(leftSide == true)
		{
			itemX =  matchingAreaSize.x //- TWEEN_DISTANCE*dir
		}
		else
		{
			var m:MatchableBox = new MatchableBox(); // HACK CODE?
			 itemX = (matchingAreaSize.x + matchingAreaSize.width) - m.width - MATCH_END_POINT_X_OFFSET*2 +6//- TWEEN_DISTANCE * dir;
		}
		for(var i:int =0; i< strings.length; i++)
		{
			var matchingBox:MovieClip = new MatchableBox();
			matchingBox.height = _curItemHeight;
			matchingBox.mouseChildren = false; // this will have the hand cursor show over text
			var matchingItem:MatchableItem = new MatchableItem();
			matchingItem.x = itemX;
			matchingItem.y = curY;
			curY += _curItemHeight+BOX_MARGIN;
			matchingItem.matchingBox = matchingBox;
			matchingItem.matchingBox.gotoAndPlay(1);
			matchingItem.addChild(matchingBox);
			var t:MovieClip;
			t = getMatchingBoxText(strings[i], matchingBox);
			t.addEventListener('vScroll', cancelMatchLine, false, 0, true)
			matchingItem.addChild(t);
			var dropShadow:DropShadowFilter = new DropShadowFilter();
			dropShadow.color = 0x000000;
			dropShadow.blurX = 6;
			dropShadow.blurY = 6;
			dropShadow.alpha = 0.45;
			dropShadow.distance = 3;
			var filtersArray:Array = new Array(dropShadow);
			matchingItem.filters = filtersArray;
			addChild(matchingItem);
			makeClipIntoButton(matchingItem);
			matchingBoxClips.push(matchingItem);
			matchingItem.addEventListener(MouseEvent.MOUSE_OVER, onMouseOverMatchingBox, false, 0, true);
			matchingItem.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDownMatchingBox, false, 0, true);
			matchingItem.addEventListener(MouseEvent.MOUSE_UP, onMouseUpMatchingBox, false, 0, true);
			matchingItem.addEventListener(MouseEvent.MOUSE_OUT, onMouseOutMatchingBox, false, 0, true);
		}
		return matchingBoxClips;
	}
	protected function getMatchingBoxText(text:String, box:MovieClip):MovieClip
	{
		var t:TextField = new TextField();
		t.text = text;
		t.width = box.width - 2*TEXT_PADDING;
		t.autoSize = "left";
		t.wordWrap = true;
		t.selectable = false;
		t.embedFonts = true;
		var curSize:Number = MAX_MATCH_FONT_SIZE;
		var tf:TextFormat = new TextFormat();
		tf.size = curSize--;
		tf.leading = -2;
		tf.font = "Arial Rounded MT Bold";
		tf.align = "center";
		tf.color = 0xffffff;
		t.setTextFormat(tf);
		while ( ( (t.textHeight > box.height) || (t.textWidth > box.width) ) && curSize >= MIN_MATCH_FONT_SIZE)
		{
			tf = new TextFormat();
			tf.size = curSize = curSize - 2;
			tf.leading = -2;
			tf.font = "Arial Rounded MT Bold";
			tf.align = "center";
			tf.color = 0xffffff;
			t.setTextFormat(tf);
		}
		var h:Number = box.height+2 //* 1/box.scaleY;
		var dropShadow:DropShadowFilter = new DropShadowFilter();
		dropShadow.color = 0x000000;
		dropShadow.blurX = 4;
		dropShadow.blurY = 4;
		dropShadow.angle = 52;
		dropShadow.alpha = 0.32;
		dropShadow.distance = 3;
		var filtersArray:Array = new Array(dropShadow);
		t.filters = filtersArray;
		t.mouseEnabled = false;
		var scrollClip:ScrollClip = new ScrollClip(box.width-TEXT_PADDING, h-3, false, true);
		scrollClip.setStyle("bgAlpha", 0.0);
		scrollClip.clip.addChild(t);
		scrollClip.x = TEXT_PADDING;
		scrollClip.buttonMode = true;
		if( t.textHeight < box.height)
		{
			t.y = ( box.height - t.textHeight ) / 2 - 3;
		}
		return scrollClip;
	}
	protected function destroyLeftMatchingBoxes(leftMatchingBoxes:Array):void
	{
		if(leftMatchingBoxes == null) return;
		for(var i:int =0; i< leftMatchingBoxes.length; i++)
		{
			clearButtonEvents(leftMatchingBoxes[i]);
			leftMatchingBoxes[i].removeEventListener(MouseEvent.MOUSE_OVER, onMouseOverMatchingBox);
			leftMatchingBoxes[i].removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDownMatchingBox);
			leftMatchingBoxes[i].removeEventListener(MouseEvent.MOUSE_UP, onMouseUpMatchingBox);
			leftMatchingBoxes[i].removeEventListener(MouseEvent.MOUSE_OUT, onMouseOutMatchingBox);
		}
		removeMovieClips(leftMatchingBoxes);
	}
	protected function destroyRightMatchingBoxes(rightMatchingBoxes:Array):void
	{
		if(rightMatchingBoxes == null) return;
		for(var i:int =0; i< rightMatchingBoxes.length; i++)
		{
			clearButtonEvents(rightMatchingBoxes[i]);
			rightMatchingBoxes[i].removeEventListener(MouseEvent.MOUSE_OVER, onMouseOverMatchingBox);
			rightMatchingBoxes[i].removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDownMatchingBox);
			rightMatchingBoxes[i].removeEventListener(MouseEvent.MOUSE_UP, onMouseUpMatchingBox);
			rightMatchingBoxes[i].removeEventListener(MouseEvent.MOUSE_OUT, onMouseOutMatchingBox);
		}
		removeMovieClips(rightMatchingBoxes);
	}
	// put a bunch of the MatchLineEndPoint clips to the right of the matching movie clips
	protected function addLeftMatchingLineEndPoints(matchingBoxes:Array):Array
	{
		var matchingEndPoitns:Array = [];
		for(var i:int =0; i< matchingBoxes.length; i++)
		{
			var endPointClip:MovieClip = new MatchLineEndPoint();
			addChild(endPointClip);
			var m:MatchableBox = matchingBoxes[i].matchingBox;
			endPointClip.x = matchingBoxes[i].x + m.width + MATCH_END_POINT_X_OFFSET+6;
			endPointClip.y = matchingBoxes[i].y + (m.height - endPointClip.height)/2;
			endPointClip.lineEndPointDot.visible = false;
			endPointClip.highlightedBorder.visible = false;
			endPointClip.buttonMode = true;
			matchingEndPoitns.push(endPointClip);
			endPointClip.addEventListener(MouseEvent.MOUSE_OVER, onMouseOverMatchingBox, false, 0, true);
			endPointClip.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDownMatchingBox, false, 0, true);
			endPointClip.addEventListener(MouseEvent.MOUSE_UP, onMouseUpMatchingBox, false, 0, true);
			endPointClip.addEventListener(MouseEvent.MOUSE_OUT, onMouseOutMatchingBox, false, 0, true);
		}
		return matchingEndPoitns;
	}
	protected function destroyLeftMatchingLineEndPoints(clips:Array):void
	{
		for(var i:int =0; i < clips.length; i++)
		{
			clips[i].removeEventListener(MouseEvent.MOUSE_OVER, onMouseOverMatchingBox);
			clips[i].removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDownMatchingBox);
			clips[i].removeEventListener(MouseEvent.MOUSE_UP, onMouseUpMatchingBox);
			clips[i].removeEventListener(MouseEvent.MOUSE_OUT, onMouseOutMatchingBox);
		}
		removeMovieClips(clips);
	}
	protected function addRightMatchingLineEndPoints(matchingBoxes:Array):Array
	{
		var matchingEndPoitns:Array = [];
		for(var i:int =0; i< matchingBoxes.length; i++)
		{
			var endPointClip:MovieClip = new MatchLineEndPoint();
			addChild(endPointClip);
			var m:MatchableBox = matchingBoxes[i].matchingBox;
			endPointClip.x = matchingBoxes[i].x - endPointClip.width - MATCH_END_POINT_X_OFFSET;
			endPointClip.y = matchingBoxes[i].y + (m.height - endPointClip.height)/2;
			endPointClip.lineEndPointDot.visible = false;
			endPointClip.highlightedBorder.visible = false;
			endPointClip.buttonMode = true;
			matchingBoxes[i].matchingBox.gotoAndPlay(1);
			matchingBoxes[i].matchingBox.gotoAndPlay(1);
			matchingEndPoitns.push(endPointClip);
			endPointClip.addEventListener(MouseEvent.MOUSE_OVER, onMouseOverMatchingBox, false, 0, true);
			endPointClip.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDownMatchingBox, false, 0, true);
			endPointClip.addEventListener(MouseEvent.MOUSE_UP, onMouseUpMatchingBox, false, 0, true);
			endPointClip.addEventListener(MouseEvent.MOUSE_OUT, onMouseOutMatchingBox, false, 0, true);
		}
		return matchingEndPoitns;
	}
	protected function destroyRightMatchingLineEndPoitns(clips:Array):void
	{
		for(var i:int =0; i < clips.length; i++)
		{
			clips[i].removeEventListener(MouseEvent.MOUSE_OVER, onMouseOverMatchingBox);
			clips[i].removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDownMatchingBox);
			clips[i].removeEventListener(MouseEvent.MOUSE_UP, onMouseUpMatchingBox);
			clips[i].removeEventListener(MouseEvent.MOUSE_OUT, onMouseOutMatchingBox);
		}
		removeMovieClips(clips);
	}
	// index is an array to return the index it was found at
	// pass in an empty array, and then the index will be stored at index[0]
	protected function getLeftOrRight(clip:MovieClip, index:Array):int
	{
		var len:int = _curLeftSideMatchingBoxes.length
		for(var i:int = 0; i < len; i++)
		{
			switch(clip)
			{
				case _curLeftSideMatchingBoxes[i]:
				case _curLeftMatchingLineEndPoints[i]:
					index.push(i);
					return LEFT;
				case _curRightSideMatchingBoxes[i]:
				case _curRightMatchingLineEndPoints[i]:
					index.push(i);
					return RIGHT;
			}
		}
		return NONE;
	}
	protected function addMatch(leftIndex:int,rightIndex:int, xOffset:Number = 0.0, isNew:Boolean = false):void
	{
		var m:MovieClip = _curMatchDrawingClips[leftIndex];
		var l:MovieClip = _curLeftMatchingLineEndPoints[leftIndex];
		var r:MovieClip = _curRightMatchingLineEndPoints[rightIndex];
		m.graphics.clear();
		m.graphics.lineStyle(4, LINE_COLOR);
		m.graphics.moveTo(l.x + l.width/2 + xOffset, l.y + l.height/2);
		m.graphics.lineTo(r.x + r.width/2 + xOffset, r.y + r.height/2);
		// store the match
		_userMatchesLeftToRight[_curQuestionPage][leftIndex] = rightIndex;
		for( var i:int = 0; i< _userMatchesLeftToRight[_curQuestionPage].length; i++)
		{
			if( i != leftIndex &&  _userMatchesLeftToRight[_curQuestionPage][i] == rightIndex)
			{
				_userMatchesLeftToRight[_curQuestionPage][i] = -1;
				_curMatchDrawingClips[i].graphics.clear();
			}
		}
		if(isNew)
		{
			_progressText.text = getProgressString();
			updateButtonStatus();
		}
		updateMatchingEndpointDots();
		// reset the clicked points
		_leftMatchClicked = -1;
		_rightMatchClicked = -1;
	}
	// switch the line endpoint dots on or off depending on the matches
	protected function updateMatchingEndpointDots():void
	{
		// turn off all the dots
		var i:int;
		for( i=0; i< _curLeftMatchingLineEndPoints.length; i++)
		{
			_curLeftMatchingLineEndPoints[i].lineEndPointDot.visible = false;
			_curRightMatchingLineEndPoints[i].lineEndPointDot.visible = false;
			_curLeftMatchingLineEndPoints[i].highlightedBorder.visible = false;
			_curRightMatchingLineEndPoints[i].highlightedBorder.visible = false;
			_curLeftSideMatchingBoxes[i].matchingBox.gotoAndStop(1);
			_curRightSideMatchingBoxes[i].matchingBox.gotoAndStop(1);
		}
		// turn on dots with matches
		for( i = 0; i< _userMatchesLeftToRight[_curQuestionPage].length; i++)
		{
			if( _userMatchesLeftToRight[_curQuestionPage][i] != -1 )
			{
				_curLeftSideMatchingBoxes[i].matchingBox.gotoAndStop(2);
				_curRightSideMatchingBoxes[_userMatchesLeftToRight[_curQuestionPage][i]].matchingBox.gotoAndStop(2);
				_curLeftMatchingLineEndPoints[i].lineEndPointDot.visible = true;
				_curLeftMatchingLineEndPoints[i].highlightedBorder.visible = true;
				_curRightMatchingLineEndPoints[_userMatchesLeftToRight[_curQuestionPage][i]].lineEndPointDot.visible = true;
				_curRightMatchingLineEndPoints[_userMatchesLeftToRight[_curQuestionPage][i]].highlightedBorder.visible = true;
			}
		}
	}
	public override function addChild(child:DisplayObject):DisplayObject
	{
		if(child.name == "instance198")
		{
			trace("FOUND HIM");
		}
		return super.addChild(child);
	}
	// mouse up anywhere will end a matching selection
	public function onMouseUp(e:MouseEvent):void
	{
		trace(e.target.name, e.target.parent.name);
		if(_nextMouseupWontSelect == true)
		{
			_nextMouseupWontSelect = false;
			return;
		}
		if(	_matchSelection1Side == LEFT && _matchSelection2Side == RIGHT)
		{
			addMatch(_matchSelection1Index, _matchSelection2Index, 0.0, true);
		}
		else if ( _matchSelection1Side == RIGHT && _matchSelection2Side == LEFT )
		{
			addMatch(_matchSelection2Index, _matchSelection1Index, 0.0, true);
		}
		if(_matchSelection1Side == LEFT)
		{
			setMouseOutBoxColor(_curLeftSideMatchingBoxes[_matchSelection1Index]);
		}
		if(_matchSelection1Side == RIGHT)
		{
			setMouseOutBoxColor(_curRightSideMatchingBoxes[_matchSelection1Index]);
		}
		_matchSelection1Side = NONE;
		_matchSelection1Index = -1;
		_matchSelection2Side = NONE;
		_matchSelection2Index = -1;
		_curMatchDrawingClip.graphics.clear();
	}
	protected function drawEndpointCircle(x:Number, y:Number, m:MovieClip, color:Number):void
	{
		m.graphics.beginFill(color);
		m.graphics.drawCircle(x-1 , y-1, 4);
		m.graphics.endFill();
	}
	// re-draw the match graphics on mouse move, only when there is a selection
	protected function onMouseMove(e:MouseEvent):void
	{
		if(_matchSelection1Index != -1)
		{
			// set up the box & end point that we currently selected
			var ep:MovieClip = null; // starting End Point
			var mb:MovieClip = null; // starting Matching Box
			var ep2:MovieClip // ending End Point
			var mb2:MovieClip // ending Matching Box
			if(_matchSelection1Side == LEFT)
			{
				ep = _curLeftMatchingLineEndPoints[_matchSelection1Index];
				mb = _curLeftSideMatchingBoxes[_matchSelection1Index];
			}
			else if( _matchSelection1Side == RIGHT)
			{
				ep = _curRightMatchingLineEndPoints[_matchSelection1Index];
				mb = _curRightSideMatchingBoxes[_matchSelection1Index];
			}
			// if they are over another match, connect to its end point
			// else go to the mouse point
			if(ep != null)
			{
				if(_matchSelection1Index != -1)
				{
					if(_matchSelection2Side == LEFT && _matchSelection2Side != _matchSelection1Side)
					{
						ep2 = _curLeftMatchingLineEndPoints[_matchSelection2Index];
						drawMatchingLine(_curMatchDrawingClip, ep.x + ep.width/2, ep.y + ep.height/2, ep2.x + ep2.width/2, ep2.y + ep2.height/2)
					}
					else if( _matchSelection2Side == RIGHT && _matchSelection2Side != _matchSelection1Side)
					{
						ep2 = _curRightMatchingLineEndPoints[_matchSelection2Index];
						drawMatchingLine(_curMatchDrawingClip, ep.x + ep.width/2, ep.y + ep.height/2, ep2.x + ep2.width/2, ep2.y + ep2.height/2)
					}
					else
					{
						drawMatchingLine(_curMatchDrawingClip, ep.x + ep.width/2, ep.y + ep.height/2, _curMatchDrawingClip.mouseX, _curMatchDrawingClip.mouseY)
					}
				}
				else
				{
					// does it actually even get here?
					_curMatchDrawingClip.graphics.clear();
				}
			}
		}
	}
	protected function drawMatchingLine(canvas:MovieClip, startX:Number, startY:Number, endX:Number, endY:Number):void
	{
		// clear
		canvas.graphics.clear();
		canvas.graphics.lineStyle(4, LINE_COLOR_ACTIVE);
		drawEndpointCircle(startX, startY, canvas, LINE_COLOR_ACTIVE);// starting circle
		canvas.graphics.moveTo(startX, startY);// move to starting point
		canvas.graphics.lineTo(endX, endY);// draw to end point
		drawEndpointCircle(endX, endY, canvas, LINE_COLOR_ACTIVE);// end point circle
	}
	// mouseing over a matching box changes the match selection
	protected function onMouseOverMatchingBox(e:MouseEvent):void
	{
		var indexReturn:Array = [];
		_matchSelection2Side = getLeftOrRight(e.currentTarget as MovieClip, indexReturn);
		if(_matchSelection2Side == _matchSelection1Side) return;
		_matchSelection2Index = indexReturn[0];
		if(_leftMatchClicked != -1)
		{
			setMouseOverBoxColor(_curLeftSideMatchingBoxes[_leftMatchClicked]);
		}
		if(_rightMatchClicked != -1)
		{
			setMouseOverBoxColor(_curRightSideMatchingBoxes[_rightMatchClicked]);
		}
	}
	protected function onMouseOutMatchingBox(e:MouseEvent):void
	{
		var index:Array = [];
		var side:int = getLeftOrRight(e.currentTarget as MovieClip, index);
		// if this is a mouse out for the 2nd selection, un-select it
		if(side == _matchSelection2Side && index[0] == _matchSelection2Index)
		{
			_matchSelection2Index = -1;
			_matchSelection2Side = NONE;
		}
		if(_leftMatchClicked != -1)
		{
			setMouseOutBoxColor(_curLeftSideMatchingBoxes[_leftMatchClicked]);
		}
		if(_rightMatchClicked != -1)
		{
			setMouseOutBoxColor(_curRightSideMatchingBoxes[_rightMatchClicked]);
		}
		checkForClickedMatches();
	}
	protected function cancelMatchLine(e:Event):void
	{
		_nextMouseupWontSelect = true;
		_matchSelection1Index = -1;
		_matchSelection1Side = NONE;
		_matchSelection2Index = -1;
		_matchSelection2Side = NONE;
		_curMatchDrawingClip.graphics.clear();
	}
	// mouse down in a matching box starts a matching selection
	protected function onMouseDownMatchingBox(e:MouseEvent):void
	{
		var index:Array = [];
		_matchSelection1Side = getLeftOrRight(e.currentTarget as MovieClip, index);
		_matchSelection1Index = index[0];
	}
	protected function onMouseUpMatchingBox(e:MouseEvent):void
	{
		updateMatchingEndpointDots()
		updateButtonStatus()
		if(_nextMouseupWontSelect == true)
		{
			// _nextMouseupWontSelect will be set false on the onMouseUp function
			return;
		}
		var indexReturn:Array = [];
		var side:int = getLeftOrRight(e.currentTarget as MovieClip, indexReturn);
		var index:int = indexReturn[0];
		if(side == LEFT)
		{
			_leftMatchClicked = index;
			checkForClickedMatches();
		}
		else if(side == RIGHT)
		{
			_rightMatchClicked = index;
			checkForClickedMatches();
		}
		if(_leftMatchClicked != -1)
		{
			setMouseOutBoxColor(_curLeftSideMatchingBoxes[_leftMatchClicked]);
		}
		if(_rightMatchClicked != -1)
		{
			setMouseOutBoxColor(_curRightSideMatchingBoxes[_rightMatchClicked]);
		}
	}
	// try to form matches by clicking one, then the other
	protected function checkForClickedMatches():void
	{
		if( _leftMatchClicked != -1 && _rightMatchClicked != -1)
		{
			addMatch(_leftMatchClicked, _rightMatchClicked,0.0, true);
		}
	}
	/**
	* Called at the beginning of the game to set up all the questions and answers.
	*/
	protected function initGameContent():void // get external data from gameserv to make the game
	{
		if(EngineCore.qSetData.items[0].items[0].options != null && EngineCore.qSetData.items[0].items[0].options["caseSensitive"] != null)
		{
			_isCaseSensitive = EngineCore.qSetData.items[0].items[0].options.caseSensitive;
		}
		else
		{
			_isCaseSensitive = false;
		}
		// populate the choices lists
		var i:int, j:int = -1;
		var numberOfPages:Number = Math.ceil(EngineCore.qSetData.items[0].items.length / QUESTIONS_PER_PAGE);
		var tempLeftChoiceStrings:Array = new Array();
		var tempRightChoiceStrings:Array = new Array();
		var tempLeftChoiceIDs:Array = new Array();
		var tempHints:Array = new Array();
		// get all the data
		for(i=0; i< EngineCore.qSetData.items[0].items.length; i++)
		{
			if(EngineCore.qSetData.items[0].items[i].questions)
			{
				tempLeftChoiceStrings.push(EngineCore.qSetData.items[0].items[i].questions[0].text);
			}
			else
			{
				tempLeftChoiceStrings.push("Question Error");
			}
			if(EngineCore.qSetData.items[0].items[i].answers)
			{
				tempRightChoiceStrings.push(EngineCore.qSetData.items[0].items[i].answers[0].text);
			}
			else
			{
				tempRightChoiceStrings.push("Answer Error");
			}
			tempLeftChoiceIDs.push(EngineCore.qSetData.items[0].items[i].id);
			if(EngineCore.qSetData.items[0].items[i]["options"] != null && EngineCore.qSetData.items[0].items[i].options["hint"] != null)
			{
				tempHints.push( EngineCore.qSetData.items[0].items[i].options.hint);
			}
		}
		// distribute data to pages randomly
		_leftSideTexts = new Array();
		_rightSideTexts = new Array();
		_leftSideQuestionIds = new Array();
		for(i=0; i< numberOfPages; i++)
		{
			_leftSideTexts.push(new Array());
			_rightSideTexts.push(new Array());
			_leftSideQuestionIds.push(new Array());
		}
		// randomize the question order
		user_so = SharedObject.getLocal('rSeed');
		if(user_so.data.rNum == undefined)
		{
			user_so.data.rNum = Math.floor(Math.random()*1000000000);
		}
		var rand:Number = user_so.data.rNum;
		var r:Number;
		for(i=0; i< EngineCore.qSetData.items[0].items.length; i++)
		{
			rand = MiddleSquareRNG.randomNumber(rand);
			r = rand % tempLeftChoiceStrings.length;
			_leftSideTexts[i%numberOfPages].push( tempLeftChoiceStrings[r]);
			_rightSideTexts[i%numberOfPages].push( tempRightChoiceStrings[r]);
			_leftSideQuestionIds[i%numberOfPages].push( tempLeftChoiceIDs[r]);
			tempLeftChoiceStrings.splice(r,1);
			tempRightChoiceStrings.splice(r,1);
			tempLeftChoiceIDs.splice(r,1);
			tempHints.splice(r,1);
		}
		// make the scrambled right choice indices array
		_scrambledRightSideTexts = new Array();
		for(i = 0; i < _rightSideTexts.length; i++)
		{
			_scrambledRightSideTexts.push(randomArray(_rightSideTexts[i].length));
		}
		_userMatchesLeftToRight = new Array();
		// init the array for storing match locating numbers
		for(j=0; j< _leftSideTexts.length; j++)
		{
			_userMatchesLeftToRight[j] = new Array();
			for(i=0;i<_leftSideTexts[j].length; i++)
			{
				_userMatchesLeftToRight[j][i] = -1;
			}
		}
	}
	/**
	* Return a random array of the numbers 0 through num-1
	*/
	protected function randomArray(num:Number):Array
	{
		var c:Array,d:Array
		var i:int
		var r:int;
		c = new Array();
		for(i = 0; i < num; i++)
		{
			c.push(i);
		}
		d = new Array();
		while( c.length > 0)
		{
			r = Math.floor(Math.random()*c.length);
			d.push(c[r]);
			c.splice(r,1);
		}
		return d;
	}
	/**
	* End the game.
	*/
	public function gameOver():void
	{
		var i:int, j:int, c:int = 0;
		// they answered all the questions?
		for(i=0; i<_userMatchesLeftToRight.length; i++)
		{
			for(j=0; j<_userMatchesLeftToRight[i].length; j++)
			{
				if(_userMatchesLeftToRight[i][j] == -1) // a question has not been answered
				{
					return;
				}
			}
		}
		var correct:int = 0;
		for(i=0; i<_userMatchesLeftToRight.length; i++)
		{
			for(j=0; j<_userMatchesLeftToRight[i].length; j++)
			{
				var correctAnswer:String = _rightSideTexts[i][j];
				var answer:String = _rightSideTexts[i][_scrambledRightSideTexts[i][_userMatchesLeftToRight[i][j]]];
				scoring.submitQuestionForScoring(String(_leftSideQuestionIds[i][j]), answer);
				c++;
			}
		}
		user_so.clear();
		// submits the score and goes to the score screen
		end();
	}
	// made using the easing explorer found at http://www.madeinflex.com/img/entries/2007/05/customeasingexplorer.html
	protected static function customTween(t:Number, b:Number, c:Number, d:Number):Number
	{
		var ts:Number=(t/=d)*t;
		var tc:Number=ts*t;
		return b+c*(0*tc*ts + -1*ts*ts + 4*tc + -6*ts + 4*t);
	}
}
}
import flash.display.MovieClip;
class MatchableItem extends MovieClip
{
	public var matchingBox:MovieClip;
}