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

	class Vector {


		public var x:Float;
		public var y:Float;


		public function new(?_opt_px:Null<Float>, ?_opt_py:Null<Float>) {
			var px:Float = _opt_px==null ? 0 : _opt_px;
			var py:Float = _opt_py==null ? 0 : _opt_py;
			x = px;
			y = py;
		}


		public function setTo(px:Float, py:Float):Void {
			x = px;
			y = py;
		}


		public function copy(v:Vector):Void {
			x = v.x;
			y = v.y;
		}


		public function dot(v:Vector):Float {
			return x * v.x + y * v.y;
		}


		public function cross(v:Vector):Float {
			return x * v.y - y * v.x;
		}


		public function plus(v:Vector):Vector {
			return new Vector(x + v.x, y + v.y);
		}


		public function plusEquals(v:Vector):Vector {
			x += v.x;
			y += v.y;
			return this;
		}


		public function minus(v:Vector):Vector {
			return new Vector(x - v.x, y - v.y);
		}


		public function minusEquals(v:Vector):Vector {
			x -= v.x;
			y -= v.y;
			return this;
		}


		public function mult(s:Float):Vector {
			return new Vector(x * s, y * s);
		}


		public function multEquals(s:Float):Vector {
			x *= s;
			y *= s;
			return this;
		}


		public function times(v:Vector):Vector {
			return new Vector(x * v.x, y * v.y);
		}


		public function divEquals(s:Float):Vector {
			if (s == 0) s = 0.0001;
			x /= s;
			y /= s;
			return this;
		}


		public function magnitude():Float {
			return Math.sqrt(x * x + y * y);
		}


		public function distance(v:Vector):Float {
			var delta:Vector = this.minus(v);
			return delta.magnitude();
		}


		public function normalize():Vector {
			 var m:Float = magnitude();
			 if (m == 0) m = 0.0001;
			 return mult(1 / m);
		}


		public function toString():String {
			return (x + " : " + y);
		}
	}

