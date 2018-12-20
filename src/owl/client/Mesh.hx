package owl.client;

#if owl_client

import js.Promise;
import js.html.rtc.SessionDescription;
import js.html.rtc.IceCandidate;

class Mesh {

	public dynamic function onJoin() {}
	public dynamic function onConnect( n : Node ) {}
	public dynamic function onDisconnect( n : Node ) {}
	public dynamic function onData( n : Node, data : Dynamic ) {}

	public var id(default,null) : String;

	var server : Server;
	var nodes : Map<String,Node>;

	public function new( server : Server, id : String ) {
		this.server = server;
		this.id = id;
	}

	public function join() {
		nodes = [];
		//server.signal( { type : 'join', mesh : id } );
		server.signal( new Signal( Signal.SignalType.join, { mesh : id } ) );
	}

	public function send( str : String ) {
		for( n in nodes ) {
			n.send(str);
		}
	}

	public function handleSignal( signal : Signal ) {
		switch signal.type {
		case join:
			/*
			if( signal.data.nodes.length == 0 ) {
				onJoin();
			} else {
				var ids : Array<String> = signal.data.nodes;
				for( id in ids ) {
					var node = addNode( id );
					node.connectTo().then( function(sdp){
						server.signal( { type: 'offer', data: { mesh : this.id, node: node.id, sdp: sdp } } );
					});
				}
			}
			*/
			var ids : Array<String> = signal.data.nodes;
			for( id in ids ) {
				var node = addNode( id );
				node.connectTo().then( function(sdp){
					//server.signal( { type: 'offer', data: { mesh : this.id, node: node.id, sdp: sdp } } );
					server.signal( new Signal( offer,  { mesh : this.id, node: node.id, sdp: sdp } ) );
				});
			}
			onJoin();
		case enter:
			var node = addNode( signal.data.node );
		case offer:
			var node = nodes.get( signal.data.node );
			node.connectFrom( new SessionDescription( signal.data.sdp ) ).then( function(sdp){
				//server.signal( { type: 'answer', data: { mesh : id, node: node.id, sdp: sdp } } );
				server.signal( new Signal( answer, { mesh : id, node: node.id, sdp: sdp } ) );
			});
		case answer:
			var node = nodes.get( signal.data.node );
			node.setRemoteDescription( new SessionDescription( signal.data.sdp ) ).then( function(_){
				//trace('oi');
				//node.send("fucvk");
			});
		case candidate:
			var node = nodes.get( signal.data.node );
			node.addIceCandidate( new IceCandidate( signal.data.candidate ) ).then( function(_){
				//trace("OKOPKPKL");
			});
		default:
			trace('unhandled signal '+signal);
		}
	}

	function addNode( id : String ) : Node {
		var node = new Node( id );
		nodes.set( id, node );
		node.onCandidate = function(c){
			//server.signal( { type: 'candidate', data: { mesh : this.id, node: node.id, candidate: c } } );
			server.signal( new Signal( candidate, { mesh : this.id, node: node.id, candidate: c } ) );
		}
		node.onConnect = function(){
			onConnect( node );
		}
		node.onData = function(data){
			onData( node, data );
		}
		node.onDisconnect = function(){
			onDisconnect( node );
		}
		return node;
	}

	/*
	@:allow(owl.client.Server)
	function init( nodeList : Array<Dynamic> ) : Promise<Mesh> {
		trace("INIT "+nodeList.length);
		if( nodeList.length == 0 )
			return Promise.resolve( this );

		var proms = new Array<Promise<Dynamic>>();
		for( id in nodeList ) {
			var node = new Node( id );
			nodes.set( id, node );
			node.onConnect = function() {
				trace("NODEM CONNECZED");
			}
			node.onCandidate = function(c){
				//trace("XCXxxxxxxxxxxxxxxxxxxxxxxccccccccccccccccccc");
				server.signal( { type: 'candidate', data: { mesh : this.id, node: node.id, candidate: c } } );
			}
			proms.push( node.connectTo().then( function(sdp){
				//trace("XXXXXXXXXXXXXXXXXXX "+node.id);
				server.signal( { type: 'offer', data: { mesh : this.id, node: node.id, sdp: sdp } } );
			}) );
			/*
			node.connectTo().then( function(sdp){
				//trace("XXXXXXXXXXXXXXXXXXX "+node.id);
				server.signal( { type: 'offer', data: { mesh : this.id, node: node.id, sdp: sdp } } );
			});
		}
		/*
		return Promise.all( proms ).then( function(a){
			trace(a);
			return this;
		});
		//return Promise.reject();
		return Promise.add([for(n in nodes)
			n.connectTo().then( function(sdp){
				//trace("XXXXXXXXXXXXXXXXXXX "+node.id);
				server.signal( { type: 'offer', data: { mesh : this.id, node: node.id, sdp: sdp } } );
			});
		return Promise.all( [for(n in nodes) n.connectTo()] ).then( function(e){
			trace(">>>>>>>>>>>>>>>>>>",e);
			server.signal( { type: 'offer', data: { node: node.id, sdp: sdp } } );
			return Promise.reject();
		});
	}
	*/

	/*
	@:allow(owl.client.Server)
	function init( nodeList : Array<Dynamic> ) : Promise<Mesh> {
		return Promise.reject();
	}

	public function get( id : String ) {
		return nodes.get( id );
	}

	public function add( node : Node ) {
		nodes.set( node.id, node );
	}

	@:allow(owl.client.Server)
	function handleSignal( signal : Dynamic ) {
		trace("handleSignal");
	}
	*/

}

#end
