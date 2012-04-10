// $Id$

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

import java.util.*;
import java.text.*;
import java.io.*;

import net.tinyos.packet.*;
import net.tinyos.util.*;
import net.tinyos.message.*;

public class ContactDump implements MessageListener {
	
	private MoteIF moteIF;
	private CmdMsg cmd;
	
	public ContactDump(MoteIF moteIF, String nodeType) {
		this.moteIF = moteIF;
		this.moteIF.registerListener(new CmdMsg(), this);
		cmd = new CmdMsg();
		if (nodeType.equalsIgnoreCase("mobile")) {
			cmd.set_cmd_type((short)1);
		} else if (nodeType.equalsIgnoreCase("infrastructure")) {
			cmd.set_cmd_type((short)2);
			Date today = new Date();
			long reference_time = today.getTime();
			
			cmd.set_ref_time_m((int)(reference_time >> 32));
			cmd.set_ref_time_l((int)(reference_time & 0x00000000FFFFFFFF));
						
		}
		try {
			Thread.sleep(5000);
		} catch (InterruptedException ie) {}
		try {
			this.moteIF.send( MoteIF.TOS_BCAST_ADDR, cmd );
			System.out.println("FlushFlashMemory command sent, waiting for new packets");
		} catch(IOException ioe) {
			System.err.println("Warning: Got IOException sending reset message: "+ioe);
			ioe.printStackTrace();
		}
		this.moteIF.deregisterListener(new CmdMsg(), this);
		this.moteIF.registerListener(new ContactMsg(), this);	
	}
	
	public void messageReceived(int to, Message message) {
		ContactMsg msg = (ContactMsg)message;
		SimpleDateFormat sdf = new SimpleDateFormat( "mm:ss:SS" );
		  System.err.print( sdf.format( new Date() ) + "\t" );
		  
		  //System.out.println( serial.toString() );
		  
		  long timestamp = ((long)msg.get_time_stamp_m() & 0x00000000FFFFFFFF);
		  timestamp = timestamp << 32;
		  timestamp += ((long)msg.get_time_stamp_l() & 0x00000000FFFFFFFF);
		  		  
		  Date packet_time = new Date(timestamp); 
		  
		  System.out.println(new Date().toString()+" "+packet_time.toString()+" "+msg.get_channel_ID()+" "+msg.get_pot()+" "+msg.get_len()+" "         
                           +msg.get_source()+" "+msg.get_neigh_ID()+" "+msg.get_pkt_ID()+" "+msg.get_rssi()+" "+msg.get_lqi());
		
	}
		
    public static void main(String args[]) throws IOException {
        String source = null;
        String nodeType = null;
        if (args.length == 3 && args[0].equals("-comm")) {
          source = args[1];
          nodeType = args[2];
        } else if (args.length >= 0) {
        	System.err.println("usage: java ContactDump [-comm PACKETSOURCE]");
        	System.err.println("       (default packet source from MOTECOM environment variable)");
        	System.exit(2);
        }
        if (source != null) {
        	PhoenixSource phoenix = BuildSource.makePhoenix(source, PrintStreamMessenger.err);
            MoteIF mif = new MoteIF(phoenix);
            ContactDump dump = new ContactDump(mif, nodeType);
        } 
	
    }
}

