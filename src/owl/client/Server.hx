package owl.client;

#if owl_client

import js.Browser.console;
import js.Error;
import js.Promise;
import js.html.CloseEvent;
import js.html.WebSocket;
import om.Json;
import om.Nil;

/**
    Mesh network application server connection.
**/
class Server {

    public var event(default,null) = new om.Emitter<Void>();

    public dynamic function onConnect() {}
    public dynamic function onDisconnect( ?error : Error ) {}
    public dynamic function onSignal( msg : Message ) {}

    public var ip(default,null) : String;
    public var port(default,null) : Int;
    public var connected(default,null) = false;

    var socket : WebSocket;

    public function new( ip : String, port : Int ) {
        this.ip = ip;
        this.port = port;
    }

    public function connect() : Promise<Server> {

        connected = false;

        return new Promise( function(resolve,reject){

            socket = new WebSocket( 'ws://$ip:$port' );
            socket.addEventListener( 'open', function(e){
                connected = true;
                resolve( this );
                //event.emit();
            });
            socket.addEventListener( 'close', function(e){
                var wasConnected = connected;
                connected = false;
                var message = om.net.WebSocket.ErrorCode.getMeaning( e.code );
                var err = new Error( message );
                //trace( "ERRR "+err );
                reject( err );
                onDisconnect( err );
                //trace( wasConnected );
                if( wasConnected ) event.emit( 'disconnect' );

            });
            socket.addEventListener( 'error', function(e){
                trace(e);
                //reject( e );
                //onDisconnect( e );
            });
            socket.addEventListener( 'message', handleSocketMessage, false );
        });
    }

    public function disconnect() {
        if( socket != null ) {
            socket.removeEventListener( 'message', handleSocketMessage );
            socket.close();
            socket = null;
        }
    }

	public function addMesh<T:Node>( mesh : Mesh<T> ) : Mesh<T> {
		mesh.onSignal = sendSignal;
		onSignal = mesh.handleSignal;
		return mesh;
	}

    public function sendSignal( msg : Message ) : String {
        var str = try Json.stringify( msg ) catch(e:Dynamic) {
            console.error(e);
            return null;
        }
        socket.send( str );
        return str;
    }

    /*
    public function join( mesh : String ) {
        send( { type: 'join', data: { mesh: mesh } } );
    }
    */

    public inline function leave( mesh : String ) {
        sendSignal( { type: 'leave', data: { mesh: mesh } } );
    }

    /*
    function handleSocketClose( e ) {
        trace(e);
    }
    */

    function handleSocketMessage( e ) {
        var msg : Message = try Json.parse( e.data ) catch(e:Dynamic) {
            console.error( e );
            return;
        }
        handleSignal( msg );
    }

    inline function handleSignal( msg : Message ) {
        onSignal( msg );
    }
}

#end
