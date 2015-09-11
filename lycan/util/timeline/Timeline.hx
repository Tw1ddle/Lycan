package lycan.util.timeline;

import haxe.ds.ObjectMap;

// Timeline based on Cinder timelines
class Timeline<T:{}> extends TimelineItem {
	public var currentTime(default, null):Float;
	public var defaultAutoRemoveCues:Bool;
	private var items:ObjectMap<T, Array<TimelineItem>>;
	
	public function new() {
		super(null, null, 0, 0);
		currentTime = 0;
		defaultAutoRemoveCues = false;
		useAbsoluteTime = true;
		items = new ObjectMap<T, Array<TimelineItem>>();
	}
	
	public function step(dt:Float):Void {
		currentTime += dt;
		super.stepTo(currentTime, dt < 0);
	}
	
	override public function stepTo(nextTime:Float, ?reverse:Bool):Void {
		reverse = currentTime > nextTime;
		currentTime = nextTime;
		
		eraseMarked();
		
		var iter = items.iterator();
		for (items in iter) {
			for (item in items) {
				item.stepTo(currentTime, reverse);
				if (item.completed && item.autoRemove) {
					item.markedForRemoval = true;
				}
			}
		}
		
		eraseMarked();
	}
	
	override public function update(absoluteTime:Float):Void {
		absoluteTime = loopTime(absoluteTime);
		stepTo(absoluteTime);
	}
	
	public function addFunction(target:T, f:Void->Void, atTime:Float):Cue {
		var cue = new Cue(target, f, atTime);
		cue.autoRemove = defaultAutoRemoveCues;
		add(cue);
		return cue;
	}
	
	//public function apply(item:TimelineItem):Void {
	//	if (item.target != null) {
	//		removeTarget(item.target);
	//	}
	//	add(item);
	//}
	
	public function add(item:TimelineItem):Void {
		Sure.sure(item != null);
		Sure.sure(item.target != null);
		
		item.parent = this;
		
		var existingItems = items.get(item.target);
		
		if (existingItems != null) {
			existingItems.push(item);
		} else {
			items.set(item.target, [ item ]);
		}
		
		dirtyDuration = true;
	}
	
	public function addAtTime(item:TimelineItem, ?time:Float):Void {
		if(time == null) {
			item.startTime = currentTime;
		} else {
			item.startTime = time;
		}
		add(item);
	}
	
	public function find(target:T):Array<TimelineItem> {
		return items.get(target);
	}
	
	public function remove(itemToRemove:TimelineItem):Void {
		for (items in items.iterator()) {
			for (item in items) {
				if (item == itemToRemove) {
					item.markedForRemoval = true;
				}
			}
		}
	}
	
	public function removeTarget(target:T):Void {
		if (target == null) {
			return;
		}
		
		var arr = items.get(target);
		for (item in arr) {
			item.markedForRemoval = true;
		}
		
		dirtyDuration = true;
	}
	
	public function replaceTarget(target:T, replacement:T):Void {
		if (target == null) {
			return;
		}
		
		var arr = items.get(target);
		items.remove(target);
		
		if(arr != null) {
			items.set(replacement, arr);
		}
	}
	
	public function clear():Void {
		items = new ObjectMap<T, Array<TimelineItem>>();
	}
	
	override public function reset(unsetStarted:Bool = false):Void {
		super.reset(unsetStarted);
		
		for (items in items.iterator()) {
			for (item in items) {
				item.reset(unsetStarted);
			}
		}
	}
	
	public function itemTimeChanged(item:TimelineItem):Void {
		dirtyDuration = true;
	}
	
	override public function reverse():Void {
		for (items in items.iterator()) {
			for (item in items) {
				item.reverse();
			}
		}
	}
	
	override public function onLoopStart():Void {
		reset(false);
	}
	
	private function eraseMarked():Void {
		for (items in items.iterator()) {
			for (item in items) {
				if (item.markedForRemoval) {
					items.remove(item);
				}
			}
		}
		dirtyDuration = true;
	}
	
	override public function calcDuration():Float {
		var duration:Float = 0;
		for (items in items.iterator()) {
			for (item in items) {
				duration = Math.max(item.endTime, duration);
			}
		}
		return duration;
	}
	
	override public function get_endTime():Float {
		if (dirtyDuration) {
			duration = calcDuration();
		}
		return startTime + duration;
	}
}