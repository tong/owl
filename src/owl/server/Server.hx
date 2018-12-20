package owl.server;

#if owl_server

import js.node.Http;
import js.node.Url;
import js.npm.ws.Server;
import om.Json;
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
    }

	public function start( callback : Void->Void ) {
		nodes = [];
		meshes = [];
		net = Http.createServer( function(req,res){
			var url = Url.parse( req.url, true );
			var path = url.path.substr(1);
			var parts = path.split( '/' );
			//var data : Dynamic;
			switch parts[0] {
			case 'lobby':
				res.writeHead( 200, {
					'Content-Type': 'text/json',
					'Access-Control-Allow-Origin': '*'
				} );
				var list = [for(m in meshes) { id : m.id } ];
				res.end( Json.stringify( list ) );
			/*
			case 'join':
				//var id = parts[1];
				trace(">>>>>>>>>>>>>>join>>>>>>>" );
				var str = '';
				req.on( 'data', function(c) str += c );
				req.on( 'end', function() {
					var data = Json.parse( str );
					var node = nodes.get( data.node );
					if( meshes.exists( data.mesh ) ) {
						trace("MESH EXISTS");
						var mesh = meshes.get( data.mesh );
						var nodes = [for(n in mesh) n.id ];
						mesh.add( node );
						res.writeHead( 200, {
							'Content-Type': 'text/json',
							'Access-Control-Allow-Origin': '*'
						} );
						res.end( Json.stringify( nodes ) );
					} else {
						trace("NEW MESH");
						var mesh = new Mesh( data.mesh );
						meshes.set( mesh.id, mesh );
						mesh.add( node );
						res.writeHead( 200, {
							'Content-Type': 'text/json',
							'Access-Control-Allow-Origin': '*'
						} );
						res.end( Json.stringify( [] ) );
					}
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
			var node = new Node( s, createNodeId(), r.connection.remoteAddress );
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
						var nodes = [for(n in mesh) n.id];
						for( n in mesh ) {
							//n.send( { type : 'enter', data: { mesh : mesh.id, node : node.id } } );
							n.send( new Signal( enter, { mesh : mesh.id, node : node.id } ) );
						}
						mesh.add( node );
						//node.send( { type : 'join', data: { mesh : mesh.id, nodes : nodes } } );
						node.send( new Signal( join, { mesh : mesh.id, nodes : nodes } ) );
					} else {
						trace("NEW MESH");
						/*
						var mesh = new Mesh( signal.mesh );
						meshes.set( mesh.id, mesh );
						mesh.add( node );
						node.send( { type : 'join', mesh : mesh.id } );
						*/
					}
				case offer,answer,candidate:
					var receiver = nodes.get( signal.data.node );
					if( receiver == null ) {
					   trace( 'node ['+signal.data.node+'] does not exist' );
					   trace('HAVE '+Lambda.count(nodes)+' nodes');
				   } else {
					   signal.data.node = node.id;
					   receiver.send( signal );
				   }
				default:
					trace('unhandled signal '+signal);
				}
			}
			/*
			node.onDisconnect = function(e){
				nodes.remove( node.id );
				trace("client disconnected "+(Lambda.count(nodes)) );
				//TODO remove node from joined meshes
			}
			node.onSignal = function(signal){
				trace("SIGNAL "+signal.type);
				switch signal.type {
				case 'join':
					trace("TODO join", signal.id );
					if( meshes.exists( signal.id ) ) {
						trace("MESH EXISTS");
						//var mesh = meshes.get( id );
					} else {
						trace("NEW MESH");
						var mesh = new Mesh( signal.id  );
						meshes.set( mesh.id, mesh );
						mesh.add( node );
						node.send( signal );

					}
				case 'offer','answer','candidate':
					//trace(signal.type, signal.data.node );
					//trace("candidate for "+signal.data.node+' // from: '+node.id );
					var receiver = nodes.get( signal.data.node );
		            if( receiver == null ) {
		                trace( 'node ['+signal.data.node+'] does not exist' );
						trace('HAVE '+Lambda.count(nodes)+' nodes');
					} else {
						signal.data.node = node.id;
						receiver.send( signal );
					}

				default:
					trace("unhandled signal "+signal);
				}
			}
			*/
		});
		net.listen( port, host, callback  );
	}

	public function addMesh( mesh : Mesh ) {
		meshes.set( mesh.id, mesh );
	}

	function createNodeId( len = 16 ) : String {
        var id : String;
        while( nodes.exists( id = StringTools.createRandomString( len ) ) ) {}
        return id;
    }
}

#end
