package owl.client;

#if owl_client

import js.Error;
import js.Promise;
import js.html.CloseEvent;
import js.html.MessageEvent;
import js.html.WebSocket;
import om.FetchTools.*;
import om.Json;

typedef Join<M:Mesh,I> = {
	var mesh : M;
	var info : I;
}

class Server {

	public dynamic function onDisconnect( ?reason : String ) {}

	//public var connected(default,null) = false;
	public var host(default,null) : String;
    public var port(default,null) : Int;
    public var id(default,null) : String; // My node id

	var socket : WebSocket;
	var meshes = new Map<String,Mesh>();

	public function new() {}

	public function connect( host : String, port : Int, protocol = 'owl' ) : Promise<Server> {
		return new Promise( function(resolve,reject) {
			var url = 'ws://$host:$port';
			//socket = new WebSocket( url, protocol );
			socket = new WebSocket( url );
			socket.onerror = function(e) {
				reject(e);
			}
			socket.onopen = function() {
				//connected = true;
				socket.onclose = function(e:CloseEvent) {
					trace("onclose "+e);
					id = null;
					meshes = [];
					if( onDisconnect != null ) onDisconnect( e.reason );
					//trace(om.net.WebSocket.ErrorCode.getMeaning( e.code ) );
					//connected = false;
					//callback( new Error( om.net.WebSocket.ErrorCode.getMeaning( e.code ) ) );
				}
				socket.onmessage = function(e:MessageEvent) {
					var sig = Signal.parse( e.data );
					if( sig.type == error ) {
						trace("TODO ON ERROR "+sig);
					} else {
						//trace("SIGNAL "+sig.type);
						//trace("SIGNAL "+sig);
						switch sig.type {
						case connect:
							this.id = sig.data.id;
							resolve( this );
						default:
							var m = meshes.get( sig.data.mesh );
							if( m != null ) {
								m.handleSignal( sig );
							} else {
								//TODO
								trace('mesh not exists');
							}
						}
					}
				}
			}
		});
	}

	public function disconnect() : Promise<Server> {
		return new Promise( function(resolve,reject) {
			if( socket == null ) reject( 'not connected' ) else {
				switch socket.readyState {
				case WebSocket.OPEN,WebSocket.CONNECTING:
					socket.onclose = function(e) {
						socket = null;
						resolve( this );
					}
					socket.close();
				default:
					socket = null;
					resolve( this );
				}
			}
		});
	}

	//public function join<T:Mesh>( id : String, ?info : Dynamic ) : Promise<{mesh:T,info:Dynamic}> {
	public function join<M:Mesh,I>( id : String, ?info : I ) : Promise<Join<M,I>> {
		if( meshes.exists( id ) )
			return Promise.reject( 'already joined' );
		var m : M = createMesh( id );
		meshes.set( id, m );
		return m.join( info ).then( function(i:I){
			return { mesh : m, info : i };
		});
	}

	function createMesh<M:Mesh>( id : String ) : M {
		return cast new Mesh( this, id );
	}

	public inline function lobby() : Promise<Array<String>> {
		return request( 'lobby' );
	}

	/*
	public inline function admin( cmd : String ) : Promise<Array<String>> {
		return request( 'admin/$cmd' );
	}

	public inline function nope( cmd : String ) : Promise<Array<String>> {
		return request( 'nope/$cmd' );
	}

	public inline function status( mesh ) : Promise<Array<String>> {
		return request( 'status/$mesh' );
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
