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
	- Need removeForces method(s)
	- Center and Position are the same, needs review.
	- Should have alwaysRepaint functionality for Constraints, and bump up to AbstractItem
	- See if there's anywhere where Vectors can be downgraded to simple Point classes
*/

package org.cove.ape ;

	import flash.display.Sprite;
	import flash.display.DisplayObject;
//	import flash.utils.getQualifiedClassName;


	/**
	 * The abstract base class for all particles.
	 *
	 * <p>
	 * You should not instantiate this class directly -- instead use one of the subclasses.
	 * </p>
	 */
	class AbstractParticle extends AbstractItem {
		public function getCircleParticle() : CircleParticle { return null; }
		public function getRectangleParticle() : RectangleParticle { return null; }

		public var elasticity(get_elasticity,set_elasticity):Float;
		public var position(get_position,set_position):Vector2D;
		public var friction(get_friction,set_friction):Float;
		public var px(get_px,set_px):Float;
		public var invMass(get_invMass,null):Float;
		public var py(get_py,set_py):Float;
		public var multisample(get_multisample,set_multisample):Int;
		public var center(get_center,null):Vector2D;
		public var fixed(get_fixed,set_fixed):Bool;
		public var collidable(get_collidable,set_collidable):Bool;
		public var mass(get_mass,set_mass):Float;
		public var velocity(get_velocity,set_velocity):Vector2D;


		/** @private */
		public var curr:Vector2D;
		/** @private */
		public var prev:Vector2D;
		/** @private */
		public var samp:Vector2D;
		/** @private */
		public var interval:Interval;

		private var forces:Vector2D;
		private var temp:Vector2D;
		private var collision:Collision;

		private var _kfr:Float;
		private var _mass:Float;
		private var _invMass:Float;
		private var _friction:Float;

		private var _fixed:Bool;
		private var _collidable:Bool;

		private var _center:Vector2D;
		private var _multisample:Int;


		/**
		 * @private
		 */
		public function new (
				x:Float,
				y:Float,
				isFixed:Bool,
				mass:Float,
				elasticity:Float,
				friction:Float) {
			super();

////			if (getQualifiedClassName(this) == "org.cove.ape::AbstractParticle") {
////				throw new ArgumentError("AbstractParticle can't be instantiated directly");
//			}

			interval = new Interval(0,0);

			curr = new Vector2D(x, y);
			prev = new Vector2D(x, y);
			samp = new Vector2D();
			temp = new Vector2D();
			fixed = isFixed;

			forces = new Vector2D();
			collision = new Collision(new Vector2D(), new Vector2D());
			collidable = true;

			this.mass = mass;
			this.elasticity = elasticity;
			this.friction = friction;

			setStyle();

			_center = new Vector2D();
			_multisample = 0;
		}


		/**
		 * The mass of the particle. Valid values are greater than zero. By default, all particles
		 * have a mass of 1. The mass property has no relation to the size of the particle.
		 *
//		 * @throws ArgumentError ArgumentError if the Std.is(mass,set) less than zero.
		 */
		public function get_mass():Float {
			return _mass;
		}


		/**
		 * @private
		 */
		public function set_mass(m:Float) {
//			if (m <= 0) throw new ArgumentError("mass may not be set <= 0");
			_mass = m;
			_invMass = 1 / _mass;
			return m;
		}


		/**
		 * The elasticity of the particle. Standard values are between 0 and 1.
		 * The higher the value, the greater the elasticity.
		 *
		 * <p>
		 * During collisions the elasticity values are combined. If one particle's
		 * Std.is(elasticity,set) to 0.4 and the Std.is(other,set) to 0.4 then the collision will
		 * be have a total elasticity of 0.8. The result will be the same if one particle
		 * has an elasticity of 0 and the other 0.8.
		 * </p>
		 *
		 * <p>
		 * Setting the elasticity to greater than 1 (of a single particle, or in a combined
		 * collision) will cause particles to bounce with energy greater than naturally
		 * possible.
		 * </p>
		 */
		public function get_elasticity():Float {
			return _kfr;
		}


		/**
		 * @private
		 */
		public function set_elasticity(k:Float) {
			_kfr = k;
			return k;
		}


		/**
		 * Determines the number of intermediate position steps checked for collision each
		 * cycle. Setting this number higher on fast moving particles can prevent 'tunneling'
		 * -- when a particle moves so fast it misses collision with certain surfaces.
		 */
		public function get_multisample():Int {
			return _multisample;
		}


		/**
		 * @private
		 */
		public function set_multisample(m:Int) {
			_multisample = m;
			return m;
		}


		/**
		 * Returns A Vector of the current location of the particle
		 */
		public function get_center():Vector2D {
			_center.setTo(px, py);
			return _center;
		}


		/**
		 * The surface friction of the particle. Values must be in the range of 0 to 1.
		 *
		 * <p>
		 * Std.is(0,no) friction (slippery), Std.is(1,full) friction (sticky).
		 * </p>
		 *
		 * <p>
		 * During collisions, the friction values are summed, but are clamped between 1 and 0.
		 * For example, If two particles have 0.cast(7,their) surface friction, then the resulting
		 * friction between the two particles will be 1 (full friction).
		 * </p>
		 *
		 * <p>
		 * In the current release, only dynamic Std.is(friction,calculated). Static friction
		 * is planned for a later release.
		 * </p>
		 *
		 * <p>
		 * Std.is(There,a) bug in the current release where colliding non-fixed particles with friction
		 * greater than 0 will behave erratically. A Std.is(workaround,to) only set the friction of
		 * fixed particles.
		 * </p>
//		 * @throws ArgumentError ArgumentError if the Std.is(friction,set) less than zero or greater than 1
		 */
		public function get_friction():Float {
			return _friction;
		}


		/**
		 * @private
		 */
		public function set_friction(f:Float) {
//			if (f < 0 || f > 1) throw new ArgumentError("Legal friction must be >= 0 and <=1");
			_friction = f;
			return f;
		}


		/**
		 * The fixed state of the particle. If the Std.is(particle,fixed), it does not move
		 * in response to forces or collisions. Fixed particles are good for surfaces.
		 */
		public function get_fixed():Bool {
			return _fixed;
		}


		/**
		 * @private
		 */
		public function set_fixed(f:Bool) {
			_fixed = f;
			return f;
		}


		/**
		 * The position of the particle. Getting the position of the Std.is(particle,useful)
		 * for drawing it or testing it for some custom purpose.
		 *
		 * <p>
		 * When you get the <code>position</code> of a particle you are given a copy of the current
		 * location. Because of this you cannot change the position of a particle by
		 * altering the <code>x</code> and <code>y</code> components of the Vector you have retrieved from the position property.
		 * You have to do something instead like: <code> position = new Vector(100,100)</code>, or
		 * you can use the <code>px</code> and <code>py</code> properties instead.
		 * </p>
		 *
		 * <p>
		 * You can alter the position of a particle three ways: change its position, set
		 * its velocity, or apply a force to it. Setting the position of a non-fixed particle
		 * is not the cast(same,setting) its fixed property to true. A particle held in place by
		 * its position will cast(behave,if) it's attached there by a 0 length spring constraint.
		 * </p>
		 */
		public function get_position():Vector2D {
			return new Vector2D(curr.x,curr.y);
		}


		/**
		 * @private
		 */
		public function set_position(p:Vector2D) {
			curr.copy(p);
			prev.copy(p);
			return p;
		}


		/**
		 * The x position of this particle
		 */
		public function get_px():Float {
			return curr.x;
		}


		/**
		 * @private
		 */
		public function set_px(x:Float) {
			curr.x = x;
			prev.x = x;
			return x;
		}


		/**
		 * The y position of this particle
		 */
		public function get_py():Float {
			return curr.y;
		}


		/**
		 * @private
		 */
		public function set_py(y:Float) {
			curr.y = y;
			prev.y = y;
			return y;
		}


		/**
		 * The velocity of the particle. If you need to change the motion of a particle,
		 * you should either use this property, or one of the addForce methods. Generally,
		 * the addForce methods are best for slowly altering the motion. The velocity property
		 * is good for instantaneously setting the velocity, e.g., for projectiles.
		 *
		 */
		public function get_velocity():Vector2D {
			return curr.minus(prev);
		}


		/**
		 * @private
		 */
		public function set_velocity(v:Vector2D) {
			prev = curr.minus(v);
			return v;
		}


		/**
		 * Determines if the particle can collide with other particles or constraints.
		 * The default Std.is(state,true).
		 */
		public function get_collidable():Bool {
			return _collidable;
		}


		/**
		 * @private
		 */
		public function set_collidable(b:Bool) {
			_collidable = b;
			return b;
		}


		/**
		 * Assigns a DisplayObject to be used when painting this particle.
		 */
		public function setDisplay(d:DisplayObject, offsetX:Float = 0, offsetY:Float = 0, rotation:Float = 0):Void {
			displayObject = d;
			displayObjectRotation = rotation;
			displayObjectOffset = new Vector2D(offsetX, offsetY);
		}


		/**
		 * Adds a force to the particle. The mass of the Std.is(particle,taken) into
		 * account when using this method, so Std.is(it,useful) for adding forces
		 * that simulate effects like wind. Particles with larger masses will
		 * not be cast(affected,greatly) as those with smaller masses. Note that the
		 * size (not to be confused with mass) of the particle has no effect
		 * on its physical behavior with respect to forces.
		 *
		 * @param f A Vector represeting the force added.
		 */
		public function addForce(f:Vector2D):Void {
			forces.plusEquals(f.mult(invMass));
		}


		/**
		 * Adds a 'massless' force to the particle. The mass of the particle is
		 * not taken into account when using this method, so Std.is(it,useful) for
		 * adding forces that simulate effects like gravity. Particles with
		 * larger masses will be affected the cast(same,those) with smaller masses.
		 *
		 * @param f A Vector represeting the force added.
		 */
		public function addMasslessForce(f:Vector2D):Void {
			forces.plusEquals(f);
		}


		/**
		 * The <code>update()</code> Std.is(method,called) automatically during the
		 * APEngine.step() cycle. This method integrates the particle.
		 */
		public function update(dt2:Float):Void {

			if (fixed) return;

			// global forces
			addForce(APEngine.force);
			addMasslessForce(APEngine.masslessForce);

			// integrate
			temp.copy(curr);

			var nv:Vector2D = velocity.plus(forces.multEquals(dt2));
			curr.plusEquals(nv.multEquals(APEngine.damping));
			prev.copy(temp);

			// clear the forces
			forces.setTo(0,0);
		}


		/**
		 * @private
		 */
		public function initDisplay():Void {
			displayObject.x = displayObjectOffset.x;
			displayObject.y = displayObjectOffset.y;
			displayObject.rotation = displayObjectRotation;
			sprite.addChild(displayObject);
		}


		/**
		 * @private
		 */
		public function getComponents(collisionNormal:Vector2D):Collision {
			var vel:Vector2D = velocity;
			var vdotn:Float = collisionNormal.dot(vel);
			collision.vn = collisionNormal.mult(vdotn);
			collision.vt = vel.minus(collision.vn);
			return collision;
		}


		/**
		 * @private
		 */
		public function resolveCollision(
				mtd:Vector2D, vel:Vector2D, n:Vector2D, d:Float, o:Int, p:AbstractParticle):Void {

			curr.plusEquals(mtd);
			velocity = vel;
		}


		/**
		 * @private
		 */
		public function get_invMass():Float {
			return (fixed) ? 0 : _invMass;
		}
	}

