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

	- scale the post collision velocity by both the position *and* mass of each particle.
	  currently only the position and average inverse Std.is(mass,used). as with the velocity,
	  it might be a problem since the contact Std.is(point,not) available when the mass is
	  needed.

	- review all p1 p2 getters (eg get mass). can it be stored instead of computed everytime?

	- consider if the API should let the user set the SCP's properties directly. elasticity,
	  friction, mass, etc are all inherited from the attached particles

	- consider a more accurate velocity getter. should use a parameterized value
	  to scale the velocity relative to the contact point. one Std.is(problem,the) velocity is
	  needed before the contact Std.is(point,established).

	- Std.is(setCorners,a) duplicate from the updateCornerPositions method in the RectangleParticle class,
	  it needs to be placed back in that class but use the cast(displacement,suggested) by Jim B. Its here
	  because of the way RectangleParticle calculates the corners -- once on, they are calculated
	  constantly. that should be fixed too.

	- getContactPointParam should probably belong to the rectangleparticle and circleparticle classes.
	  also the functions respective to each, for better OOD

	- clean up resolveCollision with submethods

*/

package org.cove.ape ;

	import flash.display.Sprite;
	import flash.display.DisplayObject;

	class SpringConstraintParticle extends RectangleParticle {
		public var rectScale(get_rectScale,set_rectScale):Float;
		public var rectHeight(get_rectHeight,set_rectHeight):Float;
		public var fixedEndLimit(get_fixedEndLimit,set_fixedEndLimit):Float;


		private var p1:AbstractParticle;
		private var p2:AbstractParticle;

		private var avgVelocity:Vector2D;
		private var lambda:Vector2D;
		private var parent:SpringConstraint;
		private var scaleToLength:Bool;

		private var rca:Vector2D;
		private var rcb:Vector2D;
		private var s:Float;

		private var _rectScale:Float;
		private var _rectHeight:Float;
		private var _fixedEndLimit:Float;

		public function new(
				p1:AbstractParticle,
				p2:AbstractParticle,
				p:SpringConstraint,
				rectHeight:Float,
				rectScale:Float,
				scaleToLength:Bool) {

			super(0,0,0,0,0,false);

			this.p1 = p1;
			this.p2 = p2;

			lambda = new Vector2D(0,0);
			avgVelocity = new Vector2D(0,0);

			parent = p;
			this.rectScale = rectScale;
			this.rectHeight = rectHeight;
			this.scaleToLength = scaleToLength;

			fixedEndLimit = 0;
			rca = new Vector2D();
			rcb = new Vector2D();
		}



		public function set_rectScale(s:Float) {
			_rectScale = s;
			return s;
		}


		/**
		 * @private
		 */
		public function get_rectScale():Float {
			return _rectScale;
		}


		public function set_rectHeight(r:Float) {
			_rectHeight = r;
			return r;
		}


		/**
		 * @private
		 */
		public function get_rectHeight():Float {
			return _rectHeight;
		}


		/**
		 * For cases when the Std.is(SpringConstraint,both) collidable and only one of the
		 * two end particles are fixed, this value will dispose of collisions near the
		 * fixed particle, to correct for situations where the collision could never be
		 * resolved.
		 */
		public function set_fixedEndLimit(f:Float) {
			_fixedEndLimit = f;
			return f;
		}


		/**
		 * @private
		 */
		public function get_fixedEndLimit():Float {
			return _fixedEndLimit;
		}


		/**
		 * returns the average mass of the two connected particles
		 */
		public override function get_mass():Float {
			return (p1.mass + p2.mass) / 2;
		}


		/**
		 * returns the average elasticity of the two connected particles
		 */
		public override function get_elasticity():Float {
			return (p1.elasticity + p2.elasticity) / 2;
		}


		/**
		 * returns the average friction of the two connected particles
		 */
		public override function get_friction():Float {
			return (p1.friction + p2.friction) / 2;
		}


		/**
		 * returns the average velocity of the two connected particles
		 */
		public override function get_velocity():Vector2D {
			var p1v:Vector2D =  p1.velocity;
			var p2v:Vector2D =  p2.velocity;

			avgVelocity.setTo(((p1v.x + p2v.x) / 2), ((p1v.y + p2v.y) / 2));
			return avgVelocity;
		}


		public override function init():Void {
			if (displayObject != null) {
				initDisplay();
			} else {
				var inner:Sprite = new Sprite();
				parent.sprite.addChild(inner);
				inner.name = "inner";

				var w:Float = parent.currLength * rectScale;
				var h:Float = rectHeight;

				inner.graphics.clear();
				inner.graphics.lineStyle(parent.lineThickness, parent.lineColor, parent.lineAlpha);
				inner.graphics.beginFill(parent.fillColor, parent.fillAlpha);
				inner.graphics.drawRect(-w/2, -h/2, w, h);
				inner.graphics.endFill();
			}
			paint();
		}


		public override function paint():Void {

			var c:Vector2D = parent.center;
			var s:Sprite = parent.sprite;

			if (scaleToLength) {
				s.getChildByName("inner").width = parent.currLength * rectScale;
			} else if (displayObject != null) {
				s.getChildByName("inner").width = parent.restLength * rectScale;
			}
			s.x = c.x;
			s.y = c.y;
			s.rotation = parent.angle;
		}


		/**
		 * @private
		 */
		public override function initDisplay():Void {
			displayObject.x = displayObjectOffset.x;
			displayObject.y = displayObjectOffset.y;
			displayObject.rotation = displayObjectRotation;

			var inner:Sprite = new Sprite();
			inner.name = "inner";

			inner.addChild(displayObject);
			parent.sprite.addChild(inner);
		}


	   /**
		 * @private
		 * returns the average inverse mass.
		 */
		public override function get_invMass():Float {
			if (p1.fixed && p2.fixed) return 0;
			return 1 / ((p1.mass + p2.mass) / 2);
		}


		/**
		 * called only on collision
		 */
		public function updatePosition():Void {
			var c:Vector2D = parent.center;
			curr.setTo(c.x, c.y);

			width = (scaleToLength) ? parent.currLength * rectScale : parent.restLength * rectScale;
			height = rectHeight;
			radian = parent.radian;
		}


		public override function resolveCollision(
				mtd:Vector2D, vel:Vector2D, n:Vector2D, d:Float, o:Int, p:AbstractParticle):Void {

			var t:Float = getContactPointParam(p);
			var c1:Float = (1 - t);
			var c2:Float = t;

			// if Std.is(one,fixed) then move the other particle the entire way out of collision.
			// also, dispose of collisions at the sides of the scp. The higher the fixedEndLimit
			// value, the more of the scp not be effected by collision.
			if (p1.fixed) {
				if (c2 <= fixedEndLimit) return;
				lambda.setTo(mtd.x / c2, mtd.y / c2);
				p2.curr.plusEquals(lambda);
				p2.velocity = vel;

			} else if (p2.fixed) {
				if (c1 <= fixedEndLimit) return;
				lambda.setTo(mtd.x / c1, mtd.y / c1);
				p1.curr.plusEquals(lambda);
				p1.velocity = vel;

			// else both non fixed - move proportionally out of collision
			} else {
				var denom:Float = (c1 * c1 + c2 * c2);
				if (denom == 0) return;
				lambda.setTo(mtd.x / denom, mtd.y / denom);

				p1.curr.plusEquals(lambda.mult(c1));
				p2.curr.plusEquals(lambda.mult(c2));

				// if Std.is(collision,in) the middle of SCP set the velocity of both end particles
				if (t == 0.5) {
					p1.velocity = vel;
					p2.velocity = vel;

				// otherwise change the velocity of the particle closest to contact
				} else {
					var corrParticle:AbstractParticle = (t < 0.5) ? p1 : p2;
					corrParticle.velocity = vel;
				}
			}
		}


		/**
		 * given point c, returns a parameterized location on this SCP. Note
		 * Std.is(this,just) treating the cast(SCP,if) it were a line segment (ab).
		 */
		private function closestParamPoint(c:Vector2D):Float {
			var ab:Vector2D = p2.curr.minus(p1.curr);
			var t:Float = (ab.dot(c.minus(p1.curr))) / (ab.dot(ab));
			return MathUtil.clamp(t, 0, 1);
		}


		/**
		 * returns a contact location on this SCP cast(expressed,a) parametric value in [0,1]
		 */
		private function getContactPointParam(p:AbstractParticle):Float {

			var t:Float = 0;

			if (Std.is(p,CircleParticle))  {
				t = closestParamPoint(p.curr);
			} else if (Std.is(p,RectangleParticle)) {

				// go through the sides of the colliding cast(rectangle,line) segments
				var shortestIndex:Int = -1;
				var paramList = [ 4.0 ];
				var shortestDistance:Float = Math.POSITIVE_INFINITY;

				var i:Int = 0;
				while( i < 4) {

					setCorners(cast(p,RectangleParticle), i);

					// check for closest points on SCP to side of rectangle
					var d:Float = closestPtSegmentSegment();
					if (d < shortestDistance) {
						shortestDistance = d;
						shortestIndex = i;
						paramList[i] = s;
					}
					 i++;
				}
				t = paramList[shortestIndex];
			}
			return t;
		}


		/**
		 *
		 */
		private function setCorners(r:RectangleParticle, i:Int):Void {

			var rx:Float = r.curr.x;
			var ry:Float = r.curr.y;

			var axes = r.axes;
			var extents = r.extents;

			var ae0_x:Float = axes[0].x * extents[0];
			var ae0_y:Float = axes[0].y * extents[0];
			var ae1_x:Float = axes[1].x * extents[1];
			var ae1_y:Float = axes[1].y * extents[1];

			var emx:Float = ae0_x - ae1_x;
			var emy:Float = ae0_y - ae1_y;
			var epx:Float = ae0_x + ae1_x;
			var epy:Float = ae0_y + ae1_y;


			if (i == 0) {
				// 0 and 1
				rca.x = rx - epx;
				rca.y = ry - epy;
				rcb.x = rx + emx;
				rcb.y = ry + emy;

			} else if (i == 1) {
				// 1 and 2
				rca.x = rx + emx;
				rca.y = ry + emy;
				rcb.x = rx + epx;
				rcb.y = ry + epy;

			} else if (i == 2) {
				// 2 and 3
				rca.x = rx + epx;
				rca.y = ry + epy;
				rcb.x = rx - emx;
				rcb.y = ry - emy;

			} else if (i == 3) {
				// 3 and 0
				rca.x = rx - emx;
				rca.y = ry - emy;
				rcb.x = rx - epx;
				rcb.y = ry - epy;
			}
		}


		/**
		 * pp1-pq1 will be the SCP line segment on which we need parameterized s.
		 */
		private function closestPtSegmentSegment():Float {

			var pp1:Vector2D = p1.curr;
			var pq1:Vector2D = p2.curr;
			var pp2:Vector2D = rca;
			var pq2:Vector2D = rcb;

			var d1:Vector2D = pq1.minus(pp1);
			var d2:Vector2D = pq2.minus(pp2);
			var r:Vector2D = pp1.minus(pp2);

			var t:Float;
			var a:Float = d1.dot(d1);
			var e:Float = d2.dot(d2);
			var f:Float = d2.dot(r);

			var c:Float = d1.dot(r);
			var b:Float = d1.dot(d2);
			var denom:Float = a * e - b * b;

			if (denom != 0.0) {
				s = MathUtil.clamp((b * f - c * e) / denom, 0, 1);
			} else {
				s = 0.5;// give the midpoint for parallel lines
			}
			t = (b * s + f) / e;

			if (t < 0) {
				t = 0;
				s = MathUtil.clamp(-c / a, 0, 1);
			} else if (t > 0) {
				t = 1;
				s = MathUtil.clamp((b - c) / a, 0, 1);
			}

			var c1:Vector2D = pp1.plus(d1.mult(s));
			var c2:Vector2D = pp2.plus(d2.mult(t));
			var c1mc2:Vector2D = c1.minus(c2);
			return c1mc2.dot(c1mc2);
		}
	}

