package owl;

typedef Node =
	#if owl_server
	owl.server.Node;
	#elseif owl_client
	owl.client.Node;
	#end
