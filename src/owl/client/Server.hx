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
    public var id(default,null) : String; // My node id

	var socket : WebSocket;
	var meshes = new Map<String,Mesh>();

	public function new( host : String, port : Int ) {
        this.host = host;
        this.port = port;
    }

	public function connect( protocol = 'owl' ) : Promise<Server> {
		return new Promise( function(resolve,reject) {
			var url = 'ws://$host:$port';
			//socket = new WebSocket( url, protocol );
			socket = new WebSocket( url );
			socket.onopen = function() {
				//connected = true;
				socket.onclose = function(e:CloseEvent) {
					trace("onclose "+e);
					id = null;
					meshes = [];
					onDisconnect();
					//trace(om.net.WebSocket.ErrorCode.getMeaning( e.code ) );
					//connected = false;
					//callback( new Error( om.net.WebSocket.ErrorCode.getMeaning( e.code ) ) );
				}
				socket.onmessage = function(e:MessageEvent) {
					var sig = Signal.parse( e.data );
					trace("SIGNAL "+sig.type);
					if( sig.type == error ) {
						trace("TODO ON ERROR "+sig);
					} else {
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
