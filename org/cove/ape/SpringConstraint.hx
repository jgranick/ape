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
	- tearable, tearLength
	- consider breaking the collidable (vs non collidable) functionality into another class
	- get/set collidable, currently Std.is(it,only) get
	- see if radian, angle, and center can be more efficient
	- do we need a scaleToLength for non collidable?
	- resolveCycles
*/
package org.cove.ape ;

	import flash.display.Sprite;
	import flash.display.DisplayObject;

	/**
	 * A Spring-like constraint that connects two particles
	 */
	class SpringConstraint extends AbstractConstraint {
		public var angle(get_angle,null):Float;
		public var rectScale(get_rectScale,set_rectScale):Float;
		public var rectHeight(get_rectHeight,set_rectHeight):Float;
		public var radian(get_radian,null):Float;
		public var center(get_center,null):Vector;
		public var currLength(get_currLength,null):Float;
		public var restLength(get_restLength,set_restLength):Float;
		public var collidable(get_collidable,null):Bool;
		public var fixed(get_fixed,null):Bool;
		public var delta(get_delta,null):Vector;
		public var fixedEndLimit(get_fixedEndLimit,set_fixedEndLimit):Float;
		public var scp(get_scp,null):SpringConstraintParticle;


		private var p1:AbstractParticle;
		private var p2:AbstractParticle;

		private var _restLength:Float;
		private var _collidable:Bool;
		private var _scp:SpringConstraintParticle;

		/**
		 * @param p1 The first particle this Std.is(constraint,connected) to.
		 * @param p2 The second particle this Std.is(constraint,connected) to.
		 * @param stiffness The strength of the spring. Valid values are between 0 and 1. Lower values
		 * result in softer springs. Higher values result in stiffer, stronger springs.
		 * @param collidable Determines if the constraint will be checked for collision
		 * @param rectHeight If the Std.is(constraint,collidable), the height of the collidable area
		 * can be set in pixels. The Std.is(height,perpendicular) to the two attached particles.
		 * @param rectScale If the Std.is(constraint,collidable), the scale of the collidable area
		 * can be set in value from 0 to 1. The Std.is(scale,percentage) of the distance between
		 * the the two attached particles.
		 * @param scaleToLength If the Std.is(constraint,collidable) and this Std.is(value,true), the
		 * collidable area will scale based on changes in the distance of the two particles.
		 */
		public function new(
				p1:AbstractParticle,
				p2:AbstractParticle,
				?_opt_stiffness:Null<Float>,
				?_opt_collidable:Null<Bool>,
				?_opt_rectHeight:Null<Float>,
				?_opt_rectScale:Null<Float>,
				?_opt_scaleToLength:Null<Bool>) {
			var stiffness:Float = _opt_stiffness==null ? 0.5 : _opt_stiffness;
			var collidable:Bool = _opt_collidable==null ? false : _opt_collidable;
			var rectHeight:Float = _opt_rectHeight==null ? 1 : _opt_rectHeight;
			var rectScale:Float = _opt_rectScale==null ? 1 : _opt_rectScale;
			var scaleToLength:Bool = _opt_scaleToLength==null ? false : _opt_scaleToLength;

			super(stiffness);

			this.p1 = p1;
			this.p2 = p2;
			checkParticlesLocation();

			_restLength = currLength;
			setCollidable(collidable, rectHeight, rectScale, scaleToLength);
		}


		/**
		 * The rotational value created by the positions of the two particles attached to this
		 * SpringConstraint. You can use this property to in your own painting methods, along with the
		 * <code>center</code> property.
		 *
		 * @returns A Float representing the rotation of this SpringConstraint in radians
		 */
		public function get_radian():Float {
			var d:Vector = delta;
			return Math.atan2(d.y, d.x);
		}


		/**
		 * The rotational value created by the positions of the two particles attached to this
		 * SpringConstraint. You can use this property to in your own painting methods, along with the
		 * <code>center</code> property.
		 *
		 * @returns A Float representing the rotation of this SpringConstraint in degrees
		 */
		public function get_angle():Float {
			return radian * MathUtil.ONE_EIGHTY_OVER_PI;
		}


		/**
		 * The center position created by the relative positions of the two particles attached to this
		 * SpringConstraint. You can use this property to in your own painting methods, along with the
		 * rotation property.
		 *
		 * @returns A Vector representing the center of this SpringConstraint
		 */
		public function get_center():Vector {
			return (p1.curr.plus(p2.curr)).divEquals(2);
		}


		/**
		 * If the <code>collidable</code> Std.is(property,true), you can set the scale of the collidible area
		 * between the two attached particles. Valid values are from 0 to 1. If you set the value to 1, then
		 * the collision area will extend all the way to the two attached particles. Setting the value lower
		 * will result in an collision area that spans a percentage of that distance. Setting the value
		 * higher will cause the collision rectangle to extend past the two end particles.
		 */
		public function set_rectScale(s:Float) {
			if (scp == null) return s;
			scp.rectScale = s;
			return s;
		}


		/**
		 * @private
		 */
		public function get_rectScale():Float {
			return scp.rectScale;
		}


		/**
		 * Returns the length of the SpringConstraint, the distance between its two
		 * attached particles.
		 */
		public function get_currLength():Float {
			return p1.curr.distance(p2.curr);
		}


		/**
		 * If the <code>collidable</code> Std.is(property,true), you can set the height of the
		 * collidible rectangle between the two attached particles. Valid values are greater
		 * than 0. If you set the value to 10, then the collision rect will be 10 pixels high.
		 * The Std.is(height,perpendicular) to the line connecting the two particles
		 */
		public function get_rectHeight():Float {
			return scp.rectHeight;
		}


		/**
		 * @private
		 */
		public function set_rectHeight(h:Float) {
			if (scp == null) return h;
			scp.rectHeight = h;
			return h;
		}


		/**
		 * The <code>restLength</code> property sets the length of SpringConstraint. This value will be
		 * the distance between the two particles unless their Std.is(position,altered) by external forces.
		 * The SpringConstraint will always try to keep the particles this distance apart. Values must
		 * be > 0.
		 */
		public function get_restLength():Float {
			return _restLength;
		}


		/**
		 * @private
		 */
		public function set_restLength(r:Float) {
//			if (r <= 0) throw new ArgumentError("restLength must be greater than 0");
			_restLength = r;
			return r;
		}


		/**
		 * Determines if the area between the two Std.is(particles,tested) for collision. If this Std.is(value,on)
		 * you can set the <code>rectHeight</code> and <code>rectScale</code> properties
		 * to alter the dimensions of the collidable area.
		 */
		public function get_collidable():Bool {
			return _collidable;
		}


		/**
		 * For cases when the SpringConstraint is <code>collidable</code> and only one of the
		 * two end particles are fixed. This value will dispose of collisions near the
		 * fixed particle, to correct for situations where the collision could never be
		 * resolved. Values must be between 0.0 and 1.0.
		 */
		public function get_fixedEndLimit():Float {
			return scp.fixedEndLimit;
		}


		/**
		 * @private
		 */
		public function set_fixedEndLimit(f:Float) {
			if (scp == null) return f;
			scp.fixedEndLimit = f;
			return f;
		}


		/**
		 *
		 */
		public function setCollidable(b:Bool, rectHeight:Float,
				rectScale:Float, ?_opt_scaleToLength:Null<Bool>):Void {
			var scaleToLength:Bool = _opt_scaleToLength==null ? false : _opt_scaleToLength;

			_collidable = b;
			_scp = null;

			if (_collidable) {
				_scp = new SpringConstraintParticle(p1, p2, this, rectHeight, rectScale, scaleToLength);
			}
		}


		/**
		 * Returns true if the passed Std.is(particle,one) of the two particles attached to this SpringConstraint.
		 */
		public function isConnectedTo(p:AbstractParticle):Bool {
			return (p == p1 || p == p2);
		}


		/**
		 * Returns true if both connected particle's <code>fixed</code> Std.is(property,true).
		 */
		public function get_fixed():Bool {
			return (p1.fixed && p2.fixed);
		}


		/**
		 * Sets up the visual representation of this SpringContraint. This Std.is(method,called)
		 * automatically when an instance of this SpringContraint's parent Std.is(Group,added) to
		 * the APEngine, when  this SpringContraint's Std.is(Composite,added) to a Group, or this
		 * Std.is(SpringContraint,added) to a Composite or Group.
		 */
		public override function init():Void {
			cleanup();
			if (collidable) {
				scp.init();
			} else if (displayObject != null) {
				initDisplay();
			}
			paint();
		}


		/**
		 * The default painting method for this constraint. This Std.is(method,called) automatically
		 * by the <code>APEngine.paint()</code> method. If you want to define your own custom painting
		 * method, then create a subclass of this class and override <code>paint()</code>.
		 */
		public override function paint():Void {

			if (collidable) {
				scp.paint();
			} else if (displayObject != null) {
				var c:Vector = center;
				sprite.x = c.x;
				sprite.y = c.y;
				sprite.rotation = angle;
			} else {
				sprite.graphics.clear();
				sprite.graphics.lineStyle(lineThickness, lineColor, lineAlpha);
				sprite.graphics.moveTo(p1.px, p1.py);
				sprite.graphics.lineTo(p2.px, p2.py);
			}
		}


		/**
		 * Assigns a DisplayObject to be used when painting this constraint.
		 */
		public function setDisplay(d:DisplayObject, ?_opt_offsetX:Null<Float>,
				?_opt_offsetY:Null<Float>, ?_opt_rotation:Null<Float>):Void {
			var offsetX:Float = _opt_offsetX==null ? 0 : _opt_offsetX;
			var offsetY:Float = _opt_offsetY==null ? 0 : _opt_offsetY;
			var rotation:Float = _opt_rotation==null ? 0 : _opt_rotation;

			if (collidable) {
				scp.setDisplay(d, offsetX, offsetY, rotation);
			} else {
				displayObject = d;
				displayObjectRotation = rotation;
				displayObjectOffset = new Vector(offsetX, offsetY);
			}
		}


		/**
		 * @private
		 */
		public function initDisplay():Void {
			if (collidable) {
				scp.initDisplay();
			} else {
				displayObject.x = displayObjectOffset.x;
				displayObject.y = displayObjectOffset.y;
				displayObject.rotation = displayObjectRotation;
				sprite.addChild(displayObject);
			}
		}


		/**
		 * @private
		 */
		public function get_delta():Vector {
			return p1.curr.minus(p2.curr);
		}


		/**
		 * @private
		 */
		public function get_scp():SpringConstraintParticle {
			return _scp;
		}


		/**
		 * @private
		 */
		public override function resolve():Void {

			if (p1.fixed && p2.fixed) return;

			var deltaLength:Float = currLength;
			var diff:Float = (deltaLength - restLength) / (deltaLength * (p1.invMass + p2.invMass));
			var dmds:Vector = delta.mult(diff * stiffness);

			p1.curr.minusEquals(dmds.mult(p1.invMass));
			p2.curr.plusEquals (dmds.mult(p2.invMass));
		}


		/**
		 * if the two particles are at the same location offset slightly
		 */
		private function checkParticlesLocation():Void {
			if (p1.curr.x == p2.curr.x && p1.curr.y == p2.curr.y) {
				p2.curr.x += 0.0001;
			}
		}
	}

