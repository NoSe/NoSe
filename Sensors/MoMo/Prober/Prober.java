
import java.io.*;
import java.text.*;
import java.io.IOException;
import java.util.*;

import net.tinyos.message.*;
import net.tinyos.packet.*;
import net.tinyos.util.*;

public class Prober extends Thread {
	
	public static final short MODULE_MAC_ACK			= 0;  // MAC Layer Ack Message.
	public static final short MODULE_MAC_SYNC			= 1;  
	public static final short MODULE_MAC_DATA			= 2;  // All application messages
															  // Data Join or Ctrl Message
	public static final short HEADER_LENGTH				= 3;
	public static final short AM_MM_DATA_MSG			= 120;
	public static final short AM_MM_CTRL_MSG			= 121;
	public static final short AM_MM_JOIN_MSG			= 122;
	
	//public HashMap<Short,String> types;
	public HashMap types;
	PacketSource reader;
	
	public Prober( PacketSource reader ) {
		this.reader = reader;
		types = new HashMap();
		types.put( new Short( MODULE_MAC_ACK ), new String( "ACK" ) );
		types.put( new Short( MODULE_MAC_SYNC ), new String( "Sync" ) );
		types.put( new Short( MODULE_MAC_DATA ), new String( "App" ) );
		types.put( new Short( AM_MM_DATA_MSG ), new String( "Data" ) );
		types.put( new Short( AM_MM_CTRL_MSG ), new String( "Ctrl" ) );
		types.put( new Short( AM_MM_JOIN_MSG ), new String( "Join" ) );
	}
		
	public void run() {
		try {
			reader.open(PrintStreamMessenger.err);
			for (;;) {
				
				byte[] packet = reader.readPacket();
				byte[] serialpacket = new byte[ 7 ];
				byte[] headerpacket;
				byte[] subpacket;
				
				HeaderMsg header;
				ReportMsg msg;
				
				//byte[] subpacket = new byte[ packet.length - 8 ];
				
				//System.arraycopy( packet, 8, subpacket, 0, packet.length - 8 );
				System.arraycopy( packet, 1, serialpacket, 0, 7 );
				
				//ReportMsg msg = new ReportMsg( subpacket );

				SerialPacket serial = new SerialPacket( serialpacket );

				// SimpleDateFormat sdf = new SimpleDateFormat( "HH:mm:ss:SS" );
				SimpleDateFormat sdf = new SimpleDateFormat( "mm:ss:SS" );
				System.out.print( sdf.format( new Date() ) + "\t" );

				printHeader( serial );
				
				// System.out.print( new java.util.Date() + "\t");
				// Dump.printPacket(System.out, msg.dataGet() );
				
				
				switch ( serial.get_header_type() ) {
					case MODULE_MAC_ACK : 
						headerpacket = new byte[ packet.length - 8 ];
						System.arraycopy( packet, 8, headerpacket, 0, packet.length - 8 );
						header = new HeaderMsg( headerpacket );
						printAck( header ); 
						break;
					case MODULE_MAC_SYNC : 
						headerpacket = new byte[ packet.length - 8 ];
						System.arraycopy( packet, 8, headerpacket, 0, packet.length - 8 );
						header = new HeaderMsg( headerpacket );
						//printSync( header ); 
						break;
					case MODULE_MAC_DATA : 
						headerpacket = new byte[ HEADER_LENGTH ];
						System.arraycopy( packet, 8, headerpacket, 0, HEADER_LENGTH );
						subpacket = new byte[ packet.length - 8 - HEADER_LENGTH ];
						System.arraycopy( packet, 8 + HEADER_LENGTH, subpacket, 0, packet.length - 8 - HEADER_LENGTH );
						header = new HeaderMsg( headerpacket );
						msg = new ReportMsg( subpacket );
						printAppMsg( header, msg ); 
						break;
					default: 
						System.out.println("Unknown packet"); 
						break;
				}
				
				System.out.println();
				
				System.out.flush();
			}
		}
		catch (IOException e) {
			System.err.println("Error on " + reader.getName() + ": " + e);
		}
	}
	
	public void printHeader( SerialPacket msg ) {	
		System.out.print("hdr: {" );
		//String type = types.get( new Short( msg.get_header_type() ) );
		//if ( type == null ) {
		if ( types.get( new Short( msg.get_header_type() ) ) == null ) {	
			System.out.print( "type: " + msg.get_header_type() );
		}
		else {
			//System.out.print( "type: " + type );
			System.out.print( "type: " + types.get( new Short( msg.get_header_type() ) ) );
		}
		System.out.print( ", length: " + msg.get_header_length() );
		System.out.print( ", src: " + msg.get_header_src() );
		System.out.print( ", dest: " );
		if ( msg.get_header_dest() == 65535 )
			System.out.print( "BROADCAST" );
		else
			System.out.print( msg.get_header_dest() );
		System.out.print( "} " );
	}
	
	public void printData( ReportMsg msg ) {
		System.out.print("data: {" );
		System.out.print( "cmd_type: " + msg.get_data_cmd_type_() );
		System.out.print( ", sample: " + msg.get_data_sample_() );
		System.out.print( ", pkt_num: " + msg.get_data_pkt_num_() );
		System.out.print( ", serial: " + msg.get_data_serial_() );
		System.out.print( ", age: " + msg.get_data_age_() / 1024.0 );
		System.out.print( "} " );
	}
	
	public void printAppMsg( HeaderMsg header, ReportMsg msg ) {
		switch ( header.get_header_type() ) {
			case AM_MM_DATA_MSG : printData( msg ); break;
			case AM_MM_CTRL_MSG : printCtrl( msg ); break;
			case AM_MM_JOIN_MSG : printJoin( msg ); break;
			default: System.out.println("Unknown packet"); break;
		}
	}
	
	public void printAck( HeaderMsg header ) {
		System.out.print("ack: {" );
		System.out.print( "node_id: " + header.get_ack_node_id() );
		System.out.print( " force_awake: " + header.get_ack_force_awake() );
		System.out.print( "} " );
	}
	
	public void printCtrl( ReportMsg msg ) {
		System.out.print("ctrl: {" );
		System.out.print( "version: " + msg.get_ctrl_version_() );
		System.out.print( ", cmd_type: " + msg.get_ctrl_cmd_type_() );
		System.out.print( ", lpl_duty: " + msg.get_ctrl_lpl_duty_() );
		System.out.print( ", threshold: " + msg.get_ctrl_threshold_() );
		System.out.print( ", sampling_p: " + msg.get_ctrl_sampling_p_() );
		System.out.print( ", collectiong_p: " + msg.get_ctrl_collecting_p_() );
		System.out.print( "} " );
	}
	
	public void printJoin( ReportMsg msg ) {
		System.out.print("join: {" );
		System.out.print( "sink_id: " + msg.get_join_sink_id_() );
		System.out.print( ", node_id: " + msg.get_join_node_id_() );
		System.out.print( "} " );
	}
	
    public static void main(String args[]) throws IOException {
        String source = null;
		PacketSource reader;
        if (args.length == 2 && args[0].equals("-comm")) {
			source = args[1];
        }
		else if (args.length > 0) {
			System.err.println("usage: java net.tinyos.tools.Listen [-comm PACKETSOURCE]");
			System.err.println("       (default packet source from MOTECOM environment variable)");
			System.exit(2);
		}
        if (source == null) {	
			reader = BuildSource.makePacketSource();
        }
        else {
			reader = BuildSource.makePacketSource(source);
        }
		if (reader == null) {
			System.err.println("Invalid packet source (check your MOTECOM environment variable)");
			System.exit(2);
		}
		
		new Prober( reader ).start();

    }
}
