package org.nose.servlet;

import java.io.IOException;
import java.util.List;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.mongodb.util.JSON;

/**
 * This servlet allows to put data inside the main system.
 * Data are stored into a MongoDB
 */
public class DataImporterServlet extends HttpServlet {
	
	private static final long serialVersionUID = 1L;
       
    /**
     * @see HttpServlet#HttpServlet()
     */
    public DataImporterServlet() {
        super();
    }
    
    private void serve(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
    	String data = request.getParameter("data");
    	Object value = JSON.parse(data);
    	if (!( value instanceof List )) {
    		return;
    	}
    	@SuppressWarnings("unchecked")
		List<Object> list = (List<Object>) value;
    	System.out.println(list);
    }

	/**
	 * @see HttpServlet#doGet(HttpServletRequest request, HttpServletResponse response)
	 */
	protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		serve(request, response);
	}

	/**
	 * @see HttpServlet#doPost(HttpServletRequest request, HttpServletResponse response)
	 */
	protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		serve(request, response);
	}

}
