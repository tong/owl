package owl;

#if owl_server
typedef Mesh = owl.server.Mesh;
#elseif owl_client
typedef Mesh<T:owl.Node> = owl.client.Mesh<T>;
#end
