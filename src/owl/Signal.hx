package owl;

import om.Json;

@:enum abstract Type(Int) {

	var join = 0;
	var leave = 1;

	var enter = 2;

	var offer = 100;
	var answer = 101;
	var candidate = 102;

	var error = 1000;
}

class Signal {

	public var type : Type;
	public var data : Dynamic;

	public function new( type : Type, ?data : Dynamic ) {
		this.type = type;
		this.data = data;
	}

	public function toJson() : Dynamic {
		var o : Dynamic = { t : type };
		if( data != null ) o.d = data;
		return o;
	}

	public inline function toString() : String {
		return Json.stringify( toJson() );
	}

	public static inline function fromJson( o : Dynamic ) : Signal {
		return new Signal( o.t, o.d );
	}

	public static inline function fromString( s : String ) : Signal {
		return fromJson( Json.parse( s ) );
	}
}
