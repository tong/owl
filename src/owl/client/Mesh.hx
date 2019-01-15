package owl.client;

#if owl_client

import haxe.Timer;
import js.Promise;
import js.Browser.console;
import js.html.rtc.DataChannelInit;
import js.html.rtc.SessionDescription;
import js.html.rtc.IceCandidate;
import owl.Signal.Type;

private enum Status {
	joining;
	joined;
	//leaving;
	timeout;
}

class Mesh {

	//public dynamic function onJoin() {}
	//public dynamic function onLeave() {}

	public dynamic function onNodeJoin<T:Node>( n : T ) {}
	public dynamic function onNodeLeave<T:Node>( n : T ) {}
	public dynamic function onNodeData<T:Node>( n : T, d : Dynamic ) {}

	public final server : Server;
	public final id : String;

	public var status(default,null) : Status;
	public var numNodes(default,null) = 0;

	var nodes : Map<String,Node>;
	var joinHandler : Void->Void;
	var joinData : Dynamic;
	var joinNodesConnected : Int;
	var joinTimeout : Timer;

	public function new( server : Server, id : String ) {
		this.server = server;
		this.id = id;
	}

	public inline function iterator() : Iterator<Node>
		return nodes.iterator();

	public inline function first() : Node
		return nodes.iterator().next();

	@:allow(owl.client.Server)
	function join( creds : Dynamic, timeout = 5000 ) : Promise<Dynamic> {
		return new Promise( function(resolve,reject) {
			nodes = [];
			numNodes = 0;
			status = Status.joining;
			joinHandler = function(){
				joinTimeout.stop();
				status = Status.joined;
				resolve( joinData );
			}
			server.signal( Type.join, { mesh : id, creds : creds } );
			joinTimeout = new Timer( timeout );
			joinTimeout.run = function(){
				joinTimeout.stop();
				status = Status.timeout;
				//for( n in nodes ) n.disconnect();
				//nodes = [];
				reject( 'timeout' );
			}
		});
	}

	/*
	public function leave() {
		//joined = false;
		server.signal( Type.leave, { mesh : id } );
		for( n in nodes ) n.disconnect();
		nodes = [];
		onLeave();
	}
	*/

	@:overload( function( data : js.html.Blob ) : Void {} )
	@:overload( function( data : js.html.ArrayBuffer ) : Void {} )
	@:overload( function( data : js.html.ArrayBufferView ) : Void {} )
	public function send( data : String ) {
		for( n in nodes ) n.send( data );
	}

	@:allow(owl.client.Server)
	function handleSignal( sig : Signal ) {
		//trace(">>>>>>>>>>>>>>>>>>>>>>>>>> "+sig.type);
		switch sig.type {
		case enter:
			//joinData = sig.data.creds;
			joinData = { creds : sig.data.creds, data : sig.data.data };
			if( sig.data.nodes.length == 0 ) {
				joinHandler();
			} else {
				joinNodesConnected = 0;
				var others : Array<{id:String,creds:Dynamic}> = sig.data.nodes;
				numNodes = others.length;
				for( n in others ) {
					///trace(n);
					addNode( createNode( n.id, n.creds ) );
				}
				for( n in nodes ) {
					n.connectTo( createDataChannelConfig() ).then( function(sdp){
						server.signal( offer, { mesh : this.id, node: n.id, creds : sig.data.creds, sdp: sdp } );
					});
				}
			}
		case offer:
			if( nodes.exists( sig.data.node ) ) throw 'NODE ALREADY EXISTS';
			var n = addNode( createNode( sig.data.node, sig.data.creds ) );
			n.connectFrom( new SessionDescription( sig.data.sdp ) ).then( function(sdp){
 				server.signal( answer, { mesh : id, node: n.id, sdp: sdp } );
 			});
		case answer:
			if( !nodes.exists( sig.data.node ) ) throw 'NODE DOES NOT EXIST';
			var n = nodes.get( sig.data.node );
			n.setRemoteDescription( new SessionDescription( sig.data.sdp ) ).then( function(_){
				//trace('oi');
				//n.send("YES!!!!!!!!!!!!!!!!!!!!");
			});
		case candidate:
			if( !nodes.exists( sig.data.node ) ) throw 'NODE DOES NOT EXIST';
			var n = nodes.get( sig.data.node );
			n.addIceCandidate( new IceCandidate( sig.data.candidate ) ).then( function(_){
				//trace("----------------------------");
				//trace("addIceCandidate");
			});
		default:
			trace("TODO>>>>>>>>>>"+sig);

		}
		/*
		switch sig.type {
		case join:
			switch state {
			case joining:
				joinData = { creds : sig.data.creds, data : sig.data.data };
				trace(sig.data.nodes.length );
				if( sig.data.nodes.length == 0 ) {
					joinHandler();
				} else {
					//trace(sig.data);
					//joinInfo = sig.data.info;
					var _nodes : Array<Dynamic> = sig.data.nodes;
					numNodes = _nodes.length;
					trace('JOINING $id [${_nodes.length}]');
					for( n in _nodes ) {
						trace(n);
						addNode( createNode( n.id, n.creds ) ).connectTo( createDataChannelConfig() ).then( function(sdp){
							server.signal( offer, { mesh : this.id, node: n.id, sdp: sdp } );
						});
					}
				}

				/*
				var _nodes : Array<Dynamic> = sig.data.nodes;
				numNodes = _nodes.length;
				for( n in _nodes ) {
					trace(n);
					addNode( createNode( n.id, n.creds ) ).connectTo( createDataChannelConfig() ).then( function(sdp){
						server.signal( offer, { mesh : this.id, node: n.id, sdp: sdp } );
					});
				}
				joinHandler();
				* /

			case joined:
				//trace("I AM JOINED "+sig.data );
				trace("Another "+sig.data );
				//Another joined
				var n = addNode( createNode( sig.data.node.id, sig.data.node.creds ) );
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
		* /
		case offer:
			trace(sig.data.sdp);
			var n = nodes.get( sig.data.node );
			n.connectFrom( new SessionDescription( sig.data.sdp ) ).then( function(sdp){
				server.signal( answer, { mesh : id, node: n.id, sdp: sdp } );
			});
		case answer:
			trace(sig.data.sdp);
			var n = nodes.get( sig.data.node );
			n.setRemoteDescription( new SessionDescription( sig.data.sdp ) ).then( function(_){
				trace('oi');
			});
		case candidate:
			trace(sig.data.candidate);
			var n = nodes.get( sig.data.node );
			n.addIceCandidate( new IceCandidate( sig.data.candidate ) ).then( function(_){
				//trace("addIceCandidate");
			});
		default:
			trace('unhandled signal '+sig);
		}
		*/
	}

	function addNode( n : Node ) : Node {
	//	trace("addNode "+n.id );
		nodes.set( n.id, n );
		n.onCandidate = function(c){
			server.signal( candidate, { mesh : this.id, node: n.id, candidate: c } );
		}
		n.onConnect = function(){
			//trace("onConnect "+status);
			switch status {
			case joining:
				if( ++joinNodesConnected == numNodes ) joinHandler();
			case joined:
				numNodes++;
				onNodeJoin( n );
			case timeout:
			}
		}
		n.onData = function(d){
			//trace("onData ");
			onNodeData( n, d );
		}
		n.onDisconnect = function(){
			//TODO
			//trace("onDisconnect");
			nodes.remove( n.id );
			numNodes--;
			onNodeLeave( n );
		}
		return n;
	}

	function createNode( id : String, creds : Dynamic ) : Node {
		return new Node( id, creds );
	}

	function createDataChannelConfig() : DataChannelInit {
		return null;
    }

}

#end
