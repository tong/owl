package owl;

typedef Server =
	#if owl_server
	owl.server.Server;
	#elseif owl_client
	owl.client.Server;
	#end
