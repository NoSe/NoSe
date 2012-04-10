package org.nose.servlet;

import java.io.BufferedReader;
import java.io.DataInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.tomcat.util.http.fileupload.FileItemIterator;
import org.apache.tomcat.util.http.fileupload.FileItemStream;
import org.apache.tomcat.util.http.fileupload.MultipartStream;
import org.apache.tomcat.util.http.fileupload.servlet.ServletFileUpload;
import org.apache.tomcat.util.http.fileupload.util.Streams;
import org.springframework.web.multipart.MultipartHttpServletRequest;

public class ReceiveServlet extends HttpServlet {

	private static final long serialVersionUID = 1L;
	
	private void dump(float tot) {
		tot /= 1024;
		if ( tot < 1024 ) {
			System.out.println("Readed: " + tot + " kb" );
			return;
		}
		tot /= 1024;
		if ( tot < 1024 ) {
			System.out.println("Readed: " + tot + " Mb" );
			return;
		}
		tot /= 1024;
		System.out.println("Readed: " + tot + " Gb" );
	}

	private void serve(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {

		boolean isMultipart = ServletFileUpload.isMultipartContent(request);
		if ( ! isMultipart )
			return;
			
		// Create a new file upload handler
		ServletFileUpload upload = new ServletFileUpload();

		try {
			// Parse the request
			FileItemIterator iter = upload.getItemIterator(request);
			while (iter.hasNext()) {
				FileItemStream item = iter.next();
				String name = item.getFieldName();
				InputStream stream = item.openStream();
				if (item.isFormField()) {
					System.out.println("Form field " + name + " with value " + Streams.asString(stream) + " detected.");
				} else {
					System.out.println("File field " + name + " with file name " + item.getName() + " detected.");
					System.out.println("Starting");
					byte[] buffer = new byte[1024 * 1024];
					long tot = 0;
					int len;
					while ( true ) {
						len = stream.read(buffer, 0, 1024 * 1024);						
						if ( len <= 0 )
							break;
						tot += len;
						dump((float) tot);
					}
					System.out.println("DONE");
				}
			}
		}
		catch (Exception e) {
			e.printStackTrace();
		}
	}

	@Override
	protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
		serve(req, resp);
	}

	@Override
	protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
		serve(req, resp);
	}

}
