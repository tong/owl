package owl.client;

#if owl_client

import js.Error;
import js.Promise;
import js.html.CloseEvent;
import js.html.MessageEvent;
import js.html.WebSocket;
import om.FetchTools.*;
import om.Json;
import om.Nil;

class Server {

	public dynamic function onDisconnect() {}

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

	public inline function lobby() : Promise<Array<String>> {
		return request( 'lobby' );
	}

	public function connect( protocol = 'owl' ) : Promise<Nil> {
		return new Promise( function(resolve,reject){
			var url = 'ws://$host:$port';
			//socket = new WebSocket( url, protocol );
			socket = new WebSocket( url );
			socket.onopen = function() {
				//connected = true;
				socket.onclose = function(e:CloseEvent) {
					trace("onclose "+e);
					onDisconnect();
					//trace(om.net.WebSocket.ErrorCode.getMeaning( e.code ) );
					//connected = false;
					//callback( new Error( om.net.WebSocket.ErrorCode.getMeaning( e.code ) ) );
				}
				socket.onmessage = function(e:MessageEvent) {
					var sig = Signal.fromString( e.data );
					trace("SIGNAL "+sig.type);
					if( sig.type == error ) {
						trace("TODO ON ERROR "+sig);
					} else {
						var m = meshes.get( sig.data.mesh );
						m.handleSignal( sig );
					}
				}
				resolve( nil );
			}
		});
	}

	public function join( id : String ) : Mesh {
		var m = new Mesh( this, id );
		meshes.set( id, m );
		//m.join();
		signal( Signal.Type.join, { mesh : id } );
		return m;
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
	inline function signal( type : Signal.Type, ?data : Dynamic ) {
		sendSignal( new Signal( type, data ) );
	}

	@:allow(owl.client.Mesh)
	inline function sendSignal( s : Signal ) {
		socket.send( s.toString() );
	}

}

#end
