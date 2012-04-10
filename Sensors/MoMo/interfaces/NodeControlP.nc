/**
 *
 * This component provides the NodeControl interface 
 * and uses the Boot and ActiveMessageAddress interfaces 
 * It provides and manages information about the node 
 * (uniqueID, address etc etc) and the number
 * of its neighbors.
 * 
 */

#include "MoMoMsg.h"

module NodeControlP {

    provides {
        interface NodeControl;
    }
    
    uses {
        interface Boot;
        interface ActiveMessageAddress as LocalAddress;
    }
}

implementation {

    bool is_sink_;
    uint16_t my_sink_;
	uint16_t unique_id_;
    uint8_t num_neigh_;
 
    event void Boot.booted() {
        //MN: put HERE more initializations
        is_sink_ = FALSE;
        num_neigh_ = 0;
		unique_id_ = 0;
#ifdef MM_SINK
        call NodeControl.setMySink( MM_SINK );
#endif
    }

    async event void LocalAddress.changed() {
	}
	
	command void NodeControl.setNodeAddress( am_group_t group, am_addr_t addr ) {
	   call LocalAddress.setAddress( group, addr );
	}
	
	command am_addr_t NodeControl.getNodeAddress() {
	   return call LocalAddress.amAddress();
	}
	
	command void NodeControl.setSink() {
        is_sink_ = TRUE;
	}
	
	command bool NodeControl.isSink() {
	   return is_sink_;
	}
	
	command void NodeControl.setMySink( am_addr_t sink ) {
	   my_sink_ = sink;
	}
	
	command am_addr_t NodeControl.getMySink() {
	   return my_sink_;
	}
	
	command bool NodeControl.isForMe( am_addr_t addr ) {
	   return ( addr == call LocalAddress.amAddress() );
	}
	
	command void NodeControl.addNeigh() {
	   num_neigh_ ++;
	   signal NodeControl.changedNumNeigh( num_neigh_ );
	}
	
	command void NodeControl.setNumNeigh( uint8_t neigh ) {
	   num_neigh_ = neigh;
	   signal NodeControl.changedNumNeigh( num_neigh_ );
	}
	
	command void NodeControl.setUniqueID( uint16_t id ) {
		unique_id_ = id;
	}
	
	command uint16_t NodeControl.getUniqueID() {
		return unique_id_;
	}
	
	command uint8_t NodeControl.getNumNeigh() {
	   return num_neigh_;
	}
}
