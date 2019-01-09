package owl.client;

#if owl_client

import js.Promise;
import js.html.rtc.DataChannelInit;
import js.html.rtc.SessionDescription;
import js.html.rtc.IceCandidate;
import owl.Signal.Type;

private enum State {
	joining;
	joined;
	//leaving;
}

class Mesh {

	//public dynamic function onJoin() {}
	public dynamic function onLeave() {}

	public dynamic function onNodeJoin<T:Node>( n : T ) {}
	public dynamic function onNodeLeave<T:Node>( n : T ) {}
	public dynamic function onNodeData<T:Node>( n : T, d : Dynamic ) {}

	public final server : Server;
	public final id : String;

	public var state(default,null) : State;
	public var numNodes(default,null) = 0;

	var nodes = new Map<String,Node>();
	var numNodesJoinRemaining : Int;
	var joinHandler : Void->Void;
	var joinInfo : Dynamic;

	//@:allow(owl.client.Server)
	public function new( server : Server, id : String ) {
		this.server = server;
		this.id = id;
	}

	public inline function iterator() : Iterator<Node>
		return nodes.iterator();

	@:allow(owl.client.Server)
	//function join<T:Mesh>( ?info : Dynamic ) : Promise<T> {
	function join<I>( ?info : I ) : Promise<I> {
		return new Promise( function(resolve,reject) {
			state = joining;
			joinInfo = info;
			numNodesJoinRemaining = 0;
			joinHandler = function(){
				//trace("JOINHANDLER");
				state = joined;
				//resolve( cast this );
				resolve( joinInfo );
				//trace("REPORT NODEs..........."+Lambda.count(nodes));
				//for( n in nodes ) onNodeJoin( n );
				//return resolve( this );
			}
			server.signal( Type.join, { mesh : id, info : info } );
		});
	}

	public function leave() {
		//joined = false;
		server.signal( Type.leave, { mesh : id } );
		for( n in nodes ) n.disconnect();
		nodes = [];
		onLeave();
	}

	@:overload( function( data : js.html.Blob ) : Void {} )
	@:overload( function( data : js.html.ArrayBuffer ) : Void {} )
	@:overload( function( data : js.html.ArrayBufferView ) : Void {} )
	public function send( data : String ) {
		for( n in nodes ) n.send( data );
	}

	public function first() : Node {
		return nodes.iterator().next();
	}

	@:allow(owl.client.Server)
	function handleSignal( sig : Signal ) {
		//trace("handleSignal "+sig);
		switch sig.type {
		case join:
			switch state {
			case joining:
				joinInfo = sig.data.info;
				if( sig.data.nodes.length == 0 ) {
					joinHandler();
				} else {
					//trace(sig.data);
					//joinInfo = sig.data.info;
					var _nodes : Array<Dynamic> = sig.data.nodes;
					numNodes = _nodes.length;
					for( n in _nodes ) {
						addNode( createNode( n.id, n.info ) ).connectTo( createDataChannelConfig() ).then( function(sdp){
							server.signal( offer, { mesh : this.id, node: n.id, sdp: sdp } );
						});
					}
				}
			case joined:
				//trace("I AM JOINED "+sig.data );
				//Another joined
				var n = addNode( createNode( sig.data.node.id, sig.data.node.info ) );
			}
	/*
		case leave:
			joined = false;
			onLeave();
	*/
		/*
		case enterr:
			trace("EENTER");
			var n = addNode( createNode( sig.data.node ) );
		*/
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
		//numNodes++;
		n.onCandidate = function(c){
			server.signal( candidate, { mesh : this.id, node: n.id, candidate: c } );
		}
		n.onConnect = function(){
			switch state {
			case joining:
				if( ++numNodesJoinRemaining == numNodes ) joinHandler();
			default:
				numNodes++;
				onNodeJoin( n );
			}
		}
		n.onData = function(d){
			onNodeData( n, d );
		}
		n.onDisconnect = function(){
			//TODO
			trace("onDisconnect");
			nodes.remove( n.id );
			numNodes--;
			onNodeLeave( n );
		}
		return n;
	}

	function createNode( id : String, ?info : Dynamic ) : Node {
		return new Node( id, info );
	}

	/*
	function createNode( id : String, ?configuration : js.html.rtc.Configuration, ?info : Dynamic ) : Node {
		return new Node( id, configuration, info );
	}
	*/

	function createDataChannelConfig() : DataChannelInit {
		return null;
		/*
        return {
            ordered: true,
        //    outOfOrderAllowed: false,
            //maxRetransmitTime: 400,
            //maxPacketLifeTime: 1000
        };
		*/
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
