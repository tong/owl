package owl;

import om.Json;

@:enum abstract Type(String) from String to String {
    var join;
    var offer;
    var answer;
    var candidate;
}

class Message {

	public var type : Type;
	public var data : Dynamic;

	public function new( type : Type, ?data : Dynamic ) {
		this.type = type;
		this.data = data;
	}

	public function toJson() : Dynamic {
		var obj : Dynamic = { type : type };
		if( data != null ) Reflect.setField( obj, 'data', data );
		return obj;
	}

	public inline function toString() : String {
		return Json.stringify( toJson() );
	}

	public static inline function fromJson( obj : Dynamic ) : Message {
		return new Message( obj.type, obj.data );
	}

	public static inline function fromString( str : String ) : Message {
		return fromJson( Json.parse( str ) );
	}
}
