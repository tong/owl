package owl.server;

#if owl_server

import js.Promise;
import om.Nil;

class Mesh {

    public final id : String;
	public var maxNodes(default,null) : Int;
	public var permanent(default,null) : Bool;
	public var numNodes(default,null) = 0;
	//public var visible(default,null) : String;
	//public var password(default,null) : String;
	//public var birth(default,null) : Float;

	var nodes = new Map<String,Node>();

	public var infos(default,null) = new Map<String,Dynamic>();

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

	public function add( n : Node, ?info : Dynamic ) : Node {
		//TODO if( )
		nodes.set( n.id, n );
		if( info != null ) infos.set( n.id, info );
		numNodes++;
		return n;
	}

	public function remove( n : Node ) : Bool {
		if( nodes.remove( n.id ) ) {
			numNodes--;
			//infos.remove( n.id );
			return true;
		}
		return false;
	}
}

#end
