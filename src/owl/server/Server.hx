package owl.server;

#if owl_server

import js.Promise;
import js.node.Http;
import js.node.Url;
import js.npm.ws.Server;
import js.npm.ws.WebSocket as Socket;
import om.Json;
import om.StringTools;

class Server {

	public var host(default,null) : String;
    public var port(default,null) : Int;
    public var accessControl = ['Allow-Origin'=>'*'];

	var net : js.node.http.Server;
	var ws : js.npm.ws.Server;
	var nodes = new Map<String,Node>();
	var meshes = new Map<String,Mesh>();

	public function new( host : String, port : Int ) {
        this.host = host;
        this.port = port;
    }

	public function start() : Promise<Server> {
		return new Promise( (resolve,reject) -> {
			net = Http.createServer( handleRequest );
			ws = new js.npm.ws.Server( { server : net } );
			ws.on( Connection, handleConnection );
			net.listen( port, host, () -> resolve( this ) );
		});
	}

	public function stop() : Promise<Server> {
		return new Promise( (resolve,reject) ->
			if( net == null ) reject( 'not connected' )
			else net.close( () -> resolve( this ) )
		);
	}

	public function addMesh( mesh : Mesh ) : Bool {
		if( meshes.exists( mesh.id ) )
			return false;
		meshes.set( mesh.id, mesh );
		return true;
	}

	function handleConnection(s,r) {
		//trace(s,r);
		trace( "client connected "+(Lambda.count(nodes)+1) );
		var node = createNode( s, r.connection.remoteAddress );
		nodes.set( node.id, node );
		node.signal( connect, { id : node.id } );
		node.onSignal = function(sig) {
			trace("SIGNAL "+sig.type);
			switch sig.type {
			case join:
				if( meshes.exists( sig.data.mesh ) ) {
					trace("MESH EXISTS");
					var mesh = meshes.get( sig.data.mesh );
					//trace(mesh.numNodes,mesh.maxNodes);
					if( mesh.maxNodes != null && mesh.numNodes >= mesh.maxNodes ) {
						node.signal( error, { info : 'max nodes' } );
					} else {
						node.signal( join, { mesh : mesh.id, nodes : [for(n in mesh) n.id] } );
						for( n in mesh ) {
							n.signal( join, { mesh : mesh.id, node : node.id } );
						}
						mesh.add( node );
					}
				} else {
					trace("NEW MESH "+sig.data.mesh);
					//var mesh = createMesh( signal.data.mesh );
					var mesh = createMesh( sig.data.mesh );
					meshes.set( mesh.id, mesh );
					mesh.add( node );
					node.signal( join, { mesh : mesh.id, nodes : [] } );
				}
			case leave:
				trace(">>>>>>>>LEAVE "+sig);
				var m = meshes.get( sig.data.mesh );
				if( m.remove( node ) ) {
					//TODO really report ?
					//node.signal( leave, { mesh : m.id } );
					//for( n in m ) n.signal( leave, { mesh : m.id, node : n.id } );
					if( m.numNodes == 0 && !m.permanent ) {
						trace("ALL NODES LEFT THE MESH, destroy ?");
						meshes.remove( m.id );
					}
				} else {
					//TODO
					node.signal( error, { info : 'not joined' } );
				}
			case offer,answer,candidate:
				var recv = nodes.get( sig.data.node );
				if( recv == null ) {
				   trace( 'node ['+sig.data.node+'] does not exist' );
				   trace('HAVE '+Lambda.count(nodes)+' nodes');
			   } else {
				   sig.data.node = node.id;
				   recv.sendSignal( sig );
			   }
			default:
				trace('unknown signal '+sig);
				node.signal( error, { info : 'unknown signal' } );
			}
		}
		node.onDisconnect = function(){
			for( m in meshes ) m.remove( node );
			nodes.remove( node.id );
			trace("client disconnected "+(Lambda.count(nodes)) );
		}
	}

	function handleRequest( req : js.node.http.IncomingMessage, res : js.node.http.ServerResponse ) {
		var url = Url.parse( req.url, true );
		var path = url.path.substr(1);
		var parts = path.split( '/' );
		var data : Dynamic = null;
		switch parts[0] {
		case 'lobby':
			data = [for(m in meshes) {
				id : m.id,
				nodes : [for(n in m) n.id],
				max : m.maxNodes
			} ];
		case 'admin':
			res.statusCode = 403;
			//TODO
			//node: kick, ban, ..
			//mesh: destroy, ..
			/*
			var cmd = parts[1];
			switch parts[1] {
			case 'status':
				//TODO
			default:
				res.statusCode = 404;
			}
			*/
		default:
			res.statusCode = 404;
		}
		for( k in accessControl.keys() )
			res.setHeader( 'Access-Control-$k', accessControl.get( k ) );
		if( data == null ) res.end() else {
			res.setHeader( 'Content-Type', 'text/json' );
			res.end( Json.stringify( data ) );
		}
	}

	function createMesh( id : String ) : Mesh {
		return new Mesh( id );
	}

	function createNode( sock : Socket, ip : String  ) : Node {
		return new Node( sock, createNodeId(), ip );
	}

	function createNodeId( len = 16 ) : String {
        var id : String;
        while( nodes.exists( id = StringTools.createRandomString( len ) ) ) {}
        return id;
    }

}

#end
