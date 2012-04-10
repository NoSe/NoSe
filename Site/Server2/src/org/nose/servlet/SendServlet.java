package org.nose.servlet;

import java.io.IOException;
import java.io.OutputStream;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.tomcat.util.http.fileupload.servlet.ServletFileUpload;

public class SendServlet extends HttpServlet {

	@Override
	protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {

		OutputStream op = resp.getOutputStream();
		
		int BUFSIZE = 1024;
		
		String mimetype = "text/plain";
		
		String original_filename = "pippo.txt";

		int tot = 1024 * 1024 * 1024 * 2;
		
		resp.setContentType( (mimetype != null) ? mimetype : "application/octet-stream" );
		resp.setContentLength( tot );
		resp.setHeader( "Content-Disposition", "attachment; filename=\"" + original_filename + "\"" );

//		while (tot > 0) {
//			op.write(bbuf, 0, length);
//		}

		op.flush();
		op.close();

	}

}
