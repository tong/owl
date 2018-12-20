package owl.server;

#if owl_server

import js.Promise;
import om.Nil;

class Mesh {

    public var id(default,null) : String;
	public var numNodes(default,null) = 0;

	var nodes = new Map<String,Node>();

	public function new( id : String, maxNodes = 16 ) {
        this.id = id;
        //this.maxNodes = maxNodes;
    }

	public inline function iterator() : Iterator<Node>
        return nodes.iterator();

	public function add( node : Node ) : Node {
		nodes.set( node.id, node );
		numNodes++;
		return node;
	}

	public function remove( node : Node ) : Node {
		nodes.remove( node.id );
		numNodes--;
		return node;
	}

}

#end
