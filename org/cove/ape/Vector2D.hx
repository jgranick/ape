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
- provide passible vectors for results. too much object creation happening here
- review the division by zero checks/corrections. why are they needed?
*/

package org.cove.ape ;

	class Vector2D {


		public var x:Float;
		public var y:Float;


		public function new(px:Float = 0, py:Float = 0) {
			x = px;
			y = py;
		}


		public function setTo(px:Float, py:Float):Void {
			x = px;
			y = py;
		}


		public function copy(v:Vector2D):Void {
			x = v.x;
			y = v.y;
		}


		public function dot(v:Vector2D):Float {
			return x * v.x + y * v.y;
		}


		public function cross(v:Vector2D):Float {
			return x * v.y - y * v.x;
		}


		public function plus(v:Vector2D):Vector2D {
			return new Vector2D(x + v.x, y + v.y);
		}


		public function plusEquals(v:Vector2D):Vector2D {
			x += v.x;
			y += v.y;
			return this;
		}


		public function minus(v:Vector2D):Vector2D {
			return new Vector2D(x - v.x, y - v.y);
		}


		public function minusEquals(v:Vector2D):Vector2D {
			x -= v.x;
			y -= v.y;
			return this;
		}


		public function mult(s:Float):Vector2D {
			return new Vector2D(x * s, y * s);
		}


		public function multEquals(s:Float):Vector2D {
			x *= s;
			y *= s;
			return this;
		}


		public function times(v:Vector2D):Vector2D {
			return new Vector2D(x * v.x, y * v.y);
		}


		public function divEquals(s:Float):Vector2D {
			if (s == 0) s = 0.0001;
			x /= s;
			y /= s;
			return this;
		}


		public function magnitude():Float {
			return Math.sqrt(x * x + y * y);
		}


		public function distance(v:Vector2D):Float {
			var delta:Vector2D = this.minus(v);
			return delta.magnitude();
		}


		public function normalize():Vector2D {
			 var m:Float = magnitude();
			 if (m == 0) m = 0.0001;
			 return mult(1 / m);
		}


		public function toString():String {
			return (x + " : " + y);
		}
	}

