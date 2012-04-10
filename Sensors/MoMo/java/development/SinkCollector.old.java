
import java.io.*;
import java.util.*;

import net.tinyos.message.*;
import net.tinyos.packet.*;
import net.tinyos.util.*;

interface Refresh {
	public void updated( Node node );
}

abstract class Node implements MessageListener {
	private Refresh refresh;
	public void messageReceived( int to, Message message ) {
		refresh.updated( this );
	}
	abstract public double dump();
	public void register( Refresh refresh ) {
		this.refresh = refresh;
	}
}

class NodeSender extends Node {
	
	private int id;

	public NodeSender( int id, MoteIF moteIF ) {
		this.id = id;
		moteIF.registerListener( new UartSendMsg(), this );
	}
	
	public void messageReceived( int to, Message message ) {
		UartSendMsg msg = (UartSendMsg) message;
		
		//System.out.println( msg.toString() );
		
		int cmd_type = (int) msg.get_cmd_type();
		int sample = (int) msg.get_sample();
		int source = (int) msg.get_source();
		int pkt_num = (int) msg.get_pkt_num();
		int serial = (int) msg.get_serial();
		double age = (int) msg.get_age() / 1024.0;
		
		System.out.println("SINK received msg # "+pkt_num+" of type "+cmd_type+" from node "+source+" (serial="+serial+") with value "+sample+" and age "+age);
		
		//super.messageReceived( to, message );
	}
	
	public void sendMessage(MoteIF moteIF, short version, short cmd_type, int lpl_duty, int thr, long sampling_p, long collecting_p) {
		
        try {
			CtrlMsg msg = new CtrlMsg();			
			msg.set_version_( version );
			msg.set_cmd_type_( cmd_type );
			msg.set_lpl_duty_( lpl_duty );
			msg.set_threshold_( thr );
			msg.set_sampling_p_( sampling_p );
			msg.set_collecting_p_( collecting_p );
			moteIF.deregisterListener( new UartSendMsg(), this );
			moteIF.registerListener( new CtrlMsg(), this );
            moteIF.send( MoteIF.TOS_BCAST_ADDR, msg );
			moteIF.deregisterListener( new CtrlMsg(), this );
			moteIF.registerListener( new UartSendMsg(), this );
			//moteIF.send( 0, msg );
        } catch(IOException ioe) {
            System.err.println("Warning: Got IOException sending reset message: "+ioe);
            ioe.printStackTrace();
        }
	}

	public double dump() {
		return 0;
	}
	
}

class Controller implements Refresh {

	private Vector nodes;
	private MoteIF mif;
	private NodeSender node;
	
	public Controller() {
		nodes = new Vector();
	}
	
	public void updated( Node n ) {
	}
	
	public void addNode( String address, int id ) {
		//if ( new File( "/dev/cu.usbserial-" + address ).exists() ) {
		if ( new File( address ).exists() ) {
			//PhoenixSource phoenix = BuildSource.makePhoenix( "serial@/dev/cu.usbserial-" + address + ":telos" , PrintStreamMessenger.err );
			PhoenixSource phoenix = BuildSource.makePhoenix( "serial@" + address + ":telos" , PrintStreamMessenger.err );
			mif = new MoteIF( phoenix );
			node = new NodeSender( id, mif );
			nodes.addElement( node );
			node.register( this );
		}
		else {
			System.out.println( "Node " + id + " (" + address + ") is not connected" );
		}
	}
	
	public void sendMessage(short version, short cmd_type, int lpl_duty, int thr, long sampling_p, long collecting_p) {
		node.sendMessage( mif, version, cmd_type, lpl_duty, thr, sampling_p, collecting_p ); 
	}
	
}

public class SinkCollector {
	public static void main(String[] args) throws Exception {
		Controller c = new Controller();
		//c.addNode( "XBQABZ8Z", 0 );
		//c.addNode( "M4AF8BAJ", 0 );
		c.addNode( args[0], 0 );
		
		if ( args.length == 7 ) {
			c.sendMessage( Short.parseShort(args[1]), Short.parseShort(args[2]), Integer.parseInt(args[3]), Integer.parseInt(args[4]), Long.parseLong(args[5]), Long.parseLong(args[6]) );
		}
	}
}

