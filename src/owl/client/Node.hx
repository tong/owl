package owl.client;

#if owl_client

import js.Promise;
import js.html.MediaStream;
import js.html.rtc.PeerConnection;
import js.html.rtc.DataChannel;
import js.html.rtc.DataChannelInit;
import js.html.rtc.IceCandidate;
import js.html.rtc.SessionDescription;

class Node {

	@:allow(owl.client.Mesh) dynamic function onCandidate( e : IceCandidate ) {}
	@:allow(owl.client.Mesh) dynamic function onConnect() {}
	@:allow(owl.client.Mesh) dynamic function onDisconnect() {}
	@:allow(owl.client.Mesh) dynamic function onData( data : Dynamic ) {}

	public dynamic function onChannel( channel : DataChannel ) {}

	public var id(default,null) : String;
	public var connected(default,null) = false;
	public var initiator(default,null) : Bool;
	public var connection(default,null) : PeerConnection;
	public var channel(default,null) : DataChannel;

	public function new( id : String ) {
		this.id = id;
		connection = new PeerConnection();
		connection.onicecandidate = function(e){
			if( e.candidate != null )
				onCandidate( e.candidate );
		}
		connection.oniceconnectionstatechange = function(e){
			if( connection.iceConnectionState == DISCONNECTED )
				onDisconnect();
		}
	}

	@:overload( function( data : js.html.Blob ) : Void {} )
	@:overload( function( data : js.html.ArrayBuffer ) : Void {} )
	@:overload( function( data : js.html.ArrayBufferView ) : Void {} )
	public function send( data : String ) {
		//if( channel.readyState == OPEN ) channel.send( data );
		channel.send( data );
	}

	/*
	public function addStream( stream : MediaStream ) {
        connection.addStream( stream );
    }
	*/

	@:allow(owl.client.Mesh)
	function connectTo( ?config : DataChannelInit ) : Promise<SessionDescription> {
		initiator = true;
        setDataChannel( connection.createDataChannel( 'mesh', config ) );
		return new Promise( (resolve,reject) -> {
			connection.onnegotiationneeded = () -> {
                return connection.createOffer()
                    .then( (d) -> connection.setLocalDescription( d ) )
                    .then( (_) -> resolve( connection.localDescription ) );
            }
		});
	}

	@:allow(owl.client.Mesh)
    function connectFrom( sdp : SessionDescription ) : Promise<SessionDescription> {
        initiator = false;
        connection.ondatachannel = function(e) {
            (channel == null) ? setDataChannel( e.channel ) : onChannel( e.channel );
        }
        return new Promise( function(resolve,reject) {
            //trace(sdp.type); // TODO null on firefox 64
            connection.setRemoteDescription( sdp ).then( function(_){
                connection.createAnswer().then( function(answer){
                    connection.setLocalDescription( answer ).then( function(e){
                        resolve( connection.localDescription );
                    });
                });
            });
        });
    }

	@:allow(owl.client.Mesh)
    inline function setRemoteDescription( sdp : SessionDescription ) : Promise<Void> {
        //if( !initiator )
        return connection.setRemoteDescription( sdp );
    }

	@:allow(owl.client.Mesh)
	inline function addIceCandidate( candidate : IceCandidate ) : Promise<Void> {
		return connection.addIceCandidate( new IceCandidate( candidate ) );
	}

	function setDataChannel( ch : DataChannel ) {
        channel = ch;
        channel.onopen = function(e) {
			connected = true;
            onConnect();
        }
        channel.onmessage = function(e) {
			onData( e.data );
        };
        channel.onclose = function(e) {
			trace(e);
			///TODO
        }
        channel.onerror = function(e) {
			trace(e);
			///TODO
        }
    }
}

#end
