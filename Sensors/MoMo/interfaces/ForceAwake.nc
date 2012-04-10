
interface ForceAwake {

    //These functions are exclusively used by the Sink node
    
    /* Set the given node is required to stay awake */
    command void setNeighbors( am_addr_t neigh );
    
    /* The node is no more required to stay awake */
    command void resetNeighbors( am_addr_t neigh );
    
    /* Check if the required node should stay awake */
    command uint8_t checkNeighbors( am_addr_t neigh );
    
    /* Set all the nodes are required to stay awake */
    command void setAllNeighbors( uint8_t num_neigh );
    
    /* Check if at least one node should stay awake */
    command bool checkAllNeighbors( uint8_t num_neigh );
    
    /* Set the neighbors duty cycle */
    command void setNeighborsDuty( uint16_t duty );
    
    /* Get the neighbors duty cycle */
    command uint16_t getNeighborsDuty();
    
    /* Set the node unique ID in the network is joining */
    command void setNeighborsID( am_addr_t neigh, am_addr_t id );
    
    /* Set the mode the node with the given ID is required to operate (RT = 0, PER = 1) */
    command void setNeighborsMode( uint8_t mode, am_addr_t id );
    
    /* Set the mode all the nodes are required to operate */
    command void setAllNeighborsMode( uint8_t mode );
    
    /* Check the mode the given node is required to operate */
    command uint8_t checkNeighborsMode( am_addr_t neigh );
    
}
