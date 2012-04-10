
interface NodeControl {

    /**
	 * Set the node address in the network is joining
	 */
    command void setNodeAddress( am_group_t group, am_addr_t addr );
    
    /**
	 * Get the node address
	 */   
    command am_addr_t getNodeAddress();
    
    /**
	 * Declare that the node is a sink
	 */
	command void setSink();

	/**
	 * Check if the node is a sink
	 */
	command bool isSink();
	
	/**
	 * Set the sink node of the network the node is joining
	 */
	command void setMySink( am_addr_t sink );
	
	/**
	 * Return the sink node of the network the node is participating
	 */
	command am_addr_t getMySink();
	
	/**
	 * Check if a node is the destination for the current packet
	 */
	command bool isForMe( am_addr_t addr );

    /**
	 * Add a new node to the neighbors list of the node
	 */
	command void addNeigh();
	
	/**
	 * Set the number of neighbors of the node
	 */
	command void setNumNeigh( uint8_t neigh );
	
	/**
	 * Check the number of neighbors of the node
	 */
	command uint8_t getNumNeigh();
	
	/**
	 * Set the unique ID of the node
	 */
	command void setUniqueID( uint16_t id );
	
	/**
	 * Get the unique ID of the node
	 */
	command uint16_t getUniqueID();
	
	/**
	 * A new neighbor is discovered
	 */
	async event void changedNumNeigh( uint8_t neigh );
	
	//MN: add some events HERE like address or channel changing

}
