package owl.server;

#if owl_server

class Mesh {

    public final id : String;
	public final maxNodes : Int;

	//public var visible(default,null) : String;
	//public var password(default,null) : String;
	public var permanent(default,null) : Bool;
	public var numNodes(default,null) = 0;
	//public var birth(default,null) : Float;

	@:allow(owl.server.Server)
	var nodes = new Map<String,Node>();

	@:allow(owl.server.Server)
	var credentials = new Map<String,Dynamic>();

	public function new( id : String, ?maxNodes : Int, permanent = false ) {
        this.id = id;
    	this.maxNodes = maxNodes;
    	this.permanent = permanent;
		//birth = Date.now().getTime();
    }

	public inline function iterator() : Iterator<Node>
        return nodes.iterator();

	public function addNode( n : Node, creds : Dynamic ) : Dynamic {
		if( nodes.exists( n.id ) )
			throw 'joined';
		if( maxNodes != null && numNodes >= maxNodes )
			throw 'max';
		nodes.set( n.id, n );
		credentials.set( n.id, creds );
		numNodes++;
		//return creds;
		return null;
	}

	public function removeNode( n : Node ) : Bool {
		if( nodes.remove( n.id ) ) {
			numNodes--;
			credentials.remove( n.id );
			return true;
		}
		return false;
	}
}

#end
