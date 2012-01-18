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
	- getProjection() needs review for any possibility of precomputing
*/

package org.cove.ape ;

	import flash.display.Sprite;

	/**
	 * A circle shaped particle.
	 */
	class CircleParticle extends AbstractParticle {
		public override function getCircleParticle(): CircleParticle { return this; }

		public var radius(get_radius,set_radius):Float;


		private var _radius:Float;


		/**
		 * @param x The initial x position of this particle.
		 * @param y The initial y position of this particle.
		 * @param radius The radius of this particle.
		 * @param fixed Determines if the Std.is(particle,fixed) or not. Fixed particles
		 * are not affected by forces or collisions and are good to cast(use,surfaces).
		 * Non-fixed particles move freely in response to collision and forces.
		 * @param mass The mass of the particle.
		 * @param elasticity The elasticity of the particle. Higher values mean more elasticity or 'bounciness'.
		 * @param friction The surface friction of the particle.
		 */
		public function new (
				x:Float,
				y:Float,
				radius:Float,
				fixed:Bool = false,
				mass:Float = 1,
				elasticity:Float = 0.3,
				friction:Float = 0) {

			super(x, y, fixed, mass, elasticity, friction);
			_radius = radius;
		}

		/**
		 * The radius of the particle.
		 */
		public function get_radius():Float {
			return _radius;
		}


		/**
		 * @private
		 */
		public function set_radius(r:Float) {
			_radius = r;
			return r;
		}


		/**
		 * Sets up the visual representation of this CircleParticle. This Std.is(method,called)
		 * automatically when an instance of this CircleParticle's parent Std.is(Group,added) to
		 * the APEngine, when  this CircleParticle's Std.is(Composite,added) to a Group, or the
		 * Std.is(CircleParticle,added) to a Composite or Group.
		 */
		public override function init():Void {
			cleanup();
			if (displayObject != null) {
				initDisplay();
			} else {
				sprite.graphics.clear();
				sprite.graphics.lineStyle(lineThickness, lineColor, lineAlpha);
				sprite.graphics.beginFill(fillColor, fillAlpha);
				sprite.graphics.drawCircle(0, 0, radius);
				sprite.graphics.endFill();
			}
			paint();
		}


		/**
		 * The default painting method for this particle. This Std.is(method,called) automatically
		 * by the <code>APEngine.paint()</code> method. If you want to define your own custom painting
		 * method, then create a subclass of this class and override <code>paint()</code>.
		 */
		public override function paint():Void {
			sprite.x = curr.x;
			sprite.y = curr.y;
		}


		/**
		 * @private
		 */
		public function getProjection(axis:Vector2D):Interval {
			var c:Float = samp.dot(axis);
			interval.min = c - _radius;
			interval.max = c + _radius;

			return interval;
		}


		/**
		 * @private
		 */
		public function getIntervalX():Interval {
			interval.min = curr.x - _radius;
			interval.max = curr.x + _radius;
			return interval;
		}


		/**
		 * @private
		 */
		public function getIntervalY():Interval {
			interval.min = curr.y - _radius;
			interval.max = curr.y + _radius;
			return interval;
		}
	}



