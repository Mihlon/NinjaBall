package game {
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	public class DrawingController extends EventDispatcher{
		private var _parentContainer:Sprite;
		private var _drawingContainer:Sprite;
		private var _drawing:Boolean;
		private var _pathParts:Vector.<Sprite>;

		private var _ninja:Sprite;
		
		private var _currentX:Number;
		private var _currentY:Number;
		
		private var _partsDistance:Number;
		private var _partShape:String;
		
		public static const SHAPE_RECTANGLE:String = "rectangle";
		
		public function DrawingController(container:Sprite, ninja:Sprite) {
			super();
			_ninja = ninja;
			_partsDistance = 2;
			_parentContainer = container;
			_drawingContainer = new Sprite();
			_parentContainer.addChild(_drawingContainer);
		}
		
		public function setPathPartsDistance(value:Number):void {
			_partsDistance = value;
		}
		
		public function setPartShape(shapeName:String):void {
			_partShape = shapeName;
		}
		
		public function removePoint(point:Point):void {
			if (!_pathParts) { return; }
			for (var i:int = 0; i < _pathParts.length; ++i) {
				if (_pathParts[i].x == point.x && _pathParts[i].y == point.y) {
					if (_drawingContainer.contains(_pathParts[i])) {
						_drawingContainer.removeChild(_pathParts[i]);
					}
					//removeFirstPoints(i+1);
				}
			}
		}

		private function removePathPart(pathPart:Sprite):void {
			if (!_pathParts) { return; }
			if (_drawingContainer.contains(pathPart)) {
				_drawingContainer.removeChild(pathPart);
				var index:int = _pathParts.indexOf(pathPart);
				if (index != -1) { _pathParts.splice(index, 1); }
			}
		}

		public function removeAllParts():void {
			for each (var pathPart:Sprite in _pathParts) {
				if (_drawingContainer.contains(pathPart)) {
					_drawingContainer.removeChild(pathPart);
				}
			}
			_pathParts = null;
		}

		public function addListeners():void {
			_parentContainer.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			_parentContainer.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			_parentContainer.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
		}
		
		public function removeListeners():void {
			_parentContainer.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			_parentContainer.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			_parentContainer.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			_parentContainer.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
		}
		
		/* Internal functions */
		
		private function removeFirstPoints(num:int):void {
			for (var i:int = 0; i < num; ++i) {
				if (_drawingContainer.contains(_pathParts[i])) {
					_drawingContainer.removeChild(_pathParts[i]);
				} else { trace(" WARN [DrawingController.removePoint] pathPart dosnt contains on drawingContainer"); }
			}
			_pathParts.splice(0, num);
		}

		private function onEnterFrame(event:Event):void {
			drawPathToCurrentPoint();	
		}
		
		private function drawPathToCurrentPoint():void {
			if (!_drawing || !needDrawLine()) { return; }
			var lastPoint:Point = (_pathParts && _pathParts.length > 0) ?
											new Point(_pathParts[_pathParts.length-1].x, _pathParts[_pathParts.length-1].y) :
											null;
			var newPathPart:Sprite;
			if (!lastPoint) {
				newPathPart = createPathPart();
				addNewPathPart(newPathPart);
			} else {
				var nowPoint:Point = new Point(_currentX, _currentY);
				var lineLength:Number = Point.distance(lastPoint, nowPoint);
				for (var i:int = 4 + _partsDistance; i < lineLength; i+= 4 + _partsDistance) {
					newPathPart = createPathPart( Point.interpolate(nowPoint, lastPoint, i / lineLength) );
					addNewPathPart(newPathPart);
				}
			}
		}
		
		private function addNewPathPart(pathPart:Sprite):void {
			_drawingContainer.addChild(pathPart);
			addPathPartToVector(pathPart);
			dispatchEvent(new DrawingControllerEvent(DrawingControllerEvent.ADD_PATH_POINT, new Point(pathPart.x, pathPart.y)));
		}
		
		private function needDrawLine():Boolean {
			if (_pathParts && _pathParts.length > 0) {
				if ( (_pathParts[_pathParts.length-1].x - _currentX < 6 &&
					_pathParts[_pathParts.length-1].x - _currentX > -6) &&
					(_pathParts[_pathParts.length-1].y - _currentY < 6 &&
						_pathParts[_pathParts.length-1].y - _currentY > -6) ) {
							return false;
						}
			}
			return true;
		}
		
		private function onMouseMove(event:MouseEvent):void {
			if (_drawing) {
				_currentX = event.stageX;
				_currentY = event.stageY;
			}
		}
		
		private function onMouseDown(event:MouseEvent):void {
			trace("mouse down");
			if (_ninja.hitTestPoint(event.stageX, event.stageY)) {
				trace("mouse down on ninja");
				removeAllPathParts();
				_drawing = true;
				_currentX = event.stageX;
				_currentY = event.stageY;
				_parentContainer.addEventListener(Event.ENTER_FRAME, onEnterFrame);
				dispatchEvent(new DrawingControllerEvent(DrawingControllerEvent.START_DRAWING_PATH, new Point(event.stageX, event.stageY)));
			}
		}
		
		private function onMouseUp(event:MouseEvent):void {
			_parentContainer.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			_drawing = false;
		}
		
		private function removeAllPathParts():void {
			for each (var part:Sprite in _pathParts) { _drawingContainer.removeChild(part); }
			_pathParts = null;
		}
		
		private function addPathPartToVector(pathPart:Sprite):void {
			if (!_pathParts) { _pathParts = new Vector.<Sprite>(); }
			_pathParts.push(pathPart);
		}
		
		private function createPathPart(point:Point = null):Sprite {
			var result:Sprite = new Sprite();
			result.graphics.beginFill(0x000000);
			if (_partShape == SHAPE_RECTANGLE) {
				result.graphics.drawRect(-3, -3, 6, 6);
			} else { result.graphics.drawCircle(0, 0, 2); }
			result.graphics.endFill();
			if (point) {
				result.x = point.x;
				result.y = point.y;
			} else {
				result.x = _currentX;
				result.y = _currentY;
			}
			return result;
		}
		
	}
}