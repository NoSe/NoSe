import java.io.*;
import net.tinyos.packet.*;
import net.tinyos.util.*;
import net.tinyos.message.*;
import java.text.*;
import java.sql.Timestamp;

import java.io.IOException;
import java.util.*;

import net.tinyos.message.*;
import net.tinyos.packet.*;
import net.tinyos.util.*;

import java.lang.*;
import java.util.LinkedList;
import java.lang.Math;
import java.math.BigInteger;
import java.lang.Integer;
import java.lang.Double;
import java.util.StringTokenizer;
import java.util.Arrays;
import java.util.HashMap;

public class analyzeMoMo {
	
	String filename = null;
	int cont = 0;
	
	public analyzeMoMo(String file) {
		
		filename = file;
		
	};
	
	
	public void readLog() {
		
		String inputLine = null, line = null;
		StringTokenizer st = null;
		BufferedReader is = null;
		
		
		try{
			is=new BufferedReader(new InputStreamReader(new FileInputStream(filename)));
			
			while ((inputLine=is.readLine())!=null) {
				extractMessage(inputLine);
			}
			is.close();
			//System.out.println("MN: "+cont);
		}catch(IOException io){} 
		
		st=null;
		is=null;    
		
	};
	
	public void extractMessage(String log) {
		
		int type = 0;
		String time = null;
		
		String[] fields = log.split(" ");
		String[] metadata = null;
		byte[] data = null;
		
		if(fields.length > 3) {
			
			if( Integer.parseInt(fields[1]) < 0 ) return;
			
			metadata = fields[3].split(":");
			
			data = new byte[metadata.length];
		
			for (int i = 0; i < data.length; i++) {
				data[i] = Byte.parseByte(metadata[i]);
			}
		}
		
		type = Integer.parseInt(fields[1]);
		
		try {
			
			switch(type) {
			
				case 0: {
					RecvMsg msg = new RecvMsg(data);
					System.out.println(fields[1]+" "+fields[0]+" "+fields[2]+" "+msg.get_sample()+" "+msg.get_pkt_num()+" "+msg.get_serial()+" "+msg.get_age());
					break;
				}
				case 1: {
					GenMsg msg = new GenMsg(data);
					System.out.println(fields[1]+" "+fields[0]+" "+fields[2]+" "+msg.get_pkt_num()+" "+msg.get_serial());
					break;
				}
				case 2: {
					SentMsg msg = new SentMsg(data);
					System.out.println(fields[1]+" "+fields[0]+" "+fields[2]+" "+msg.get_pkt_num()+" "+msg.get_serial()+" "+msg.get_error());
					break;
				}
				default:
					break;
			}
		} catch(NullPointerException e) {
			//e.printStackTrace();
			cont ++;
		}
	};
	
	public static void main(String s[]) {
		
		//arg[0] = filename
		
		analyzeMoMo anal = new analyzeMoMo(s[0]);
		anal.readLog();
		
	};	
	
}