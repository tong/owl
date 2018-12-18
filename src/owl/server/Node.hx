package owl.server;

#if owl_server

import haxe.Json;
import js.Node.console;
import js.node.Buffer;
import js.npm.ws.WebSocket as Socket;

class Node {

    //public dynamic function onConnect() {}
    public dynamic function onDisconnect() {}
    public dynamic function onMessage( msg : Dynamic ) {}

    public var id(default,null) : String;
    public var meshes(default,null) : Array<String>;

    public var ip(default,null) : String;
//    public var ip(get,null) : String;
//    inline function get_ip() return socket.remoteAddress;

    //public var isWebSocket(default,null) : Null<Bool>;

    var socket : Socket;

    public function new( id : String, socket : Socket, ip : String ) {

        this.id = id;
        this.socket = socket;
        this.ip = ip;

        meshes = [];

        socket.once( 'close', function(e) {
            onDisconnect();
        });
        socket.on( 'message', function(str:String) {
            //trace(buf);
            var msg = try Json.parse( str ) catch(e:Dynamic){
                console.warn(e);
                return;
            }
            onMessage( msg );
        });

        //onConnect();

        /*
        socket.addListener( 'data', function(buf:Buffer) {

            trace(buf);

            if( buf == null ) return;

            if( isWebSocket == null ) {
                if( buf.slice( 0, 10 ).toString() == 'GET / HTTP' ) { //TODO
                    isWebSocket = true;
                    socket.write( WebSocket.createHandshake( buf ) );
                    onConnect();
                    return;
                } else {
                    isWebSocket = false;
                    onConnect();
                }
            } else if( isWebSocket ) {
                buf = WebSocket.readFrame( buf );
                if( buf == null ) return;
            }

            var str = buf.toString();
            var msg = try Json.parse( str ) catch(e:Dynamic){
                console.warn(e);
                return;
            }
            onMessage( msg );
        });
        */
    }

    public inline function sendError( message : String, ?callback : js.Error->Void ) {
        sendMessage( { type: 'error', data: message }, callback );
    }

    public function sendMessage( msg : Dynamic, ?callback : js.Error->Void ) {
        var str = try Json.stringify( msg ) catch(e:Dynamic) {
            trace( e );
            if( callback != null ) callback( e );
            return;
        }
        sendString( str, callback );
    }

    public function sendString( str : String, ?callback : js.Error->Void ) {
        //sendBuffer( new Buffer( str ) );
        //sendBuffer( Buffer.from( str ) );
        //trace(socket.readyState);
        socket.send( str, function(e){
            if( e != null ) {
                trace(e);
                if( callback != null ) callback(e);
            }
        } );
    }

    /*
    public function sendBuffer( buf : Buffer ) {
        //if( isWebSocket ) buf = WebSocket.writeFrame( buf );
        //socket.write( buf );
        socket.send( buf );
    }
    */

    public function disconnect() {
//        socket.end();
    }

    public function toString() {
        return 'Node($ip:$id)';
    }
}

/*
import js.node.Buffer;
import js.node.net.Socket;
import js.Node.console;
import om.net.WebSocket;

class Node {

    public dynamic function onConnect() {}
    public dynamic function onDisconnect() {}
    public dynamic function onMessage( msg : Dynamic ) {}

    public var id(default,null) : String;
    public var meshes(default,null) : Array<String>;

    public var ip(get,null) : String;
    inline function get_ip() return socket.remoteAddress;

    public var isWebSocket(default,null) : Null<Bool>;

    var socket : Socket;

    public function new( id : String, socket : Socket ) {

        this.id = id;
        this.socket = socket;

        meshes = [];

        socket.once( 'close', function(e) {
            onDisconnect();
        });
        socket.addListener( 'data', function(buf:Buffer) {

            if( buf == null ) return;

            if( isWebSocket == null ) {
                if( buf.slice( 0, 10 ).toString() == 'GET / HTTP' ) { //TODO
                    isWebSocket = true;
                    socket.write( WebSocket.createHandshake( buf ) );
                    onConnect();
                    return;
                } else {
                    isWebSocket = false;
                    onConnect();
                }
            } else if( isWebSocket ) {
                buf = WebSocket.readFrame( buf );
                if( buf == null ) return;
            }

            var str = buf.toString();
            var msg = try Json.parse( str ) catch(e:Dynamic){
                console.warn(e);
                return;
            }
            onMessage( msg );
        });
    }

    public inline function sendError( message : String ) {
        sendMessage( { type: 'error', data: message } );
    }

    public function sendMessage( msg : Dynamic ) {
        var str = try Json.stringify( msg ) catch(e:Dynamic) {
            trace( e );
            return;
        }
        sendString( str );
    }

    public inline function sendString( str : String ) {
        //sendBuffer( new Buffer( str ) );
        sendBuffer( Buffer.from( str ) );
    }

    public function sendBuffer( buf : Buffer ) {
        if( isWebSocket ) buf = WebSocket.writeFrame( buf );
        socket.write( buf );
    }

    public function disconnect() {
        socket.end();
    }
}
*/

#end
