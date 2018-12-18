package owl.server;

class Main {

	static function main() {

        var args = Sys.args();
		//var ip = om.Network.getLocalIP()[0];
		var ip = '192.168.0.10';
		var port = 7000;

		var server = new owl.Server( ip, port );
		server.start().then( function(_) {
			trace('SERVER READY');
            //var timer = new haxe.Timer(1000);
            //timer.run = server.update;
        });
	}
}
