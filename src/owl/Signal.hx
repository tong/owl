package owl;

import om.Json;

@:enum abstract Type(Int) {

	var error = -1;

	var connect = 0;

	var enter = 1;
	var join = 2;
	var leave = 3;

	var offer = 10;
	var answer = 11;
	var candidate = 12;

	//var ping = "ping";
    //var pong = "pong";

	var custom = 1000;

	inline function new(t) this = t;

	public function toString() return switch new Type(this) {
		case error: "error";
		case enter: "enter";
		case connect: "connect";
		case join: "join";
		case leave: "leave";
		case offer: "offer";
		case answer: "answer";
		case candidate: "candidate";
		case custom: "custom";
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
