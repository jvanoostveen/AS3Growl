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
	import flash.events.EventDispatcher;
	
	import com.adobe.growl.events.MessageParseEvent;

	/**
	 * Class that queues up message fragments and then builds them based on 
	 * start and end tokens.
	 * 
	 * This is useful for constructing messages arriving over a socket, where
	 * the complete message may not be sent all at once.
	 */
	public class MessageQueue extends EventDispatcher
	{
		private var startToken:String;
		private var endToken:String;
		
		private var startTokenLen:int;
		private var endTokenLen:int;
		
		private var data:String = "";
		
		/**
		 * Constructor.
		 * 
		 * @param startToken The string that indicates the start of a message.
		 * @param endToke The string the indicates the end of a message.
		 */
		public function MessageQueue(startToken:String, endToken:String)
		{
			this.startToken = startToken;
			this.endToken = endToken;
			
			startTokenLen = this.startToken.length;
			endTokenLen = this.endToken.length;
		}
		
		/**
		 * Adds data to the data queue.
		 * 
		 * @param data string fragment to be added to the queue.
		 */
		public function addData(data:String):void
		{
			this.data += data;
			parseMessages();
		}
		
		/**
		 * Searches the queued data for complete messages. If a message is found,
		 * it is removed from the data, and an event is broadcast with the message.
		 * @private
		 */
		private function parseMessages():void
		{
			//whether we should keep searching the data
			var search:Boolean = true;
			
			var startIndex:int;
			var endIndex:int;
			
			//loop through string until all messages are extracted
			while(search)
			{
				//see if we can find the startToken
				startIndex = data.indexOf(startToken);
				if(startIndex > -1)
				{
					//see if we can find the endToken
					endIndex = data.indexOf(endToken, startIndex + startTokenLen);
					
					if(endIndex > -1)
					{
						//if we are here, it means we found start and end token, 
						//which means we have a complete message.
						
						//extract the message.
						var m:String = data.substring(startIndex, endIndex + endTokenLen);
						
						//send event with the message
						var mpe:MessageParseEvent = new MessageParseEvent(MessageParseEvent.MESSAGE);
						mpe.message = m;
						dispatchEvent(mpe);
						
						//remove message from data.
						data = data.substr(endIndex + endTokenLen);
						continue;
					}
				}
				
				search=false;
			}
		}
		
	}
}