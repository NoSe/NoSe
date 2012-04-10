/**
 *
 * This component provides the ForceAwake interface.
 * It provides the command that application layer uses to
 * set the node is required to remain awake. At mac layer the
 * packets for this given node should have the force awake
 * flag set to 1.
 * Commands to know the operating mode of each neighbors
 * are also implemented.
 * 
 */

#include "MoMoMsg.h"

module ForceAwakeP {

    provides {
        interface ForceAwake;
    }
}

implementation {
    
    uint16_t neigh_list_[MM_MAX_NUM_NEIGH];     // List of nodes that are required to stay awake
    uint16_t neigh_mode_[MM_MAX_NUM_NEIGH];     // List of the way the nodes are operating
    uint16_t new_nodes_list_[MM_MAX_NUM_NEIGH]; // List of the nodes ID in the network
    
    uint16_t neigh_duty_;                       // Neighbors duty cycle
    
    
    command void ForceAwake.setNeighbors( am_addr_t neigh ) {
        neigh_list_[neigh] = 1;
    }

    command void ForceAwake.resetNeighbors( am_addr_t neigh ) {
        neigh_list_[neigh] = 0;
    }

    command uint8_t ForceAwake.checkNeighbors( am_addr_t neigh ) {
        return neigh_list_[neigh];
    }
    
    command void ForceAwake.setAllNeighbors( uint8_t num_neigh ) {
        uint8_t i;
        for ( i = 1; i <= num_neigh; i++) {
            neigh_list_[i] = 1;
        }
    }
    
    command bool ForceAwake.checkAllNeighbors( uint8_t num_neigh ) {
        uint8_t i;
        for ( i = 1; i <= num_neigh; i++) {
            if ( neigh_list_[i] == 1 )
                return TRUE;
        }
        return FALSE;
    }
    
    command void ForceAwake.setNeighborsDuty( uint16_t duty ) {
        neigh_duty_ = duty;
    }
    
    command uint16_t ForceAwake.getNeighborsDuty() {
        return neigh_duty_;
    }
    
    command void ForceAwake.setNeighborsID( am_addr_t neigh, am_addr_t id ) {
        new_nodes_list_[neigh] = id;
    }
    
    command void ForceAwake.setNeighborsMode( uint8_t mode, am_addr_t id ) {
        uint8_t i;
        for ( i = 0; i < MM_MAX_NUM_NEIGH; i++) {
            if ( new_nodes_list_[i] == id ) {
                neigh_mode_[i] = mode;
                return;
            }
        }
    }
    
    command void ForceAwake.setAllNeighborsMode( uint8_t mode ) {
        uint8_t i;
        for ( i = 0; i < MM_MAX_NUM_NEIGH; i++) {
            neigh_mode_[i] = mode;
        }
    }
    
    command uint8_t ForceAwake.checkNeighborsMode( am_addr_t neigh ) {
        return neigh_mode_[neigh];
    }
    
}
