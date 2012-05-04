// $Id$

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
Y
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

public class ChannelDump implements MessageListener {
	
	private MoteIF moteIF;
	private CmdMsg cmd;
	
	public ChannelDump(MoteIF moteIF) {
		this.moteIF = moteIF;
		this.moteIF.registerListener(new CmdMsg(), this);
		cmd = new CmdMsg();
		cmd.set_cmd_type((short)10);
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
		this.moteIF.registerListener(new ChannelMsg(), this);
	}
	
	public void messageReceived(int to, Message message) {
		ChannelMsg msg = (ChannelMsg)message;
		SimpleDateFormat sdf = new SimpleDateFormat( "mm:ss:SS" );
		  System.out.print( sdf.format( new Date() ) + "\t" );
		  
		  //System.out.println( serial.toString() );
		  
		  System.out.println(new Date().toString()+" "+msg.get_channel_ID()+" "+msg.get_pot()+" "+msg.get_len()+" "         
                           +msg.get_source()+" "+msg.get_neigh_ID()+" "+msg.get_pkt_ID()+" "+msg.get_num_pkts()+" "+msg.get_rssi()+" "+msg.get_lqi());
		
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
            ChannelDump dump = new ChannelDump(mif);
        } 
	
    }
}

