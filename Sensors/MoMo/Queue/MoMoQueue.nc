
interface MoMoQueue<t> {

    /* Check if the queue is empty */
	command bool empty();

    /* Check if the queue is full */
	command bool full();
	
	/* Return the current queue occupation */
	command uint8_t size();

    /* Return the queue length */
	command uint8_t maxSize();

    /* Return the current number of available queue location */
	command uint8_t remain();

    /* Insert item t at the tail of the queue */
	command error_t pushTop( t item );

    /* Insert item t at the head of the queue */
	command error_t pushBottom( t item );
	
	/* Get an item from the head of the queue */
	command t popBottom();
	
	/* Get from the queue the element at the idx position */
	command t * element( uint8_t idx );
	
}

