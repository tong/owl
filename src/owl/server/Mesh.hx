package owl.server;

#if owl_server

import js.Promise;
import om.Nil;

class Mesh {

    public final id : String;
	public final maxNodes : Int;

	public var permanent(default,null) : Bool;
	public var numNodes(default,null) = 0;
	//public var visible(default,null) : String;
	//public var password(default,null) : String;
	//public var birth(default,null) : Float;

	@:allow(owl.server.Server)
	var infos = new Map<String,Dynamic>();

	var nodes = new Map<String,Node>();

	public function new( id : String, ?maxNodes : Int, permanent = false ) {
        this.id = id;
    	this.maxNodes = maxNodes;
    	this.permanent = permanent;
		//birth = Date.now().getTime();
    }

	public inline function iterator() : Iterator<Node>
        return nodes.iterator();

	/*
	public function start() : Promise<Nil>
        return Promise.resolve( null );

    public function stop() : Promise<Nil>
        return Promise.resolve( null );
	*/

	public function addNode( n : Node, ?info : Dynamic ) : Node {
		//TODO if( )
		nodes.set( n.id, n );
		if( info != null ) infos.set( n.id, info );
		numNodes++;
		return n;
	}

	public function removeNode( n : Node ) : Bool {
		if( nodes.remove( n.id ) ) {
			numNodes--;
			infos.remove( n.id );
			return true;
		}
		return false;
	}
}

#end
