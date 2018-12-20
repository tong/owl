package owl.client;

#if owl_client

import js.Error;
import js.Promise;
import js.html.CloseEvent;
import js.html.MessageEvent;
import js.html.WebSocket;
import om.FetchTools.*;
import om.Json;

class Server {

	public var host(default,null) : String;
    public var port(default,null) : Int;

	var socket : WebSocket;
	var meshes : Map<String,Mesh>;
	//var myid : String;

	public function new( host : String, port : Int ) {
        this.host = host;
        this.port = port;
		meshes = [];
    }

	public function lobby() : Promise<Array<String>> {
		return request( 'lobby' );
	}

	public function connect( callback : ?Error->Void, protocol = 'owl' ) {
		var url = 'ws://$host:$port';
		//socket = new WebSocket( url, protocol );
		socket = new WebSocket( url );
		socket.onopen = function() {
			//connected = true;
			callback();
			socket.onclose = function(e:CloseEvent) {
				trace("onclose "+e);
				//trace(om.net.WebSocket.ErrorCode.getMeaning( e.code ) );
				//connected = false;
				//callback( new Error( om.net.WebSocket.ErrorCode.getMeaning( e.code ) ) );
			}
			socket.onmessage = function(e:MessageEvent) {
				var signal = Signal.fromString( e.data );
				trace("SIGNAL "+signal.type);
				var mesh = meshes.get( signal.data.mesh );
				mesh.handleSignal( signal );
			}
		}
	}

	public function join( id : String ) : Mesh {
		var mesh = new Mesh( this, id );
		meshes.set( id, mesh );
		mesh.join();
		return mesh;
	}

	/*
	public function join( id : String ) : Promise<Dynamic> {
		return request( 'join', { node : myid, mesh : id } ).then( function(nodes){
			var mesh = new Mesh( this, id );
			meshes.set( id, mesh );
			return mesh.init( nodes );
		});
	}
	*/

	function request<T>( path : String, ?data : Dynamic ) : Promise<T> {
		//var init = {}
		//var headers = {};
		//var headers = { 'owl-id' : myid };
		//if( myid != null ) Reflect.setField( headers, 'owl-id', myid );
		return cast fetchJson( 'http://$host:$port/$path', {
			//headers: headers,
			method: (data == null) ? "GET" : "POST",
			//method: "POST",
			body: (data == null) ? null : Json.stringify( data )
		} );
	}

	@:allow(owl.client.Mesh)
	inline function signal( s : Signal ) {
		socket.send( s.toString() );
	}

}

#end
