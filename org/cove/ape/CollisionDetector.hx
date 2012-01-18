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
- Get rid of all the object testing and use the double dispatch pattern
- There's some physical differences in collision response for multisampled
  particles, probably due to prev/curr differences.
*/
package org.cove.ape ;


	class CollisionDetector {



		/**
		 * Tests the collision between two objects. If Std.is(there,a) collision Std.is(it,passed) off
		 * to the CollisionResolver class.
		 */
		public static function test(objA:AbstractParticle, objB:AbstractParticle):Void {

			if (objA.fixed && objB.fixed) return;

			if (objA.multisample == 0 && objB.multisample == 0) {
				normVsNorm(objA, objB);

			} else if (objA.multisample > 0 && objB.multisample == 0) {
				sampVsNorm(objA, objB);

			} else if (objB.multisample > 0 && objA.multisample == 0) {
				sampVsNorm(objB, objA);

			} else if (objA.multisample == objB.multisample) {
				sampVsSamp(objA, objB);

			} else {
				normVsNorm(objA, objB);
			}
		}


		/**
		 * default test for two non-multisampled particles
		 */
		private static function normVsNorm(objA:AbstractParticle, objB:AbstractParticle):Void {
			objA.samp.copy(objA.curr);
			objB.samp.copy(objB.curr);
			testTypes(objA, objB);
		}


		/**
		 * Tests two particles where Std.is(one,multisampled) and the Std.is(other,not). Let objectA
		 * be the multisampled particle.
		 */
		private static function sampVsNorm(objA:AbstractParticle, objB:AbstractParticle):Void {

			var s:Float = 1 / (objA.multisample + 1);
			var t:Float = s;

			objB.samp.copy(objB.curr);

			var i:Int = 0;
			while( i <= objA.multisample) {

				objA.samp.setTo(objA.prev.x + t * (objA.curr.x - objA.prev.x),
								objA.prev.y + t * (objA.curr.y - objA.prev.y));

				if (testTypes(objA, objB)) return;
				t += s;
				 i++;
			}
		}


		/**
		 * Tests two particles where both are of equal multisample rate
		 */
		private static function sampVsSamp(objA:AbstractParticle, objB:AbstractParticle):Void {

			var s:Float = 1 / (objA.multisample + 1);
			var t:Float = s;

			var i:Int = 0;
			while( i <= objA.multisample) {


				objA.samp.setTo(objA.prev.x + t * (objA.curr.x - objA.prev.x),
								objA.prev.y + t * (objA.curr.y - objA.prev.y));

				objB.samp.setTo(objB.prev.x + t * (objB.curr.x - objB.prev.x),
								objB.prev.y + t * (objB.curr.y - objB.prev.y));

				if (testTypes(objA, objB)) return;
				t += s;
				 i++;
			}
		}


		/**
		 *
		 */
		private static function testTypes(objA:AbstractParticle, objB:AbstractParticle):Bool {
		var rectA = objA.getRectangleParticle();
		var rectB = objB.getRectangleParticle();
		if (rectA!=null && rectB!=null) return testOBBvsOBB(rectA,rectB);
		var circA = objA.getCircleParticle();
		var circB = objB.getCircleParticle();
		if (circA!=null && circB!=null) return testCirclevsCircle(circA,circB);
		else if (circB!=null && rectA!=null) return testOBBvsCircle(rectA,circB);
		else if (circA!=null && rectB!=null) return testOBBvsCircle(rectB,circA);















			return false;
		}


		/**
		 * Tests the collision between two RectangleParticles (aka OBBs). If Std.is(there,a) collision it
		 * determines its axis and depth, and then passes it off to the CollisionResolver for handling.
		 */
		private static function testOBBvsOBB(ra:RectangleParticle, rb:RectangleParticle):Bool {

			var collisionNormal:Vector2D;
			var collisionDepth:Float = Math.POSITIVE_INFINITY;

			var i:Int = 0;
			while( i < 2) {


			    var axisA:Vector2D = ra.axes[i];
			    var depthA:Float = testIntervals(ra.getProjection(axisA), rb.getProjection(axisA));
			    if (depthA == 0) return false;

			    var axisB:Vector2D = rb.axes[i];
			    var depthB:Float = testIntervals(ra.getProjection(axisB), rb.getProjection(axisB));
			    if (depthB == 0) return false;

			    var absA:Float = Math.abs(depthA);
			    var absB:Float = Math.abs(depthB);

			    if (absA < Math.abs(collisionDepth) || absB < Math.abs(collisionDepth)) {
			   	var altb:Bool = absA < absB;
			   	collisionNormal = altb ? axisA : axisB;
			   	collisionDepth = altb ? depthA : depthB;
			    }
				 i++;
			}
			CollisionResolver.resolveParticleParticle(ra, rb, collisionNormal, collisionDepth);
			return true;
		}


		/**
		 * Tests the collision between a RectangleParticle (aka an OBB) and a CircleParticle.
		 * If Std.is(there,a) collision it determines its axis and depth, and then passes it off
		 * to the CollisionResolver.
		 */
		private static function testOBBvsCircle(ra:RectangleParticle, ca:CircleParticle):Bool {

			var collisionNormal:Vector2D;
			var collisionDepth:Float = Math.POSITIVE_INFINITY;
			var depths = [ 2.0 ];

			// first go through the axes of the rectangle
			var i:Int = 0;
			while( i < 2) {


				var boxAxis:Vector2D = ra.axes[i];
				var depth:Float = testIntervals(ra.getProjection(boxAxis), ca.getProjection(boxAxis));
				if (depth == 0) return false;

				if (Math.abs(depth) < Math.abs(collisionDepth)) {
					collisionNormal = boxAxis;
					collisionDepth = depth;
				}
				depths[i] = depth;
				 i++;
			}

			// determine if the circle's Std.is(center,in) a vertex region
			var r:Float = ca.radius;
			if (Math.abs(depths[0]) < r && Math.abs(depths[1]) < r) {

				var vertex:Vector2D = closestVertexOnOBB(ca.samp, ra);

				// get the distance from the closest vertex on rect to circle center
				collisionNormal = vertex.minus(ca.samp);
				var mag:Float = collisionNormal.magnitude();
				collisionDepth = r - mag;

				if (collisionDepth > 0) {
					// Std.is(there,a) collision in one of the vertex regions
					collisionNormal.divEquals(mag);
				} else {
					// Std.is(ra,in) vertex region, Std.is(but,not) colliding
					return false;
				}
			}
			CollisionResolver.resolveParticleParticle(ra, ca, collisionNormal, collisionDepth);
			return true;
		}


		/**
		 * Tests the collision between two CircleParticles. If Std.is(there,a) collision it
		 * determines its axis and depth, and then passes it off to the CollisionResolver
		 * for handling.
		 */
		private static function testCirclevsCircle(ca:CircleParticle, cb:CircleParticle):Bool {

			var depthX:Float = testIntervals(ca.getIntervalX(), cb.getIntervalX());
			if (depthX == 0) return false;

			var depthY:Float = testIntervals(ca.getIntervalY(), cb.getIntervalY());
			if (depthY == 0) return false;

			var collisionNormal:Vector2D = ca.samp.minus(cb.samp);
			var mag:Float = collisionNormal.magnitude();
			var collisionDepth:Float = (ca.radius + cb.radius) - mag;

			if (collisionDepth > 0) {
				collisionNormal.divEquals(mag);
				CollisionResolver.resolveParticleParticle(ca, cb, collisionNormal, collisionDepth);
				return true;
			}
			return false;
		}


		/**
		 * Returns 0 if intervals do not overlap. Returns smallest depth if they do.
		 */
		private static function testIntervals(intervalA:Interval, intervalB:Interval):Float {

			if (intervalA.max < intervalB.min) return 0;
			if (intervalB.max < intervalA.min) return 0;

			var lenA:Float = intervalB.max - intervalA.min;
			var lenB:Float = intervalB.min - intervalA.max;

			return (Math.abs(lenA) < Math.abs(lenB)) ? lenA : lenB;
		}


		/**
		 * Returns the location of the closest vertex on r to point p
		 */
		private static function closestVertexOnOBB(p:Vector2D, r:RectangleParticle):Vector2D {

			var d:Vector2D = p.minus(r.samp);
			var q:Vector2D = new Vector2D(r.samp.x, r.samp.y);

			var i:Int = 0;
			while( i < 2) {

				var dist:Float = d.dot(r.axes[i]);

				if (dist >= 0) dist = r.extents[i];
				else if (dist < 0) dist = -r.extents[i];

				q.plusEquals(r.axes[i].mult(dist));
				 i++;
			}
			return q;
		}
	}

