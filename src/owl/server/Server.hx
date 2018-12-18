package owl.server;

#if owl_server

import js.Node.console;
import js.Promise;
//import js.node.Net;
//import js.node.net.Socket;
import js.npm.ws.Server;
import js.npm.ws.WebSocket as Socket;
import om.Nil;

/**
    Mesh network negotiation server base class.
**/
class Server {

    public dynamic function onNodeConnect( node : Node ) {}
    public dynamic function onNodeDisconnect( node : Node ) {}
    public dynamic function onNodeSignal( node : Node, msg : Message ) {}

    public var ip(default,null) : String;
    public var port(default,null) : Int;

    //var net : js.node.net.Server;
    var net : js.npm.ws.Server;
    var nodes : Map<String,Node>;
    var meshes : Map<String,Mesh>;

    public function new( ip : String, port : Int ) {
        this.ip = ip;
        this.port = port;
        nodes = new Map();
        meshes = new Map();
    }

    public function start() : Promise<Nil> {
        return new Promise( function(resolve,reject){
            net = new js.npm.ws.Server({
                host: ip,
                port: port
            });
            net.on( 'connection', function(s,r) {
                //trace( 'Client connected' );
                //trace( r.connection.remoteAddress );
                //trace( e.socket );
                //handleSocketConnect(e);
                var node = new Node( createNodeId(), s, r.connection.remoteAddress );
                nodes.set( node.id, node );
                /*
                node.onConnect = function() {
                    onNodeConnect( node );
                }
                */
                node.onDisconnect = function() {
                    nodes.remove( node.id );
                    for( id in node.meshes ) {
                        var mesh = meshes.get( id );
                        if( mesh != null ) mesh.remove( node.id );
                    }
                    onNodeDisconnect( node );
                }
                node.onMessage = function(msg) {
                    onNodeSignal( node, msg );
                    handleSignal( node, msg );
                }

                onNodeConnect( node );
                /*
                Timer.delay( function(){
                    onNodeConnect( node );
                },100);
                */
            });
            /*
            net = Net.createServer( handleSocketConnect );
            net.on( 'error', function(e){
                reject( e );
            });
            net.listen( port, ip, function(){
                resolve( nil );
            });
            */
            resolve( nil );
        });
    }

    public function stop( ?callback : Void->Void ) {
        if( net != null ) {
            for( n in nodes ) n.disconnect();
            nodes = null;
            meshes = null;
            net.close( callback );
        }
    }

    public function addMesh( mesh : Mesh ) : Bool {
        if( meshes.exists( mesh.id ) )
            return false;
        meshes.set( mesh.id, mesh );
        return true;
    }

    public function createMesh( id : String ) : Mesh {
        if( meshes.exists( id ) )
            return null;
        var mesh = new Mesh( id );
        meshes.set( id, mesh );
        return mesh;
    }


    /*
    function handleSocketConnect( socket : Socket ) {

        trace(">>>>>>>>>>>>>");
    //    socket.setKeepAlive( true );
        trace(socket);

        var node = new Node( createNodeId(), socket );
        nodes.set( node.id, node );
        node.onConnect = function() {
            onNodeConnect( node );
        }
        node.onDisconnect = function() {
            nodes.remove( node.id );
            for( id in node.meshes ) {
                var mesh = meshes.get( id );
                if( mesh != null ) mesh.remove( node.id );
            }
            onNodeDisconnect( node );
        }
        node.onMessage = function(msg) {
            onNodeSignal( node, msg );
            handleSignal( node, msg );
        }
    }
    */

    function handleSignal( node : Node, msg : Message ) {

        //trace("handleSignal "+msg.type );

        switch msg.type {

        case 'init':
            //TODO
            if( msg.data != null ) {
                trace(msg.data);
            }

        case 'join':
            var data : { mesh: String } = msg.data;
            if( !meshes.exists( data.mesh ) ) {
                node.sendError( 'mesh does not exist', function(e){
                    trace(e);
                } );
                return;
            }
            var mesh = meshes.get( data.mesh );
            //mesh.handleNodeMessage( node, msg );
            if( mesh.add( node ) ) {
                node.sendMessage(
                    {
                        type: 'join',
                        data: {
                            mesh: mesh.id,
                            nodes: [for(n in mesh.nodes) if(n != node) n.id]
                        }
                    },
                    function(e){ trace(e); }
                );
            }

        case 'leave':
            var data : { mesh: String } = msg.data;
            if( !meshes.exists( data.mesh ) ) {
                node.sendError( 'mesh does not exist' );
                return;
            }
            var mesh = meshes.get( data.mesh );
            mesh.remove( node.id );

        case 'offer','answer','candidate':
            var data : { node: String } = msg.data;
            var receiver = nodes.get( data.node );
            if( receiver == null ) {
                trace( 'node does not exist' );
                node.sendError( 'node does not exist' );
                return;
            }
            data.node = node.id;
            receiver.sendMessage( msg );

        default:
            console.warn( 'Unknown message type: '+msg.type );
            node.sendError( 'unknown message type' );
        }
    }

    function createNodeId( length = 16 ) : String {
        var id : String;
        while( nodes.exists( id = createRandomString( length ) ) ) {}
        return id;
    }

    static function createRandomString( length : Int ) : String {
        #if nodejs
        return js.node.Crypto.randomBytes( length ).toString( 'hex' ).substr( 0, length );
        #else
        var charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
        var values = new js.html.Uint32Array( length );
        window.crypto.getRandomValues( values );
        var str = "";
        for( i in 0...length ) result += charset.charAt( values[i] % charset.length );
        return str;
        #end
    }
}

/*
class Server {

    public dynamic function onNodeConnect( node : Node ) {}
    public dynamic function onNodeDisconnect( node : Node ) {}
    public dynamic function onNodeSignal( node : Node, msg : Message ) {}

    public var ip(default,null) : String;
    public var port(default,null) : Int;

    var net : js.node.net.Server;
    var nodes : Map<String,Node>;
    var meshes : Map<String,Mesh>;

    public function new( ip : String, port : Int ) {
        this.ip = ip;
        this.port = port;
        nodes = new Map();
        meshes = new Map();
    }

    public function start() : Promise<Nil> {
        return new Promise( function(resolve,reject){
            net = Net.createServer( handleSocketConnect );
            net.on( 'error', function(e){
                reject( e );
            });
            net.listen( port, ip, function(){
                resolve( nil );
            });
        });
    }

    public function stop( ?callback : Void->Void ) {
        if( net != null ) {
            for( node in nodes ) node.disconnect();
            nodes = null;
            meshes = null;
            net.close( callback );
        }
    }

    public function addMesh( mesh : Mesh ) : Bool {
        if( meshes.exists( mesh.id ) )
            return false;
        meshes.set( mesh.id, mesh );
        return true;
    }

    public function createMesh( id : String ) : Mesh {
        if( meshes.exists( id ) )
            return null;
        var mesh = new Mesh( id );
        meshes.set( id, mesh );
        return mesh;
    }

    function handleSocketConnect( socket : Socket ) {

        socket.setKeepAlive( true );

        var node = new Node( createNodeId(), socket );
        nodes.set( node.id, node );
        node.onConnect = function() {
            onNodeConnect( node );
        }
        node.onDisconnect = function() {
            nodes.remove( node.id );
            for( id in node.meshes ) {
                var mesh = meshes.get( id );
                if( mesh != null ) mesh.remove( node.id );
            }
            onNodeDisconnect( node );
        }
        node.onMessage = function(msg) {
            onNodeSignal( node, msg );
            handleSignal( node, msg );
        }
    }

    function handleSignal( node : Node, msg : Message ) {

        //trace("handleSignal "+msg );

        switch msg.type {

        case 'init':
            //TODO
            if( msg.data != null ) {
                trace(msg.data);
            }

        case 'join':
            var data : { mesh: String } = msg.data;
            if( !meshes.exists( data.mesh ) ) {
                node.sendError( 'mesh does not exist' );
                return;
            }
            var mesh = meshes.get( data.mesh );
            //mesh.handleNodeMessage( node, msg );
            if( mesh.add( node ) ) {
                node.sendMessage( {
                    type: 'join',
                    data: {
                        mesh: mesh.id,
                        nodes: [for(n in mesh.nodes) if(n != node) n.id]
                    }
                });
            }

        case 'leave':
            var data : { mesh: String } = msg.data;
            if( !meshes.exists( data.mesh ) ) {
                node.sendError( 'mesh does not exist' );
                return;
            }
            var mesh = meshes.get( data.mesh );
            mesh.remove( node.id );

        case 'offer','answer','candidate':
            var data : { node: String } = msg.data;
            var receiver = nodes.get( data.node );
            if( receiver == null ) {
                node.sendError( 'node does not exist' );
                return;
            }
            data.node = node.id;
            receiver.sendMessage( msg );

        default:
            console.warn( 'Unknown message type: '+msg.type );
            node.sendError( 'unknown message type' );
        }
    }

    function createNodeId( length = 16 ) : String {
        var id : String;
        while( nodes.exists( id = createRandomString( length ) ) ) {}
        return id;
    }

    static function createRandomString( length : Int ) : String {
        #if nodejs
        return js.node.Crypto.randomBytes( length ).toString( 'hex' ).substr( 0, length );
        #else
        var charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
        var values = new js.html.Uint32Array( length );
        window.crypto.getRandomValues( values );
        var str = "";
        for( i in 0...length ) result += charset.charAt( values[i] % charset.length );
        return str;
        #end
    }
}
*/


#end
