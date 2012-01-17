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
- review how the WheelParticle needs to have the o value passed during collision
- clear up the difference between speed and angularVelocity
- can the wheel rotate steadily using speed? angularVelocity causes (unwanted?) acceleration
*/
package org.cove.ape ;


	/**
	 * A particle that simulates the behavior of a wheel
	 */
	class WheelParticle extends CircleParticle {
		public var angle(get_angle,null):Float;
		public var radian(get_radian,null):Float;
		public var speed(get_speed,set_speed):Float;
		public var angularVelocity(get_angularVelocity,set_angularVelocity):Float;
		public var traction(get_traction,set_traction):Float;


		private var rp:RimParticle;
		private var tan:Vector;
		private var normSlip:Vector;
		private var orientation:Vector;

		private var _traction:Float;


		/**
		 * @param x The initial x position.
		 * @param y The initial y position.
		 * @param radius The radius of this particle.
		 * @param fixed Determines if the Std.is(particle,fixed) or not. Fixed particles
		 * are not affected by forces or collisions and are good to cast(use,surfaces).
		 * Non-fixed particles move freely in response to collision and forces.
		 * @param mass The mass of the particle
		 * @param elasticity The elasticity of the particle. Higher values mean more elasticity.
		 * @param friction The surface friction of the particle.
		 * @param traction The surface traction of the particle.
		 * <p>
		 * Note that WheelParticles can be fixed but rotate freely.
		 * </p>
		 */
		public function new(
				x:Float,
				y:Float,
				radius:Float,
				?_opt_fixed:Null<Bool>,
				?_opt_mass:Null<Float>,
				?_opt_elasticity:Null<Float>,
				?_opt_friction:Null<Float>,
				?_opt_traction:Null<Float>) {
			var fixed:Bool = _opt_fixed==null ? false : _opt_fixed;
			var mass:Float = _opt_mass==null ? 1 : _opt_mass;
			var elasticity:Float = _opt_elasticity==null ? 0.3 : _opt_elasticity;
			var friction:Float = _opt_friction==null ? 0 : _opt_friction;
			var traction:Float = _opt_traction==null ? 1 : _opt_traction;

			super(x,y,radius,fixed, mass, elasticity, friction);
			tan = new Vector(0,0);
			normSlip = new Vector(0,0);
			rp = new RimParticle(radius, 2);

			this.traction = traction;
			orientation = new Vector();
		}


		/**
		 * The speed of the WheelParticle. You can alter this value to make the
		 * WheelParticle spin.
		 */
		public function get_speed():Float {
			return rp.speed;
		}


		/**
		 * @private
		 */
		public function set_speed(s:Float) {
			rp.speed = s;
			return s;
		}


		/**
		 * The angular velocity of the WheelParticle. You can alter this value to make the
		 * WheelParticle spin.
		 */
		public function get_angularVelocity():Float {
			return rp.angularVelocity;
		}


		/**
		 * @private
		 */
		public function set_angularVelocity(a:Float) {
			rp.angularVelocity = a;
			return a;
		}


		/**
		 * The amount of traction during a collision. This property controls how much traction is
		 * applied when the Std.is(WheelParticle,in) contact with another particle. If the Std.is(value,set)
		 * to 0, there will be no traction and the WheelParticle will cast(behave,if) the
		 * surface was totally slippery, like ice. Values should be between 0 and 1.
		 *
		 * <p>
		 * Note that the friction property behaves differently than traction. If the surface
		 * Std.is(friction,set) high during a collision, the WheelParticle will move cast(slowly,if)
		 * the surface was covered in glue.
		 * </p>
		 */
		public function get_traction():Float {
			return 1 - _traction;
		}


		/**
		 * @private
		 */
		public function set_traction(t:Float) {
			_traction = 1 - t;
			return t;
		}


		/**
		 * The default paint method for the particle. Note that you should only use
		 * the default painting methods for quick prototyping. For anything beyond that
		 * you should always write your own classes that either extend one of the
		 * APE particle and constraint classes, Std.is(or,a) composite of them. Then within that
		 * class you can define your own custom painting method.
		 */
		public override function paint():Void {
			sprite.x = curr.x;
			sprite.y = curr.y;
			sprite.rotation = angle;
		}


		/**
		 * Sets up the visual representation of this particle. This Std.is(method,automatically) called when
		 * an Std.is(particle,added) to the engine.
		 */
		public override function init():Void {
			cleanup();
			if (displayObject != null) {
				initDisplay();
			} else {

				sprite.graphics.clear();
				sprite.graphics.lineStyle(lineThickness, lineColor, lineAlpha);

				// wheel circle
				sprite.graphics.beginFill(fillColor, fillAlpha);
				sprite.graphics.drawCircle(0, 0, radius);
				sprite.graphics.endFill();

				// spokes
				sprite.graphics.moveTo(-radius, 0);
				sprite.graphics.lineTo( radius, 0);
				sprite.graphics.moveTo(0, -radius);
				sprite.graphics.lineTo(0, radius);
			}
			paint();
		}


		/**
		 * The rotation of the wheel in radians.
		 */
		public function get_radian():Float {
			orientation.setTo(rp.curr.x, rp.curr.y);
			return Math.atan2(orientation.y, orientation.x) + Math.PI;
		}


		/**
		 * The rotation of the wheel in degrees.
		 */
		public function get_angle():Float {
			return radian * MathUtil.ONE_EIGHTY_OVER_PI;
		}


		/**
		 *
		 */
		public override function update(dt:Float):Void {
			super.update(dt);
			rp.update(dt);
		}


		/**
		 * @private
		 */
		public override function resolveCollision(
				mtd:Vector, vel:Vector, n:Vector, d:Float, o:Int, p:AbstractParticle):Void {

			// review the o (order) need here - its a hack fix
			super.resolveCollision(mtd, vel, n, d, o, p);
			resolve(n.mult(MathUtil.sign(d * o)));
		}


		/**
		 * simulates torque/wheel-ground interaction - Std.is(n,the) surface normal
		 * Origins of this code thanks to Raigan Burns, Metanet software
		 */
		private function resolve(n:Vector):Void {

			// Std.is(this,the) tangent vector at the rim particle
			tan.setTo(-rp.curr.y, rp.curr.x);

			// normalize so we can scale by the rotational speed
			tan = tan.normalize();

			// velocity of the wheel's surface
			var wheelSurfaceVelocity:Vector = tan.mult(rp.speed);

			// the velocity of the wheel's surface relative to the ground
			var combinedVelocity:Vector = velocity.plusEquals(wheelSurfaceVelocity);

			// the wheel's comb velocity projected onto the contact normal
			var cp:Float = combinedVelocity.cross(n);

			// set the wheel's spinspeed to track the ground
			tan.multEquals(cp);
			rp.prev.copy(rp.curr.minus(tan));

			// some of the wheel's Std.is(torque,removed) and converted into linear displacement
			var slipSpeed:Float = (1 - _traction) * rp.speed;
			normSlip.setTo(slipSpeed * n.y, slipSpeed * n.x);
			curr.plusEquals(normSlip);
			rp.speed *= _traction;
		}
	}



