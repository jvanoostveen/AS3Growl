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
	
	/**
	* Dispatched when a complete message has been parsed and is available.
	*
	* @eventType com.adobe.growl.events.MessageParseEvent.MESSAGE
	*/
	[Event(name="MESSAGE", type="com.adobe.growl.events.MessageParseEvent")]	
	
	
	/**
	 * Class that builds and formats requests for the Growl service.
	 */
	public class MessageBuilder
	{
		/**
		 * End of line delimeter for communication with Growl service.
		 */
		public static const EOL:String = "\r\n";

		/**
		 * Token used to indicate end of a message in communications with the 
		 * Growl service.
		 */
		public static const END_TOKEN:String = EOL + "GNTP/1.0 END" + EOL + EOL;
		
		private var messageStart:String;
		private var headers:Array;
		
		/**
		 * Constructor.
		 */
		public function MessageBuilder()
		{
			headers = new Array();
		}
		
		/**
		 * Adds a HeaderItem item to be included in the message.
		 * 
		 * HeaderItems will be included in the order they are added.
		 */
		public function addHeader(h:HeaderItem):void
		{
			headers.push(h);
		}
		
		/**
		 * Generates the message start directive based on the RequestType
		 * specified.
		 * 
		 * @param type A String representing the Request type that the message
		 * represents.
		 * 
		 * @see RequestTypes
		 */
		public function addStart(type:String):void
		{
			messageStart = "GNTP/1.0 " + type + " NONE" + EOL;
		}
		
		/**
		 * Methods that generates and returns a complete request for the Growl
		 * service based on the class instance.
		 */
		public function toString():String
		{
			var s:String = "";
			
			s += messageStart;
			
			var len:int = headers.length;
			
			for(var i:int = 0; i < len; i++)
			{
				s += headers[i].toString();
			}
			
			s += END_TOKEN;
			
			return s;
		}
	}
}