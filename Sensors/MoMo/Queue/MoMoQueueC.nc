/* $Id: QueueC.nc,v 1.4 2006/12/12 18:23:47 vlahan Exp $ */
/*
 * Copyright (c) 2006 Stanford University.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the Stanford University nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL STANFORD
 * UNIVERSITY OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 *  A general FIFO queue component, whose queue has a bounded size.
 *
 *  @author Philip Levis
 *  @author Geoffrey Mainland
 *  @date   $Date: 2006/12/12 18:23:47 $
 */

   
generic module MoMoQueueC( typedef queue_t, uint8_t QUEUE_SIZE ) {
	provides interface MoMoQueue<queue_t>;
}
implementation {

	queue_t queue[QUEUE_SIZE];
	uint8_t head = 0;
	uint8_t tail = 0;
	uint8_t size = 0;
  
	command bool MoMoQueue.empty() {
		return ( size == 0 ? TRUE : FALSE );
	}

	command uint8_t MoMoQueue.size() {
		return size;
	}

	command uint8_t MoMoQueue.maxSize() {
		return QUEUE_SIZE;
	}

	command uint8_t MoMoQueue.remain() {
		return QUEUE_SIZE - size;
	}

	command bool MoMoQueue.full() {
		return ( size == QUEUE_SIZE ? TRUE : FALSE );
	}
	
	command queue_t * MoMoQueue.element( uint8_t idx ) {
		idx += head;
		idx %= QUEUE_SIZE;
		return & queue[ idx ];
	}  
	
	command error_t MoMoQueue.pushTop( queue_t item ) {

		if ( call MoMoQueue.full() == TRUE )
			return FAIL;
			
		queue[ tail ] = item;
		tail ++;
		tail %= QUEUE_SIZE;
		size ++;
		
		return SUCCESS;
	}

	command error_t MoMoQueue.pushBottom( queue_t item ) {
	
		if ( call MoMoQueue.full() == TRUE )
			return FAIL;
	
		head += ( QUEUE_SIZE - 1 );
		head %= QUEUE_SIZE;
		queue[ head ] = item;
		size ++;
		
		return SUCCESS;
	}
	
	command queue_t MoMoQueue.popBottom() {
		queue_t result = queue[ head ];
		if ( size != 0 ) {
			head ++;
			head %= QUEUE_SIZE;
			size --;
		}
		return result;
	}

}

