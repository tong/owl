package owl;

import om.Json;

@:enum abstract Type(Int) {

	var error = -1;

	var connect = 0;

	var join = 1;
	var leave = 2;

	var offer = 10;
	var answer = 11;
	var candidate = 12;

	//var ping = "ping";
    //var pong = "pong";

	inline function new(t) this = t;

	public function toString() return switch new Type(this) {
		case connect: "connect";
		case join: "join";
		case leave: "leave";
		case offer: "offer";
		case answer: "answer";
		case candidate: "candidate";
		case error: "error";
	}
}

/*
@:enum abstract ErrorCode(Int) {
	var not_allowed = 0;
	var mesh_max = 0;
	var unknown = 0;
}
*/

class Signal {

	public var type : Signal.Type;
	public var data : Dynamic;

	public function new( type : Signal.Type, ?data : Dynamic ) {
		this.type = type;
		this.data = data;
	}

	public function toJson() {
		var o : Dynamic = { t : type };
		if( data != null ) o.d = data;
		return o;
	}

	public inline function toString() : String
		return Json.stringify( toJson() );

	public static inline function fromJson( o : { t : Signal.Type, ?d : Dynamic } ) : Signal
		return new Signal( o.t, o.d );

	public static inline function parse( s : String ) : Signal
		return fromJson( Json.parse( s ) );
}
