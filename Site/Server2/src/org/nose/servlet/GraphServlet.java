package org.nose.servlet;

import java.io.IOException;
import java.net.UnknownHostException;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.mongodb.DB;
import com.mongodb.DBCollection;
import com.mongodb.DBCursor;
import com.mongodb.DBObject;
import com.mongodb.Mongo;
import com.mongodb.MongoException;

/**
 * Servlet implementation class Graph
 */
public class GraphServlet extends HttpServlet {
	
	private static final long serialVersionUID = 1L;
	
	private Mongo mongo;
       
    /**
     * @see HttpServlet#HttpServlet()
     */
    public GraphServlet() {
        super();
        try {
			mongo = new Mongo();
		} catch (UnknownHostException e) {
			e.printStackTrace();
		} catch (MongoException e) {
			e.printStackTrace();
		}
    }

	/**
	 * @see HttpServlet#doGet(HttpServletRequest request, HttpServletResponse response)
	 */
	protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		response.getWriter().append("<html>");
		response.getWriter().append("<body>");
		DB db = mongo.getDB( "mydb" );
		DBCollection collection = db.getCollection("testCollection");
        DBCursor curs = collection.find();
		response.getWriter().append("<ul>");
        while ( curs.hasNext() ) {
        	DBObject object = curs.next();
        	response.getWriter().append(object.toString() + "<br/>");
        	// System.out.println("-- " + object);
        }
		response.getWriter().append("</ul>");
		response.getWriter().append("</body>");
		response.getWriter().append("</html>");
	}

	/**
	 * @see HttpServlet#doPost(HttpServletRequest request, HttpServletResponse response)
	 */
	protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		// TODO Auto-generated method stub
	}

}
