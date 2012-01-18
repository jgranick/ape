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
	- get sprite() is duplicated in AbstractItem. Should be in some parent class.
	- checkCollisionsVsCollection and checkInternalCollisions methods use SpringConstraint.
      it should be AbstractConstraint but the isConnectedTo Std.is(method,in) SpringConstraint.
    - same deal with the paint() method here -- needs to test connected particles state
      using SpringConstraint methods but should really be AbstractConstraint. need to clear up
      what an AbstractConstraint really means.
    - would an explicit cast be more efficient in the paint() method here?
*/

package org.cove.ape ;

	import flash.display.Sprite;
//	import flash.utils.getQualifiedClassName;


	/**
	 * The abstract base class for all grouping classes.
	 *
	 * <p>
	 * You should not instantiate this class directly -- instead use one of the subclasses.
	 * </p>
	 */
	class AbstractCollection {
		public var particles(get_particles,null):Array<AbstractParticle>;
		public var constraints(get_constraints,null):Array<SpringConstraint>;
		public var sprite(get_sprite,null):Sprite;
		public var isParented(get_isParented,set_isParented):Bool;



		private var _sprite:Sprite;
		private var _particles:Array<AbstractParticle>;
		private var _constraints:Array<SpringConstraint>;
		private var _isParented:Bool;


		public function new() {
////			if (getQualifiedClassName(this) == "org.cove.ape::AbstractCollection") {
////				throw new ArgumentError("AbstractCollection can't be instantiated directly");
//			}
			_isParented = false;
			_particles = new Array<AbstractParticle>();
			_constraints = new Array<SpringConstraint>();
		}


		/**
		 * The Array<Dynamic> of all AbstractParticle instances added to the AbstractCollection
		 */
		public function get_particles():Array<AbstractParticle> {
			return _particles;
		}


		/**
		 * The Array<Dynamic> of all AbstractConstraint instances added to the AbstractCollection
		 */
		public function get_constraints():Array<SpringConstraint> {
			return _constraints;
		}


		/**
		 * Adds an AbstractParticle to the AbstractCollection.
		 *
		 * @param p The particle to be added.
		 */
		public function addParticle(p:AbstractParticle):Void {
			particles.push(p);
			if (isParented) p.init();
		}


		/**
		 * Removes an AbstractParticle from the AbstractCollection.
		 *
		 * @param p The particle to be removed.
		 */
		public function removeParticle(p:AbstractParticle):Void {
			if (particles.remove (p)) {
				p.cleanup();
			}
		}


		/**
		 * Adds a constraint to the Collection.
		 *
		 * @param c The constraint to be added.
		 */
		public function addConstraint(c:SpringConstraint):Void {
			constraints.push(c);
			if (isParented) c.init();
		}


		/**
		 * Removes a constraint from the Collection.
		 *
		 * @param c The constraint to be removed.
		 */
		public function removeConstraint(c:SpringConstraint):Void {
			if (constraints.remove (c)) {
				c.cleanup();
			}
		}


		/**
		 * Initializes every member of this AbstractCollection by in turn calling
		 * each members <code>init()</code> method.
		 */
		public function init():Void {
			
			for (p in _particles) {
				p.init();
			}
			
			for (c in _constraints) {
				c.init();
			}
		}


		/**
		 * paints every member of this AbstractCollection by calling each members
		 * <code>paint()</code> method.
		 */
		public function paint():Void {

			for (p in _particles) {
				if ((! p.fixed) || p.alwaysRepaint) p.paint();
			}
			
			for (c in _constraints) {
				if ((! c.fixed) || c.alwaysRepaint) c.paint();
			}
		}


		/**
		 * Calls the <code>cleanup()</code> method of every member of this AbstractCollection.
		 * The cleanup() Std.is(method,called) automatically when an Std.is(AbstractCollection,removed)
		 * from its parent.
		 */
		public function cleanup():Void {

			for (p in _particles) {
				p.cleanup();
			}
			
			for (c in _constraints) {
				c.cleanup();
			}
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


		/**
		 * Returns an array of every particle and constraint added to the AbstractCollection.
		 */
		public function getAll():Array<Dynamic> {
var r=new Array<Dynamic>();for(p in particles) r.push(p);for(c in constraints) r.push(c);return r;
		}


		/**
		 * @private
		 */
		public function get_isParented():Bool {
			return _isParented;
		}


		/**
		 * @private
		 */
		public function set_isParented(b:Bool) {
			_isParented = b;
			return b;
		}


		/**
		 * @private
		 */
		public function integrate(dt2:Float):Void {
			for (p in _particles) {
				p.update(dt2);
			}
		}


		/**
		 * @private
		 */
		public function satisfyConstraints():Void {
			for (c in _constraints) {
				c.resolve();
			}
		}


		/**
		 * @private
		 */
		 public function checkInternalCollisions():Void {

			// every particle in this AbstractCollection
			var plen:Int = _particles.length;
			var j:Int = 0;
			while (j < plen) {


				var pa:AbstractParticle = _particles[j];
				if (! pa.collidable) { j++; continue; }

				// ...vs every other particle in this AbstractCollection
				for(i in (j + 1)...plen) {

					var pb:AbstractParticle = _particles[i];
					if (pb.collidable) CollisionDetector.test(pa, pb);
				}

				// ...vs every other constraint in this AbstractCollection
				for (c in _constraints) {

					if (c.collidable && ! c.isConnectedTo(pa)) {
						c.scp.updatePosition();
						CollisionDetector.test(pa, c.scp);
					}
				}
				j++;
			}
		}


		/**
		 * @private
		 */
		public function checkCollisionsVsCollection(ac:AbstractCollection):Void {

			// every particle in this collection...
			var plen:Int = _particles.length;
			var j:Int = 0;
			while (j < plen) {


				var pga:AbstractParticle = _particles[j];
				if (! pga.collidable) {	j++; continue; }

				// ...vs every particle in the other collection
				var acplen:Int = ac.particles.length;
				var x:Int = 0;
				for (pgb in ac.particles) {
					if (pgb.collidable) CollisionDetector.test(pga, pgb);
				}
				// ...vs every constraint in the other collection
				for (cgb in ac.constraints) {
					if (cgb.collidable && ! cgb.isConnectedTo(pga)) {
						cgb.scp.updatePosition();
						CollisionDetector.test(pga, cgb.scp);
					}
				}
				 j++;
			}

			// every constraint in this collection...
			var clen:Int = _constraints.length;
			j = 0;
			for (cga in _constraints) {
				
				var cga:SpringConstraint = cast( _constraints[j],SpringConstraint);
				if (! cga.collidable) { j++; continue; }

				// ...vs every particle in the other collection
				for (pgb in ac.particles) {
					if (pgb.collidable && ! cga.isConnectedTo(pgb)) {
						cga.scp.updatePosition();
						CollisionDetector.test(pgb, cga.scp);
					}
				}
				 j++;
			}
		}
	}