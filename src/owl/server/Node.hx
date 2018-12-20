package owl.server;

#if owl_server

import js.npm.ws.WebSocket as Socket;

class Node {

	@:allow(owl.server.Server) dynamic function onDisconnect() {}
	@:allow(owl.server.Server) dynamic function onSignal( s : Signal ) {}

	public var id(default,null) : String;
	public var address(default,null) : String;

	var socket : Socket;

	public function new( socket : Socket, id : String, address : String ) {

		this.socket = socket;
		this.id = id;
		this.address = address;

		socket.once( 'close', function(e) {
			//trace(e);
			this.address = null;
            onDisconnect();
        });
		socket.on( 'message', function(e) {
			onSignal( Signal.parse( e ) );
		});
	}

	@:allow(owl.server.Server)
	inline function signal( type : Signal.Type, ?data : Dynamic ) {
		sendSignal( new Signal( type, data ) );
	}

	@:allow(owl.server.Server)
	function sendSignal( s : Signal ) {
		socket.send( s.toString(), function(e){
			if( e != null ) trace(e);
		} );
	}
}

#end
