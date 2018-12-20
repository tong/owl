package owl;

import om.Json;

@:enum abstract SignalType(Int) {
	var join = 0;
	var enter = 1;
	var offer = 2;
	var answer = 3;
	var candidate = 4;
}
/*
private typedef Signal = {
	//mesh : String,
	//node : String,
	type : SignalType,
	?data : Dynamic
}
*/

class Signal {

	public var type : SignalType;
	public var data : Dynamic;

	public function new( type : SignalType, ?data : Dynamic ) {
		this.type = type;
		this.data = data;
	}

	public function toJson() : Dynamic {
		var o : Dynamic = { type : type };
		if( data != null ) o.data = data;
		return o;
	}

	public inline function toString() : String {
		return Json.stringify( toJson() );
	}

	public static inline function fromJson( o : Dynamic ) : Signal {
		return new Signal( o.type, o.data );
	}

	public static inline function fromString( s : String ) : Signal {
		return fromJson( Json.parse( s ) );
	}
}
