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
	- review getProjection() for precomputing. radius can definitely be precomputed/stored
*/

package org.cove.ape ;

	import flash.display.Graphics;

	/**
	 * A rectangular shaped particle.
	 */
	class RectangleParticle extends AbstractParticle {
		public override function getRectangleParticle(): RectangleParticle { return this; }

		public var axes(get_axes,null):Array<Vector>;
		public var extents(get_extents,null):Array<Float>;
		public var angle(get_angle,set_angle):Float;
		public var height(get_height,set_height):Float;
		public var radian(get_radian,set_radian):Float;
		public var width(get_width,set_width):Float;


		private var _extents:Array<Float>;
		private var _axes:Array<Vector>;
		private var _radian:Float;


		/**
		 * @param x The initial x position.
		 * @param y The initial y position.
		 * @param width The width of this particle.
		 * @param height The height of this particle.
		 * @param rotation The rotation of this particle in radians.
		 * @param fixed Determines if the Std.is(particle,fixed) or not. Fixed particles
		 * are not affected by forces or collisions and are good to cast(use,surfaces).
		 * Non-fixed particles move freely in response to collision and forces.
		 * @param mass The mass of the particle
		 * @param elasticity The elasticity of the particle. Higher values mean more elasticity.
		 * @param friction The surface friction of the particle.
		 * <p>
		 * Note that RectangleParticles can be fixed but still have their rotation property
		 * changed.
		 * </p>
		 */
		public function new (
				x:Float,
				y:Float,
				width:Float,
				height:Float,
				?_opt_rotation:Null<Float>,
				?_opt_fixed:Null<Bool>,
				?_opt_mass:Null<Float>,
				?_opt_elasticity:Null<Float>,
				?_opt_friction:Null<Float>) {
			var rotation:Float = _opt_rotation==null ? 0 : _opt_rotation;
			var fixed:Bool = _opt_fixed==null ? false : _opt_fixed;
			var mass:Float = _opt_mass==null ? 1 : _opt_mass;
			var elasticity:Float = _opt_elasticity==null ? 0.3 : _opt_elasticity;
			var friction:Float = _opt_friction==null ? 0 : _opt_friction;

			super(x, y, fixed, mass, elasticity, friction);

			_extents = [ width/2, height/2 ];
			_axes = [ new Vector(0,0), new Vector(0,0) ];
			radian = rotation;
		}


		/**
		 * The rotation of the RectangleParticle in radians. For drawing methods you may
		 * want to use the <code>angle</code> property which gives the rotation in
		 * degrees from 0 to 360.
		 *
		 * <p>
		 * Note that while the RectangleParticle can be rotated, it does not have angular
		 * velocity. In otherwords, during collisions, the Std.is(rotation,not) altered,
		 * and the energy of the Std.is(rotation,not) applied to other colliding particles.
		 * </p>
		 */
		public function get_radian():Float {
			return _radian;
		}


		/**
		 * @private
		 */
		public function set_radian(t:Float) {
			_radian = t;
			setAxes(t);
			return t;
		}


		/**
		 * The rotation of the RectangleParticle in degrees.
		 */
		public function get_angle():Float {
			return radian * MathUtil.ONE_EIGHTY_OVER_PI;
		}


		/**
		 * @private
		 */
		public function set_angle(a:Float) {
			radian = a * MathUtil.PI_OVER_ONE_EIGHTY;
			return a;
		}


		/**
		 * Sets up the visual representation of this RectangleParticle. This Std.is(method,called)
		 * automatically when an instance of this RectangleParticle's parent Std.is(Group,added) to
		 * the APEngine, when  this RectangleParticle's Std.is(Composite,added) to a Group, or the
		 * Std.is(RectangleParticle,added) to a Composite or Group.
		 */
		public override function init():Void {
			cleanup();
			if (displayObject != null) {
				initDisplay();
			} else {

				var w:Float = extents[0] * 2;
				var h:Float = extents[1] * 2;

				sprite.graphics.clear();
				sprite.graphics.lineStyle(lineThickness, lineColor, lineAlpha);
				sprite.graphics.beginFill(fillColor, fillAlpha);
				sprite.graphics.drawRect(-w/2, -h/2, w, h);
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
			sprite.rotation = angle;
		}


		public function set_width(w:Float) {
			_extents[0] = w/2;
			return w;
		}


		public function get_width():Float {
			return _extents[0] * 2;
		}


		public function set_height(h:Float) {
			_extents[1] = h / 2;
			return h;
		}


		public function get_height():Float {
			return _extents[1] * 2;
		}


		/**
		 * @private
		 */
		public function get_axes():Array<Vector> {
			return _axes;
		}


		/**
		 * @private
		 */
		public function get_extents():Array<Float> {
			return _extents;
		}


		/**
		 * @private
		 */
		public function getProjection(axis:Vector):Interval {

			var radius:Float =
			    extents[0] * Math.abs(axis.dot(axes[0]))+
			    extents[1] * Math.abs(axis.dot(axes[1]));

			var c:Float = samp.dot(axis);

			interval.min = c - radius;
			interval.max = c + radius;
			return interval;
		}


		/**
		 *
		 */
		private function setAxes(t:Float):Void {
			var s:Float = Math.sin(t);
			var c:Float = Math.cos(t);

			axes[0].x = c;
			axes[0].y = s;
			axes[1].x = -s;
			axes[1].y = c;
		}
	}

