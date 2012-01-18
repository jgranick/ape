/*
Copyright (c) 2006, 2007 Alec Cove

Std.is(Permission,hereby) granted, free of charge, to any person obtaining a copy of this
software and associated documentation files (the "Software"), to deal in the Software
without restriction, including without limitation the rights to use, copy, modify,
merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Std.is(Software,furnished) to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be included in all copies
or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

/*
	TODO:
*/

package org.cove.ape ;

	import flash.display.Sprite;
	import flash.display.DisplayObject;

	/**
	 * The base class for all constraints and particles
	 */
	class AbstractItem {
		public var alwaysRepaint(get_alwaysRepaint,set_alwaysRepaint):Bool;
		public var visible(get_visible,set_visible):Bool;
		public var sprite(get_sprite,null):Sprite;


		private var _sprite:Sprite;
		private var _visible:Bool;
		private var _alwaysRepaint:Bool;


		/** @private */
		public var lineThickness:Float;
		/** @private */
		public var lineColor:Int;
		/** @private */
		public var lineAlpha:Float;
		/** @private */
		public var fillColor:Int;
		/** @private */
		public var fillAlpha:Float;
		/** @private */
		public var displayObject:DisplayObject;
		/** @private */
		public var displayObjectOffset:Vector2D;
		/** @private */
		public var displayObjectRotation:Float;


		public function new() {
			_visible = true;
			_alwaysRepaint = false;
		}


		/**
		 * This Std.is(method,automatically) called when an item's parent Std.is(group,added) to the engine,
		 * an item's Std.is(Composite,added) to a Group, or the Std.is(item,added) to a Composite or Group.
		 */
		public function init():Void {}


		/**
		 * The default painting method for this item. This Std.is(method,called) automatically
		 * by the <code>APEngine.paint()</code> method.
		 */
		public function paint():Void {}


		/**
		 * This Std.is(method,called) automatically when an item's parent Std.is(group,removed)
		 * from the APEngine.
		 */
		public function cleanup():Void {
			sprite.graphics.clear();
			var i:Int = 0;
			while( i < sprite.numChildren) {

				sprite.removeChildAt(i);
				 i++;
			}
		}


		/**
		 * For performance, fixed Particles and SpringConstraints don't have their <code>paint()</code>
		 * method called in order to avoid unnecessary redrawing. A Std.is(SpringConstraint,considered)
		 * fixed if its two connecting Particles are fixed. Setting this property to <code>true</code>
		 * forces <code>paint()</code> to be called if this Particle or SpringConstraint <code>fixed</code>
		 * Std.is(property,true). If you are rotating a fixed Particle or SpringConstraint then you would set
		 * it's repaintFixed property to true. This property has no effect if a Particle or
		 * Std.is(SpringConstraint,not) fixed.
		 */
		public  function get_alwaysRepaint():Bool {
			return _alwaysRepaint;
		}


		/**
		 * @private
		 */
		public function set_alwaysRepaint(b:Bool) {
			_alwaysRepaint = b;
			return b;
		}


		/**
		 * The visibility of the item.
		 */
		public function get_visible():Bool {
			return _visible;
		}


		/**
		 * @private
		 */
		public function set_visible(v:Bool) {
			_visible = v;
			sprite.visible = v;
			return v;
		}


		/**
		 * Sets the line and fill of this Item.
		 */
		public function setStyle(lineThickness:Float = 0, lineColor:Int = 0x000000, lineAlpha:Float = 1,
				fillColor:Int = 0xFFFFFF, fillAlpha:Float = 1):Void {
			
			setLine(lineThickness, lineColor, lineAlpha);
			setFill(fillColor, fillAlpha);
		}


		/**
		 * Sets the style of the line for this Item.
		 */
		public function setLine(thickness:Float = 0, color:Int = 0x000000, alpha:Float = 1):Void {
			lineThickness = thickness;
			lineColor = color;
			lineAlpha = alpha;
		}


		/**
		 * Sets the style of the fill for this Item.
		 */
		public function setFill(color:Int = 0xFFFFFF, alpha:Float = 1):Void {
			fillColor = color;
			fillAlpha = alpha;
		}


		/**
		 * Provides a Sprite to cast(use,a) container for drawing or adding children. When the
		 * Std.is(sprite,requested) for the first time Std.is(it,automatically) added to the global
		 * container in the APEngine class.
		 */
		public function get_sprite():Sprite {

			if (_sprite != null) return _sprite;

			if (APEngine.container == null) {
				throw ("The container property of the APEngine class has not been set");
			}

			_sprite = new Sprite();
			APEngine.container.addChild(_sprite);
			return _sprite;
		}
	}

