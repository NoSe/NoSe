
import java.util.*;
import java.text.*;
import java.io.*;

import net.tinyos.packet.*;
import net.tinyos.util.*;
import net.tinyos.message.*;

public class Main implements MessageListener {
	
	private MoteIF moteIF;
	private CommandMsg cmd;
	
	public Main(MoteIF moteIF) {
		this.moteIF = moteIF;
		this.moteIF.registerListener(new NeighborsMsg(), this);
		cmd = new CommandMsg();
		cmd.set_type((short) 10);
		try {
			Thread.sleep(1000);
		} catch (InterruptedException ie) {}
		try {
			this.moteIF.send( MoteIF.TOS_BCAST_ADDR, cmd );
			System.out.println("Send neighbors query");
		} catch(IOException ioe) {
			System.err.println("Warning: Got IOException sending reset message: "+ioe);
            ioe.printStackTrace();
		}
		// this.moteIF.deregisterListener(new CommandMsg(), this);
		// this.moteIF.registerListener(new ChannelMsg(), this);
	}
	
	public void messageReceived(int to, Message message) {
		if ( message instanceof NeighborsMsg ) {
			NeighborsMsg neighborsMsg = (NeighborsMsg) message;
			System.out.println("Neighbors: " + neighborsMsg.get_length());
			int[] nodes = neighborsMsg.get_node();
			for ( int i = 0; i < neighborsMsg.get_length(); i ++ ) {
				System.out.println("Node: " + nodes[i]);
			}
		}
		/*
		ChannelMsg msg = (ChannelMsg)message;
		SimpleDateFormat sdf = new SimpleDateFormat( "mm:ss:SS" );
		  System.out.print( sdf.format( new Date() ) + "\t" );
		  
		  //System.out.println( serial.toString() );
		  
		  System.out.println(new Date().toString()+" "+msg.get_channel_ID()+" "+msg.get_pot()+" "+msg.get_len()+" "         
                           +msg.get_source()+" "+msg.get_neigh_ID()+" "+msg.get_pkt_ID()+" "+msg.get_num_pkts()+" "+msg.get_rssi()+" "+msg.get_lqi());
		*/
	}
		
    public static void main(String args[]) throws IOException {
        String source = null;
        if (args.length == 2 && args[0].equals("-comm")) {
          source = args[1];
        } else if (args.length >= 0) {
        	System.err.println("usage: java net.tinyos.tools.Listen [-comm PACKETSOURCE]");
        	System.err.println("       (default packet source from MOTECOM environment variable)");
        	System.exit(2);
        }
        if (source != null) {
        	PhoenixSource phoenix = BuildSource.makePhoenix(source, PrintStreamMessenger.err);
            MoteIF mif = new MoteIF(phoenix);
            Main dump = new Main(mif);
        } 
	
    }
}

