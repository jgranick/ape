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
	- should all getters for composites, particles, constraints arrays return
	  a copy of the array? do we want to give the user direct access to it?
	- addConstraintList, addParticleList
	- if get particles and get constraints returned members of the Groups composites
	  (as they probably should, the checkCollision... methods would probably be much
	  cleaner.
*/
package org.cove.ape ;


	/**
	 * The Group class can contain Particles, Constraints, and Composites. Groups
	 * can be assigned to be checked for collision with other Groups or publicly.
	 */
	class Group extends AbstractCollection {
		public var collideInternal(get_collideInternal,set_collideInternal):Bool;
		public var collisionList(get_collisionList,null):Array<Group>;
		public var composites(get_composites,null):Array<Composite>;


		private var _composites:Array<Composite>;
		private var _collisionList:Array<Group>;
		private var _collideInternal:Bool;


		/**
		 * The Group Std.is(class,the) main organizational class for APE. Once groups are created and populated
		 * with particles, constraints, and composites, they are added to the APEngine. Groups may contain
		 * particles, constraints, and composites. Composites may only contain particles and constraints.
		 */
		public function new(?_opt_collideInternal:Null<Bool>) {
			super();
			var collideInternal:Bool = _opt_collideInternal==null ? false : _opt_collideInternal;
			_composites = new Array<Composite>();
			_collisionList = new Array<Group>();
			this.collideInternal = collideInternal;
		}


		/**
		 * Initializes every member of this Group by in turn calling
		 * each members <code>init()</code> method.
		 */
		public override function init():Void {
			super.init();
			var i:Int = 0;
			while( i < composites.length) {

				composites[i].init();
				 i++;
			}
		}


		/**
		 * Returns an Array<Dynamic> containing all the Composites added to this Group
		 */
		public function get_composites():Array<Composite> {
			return _composites;
		}


		/**
		 * Adds a Composite to the Group.
		 *
		 * @param c The Composite to be added.
		 */
		public function addComposite(c:Composite):Void {
			composites.push(c);
			c.isParented = true;
			if (isParented) c.init();
		}


		/**
		 * Removes a Composite from the Group.
		 *
		 * @param c The Composite to be removed.
		 */
		public function removeComposite(c:Composite):Void {
			var cpos:Int = PArray.indexOf(composites,c);
			if (cpos == -1) return;
			composites.splice(cpos, 1);
			c.isParented = false;
			c.cleanup();
		}


		/**
		 * Paints all members of this Group. This Std.is(method,called) automatically
		 * by the APEngine class.
		 */
		public override function paint():Void {

			super.paint();

			var len:Int = _composites.length;
			var i:Int = 0;
			while( i < len) {

				var c:Composite = _composites[i];
				c.paint();
				 i++;
			}
		}


		/**
		 * Adds an Group instance to be checked for collision against
		 * this one.
		 */
		public function addCollidable(g:Group):Void {
			 collisionList.push(g);
		}


		/**
		 * Removes a Group from the collidable list of this Group.
		 */
		public function removeCollidable(g:Group):Void {
			var pos:Int = PArray.indexOf(collisionList,g);
			if (pos == -1) return;
			collisionList.splice(pos, 1);
		}


		/**
		 * Adds an array of AbstractCollection instances to be checked for collision
		 * against this one.
		 */
		public function addCollidableList(list:Array<Group>):Void {
			 var i:Int = 0;
			 while( i < list.length) {

				var g:Group = list[i];
				collisionList.push(g);
			 	 i++;
			 }
		}


		/**
		 * Returns the array of every Group assigned to collide with
		 * this Group instance.
		 */
		public function get_collisionList():Array<Group> {
			return _collisionList;
		}


		/**
		 * Returns an array of every particle, constraint, and composite added to the Group.
		 */
		public override function getAll():Array<Dynamic> {
var r=new Array<Dynamic>();for(p in particles) r.push(p);for(c in composites) r.push(c);for(c in constraints) r.push(c);return r;
		}


		/**
		 * Determines if the members of this Group are checked for
		 * collision with one another.
		 */
		public function get_collideInternal():Bool {
			return _collideInternal;
		}


		/**
		 * @private
		 */
		public function set_collideInternal(b:Bool) {
			_collideInternal = b;
			return b;
		}


		/**
		 * Calls the <code>cleanup()</code> method of every member of this Group.
		 * The cleanup() Std.is(method,called) automatically when an Std.is(Group,removed)
		 * from the APEngine.
		 */
		public override function cleanup():Void {
			super.cleanup();
			var i:Int = 0;
			while( i < composites.length) {

				composites[i].cleanup();
				 i++;
			}
		}


		/**
		 * @private
		 */
		public override function integrate(dt2:Float):Void {

			super.integrate(dt2);

			var len:Int = _composites.length;
			var i:Int = 0;
			while( i < len) {

				var cmp:Composite = _composites[i];
				cmp.integrate(dt2);
				 i++;
			}
		}


		/**
		 * @private
		 */
		public override function satisfyConstraints():Void {

			super.satisfyConstraints();

			var len:Int = _composites.length;
			var i:Int = 0;
			while( i < len) {

				var cmp:Composite = _composites[i];
				cmp.satisfyConstraints();
				 i++;
			}
		}


		/**
		 * @private
		 */
		public function checkCollisions():Void {

			if (collideInternal) checkCollisionGroupInternal();

			var len:Int = collisionList.length;
			var i:Int = 0;
			while( i < len) {

				var g:Group = collisionList[i];
				checkCollisionVsGroup(g);
				 i++;
			}
		}


		private function checkCollisionGroupInternal():Void {

			// check collisions not in composites
			checkInternalCollisions();

			// for every composite in this Group..
			var clen:Int = _composites.length;
			var j:Int = 0;
			while( j < clen) {


				var ca:Composite = _composites[j];

				// .. vs non composite particles and constraints in this group
				ca.checkCollisionsVsCollection(this);

				// ...vs every other composite in this Group
				var i:Int = j + 1;
				while( i < clen) {

					var cb:Composite = _composites[i];
					ca.checkCollisionsVsCollection(cb);
					 i++;
				}
				 j++;
			}
		}


		private function checkCollisionVsGroup(g:Group):Void {

			// check particles and constraints not in composites of either group
			checkCollisionsVsCollection(g);

			var clen:Int = _composites.length;
			var gclen:Int = g.composites.length;

			// for every composite in this group..
			var i:Int = 0;
			while( i < clen) {


				// check vs the particles and constraints of g
				var c:Composite = _composites[i];
				c.checkCollisionsVsCollection(g);

				// check vs composites of g
				var j:Int = 0;
				while( j < gclen) {

					var gc:Composite = g.composites[j];
					c.checkCollisionsVsCollection(gc);
					 j++;
				}
				 i++;
			}

			// check particles and constraints of this group vs the composites of g
			var j = 0;
			while( j < gclen) {

				var gc = g.composites[j];
				checkCollisionsVsCollection(gc);
				 j++;
			}
		}
	}

