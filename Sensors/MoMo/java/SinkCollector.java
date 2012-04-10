
import java.io.*;
import java.util.*;
import java.text.*;

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
		SimpleDateFormat sdf = new SimpleDateFormat( "mm:ss:SS" );
		System.err.print( sdf.format( new Date() ) + "\t" );
		
		//System.out.println( msg.toString() );
		
		int cmd_type = (int) msg.get_cmd_type();
		int sample = (int) msg.get_sample();
		int source = (int) msg.get_source();
		int pkt_num = (int) msg.get_pkt_num();
		int serial = (int) msg.get_serial();
		double age = (int) msg.get_age() / 1024.0;
		
		//System.out.println("SINK received msg # "+pkt_num+" of type "+cmd_type+" from node "+source+" (serial="+serial+") with value "+sample+" and age "+age);
		System.err.println("SINK received msg # "+pkt_num+" of type "+cmd_type+" from node "+source+" (serial="+serial+") with value "+sample+" and age "+age);
		
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
	
	//types of sensor readings
	private static short MM_GET_HUMIDITY		= 0;
	private static short MM_GET_TEMPERATURE		= 1;
	private static short MM_GET_PHOTO			= 2;
	private static short MM_GET_SOLAR			= 3;
	
	//Requires a given node to remain awake
	private static short MM_FORCE_AWAKE			= 100;
	
	//Default threshold value
	private static int MM_DEF_THR				= 0;
	
	//Type of required sensor readings
	private static short GET_AVERAGE			= 0; //Average
	private static short GET_ALL_SAMPLES		= 1; //All samples
	
	//Type of node working mode
	private static int PERIODIC					= 0; //Periodic
	private static int REALTIME					= 1; //Real-time
	
	public static HashMap commands;

	public static void main(String[] args) throws Exception {
		String[] inputs = new String[6];
		Controller c = new Controller();
		//c.addNode( "XBQABZ8Z", 0 );
		//c.addNode( "M4AF8BAJ", 0 );
		c.addNode( args[0], 0 );
		
		commands = new HashMap();
		InputStreamReader cin = new InputStreamReader(System.in);
		BufferedReader in = new BufferedReader(cin);
		String input = "";
		
		commands.put( new String( "GET_AVERAGE" ), new Short( GET_AVERAGE ) );
		commands.put( new String( "GET_ALL_SAMPLES" ), new Short( GET_ALL_SAMPLES ) );
		
		commands.put( new String( "MM_GET_HUMIDITY" ), new Short( MM_GET_HUMIDITY ) );
		commands.put( new String( "MM_GET_TEMPERATURE" ), new Short( MM_GET_TEMPERATURE ) );
		commands.put( new String( "MM_GET_PHOTO" ), new Short( MM_GET_PHOTO ) );
		commands.put( new String( "MM_GET_SOLAR" ), new Short( MM_GET_SOLAR ) );
		commands.put( new String( "MM_FORCE_AWAKE" ), new Short( MM_FORCE_AWAKE ) );
		
		System.out.print("Enter 'p' to program nodes\n");
		System.out.print(">> ");
		for(;;) {
			try {
				short version;
				input = in.readLine();
				if(input.equals("p")) {
					System.out.print("Enter version: ");
					inputs[0] = in.readLine();
					System.out.print("Enter cmd_type: ");
					inputs[1] = in.readLine();
					System.out.print("Enter lpl_duty (0 for PERIODIC mode): ");
					inputs[2] = in.readLine();
					System.out.print("Enter thr: ");
					inputs[3] = in.readLine();
					System.out.print("Enter samplign_p (secs): ");
					inputs[4] = in.readLine();
					System.out.print("Enter collecting_p (secs): ");
					inputs[5] = in.readLine();
					if ( inputs[1].equals("MM_FORCE_AWAKE") )
						version = Short.parseShort(inputs[0]);
					else
						version = ((Short)commands.get(new String(inputs[0]))).shortValue();
					c.sendMessage( version, ((Short)commands.get(new String(inputs[1]))).shortValue(), Integer.parseInt(inputs[2]), Integer.parseInt(inputs[3]), Long.parseLong(inputs[4]), Long.parseLong(inputs[5]) );
				}
				else System.out.println("Invalid Input!!!!: ");
				System.out.print(">> ");
			}
			catch (IOException e) {
				System.out.print("Error On Input!!");
			}
		}
	}
}	
