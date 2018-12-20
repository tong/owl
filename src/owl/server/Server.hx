package owl.server;

#if owl_server

import js.Promise;
import js.node.Http;
import js.node.Url;
import js.npm.ws.Server;
import js.npm.ws.WebSocket as Socket;
import om.Json;
import om.Nil;
import om.StringTools;

class Server {

	public var host(default,null) : String;
    public var port(default,null) : Int;

	var net : js.node.http.Server;
	var ws : js.npm.ws.Server;
	var nodes : Map<String,Node>;
	var meshes : Map<String,Mesh>;

	public function new( host : String, port : Int ) {
        this.host = host;
        this.port = port;
		nodes = [];
		meshes = [];
    }

	public function start() : Promise<Nil> {
		return new Promise( function(resolve,reject){
			net = Http.createServer( function(req,res){
				var url = Url.parse( req.url, true );
				var path = url.path.substr(1);
				var parts = path.split( '/' );
				switch parts[0] {
				case 'lobby':
					res.writeHead( 200, { 'Content-Type': 'text/json', 'Access-Control-Allow-Origin': '*' } );
					var list = [for(m in meshes) { id : m.id, nodes : [for(n in m) n.id], max : m.maxNodes } ];
					//trace(list);
					res.end( Json.stringify( list ) );
				//case 'admin':
					//node: kick, ban, ..
					//mesh: destroy, ..
				/*
				case 'join':
					//var id = parts[1];
					trace(">>>>>>>>>>>>>>join>>>>>>>" );
					var str = '';
					req.on( 'data', function(c) str += c );
					req.on( 'end', function() {
						var data = Json.parse( str );
					});
				*/
				default:
					//TODO error
				}
			});
			ws = new js.npm.ws.Server( { server : net } );
			ws.on( Connection, function(s,r) {
				//trace(s,r);
				trace( "node connected "+(Lambda.count(nodes)+1) );
				var node = createNode( s, createNodeId(), r.connection.remoteAddress );
				nodes.set( node.id, node );
				node.onDisconnect = function(){
					for( m in meshes ) m.remove( node );
					nodes.remove( node.id );
					trace("client disconnected "+(Lambda.count(nodes)) );
				}
				node.onSignal = function(signal){
					trace("SIGNAL "+signal.type);
					switch signal.type {
					case join:
						if( meshes.exists( signal.data.mesh ) ) {
							trace("MESH EXISTS");
							var mesh = meshes.get( signal.data.mesh );
							trace(mesh.numNodes,mesh.maxNodes);
							if( mesh.maxNodes != null && mesh.numNodes >= mesh.maxNodes ) {
								node.signal( error, { info : 'max nodes' } );
							} else {
								var nodes = [for(n in mesh) n.id];
								for( n in mesh ) {
									n.signal( enter, { mesh : mesh.id, node : node.id } );
								}
								mesh.add( node );
								node.signal( join, { mesh : mesh.id, nodes : nodes } );
							}
						} else {
							trace("NEW MESH "+signal.data.mesh);
							//var mesh = new Mesh( signal.data.mesh );
							//var mesh = createMesh( signal.data.mesh );
							var mesh = createMesh( signal.data.mesh );
							meshes.set( mesh.id, mesh );
							mesh.add( node );
							node.signal( join, { mesh : mesh.id, nodes : [] } );
						}
					case leave:
						//trace(">>>>>>>>LEAVE "+signal);
						var m = meshes.get( signal.data.mesh );
						if( m.remove( node ) ) {
							node.signal( leave, { mesh : m.id } );
						} else {
							//TODO
							node.signal( error, { info : 'not joined' } );
						}

					case offer,answer,candidate:
						var receiver = nodes.get( signal.data.node );
						if( receiver == null ) {
						   trace( 'node ['+signal.data.node+'] does not exist' );
						   trace('HAVE '+Lambda.count(nodes)+' nodes');
					   } else {
						   signal.data.node = node.id;
						   receiver.sendSignal( signal );
					   }
					default:
						trace('unhandled signal '+signal);
					}
				}
			});
			net.listen( port, host, function(){
				resolve( nil );
			});
		});
	}

	public function addMesh( mesh : Mesh ) {
		if( meshes.exists( mesh.id ) )
			return false;
		meshes.set( mesh.id, mesh );
		return true;
	}

	function createMesh( id : String ) : Mesh {
		var m = new Mesh( id );
		//meshes.set( m.id, m );
		return m;
	}

	function createNode( sock : Socket, id : String, ip : String  ) : Node {
		return new Node( sock, id, ip );
	}

	function createNodeId( len = 16 ) : String {
        var id : String;
        while( nodes.exists( id = StringTools.createRandomString( len ) ) ) {}
        return id;
    }
}

#end
