package org.nose.test;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStream;

public class TestDisk {

	/**
	 * @param args
	 * @throws IOException 
	 */
	public static void main(String[] args) throws IOException {
		File file = new File("/Users/mastrogiovannim/test.txt");
		OutputStream out = new FileOutputStream(file);
		long size = 1024L * 1024L * 1024L * 2L;
		byte[] buffer = new byte[1024];
		while ( size > 0 ) {
			out.write(buffer, 0, 1024);
			size -= 1024;
			System.out.println("Size: " + size);
		}
		out.close();
	}

}
