package owl.server;

#if owl_server

import js.Promise;
import om.Nil;

class Mesh {

    public var id(default,null) : String;
	public var maxNodes(default,null) : Int;
	public var permanent(default,null) : Bool;
	public var numNodes(default,null) = 0;
	//public var public_(default,null) : String;
	//public var password(default,null) : String;

	var nodes = new Map<String,Node>();

	public function new( id : String, ?maxNodes : Int, permanent = true ) {
        this.id = id;
    	this.maxNodes = maxNodes;
    	this.permanent = permanent;
    }

	public inline function iterator() : Iterator<Node>
        return nodes.iterator();

	/*
	public function start() : Promise<Nil>
        return Promise.resolve( null );

    public function stop() : Promise<Nil>
        return Promise.resolve( null );
	*/

	public function add( n : Node ) : Node {
		//TODO if( )
		nodes.set( n.id, n );
		numNodes++;
		return n;
	}

	public function remove( n : Node ) : Bool {
		if( nodes.remove( n.id ) ) {
			numNodes--;
			return true;
		}
		return false;
	}
}

#end
