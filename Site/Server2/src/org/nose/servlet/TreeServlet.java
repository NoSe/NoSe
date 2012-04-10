package org.nose.servlet;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Enumeration;
import java.util.List;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.codehaus.jackson.map.ObjectMapper;
import org.nose.tree.INode;
import org.nose.tree.TreeService;
import org.springframework.context.support.ClassPathXmlApplicationContext;
import org.springframework.web.context.WebApplicationContext;
import org.springframework.web.context.support.WebApplicationContextUtils;

import com.mongodb.BasicDBObject;

/**
 * Servlet implementation class Tree
 */
public class TreeServlet extends HttpServlet {
	
	private static final long serialVersionUID = 1L;
       
    /**
     * @see HttpServlet#HttpServlet()
     */
    public TreeServlet() {
        super();
    }
    
    @SuppressWarnings("unchecked")
	public void dumpParameters(HttpServletRequest request) {
    	System.out.println("Parameters:");
		Enumeration<String> e = request.getParameterNames();
    	while ( e.hasMoreElements() ) {
    		String key = e.nextElement();
    		Object value = request.getParameter(key);
    		System.out.println("\t" + key + "=" + value);
    	}
    	System.out.println("Attributes:");
    	e = (Enumeration<String>) request.getAttributeNames();
    	while ( e.hasMoreElements() ) {
    		String key = e.nextElement();
    		Object value = request.getAttribute(key);
    		System.out.println("\t" + key + "=" + value);
    	}
    	System.out.println("-------------------------------");
    }
    
    public BasicDBObject createNode(String id, String name) {
    	
		BasicDBObject node = new BasicDBObject();

		BasicDBObject attr = new BasicDBObject();
		attr.append("pippo", "sempronio");
		attr.append("id", id);
    	
		BasicDBObject data = new BasicDBObject();
		data.append("title", name);
		data.append("attr", attr);
		data.append("icon", "folder");
		
		node.append("data", data);
		node.append("state", "closed");
		
		return node;
    }

    protected void process(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {

		dumpParameters(request);

		if ("search".equals(request.getParameter("operation"))) {
			String search_str = request.getParameter("search_str");
			System.out.println(search_str);
			response.getWriter().append("[ 1, 2, 3 ]");
			return;
		}
				
		if ("get_children".equals(request.getParameter("operation"))) {
			String id = request.getParameter("id");
			WebApplicationContext ctx = WebApplicationContextUtils.getWebApplicationContext(getServletContext());
		    TreeService service = (TreeService) ctx.getBean("treeService");
			if ( id == null ) {
				List<INode> list = service.getChildrenOf(null);
				ObjectMapper mapper = new ObjectMapper();
				String value = mapper.writeValueAsString(list);
				response.getWriter().append(value);
				System.out.println(value);
			}
			else {
				System.out.println(id.getClass());
				List<INode> list = service.getChildrenOf(Long.parseLong(id));
				ObjectMapper mapper = new ObjectMapper();
				String value = mapper.writeValueAsString(list);
				response.getWriter().append(value);
				System.out.println(value);
			}

			/*
			// BasicDBObject node = createNode(id);
			BasicDBObject node1 = createNode(id + "1");
			BasicDBObject node2 = createNode(id + "2");
			ArrayList<BasicDBObject> children = new ArrayList<BasicDBObject>(2);
			children.add(node1);
			children.add(node2);
			
			// node.append("children", children);
			// System.out.println(node.toString());
			// response.getWriter().append(node.toString());
			
			response.getWriter().append(children.toString());
			*/
			
		}
		
		if ("remove_node".equals(request.getParameter("operation"))) {
			// id=identificator
		}
		
		if ("rename_node".equals(request.getParameter("operation"))) {
			// operation=rename_node
			// id=identificator
			// title=michele
		}

    }
    
    
	/**
	 * @see HttpServlet#doGet(HttpServletRequest request, HttpServletResponse response)
	 */
	protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		System.out.println("GET");
		process(request, response);
	}

	/**
	 * @see HttpServlet#doPost(HttpServletRequest request, HttpServletResponse response)
	 */
	protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		System.out.println("POST");
		process(request, response);
	}

}
