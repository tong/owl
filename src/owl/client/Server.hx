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

typedef Join<M:Mesh,D> = {
	var mesh : M;
	var creds : Dynamic;
	@:optional var data : D;
}

class Server {

	public dynamic function onDisconnect( ?reason : String ) {}
	public dynamic function onError( e : String ) {}

	public var connected(default,null) = false;
	public var host(default,null) : String;
    public var port(default,null) : Int;
    public var id(default,null) : String; // My node id

	var socket : WebSocket;
	var meshes = new Map<String,Mesh>();

	public function new() {}

	public function connect( host : String, port : Int, protocol = 'owl' ) : Promise<Server> {
		return new Promise( function(resolve,reject) {
			this.host = host;
			this.port = port;
			var url = 'ws://$host:$port';
			//socket = new WebSocket( url, protocol );
			socket = new WebSocket( url );
			socket.onerror = function(e) {
				reject(e);
			}
			socket.onopen = function() {
				connected = true;
				socket.onclose = function(e:CloseEvent) {
					trace("onclose "+e);
					connected = false;
					id = null;
					meshes = [];
					if( onDisconnect != null ) onDisconnect( e.reason );
					//trace(om.net.WebSocket.ErrorCode.getMeaning( e.code ) );
					//callback( new Error( om.net.WebSocket.ErrorCode.getMeaning( e.code ) ) );
				}
				socket.onmessage = function(e:MessageEvent) {
					var sig = Signal.parse( e.data );
					if( sig.type == error ) {
						trace("TODO ON ERROR "+sig);
						//reject( sig.data.info );
						onError( sig.data.info );
					} else {
						//trace("SIGNAL "+sig.type);
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

	public function join<M:Mesh,D>( id : String, creds : Dynamic, ?timeout : Int ) : Promise<Join<M,D>> {
		if( meshes.exists( id ) )
			return Promise.reject( 'joined' );
		var m : M = cast createMesh( id );
		meshes.set( id, m );
		return m.join( creds, timeout ).then( function(r){
			return { mesh : m, creds : r.creds, data : r.data };
		});
	}

	//public function leave( mesh : Mesh, ?status : Dynamic ) : Promise<Nil> {
	public function leave( mesh : Mesh, ?status : Dynamic ) : Promise<Nil> {
		if( meshes.exists( id ) )
			return Promise.reject( 'unjoined' );
		return new Promise( function(resolve,reject){
			//signal( owl.Signal.Type.leave, { mesh : mesh.id, status : status } );
			signal( owl.Signal.Type.leave, { mesh : mesh.id } );
			for( n in mesh ) n.disconnect();
			meshes.remove( mesh.id );
			resolve( nil );
		});
	}

	public function request<T>( path : String, ?data : Dynamic ) : Promise<T> {
		//var init = {}
		//var headers = {};
		//var headers = { 'owl-id' : myid };
		//if( myid != null ) Reflect.setField( headers, 'owl-id', myid );
		return cast js.Browser.window.fetch( 'http://$host:$port/$path', {
			//headers: headers,
			method: (data == null) ? "GET" : "POST",
			//method: "POST",
			//method: "GET",
			body: (data == null) ? null : Json.stringify( data )
		} );
		/*
		if( data == null ) {
			return cast fetchJson( 'http://$host:$port/$path', {
				//headers: headers,
				//method: (data == null) ? "GET" : "POST",
				//method: "POST",
				method: "GET",
				//body: (data == null) ? null : Json.stringify( data )
			} );
		} else {
			return cast fetchJson( 'http://$host:$port/$path', {
				//headers: headers,
				//method: (data == null) ? "GET" : "POST",
				//method: "POST",
				method : "POST",
				body : Json.stringify( data )
				//body: (data == null) ? null : Json.stringify( data )
			} );
		}
		*/
		/*
		return window.fetch( 'http://$host:$port/$path', {
			//headers: headers,
			method: (data == null) ? "GET" : "POST",
			//method: "POST",
			body: (data == null) ? null : Json.stringify( data )
		});
		*/
		/*
		return cast fetchJson( 'http://$host:$port/$path', {
			//headers: headers,
			method: (data == null) ? "GET" : "POST",
			//method: "POST",
			body: (data == null) ? null : Json.stringify( data )
		} );
		*/
	}

	function createMesh( id : String ) : Mesh {
		return new Mesh( this, id );
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
