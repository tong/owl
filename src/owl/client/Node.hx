package owl.client;

#if owl_client

import haxe.Json;
import js.Browser.console;
import js.Promise;
import js.html.MediaStream;
import js.html.WebSocket;
import js.html.rtc.Configuration;
import js.html.rtc.DataChannel;
import js.html.rtc.DataChannelInit;
import js.html.rtc.IceCandidate;
import js.html.rtc.PeerConnection;
import js.html.rtc.SessionDescription;

class Node {

    public dynamic function onConnect() {}
    public dynamic function onDisconnect() {}
    public dynamic function onCandidate( e : IceCandidate ) {}
    public dynamic function onChannel( channel : DataChannel ) {}
    public dynamic function onMessage( msg : Message ) {}

    public var id(default,null) : String;
    public var connected(default,null) = false;
    public var initiator(default,null) : Bool;
    public var connection(default,null) : PeerConnection;
    public var channel(default,null) : DataChannel;

    public function new( id : String, ?config : Configuration ) {

        this.id = id;

        connection = new PeerConnection( config );
        connection.onicecandidate = function(e){
            if( e.candidate != null ) {
                onCandidate( e.candidate );
            }
        }
        connection.oniceconnectionstatechange = function(e){
            switch e.iceConnectionState {
            case 'disconnected':
                connected = false;
                onDisconnect();
            }
        }
    }

    @:overload( function( data : String ) : Void {} )
	@:overload( function( data : js.html.Blob ) : Void {} )
	@:overload( function( data : js.html.ArrayBuffer ) : Void {} )
    public function send( data : String ) {
        if( connected ) channel.send( data );
    }

    public function sendMessage( msg : Message ) {
        if( connected ) {
            var str = try Json.stringify( msg ) catch(e:Dynamic){
                console.error(e);
                return;
            }
            channel.send( str );
        } else {
            trace("NOT CONNECTED");
        }
    }

    public function addStream( stream : MediaStream ) {
        connection.addStream( stream );
    }

    public function createDataChannel( id : String, ?config : DataChannelInit ) : DataChannel {
        return connection.createDataChannel( id, config );
    }

    public function toString() : String {
        return 'Node(id=$id,initiator=$initiator)';
    }

    @:allow(owl.client.Mesh)
    function connectTo( ?channelConfig : DataChannelInit ) {

        initiator = true;

        setDataChannel( connection.createDataChannel( 'mesh', channelConfig ) );

        return new Promise( function(resolve,reject){
            connection.onnegotiationneeded = function() {
                connection.createOffer()
                    .then( function(desc) connection.setLocalDescription( desc ) )
                    .then( function(_) {
                        resolve( connection.localDescription );
                    }
                );
            }
        });
    }

    @:allow(owl.client.Mesh)
    function connectFrom( sdp : SessionDescription ) {

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
    function addIceCandidate( candidate : IceCandidate ) : Promise<Void> {
        return connection.addIceCandidate( new IceCandidate( candidate ) );
    }

    @:allow(owl.client.Mesh)
    function setRemoteDescription( sdp : SessionDescription ) {
        //if( !initiator )
        return connection.setRemoteDescription( sdp );
    }

    @:allow(owl.client.Mesh)
    function disconnect() {
        if( connected ) {
            connected = false;
            channel.close();
            connection.close();
        }
    }

    function setDataChannel( channel : DataChannel ) {
        this.channel = channel;
        channel.onopen = function(e) {
            connected = true;
            onConnect();
        }
        channel.onmessage = function(e) {
            //trace("ON CHANNEL MESSAGE "+e.data);
            var msg = try Json.parse( e.data ) catch(e:Dynamic) {
                console.warn(e);
                return;
            }
            onMessage( msg );
        };
        channel.onclose = function(e) {
            connected = false;
            onDisconnect();
        }
        channel.onerror = function(e) {
            connected = false;
            onDisconnect();
        }
    }

}

#end
