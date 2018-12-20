package owl.client;

#if owl_client

import js.Promise;
import js.html.rtc.SessionDescription;
import js.html.rtc.IceCandidate;

class Mesh {

	public dynamic function onJoin() {}
	public dynamic function onLeave() {}

	public dynamic function onNodeConnect( n : Node ) {}
	public dynamic function onNodeDisconnect( n : Node ) {}
	public dynamic function onNodeData( n : Node, d : Dynamic ) {}

	public var id(default,null) : String;
	public var numNodes(default,null) = 0;

	var server : Server;
	var nodes = new Map<String,Node>();

	@:allow(owl.client.Server)
	function new( server : Server, id : String ) {
		this.server = server;
		this.id = id;
	}

	/*
	public function join() {
		server.signal( Signal.Type.join, { mesh : id } );
	}
	*/

	public function leave() {
		server.signal( Signal.Type.leave, { mesh : id } );
	}

	public function broadcast( str : String ) {
		for( n in nodes ) {
			n.send( str );
		}
	}

	@:allow(owl.client.Server)
	function handleSignal( sig : Signal ) {
		switch sig.type {
		case join:
			if( sig.data.nodes.length > 0 ) {
				var ids : Array<String> = sig.data.nodes;
				for( id in ids ) {
					var n = addNode( createNode( id ) );
					n.connectTo().then( function(sdp){
						server.signal( offer, { mesh : this.id, node: n.id, sdp: sdp } );
					});
				}
			}
			onJoin();
		case leave:
			onLeave();
		case enter:
			var n = addNode( createNode( sig.data.node ) );
		case offer:
			var n = nodes.get( sig.data.node );
			n.connectFrom( new SessionDescription( sig.data.sdp ) ).then( function(sdp){
				server.signal( answer, { mesh : id, node: n.id, sdp: sdp } );
			});
		case answer:
			var n = nodes.get( sig.data.node );
			n.setRemoteDescription( new SessionDescription( sig.data.sdp ) ).then( function(_){
				//trace('oi');
				//node.send("fucvk");
			});
		case candidate:
			var n = nodes.get( sig.data.node );
			n.addIceCandidate( new IceCandidate( sig.data.candidate ) ).then( function(_){
				//trace("OKOPKPKL");
			});
		default:
			trace('unhandled signal '+sig);
		}
	}

	function addNode( n : Node ) : Node {
		nodes.set( n.id, n );
		numNodes++;
		n.onCandidate = function(c){
			server.signal( candidate, { mesh : this.id, node: n.id, candidate: c } );
		}
		n.onConnect = function(){
			onNodeConnect( n );
		}
		n.onData = function(d){
			onNodeData( n, d );
		}
		n.onDisconnect = function(){
			//TODO
			trace("onDisconnect");
			nodes.remove( n.id );
			numNodes--;
			onNodeDisconnect( n );
		}
		return n;
	}

	function createNode( id : String ) : Node {
		return new Node( id );
	}

	//function signal( type : Signal.Type, ?data : Dynamic ) : Node {

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
