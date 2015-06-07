package gameUtil;
import flash.display.Graphics;
import flash.display.Stage;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.input.touch.FlxTouch;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxVector;
import flixel.util.FlxColor;
import flixel.math.FlxRect;
import openfl.display.Sprite;

/**
 * @author Joe Williamson
 */
class ScrollPanel extends FlxSprite {
	
	public var panelCamera:FlxCamera;
	
	public var scrollVelocity:FlxPoint;
	public var scrollDrag:Float = 0.05;
	/** How quickly panel camera moves back to within bounds */
	public var boundaryForce:Float = 0.14;
	/** How far over the bounds the camera may be dragged */
	public var boundaryAllowance(default, set):Float = 20;
	/** How much scrollVelocity changes based on last touch position change */
	public var scrollVelocityChangeFactor:Float = 0.35;
	/** Minimum speed panel can move with no touches */
	public var minScrollSpeed:Float = 0.5;
	/** Minimum speed can retain after a touch is released */
	public var minReleaseScrollSpeed:Float = 1;
	/** Minimum distance a touch must have moved before panel begins to scroll */
	public var minMovement:Float = 8;
	
	public var scroll(get, never):FlxPoint;
	public var minScrollX(get, set):Null<Float>;
	public var maxScrollX(get, set):Null<Float>;
	public var minScrollY(get, set):Null<Float>;
	public var maxScrollY(get, set):Null<Float>;
	
	public var scrollVertically(get, never):Bool;
	public var scrollHorizontally(get, never):Bool;
	
	private var screenPosition:FlxPoint;
	
	private var touch:FlxTouch;
	private var touchedPosition:FlxPoint;
	private var lastTouchPosition:FlxPoint;
	private var movedMinimum:Bool;
	
	public function new(x:Float, y:Float, width:Float, height:Float) {
		panelCamera = new FlxCamera(0, 0, 0, 0);
		#if FLX_RENDER_TILE
		panelCamera.pixelPerfectRender = false;
		#end
		super(x, y);
		makeGraphic(Std.int(FlxMath.bound(width, 1)), Std.int(FlxMath.bound(height, 1)), FlxColor.TRANSPARENT);
		panelCamera.setSize(Std.int(width), Std.int(height));
		
		screenPosition = FlxPoint.get();
		touchedPosition = FlxPoint.get();
		lastTouchPosition = FlxPoint.get();
		scrollVelocity = FlxPoint.get();
		
		updatePosition();
		FlxG.cameras.add(panelCamera);
	}
	
	/** Add a group to this ScrollPanel */
	public function add(object:FlxBasic):Void {
		object.cameras = [panelCamera];
	}
	
	public function setScrollBounds(?minX:Float, ?maxX:Float, ?minY:Float, ?maxY:Float):Void {
		panelCamera.setScrollBounds(minX - boundaryAllowance, maxX + boundaryAllowance,
			minY - boundaryAllowance, maxY + boundaryAllowance);
	}
	
	override public function destroy():Void {
		super.destroy();
		FlxG.cameras.remove(panelCamera);
		screenPosition.put();
		touchedPosition.put();
		scrollVelocity.put();
	}
	
	override public function update(elapsed:Float):Void {
		super.update(elapsed);
		
		// Get touch started on this panel
		if (touch == null) {
			for (touch in FlxG.touches.justStarted()) {
				if (touch.overlaps(this)) {
					this.touch = touch;
					movedMinimum = false;
					scrollVelocity.set(0, 0);
					touchedPosition.set(touch.x, touch.y);
					lastTouchPosition.copyFrom(touchedPosition);
					break;
				}
			}
		}
	
		if (touch != null) {
			var xDiff:Float = touch.x - lastTouchPosition.x;
			var yDiff:Float = touch.y - lastTouchPosition.y;
			// Update scroll velocity
			scrollVelocity.x = scrollHorizontally ? scrollVelocityChangeFactor * -xDiff + (1 - scrollVelocityChangeFactor) * scrollVelocity.x : 0;
			scrollVelocity.y = scrollVertically ? scrollVelocityChangeFactor * -yDiff + (1 - scrollVelocityChangeFactor) * scrollVelocity.y : 0;		
			// Touch released
			if (touch.justReleased) {
				touch = null;
				// Enforce minimum release scroll speed and minimum movement
				if (!movedMinimum || FlxMath.vectorLength(scrollVelocity.x, scrollVelocity.y) < minReleaseScrollSpeed) {
					scrollVelocity.set(0, 0);
				}
			}
			// Update position from touch movement
			else if (movedMinimum || FlxMath.vectorLength(xDiff, yDiff) > minMovement) {
				movedMinimum = true;
				lastTouchPosition.set(touch.x, touch.y);
				panelCamera.scroll.subtract(scrollHorizontally ? xDiff : 0, scrollVertically ? yDiff : 0);
			}
		}
		// Apply velocity
		else {
			panelCamera.scroll.addPoint(scrollVelocity);
			scrollVelocity.x *= 1 - scrollDrag;
			scrollVelocity.y *= 1 - scrollDrag;
			if (FlxMath.vectorLength(scrollVelocity.x, scrollVelocity.y) < minScrollSpeed) {
				scrollVelocity.set(0, 0);
			}
			
			if (maxScrollX != null && scroll.x + width > maxScrollX) {
				scroll.x -= (scroll.x + width - maxScrollX) * boundaryForce;
				scrollVelocity.x = 0;
			}
			if (minScrollX != null && scroll.x < minScrollX) {
				scroll.x += (minScrollX - scroll.x) * boundaryForce;
				scrollVelocity.x = 0;
			}
			if (maxScrollY != null && scroll.y + height > maxScrollY) {
				scroll.y -= (scroll.y + height - maxScrollY) * boundaryForce;
				scrollVelocity.y = 0;
			}
			if (minScrollY != null && scroll.y < minScrollY) {
				scroll.y += (minScrollY - scroll.y) * boundaryForce;
				scrollVelocity.y = 0;
			}
		}
		
	}
	
	override public function draw():Void {
		updatePosition();
		super.draw();
	}
	
	private function get_scroll():FlxPoint {
		return panelCamera.scroll;
	}
	
	private function get_minScrollX():Float {
		return panelCamera.minScrollX + boundaryAllowance;
	}
	private function set_minScrollX(value:Float):Float {
		panelCamera.minScrollX = value - boundaryAllowance;
		return value;
	}
	private function get_maxScrollX():Float {
		return panelCamera.maxScrollX - boundaryAllowance;
	}
	private function set_maxScrollX(value:Float):Float {
		panelCamera.maxScrollX = value + boundaryAllowance;
		return value;
	}
	
	private function get_minScrollY():Float {
		return panelCamera.minScrollY + boundaryAllowance;
	}
	private function set_minScrollY(value:Float):Float {
		panelCamera.minScrollY = value - boundaryAllowance;
		return value;
	}
	private function get_maxScrollY():Float {
		return panelCamera.maxScrollY - boundaryAllowance;
	}
	private function set_maxScrollY(value:Float):Float {
		panelCamera.maxScrollY = value + boundaryAllowance;
		return value;
	}
	
	public function updatePosition():Void {
		getScreenPosition(screenPosition);
		panelCamera.setPosition(camera.x + Math.floor(screenPosition.x * camera.zoom), camera.y + Math.floor(screenPosition.y * camera.zoom));
	}
	
	override private function set_width(width:Float):Float {
		super.set_width(width);
		panelCamera.width = Std.int(width);
		return width;
	}
	
	override private function set_height(height:Float):Float {
		super.set_height(height);
		panelCamera.height = Std.int(height);
		return height;
	}
	
	private function get_scrollHorizontally():Bool {
		return width < maxScrollX - minScrollX;
	}
	
	private function get_scrollVertically():Bool {
		return height < maxScrollY - minScrollY;
	}
	
	private function set_boundaryAllowance(allowance:Float):Float {
		var diff:Float = allowance - this.boundaryAllowance;
		// Modify bound allowance on actual camera bounds
		panelCamera.setScrollBounds(panelCamera.minScrollX - diff, panelCamera.maxScrollX + diff,
			panelCamera.minScrollY - diff, panelCamera.maxScrollY + diff);
		return this.boundaryAllowance = allowance;
	}
}