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
		public var constraints(get_constraints,null):Array<AbstractConstraint>;
		public var sprite(get_sprite,null):Sprite;
		public var isParented(get_isParented,set_isParented):Bool;



		private var _sprite:Sprite;
		private var _particles:Array<AbstractParticle>;
		private var _constraints:Array<AbstractConstraint>;
		private var _isParented:Bool;


		public function new() {
////			if (getQualifiedClassName(this) == "org.cove.ape::AbstractCollection") {
////				throw new ArgumentError("AbstractCollection can't be instantiated directly");
//			}
			_isParented = false;
			_particles = new Array<AbstractParticle>();
			_constraints = new Array<AbstractConstraint>();
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
		public function get_constraints():Array<AbstractConstraint> {
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
			var ppos:Int = PArray.indexOf(particles,p);
			if (ppos == -1) return;
			particles.splice(ppos, 1);
			p.cleanup();
		}


		/**
		 * Adds a constraint to the Collection.
		 *
		 * @param c The constraint to be added.
		 */
		public function addConstraint(c:AbstractConstraint):Void {
			constraints.push(c);
			if (isParented) c.init();
		}


		/**
		 * Removes a constraint from the Collection.
		 *
		 * @param c The constraint to be removed.
		 */
		public function removeConstraint(c:AbstractConstraint):Void {
			var cpos:Int = PArray.indexOf(constraints,c);
			if (cpos == -1) return;
			constraints.splice(cpos, 1);
			c.cleanup();
		}


		/**
		 * Initializes every member of this AbstractCollection by in turn calling
		 * each members <code>init()</code> method.
		 */
		public function init():Void {

			var i:Int = 0;
			while( i < particles.length) {

				particles[i].init();
				 i++;
			}
			i = 0;
			while( i < constraints.length) {

				constraints[i].init();
				 i++;
			}
		}


		/**
		 * paints every member of this AbstractCollection by calling each members
		 * <code>paint()</code> method.
		 */
		public function paint():Void {

			var p:AbstractParticle;
			var len:Int = _particles.length;
			var i:Int = 0;
			while( i < len) {

				p = _particles[i];
				if ((! p.fixed) || p.alwaysRepaint) p.paint();
				 i++;
			}

			var c:SpringConstraint;
			len = _constraints.length;
			i = 0;
			while( i < len) {

				c = cast(_constraints[i],SpringConstraint);
				if ((! c.fixed) || c.alwaysRepaint) c.paint();
				 i++;
			}
		}


		/**
		 * Calls the <code>cleanup()</code> method of every member of this AbstractCollection.
		 * The cleanup() Std.is(method,called) automatically when an Std.is(AbstractCollection,removed)
		 * from its parent.
		 */
		public function cleanup():Void {

			var i:Int = 0;
			while( i < particles.length) {

				particles[i].cleanup();
				 i++;
			}
			i = 0;
			while( i < constraints.length) {

				constraints[i].cleanup();
				 i++;
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
			var len:Int = _particles.length;
			var i:Int = 0;
			while( i < len) {

				var p:AbstractParticle = _particles[i];
				p.update(dt2);
				 i++;
			}
		}


		/**
		 * @private
		 */
		public function satisfyConstraints():Void {
			var len:Int = _constraints.length;
			var i:Int = 0;
			while( i < len) {

				var c:AbstractConstraint = _constraints[i];
				c.resolve();
				 i++;
			}
		}


		/**
		 * @private
		 */
		 public function checkInternalCollisions():Void {

			// every particle in this AbstractCollection
			var plen:Int = _particles.length;
			var j:Int = 0;
			while( j < plen) {


				var pa:AbstractParticle = _particles[j];
				if (! pa.collidable) {				 j++; continue; }

				// ...vs every other particle in this AbstractCollection
				var i:Int = j + 1;
				while( i < plen) {

					var pb:AbstractParticle = _particles[i];
					if (pb.collidable) CollisionDetector.test(pa, pb);
					 i++;
				}

				// ...vs every other constraint in this AbstractCollection
				var clen:Int = _constraints.length;
				var n:Int = 0;
				while( n < clen) {

					var c:SpringConstraint = cast( _constraints[n],SpringConstraint);
					if (c.collidable && ! c.isConnectedTo(pa)) {
						c.scp.updatePosition();
						CollisionDetector.test(pa, c.scp);
					}
					 n++;
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
			while( j < plen) {


				var pga:AbstractParticle = _particles[j];
				if (! pga.collidable) {				 j++; continue; }

				// ...vs every particle in the other collection
				var acplen:Int = ac.particles.length;
				var x:Int = 0;
				while( x < acplen) {

					var pgb:AbstractParticle = ac.particles[x];
					if (pgb.collidable) CollisionDetector.test(pga, pgb);
					 x++;
				}
				// ...vs every constraint in the other collection
				var acclen:Int = ac.constraints.length;
				x = 0;
				while( x < acclen) {

					var cgb:SpringConstraint = cast( ac.constraints[x],SpringConstraint);
					if (cgb.collidable && ! cgb.isConnectedTo(pga)) {
						cgb.scp.updatePosition();
						CollisionDetector.test(pga, cgb.scp);
					}
					 x++;
				}
				 j++;
			}

			// every constraint in this collection...
			var clen:Int = _constraints.length;
			j = 0;
			while( j < clen) {

				var cga:SpringConstraint = cast( _constraints[j],SpringConstraint);
				if (! cga.collidable) {				 j++; continue; }

				// ...vs every particle in the other collection
				var acplen = ac.particles.length;
				var n:Int = 0;
				while( n < acplen) {

					var pgb:AbstractParticle = ac.particles[n];
					if (pgb.collidable && ! cga.isConnectedTo(pgb)) {
						cga.scp.updatePosition();
						CollisionDetector.test(pgb, cga.scp);
					}
					 n++;
				}
				 j++;
			}
		}
	}



