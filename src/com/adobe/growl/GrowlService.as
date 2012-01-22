/*
  Copyright (c) 2008, Adobe Systems Incorporated
  All rights reserved.

  Redistribution and use in source and binary forms, with or without 
  modification, are permitted provided that the following conditions are
  met:

  * Redistributions of source code must retain the above copyright notice, 
    this list of conditions and the following disclaimer.
  
  * Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in the 
    documentation and/or other materials provided with the distribution.
  
  * Neither the name of Adobe Systems Incorporated nor the names of its 
    contributors may be used to endorse or promote products derived from 
    this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
  IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
  THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
  PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR 
  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

package com.adobe.growl
{
	import com.adobe.growl.events.GrowlConnectionEvent;
	import com.adobe.growl.events.GrowlErrorEvent;
	import com.adobe.growl.events.GrowlResponseEvent;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.Socket;
	import flash.utils.Dictionary;
	import com.adobe.growl.events.MessageParseEvent;
	
	/*
		create ant task to build asdocs and SWC
		
		fix punctuation in docs
	*/
	
	/**
	* Dispatched when the connection to the Growl service is disconnected.
	*
	* @eventType com.adobe.growl.events.GrowlConnectionEvent.DISCONNECT
	*/
	[Event(name="DISCONNECT", type="com.adobe.growl.events.GrowlConnectionEvent")]		
	
	/**
	* Dispatched when a connection to the Growl service is established.
	*
	* @eventType com.adobe.growl.events.GrowlConnectionEvent.CONNECT
	*/
	[Event(name="CONNECT", type="com.adobe.growl.events.GrowlConnectionEvent")]	
	
	/**
	* Dispatched when there was an error sending a notification to the Growl service.
	*
	* @eventType com.adobe.growl.events.GrowlErrorEvent.NOTIFICATION_ERROR
	*/
	[Event(name="NOTIFICATION_ERROR", type="com.adobe.growl.events.GrowlErrorEvent")]	
	
	/**
	* Dispatched when there was an error registering an application with to the
	* Growl service.
	*
	* @eventType com.adobe.growl.events.GrowlErrorEvent.REGISTRATION_ERROR
	*/
	[Event(name="REGISTRATION_ERROR", type="com.adobe.growl.events.GrowlErrorEvent")]		
	
	/**
	* Dispatched when an application has sucessfully registered with the Growl
	 * service.
	*
	* @eventType com.adobe.growl.events.GrowlResponseEvent.REGISTER
	*/
	[Event(name="REGISTER", type="com.adobe.growl.events.GrowlResponseEvent")]	
	
	/**
	* Dispatched when a notification was successfully sent to the Growl service.
	*
	* @eventType com.adobe.growl.events.GrowlResponseEvent.NOTIFICATION_SENT
	*/
	[Event(name="NOTIFICATION_SENT", type="com.adobe.growl.events.GrowlResponseEvent")]	
	
	/**
	* Dispatched when a notification has been clicked by the user.
	*
	* @eventType com.adobe.growl.events.GrowlResponseEvent.NOTIFICATION_CLICK
	*/
	[Event(name="NOTIFICATION_CLICK", type="com.adobe.growl.events.GrowlResponseEvent")]	
	
	/**
	* Dispatched when a notification has been closed by the user, or timed out.
	*
	* @eventType com.adobe.growl.events.GrowlResponseEvent.NOTIFICATION_CLOSE
	*/
	[Event(name="NOTIFICATION_CLOSE", type="com.adobe.growl.events.GrowlResponseEvent")]							
	
	/**
	* Dispatched when there is an error communicating over the socket connection
	 * with the Growl service.
	 * 
	 * In most cases, this indicates that either the Growl service is not installed
	 * or is not currently running.
	*
	* @eventType flash.events.IOErrorEvent.IO_ERROR
	*/
	[Event(name="IO_ERROR", type="flash.events.IOErrorEvent")]		
	
	/**
	* Dispatched when communication with the Growl service is denied because of
	 * security policies within the Flash Player..
	 * 
	 * This may occur when trying to connect to the Growl service from browser
	 * based Flash content when the Growl service has not been set by the user
	 * to accept browser based connections.
	*
	* @eventType flash.events.SecurityErrorEvent.SECURITY_ERROR
	*/
	[Event(name="SECURITY_ERROR", type="flash.events.SecurityErrorEvent")]		
	
	/**
	 * Class that provides an ActionScript interface to the Growl TCP API / service
	 * which provides system level notifications.
	 */			
	public class GrowlService extends EventDispatcher
	{
		//socket used to connect to the growl service
		private var s:Socket;
		
		//default host for local apps
		private var host:String = "127.0.0.1";
		
		//default port
		private var port:uint = 23053;
		
		//queues up packets sent while not connected to Growl.
		//mostly used when the service first starts up
		private var packets:Array = new Array();
		
		//application associated with the service
		private var _application:Application;
		
		//instance of message parser that builds and distributes messages
		//as they arrive over the socket
		private var mParser:MessageQueue;
		
		//start token for begining of messages packet from server
		private const START_TOKEN:String = "GNTP/1.0 -";
		
		//end token for begining of messages packet from server
		//private const END_TOKEN:String = "GNTP/1.0 END" + EOL + EOL; 
		
		/**
		 * Constructor
		 * 
		 * @parameter application An Application instance that represents the
		 * application that will be communicating with Growl.
		 * 
		 * @parameter host TCP host that the growl service is running on.
		 * 
		 * @parameter port Port that the growl service is listening on.
		 * 
		 * @see Application
		 */
		public function GrowlService(application:Application, 
									host:String = null, port:uint = 0)
		{
			_application = application;
			
			if(host != null)
			{
				this.host = host;
			}
			
			if(port != 0)
			{
				this.port = port;
			}
			
			//message queue to hold and construct messages as they arrive over
			//the socket
			mParser = new MessageQueue(START_TOKEN, MessageBuilder.END_TOKEN);
			
			//listen for when complete messages arrive
			mParser.addEventListener(MessageParseEvent.MESSAGE, onMessage);
			
			s = new Socket();
			addSocketListeners(s);
		}
		
		/**
		 * Application instance associated with the GrowlService instance.
		 * 
		 * The Application can only be set via the constructor.
		 * 
		 * @see Application
		 */
		public function get application():Application
		{
			return _application;
		}
		
		/**
		* Indicates whether the class is currently connected to Growl.
		*/
		public function get connected():Boolean
		{
			return s.connected;
		}
		
		/**
		*	Connects to the Growl API service, and registers the application
		*	and any specified notification types with Growl
		 * 
		 * @param notificationTypes An Array of NotificationType instances
		 * that represent the notification types that the application will
		 * register for and use.
		 * 
		 * @see NotificationType
		*/		
		public function connect(notificationTypes:Array = null):void
		{
			if(!s.connected)
			{
				s.connect(host, port);
			}
			
			register(notificationTypes);
		}		
		
		/**
		*	Disconnects from the Growl service
		*/
		public function disconnect():void
		{
			if(!s.connected)
			{
				return;
			}
			
			s.close();
		}
		
		/**
		*	Sends the specificied notification to Growl to be displayed to the
		 * user.
		 * 
		 * The notification name must match the name of a NotificationType which
		 * has been registered with Growl
		 * 
		 * @param notification The notification to displayed to the user. 
		 * 
		 * @see Notification
		*/
		public function notify(notification:Notification):void
		{
			var mb:MessageBuilder = new MessageBuilder();
			
			mb.addStart(RequestTypes.NOTIFY);
			mb.addHeader(new Header("Application-Name", _application.name));
			mb.addHeader(new Header("Notification-Name", notification.name));
			mb.addHeader(new Header("Notification-ID", notification.id));
			mb.addHeader(new Header("Notification-Title", notification.title));
			mb.addHeader(new Header("Notification-Text", notification.text));
			mb.addHeader(new Header("Notification-Sticky", (notification.sticky)?"Yes":"No"));
			mb.addHeader(new Header("Notification-Priority", String(notification.priority)));
			mb.addHeader(new Header("Notification-Callback-Context", _application.name));
			mb.addHeader(new Header("Notification-Callback-Context-Type", "String"));
					
			if(notification.xHeaders != null)
			{
				for each(var h:Header in notification.xHeaders)
				{
					mb.addHeader(h);
				}
			}
			
			sendPacket(mb.toString());
		}	
	
		/**
		*	Registers the application and specific notification types with Growl.
		*
		*	Note, in general you should specify notification types when calling
		*	conenct.
		 * 
		 *  The application must be registered with Growl before notifications
		 * can be sent.
		*	
		 * @param notification The notification to displayed to the user. 
		 * 
		 * @see #connect()
		 * @see Application
		*/
		public function register(notificationTypes:Array = null):void
		{
			if(notificationTypes == null)
			{
				notificationTypes = [];
			}
			
			var mb:MessageBuilder = new MessageBuilder();
				mb.addStart(RequestTypes.REGISTER);
				mb.addHeader(new Header("Application-Name", _application.name));
				mb.addHeader(new Header("Application-Icon", _application.iconPath));
				mb.addHeader(new Header("Notifications-Count", String(notificationTypes.length)));

			for each(var n:NotificationType in notificationTypes)
			{
				mb.addHeader(new HeaderSeperator());
				mb.addHeader(new Header("Notification-Name", n.name));
				mb.addHeader(new Header("Notification-Display-Name", n.displayName));
				mb.addHeader(new Header("Notification-Enabled", (n.enabled)?"True":"False"));
				
				if(n.iconPath != null)
				{
					mb.addHeader(new Header("Notification-Icon", n.iconPath));
				}
			}
						
			sendPacket(mb.toString());
		}

		
		/******** private functions ************/
		
		
		//sends a packet / message to Frowl
		private function sendPacket(p:String):void
		{
			//if connected, send
			if(s.connected)
			{
				trace("-----------------");
				trace(p);
				trace("-----------------");
				s.writeUTFBytes(p);
				
				s.flush();
			}
			else
			{
				//if not connected, queue up to send when we are connected
				//this is mostly used to 
				packets.push(p);
			}
		}
		
		//adds all of the socket listeners
		private function addSocketListeners(s:Socket):void
		{
			s.addEventListener(Event.CLOSE, onSocketClose);
			s.addEventListener(Event.CONNECT, onSocketConnect);
			s.addEventListener(IOErrorEvent.IO_ERROR, onSocketIOError);
			s.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSocketSecurityError);
			s.addEventListener(ProgressEvent.SOCKET_DATA, onSocketData);			
		}
		
		//removes all of the socket listeners
		private function removeSocketListeners(s:Socket):void
		{
			s.removeEventListener(Event.CLOSE, onSocketClose);
			s.removeEventListener(Event.CONNECT, onSocketConnect);
			s.removeEventListener(IOErrorEvent.IO_ERROR, onSocketIOError);
			s.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onSocketSecurityError);
			s.removeEventListener(ProgressEvent.SOCKET_DATA, onSocketData);			
		}
		
		/********** private socket event handlers ************/
		
		//event handler when the socket is closed / disconnected
		private function onSocketClose(e:Event):void
		{
			trace("socket close");
			
			//dispatch disconnect event
			var gce:GrowlConnectionEvent = new GrowlConnectionEvent(GrowlConnectionEvent.DISCONNECT);
			gce.application = _application;
			dispatchEvent(gce);
		}
		
		//event handler for when the socket connects
		private function onSocketConnect(e:Event):void
		{			
			//dispatch connect event
			var gce:GrowlConnectionEvent = new GrowlConnectionEvent(GrowlConnectionEvent.CONNECT);
			gce.application = _application;
			dispatchEvent(gce);
			
			//send any queued up packets
			var p:String;
			while(p = packets.shift())
			{
				sendPacket(p);
			}
		}
		
		//event handler in case there is a socket IOError
		private function onSocketIOError(e:IOErrorEvent):void
		{
			trace("onSocketIOError : " + e.text);
			var oe:IOErrorEvent = (e.clone() as IOErrorEvent);
			dispatchEvent(oe);
		}
		
		//event handler in case there is a socket security error
		private function onSocketSecurityError(e:SecurityErrorEvent):void
		{
			trace("security error");
			var oe:SecurityErrorEvent = (e.clone() as SecurityErrorEvent);
			dispatchEvent(oe);
		}
		
		//event handler called whenever data is received from the socket
		private function onSocketData(e:ProgressEvent):void
		{
			//grab the data. Note that it may only contain part of a complete
			//message
			var data:String = s.readUTFBytes(e.bytesLoaded);
			trace(data);
			
			//add to the message queue which will build complete messages, and then
			//broadcast when messages are found
			mParser.addData(data);
		}
	
	
		//event handler called when a complete message arrives from Growl
		private function onMessage(e:MessageParseEvent):void
		{
			handleMessage(e.message);
		}
	
		/***************** private response handlers ***********************/
		
		
		//parses and delegates complete messages received from Growl
		private function handleMessage(data:String):void
		{
			//split the message into rows
			var rows:Array = data.split(MessageBuilder.EOL);
			
			var len:int = rows.length;
			
			//dictionary to hold the headers
			var headers:Dictionary = new Dictionary();
			
			var row:Array;
			
			//row[0] - protocol identifier / message start token
			//row[row.length - 2] : message end token
			//\b[^\s]: [^\s]\b
			//loop through and parse the headers
			for(var i:int = 1; i < len - 2; i++)
			{
				row = rows[i].split(Header.NAME_VALUE_SEPERATOR);
				
				//add the header name / value to the dictionary
				headers[row[0]] = row[1];	
			}
			
			/*
			-OK
			-CALLBAK
			-ERROR
			*/
			//GNTP/1.0 -CALLBACK NONE NONE
			
			//var type:String = rows[0].split(" ")[1];
			
			//figure out why this matches -OK and OK
			//regular expression to get message type
			var pattern:RegExp = new RegExp(/ -([A-Z]*) /);
			
			var matches:Array = String(rows[0]).match(pattern);
			var type:String = (matches != null)?matches[1]:"UNKNOWN";
			
			//trace("Type : " + type);
			
			//delegate message to the appropriate API depending on the message type
			switch(type)
			{
				case ResponseTypes.OK:
				{
					handleOK(headers);
					break;
				}
				case ResponseTypes.CALLBACK:
				{
					handleCallback(headers);
					break;
				}
				case ResponseTypes.ERROR:
				{
					handleError(headers);
					break;
				}
				default:
				{
					//todo handle this
					//if we get to this point, something went wrong. Either 
					//in the ActionScript code or in Growl
					//Basically we either couldnt parse the message, or 
					//recived a message type that the library does not support
					trace("------------Response not recognized------------");
					trace(data);
					trace("-----------------------------------------------");
				}
			}
		}
		
		//handles error messages sent from growl
		private function handleError(headers:Dictionary):void
		{
			var type:String;
			var errorType:String = headers["Response-Action"];
			
			switch(errorType)
			{
				case RequestTypes.REGISTER:
				{
					type = GrowlErrorEvent.REGISTRATION_ERROR;
					break;
				}
				case RequestTypes.NOTIFY:
				{
					type = GrowlErrorEvent.NOTIFICATION_ERROR;
					break;
				}
			}
			
			
			//create an error event
			var e:GrowlErrorEvent = new GrowlErrorEvent(type);
			e.application = _application;
			
			//get the error info from the headers
			e.notificationId = headers["Notification-ID"];
			e.message = headers["Error-Description"];
			e.code = int(headers["Error-Code"]);
			e.headers = headers;
			e.application = _application;
			
			dispatchEvent(e);
		}	
		
		//handles OK messages from Growl
		private function handleOK(headers:Dictionary):void
		{
			//get the header that says what the OK is in response to
			var type:String = headers["Response-Action"];
			var eventType:String;
			
			//set the appropriate event type
			switch(type)
			{
				case RequestTypes.REGISTER:
				{
					eventType = GrowlResponseEvent.REGISTER;
					break;
				}
				case RequestTypes.NOTIFY:
				{
					eventType = GrowlResponseEvent.NOTIFICATION_SENT;
					break;
				}
				default:
				{
					trace("RequestType Response not recognized.");
					return;
				}
			}
			
			//create notification
			var e:GrowlResponseEvent = new GrowlResponseEvent(eventType);
			e.application = _application;
			e.headers = headers;
			
			//if it is in response to a NOTIFY request, then set the
			//notificationId
			if(type == RequestTypes.NOTIFY)
			{
				e.notificationId = headers["Notification-ID"];
			}
			
			dispatchEvent(e);
		}
		
		//handles CALLBACK messages from Growl. This is primarily when a notification
		//is clicked or closes.
		private function handleCallback(headers:Dictionary):void
		{
			var type:String;
			
			//figure out what type of callback the message represents
			switch(headers["Notification-Callback-Result"])
			{
				case CallbackTypes.CLICKED:
				{
					type = GrowlResponseEvent.NOTIFICATION_CLICK;
					break;
				}
				case CallbackTypes.CLOSED:
				{
					type = GrowlResponseEvent.NOTIFICATION_CLOSE;
					break;
				}
				default:
				{
					//implement
					trace("Callback type not recognized");
				}
			}
			
			//send event with information about the callback
			var e:GrowlResponseEvent = new GrowlResponseEvent(type);
			e.application = _application;
			e.headers = headers;
			e.notificationId = headers["Notification-ID"];
			
			dispatchEvent(e);
		}
		
	}
}