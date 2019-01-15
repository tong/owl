package owl.server;

#if owl_server

import js.Promise;
import js.node.Http;
import js.node.Url;
import js.npm.ws.Server;
import js.npm.ws.WebSocket as Socket;
import om.Json;
import om.StringTools;
import Sys.print;
import Sys.println;

using Lambda;

class Server {

	public var host(default,null) : String;
    public var port(default,null) : Int;

    public var maxNodes(default,null) : Int;

	public var nodes(default,null) : Map<String,Node>;
	public var meshes(default,null) : Map<String,Mesh>;

	var net : js.node.http.Server;
	var ws : js.npm.ws.Server;

	public function new( host : String, port : Int, ?maxNodes : Int ) {
        this.host = host;
        this.port = port;
        this.maxNodes = maxNodes;
    }

	public function start() : Promise<Server> {
		return new Promise( (resolve,reject) -> {
			if( net != null ) reject( 'running' ) else {
				net = Http.createServer( handleRequest );
				net.listen( port, host, () -> {
					nodes = [];
					meshes = [];
					ws = new js.npm.ws.Server( { server : net } );
					ws.on( Connection, handleConnection );
					resolve( this );
				} );
			}
		});
	}

	public function stop() : Promise<Server> {
		return new Promise( (resolve,reject) ->
			if( net == null ) reject( 'not running' ) else {
				net.close( () -> resolve( this ) );
			}
		);
	}

	public function addMesh( mesh : Mesh ) : Bool {
		if( meshes.exists( mesh.id ) )
			return false;
		meshes.set( mesh.id, mesh );
		return true;
	}

	function handleConnection( s : Socket, r ) {
		//trace(s,r);
		var numNodes = Lambda.count( nodes );
		if( maxNodes != null && numNodes == maxNodes ) {
			trace( 'MAX SERVER NODES [$maxNodes]' );
			s.close( 1013, 'max_nodes' );
			return;
		}
		var node = createNode( s, createNodeId(), r.connection.remoteAddress );
		println( 'CONNECT $numNodes ${node.id} ${node.address}' );
		nodes.set( node.id, node );
		node.signal( connect, { id : node.id } );
		node.onSignal = function(sig) {
			println( "SIG "+sig.type );
			switch sig.type {
			case join:
				if( meshes.exists( sig.data.mesh ) ) {
					var mesh = meshes.get( sig.data.mesh );
					//trace("MESH EXISTS............."+mesh.numNodes,Lambda.count(mesh.nodes));
					var others = mesh.nodes.copy();
					var data = try mesh.addNode( node, sig.data.creds ) catch(e:Dynamic) {
						node.signal( error, { info : e } );
						return;
					}
					var creds = mesh.credentials.get( node.id );
					node.signal( enter, {
						mesh : mesh.id,
						creds : creds,
						data : data,
						nodes : others.map( n -> return { id : n.id, creds : mesh.credentials.get( n.id ) } )
					} );
				}
				/*
				if( meshes.exists( sig.data.mesh ) ) {
					//trace(sig.data);
					var mesh = meshes.get( sig.data.mesh );
					trace("MESH EXISTS............."+mesh.numNodes,Lambda.count(mesh.nodes));
					var others = mesh.nodes.copy();

					var data = try mesh.addNode( node, sig.data.creds ) catch(e:Dynamic) {
						node.signal( error, { info : e } );
						return;
					}
					var creds = mesh.credentials.get( node.id );
					for( n in others ) {
						n.signal( join, {
							mesh : mesh.id,
							node : { id : node.id, creds : creds }
						} );
					}
					node.signal( join, {
						mesh : mesh.id,
						creds : creds,
						data : data,
						nodes : others.map( n -> return { id : n.id, creds : mesh.credentials.get( n.id ) } )
					} );
				} else {
					trace("NEW MESH "+sig.data.mesh);
					/*
					var mesh = try createMesh( sig.data.mesh ) catch(e:Dynamic) {
						node.signal( error, { info : e } );
						return;
					}
					meshes.set( mesh.id, mesh );
					mesh.addNode( node, sig.data.info );
					node.signal( join, { mesh : mesh.id, info : mesh.infos.get( node.id ), nodes : [] } );
					* /
				}
				*/
			case leave:
				//trace("LEAVE ");
				var mesh = meshes.get( sig.data.mesh );
				if( mesh.removeNode( node ) ) {
					//TODO really report ?
					//node.signal( leave, { mesh : m.id } );
					//for( n in m ) n.signal( leave, { mesh : m.id, node : n.id } );
					if( sig.data.status != null ) {
						//TODO store status here?
					}
					if( mesh.numNodes == 0 && !mesh.permanent ) {
						trace("ALL NODES LEFT THE MESH, destroy ?");
						meshes.remove( mesh.id );
					}
				} else {
					//TODO
					node.signal( error, { info : 'not joined' } );
				}
			case offer,answer,candidate:
				//trace(":::"+sig);
				var recv = nodes.get( sig.data.node );
				if( recv == null ) {
				   trace( 'node ['+sig.data.node+'] does not exist' );
				   trace('HAVE '+Lambda.count(nodes)+' nodes');
			   } else {
				   sig.data.node = node.id;
				   recv.sendSignal( sig );
			   }
			case custom:
				//trace('custom signal '+sig.data);
				handleCustomSignal( sig.data );
			default:
				trace('unknown signal '+sig);
				node.signal( error, { info : 'unknown signal' } );
			}
		}
		node.onDisconnect = function(){
			for( m in meshes ) m.removeNode( node );
			nodes.remove( node.id );
			println( 'DISCONNECT '+Lambda.count(nodes)+' ${node.id} ${node.address}' );
		}
	}

	function createMesh( id : String ) : Mesh {
		return new Mesh( id );
	}

	function createNode( sock : Socket, id : String, ip : String  ) : Node {
		return new Node( sock, id, ip );
	}

	function createNodeId( len = 16 ) : String {
        var id : String;
        while( nodes.exists( id = StringTools.createRandomString( len ) ) ) {}
        return id;
    }

	function handleCustomSignal( data : Dynamic ) {
		// override
	}

	function handleRequest( req : js.node.http.IncomingMessage, res : js.node.http.ServerResponse ) {
		/*
		var url = Url.parse( req.url, true );
		//trace(url);
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
			//node: kick, ban, ..
			//mesh: destroy, ..
			/*
			var cmd = parts[1];
			switch parts[1] {
			case 'status':
			default:
				res.statusCode = 404;
			}
			* /
		default:
			res.statusCode = 404;
		}
		for( k in accessControl.keys() )
			res.setHeader( 'Access-Control-$k', accessControl.get( k ) );
		if( data == null ) res.end() else {
			res.setHeader( 'Content-Type', 'text/json' );
			res.end( Json.stringify( data ) );
		}
		*/
	}

}

#end
