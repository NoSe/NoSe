package org.nose.test;

import java.util.ArrayList;

import org.nose.tree.INode;
import org.nose.tree.TreeService;
import org.springframework.context.support.ClassPathXmlApplicationContext;

public class TestTree {
	
	/**
	 * @param args
	 * @throws Exception 
	 */
	public static void main(String[] args) throws Exception {
		
	    ClassPathXmlApplicationContext ctx = new ClassPathXmlApplicationContext("WEB-INF/spring.xml");
	    
	    TreeService service = (TreeService) ctx.getBean("treeService");
	    
	    INode root = service.createNode(null, "root", "folder", null);
	    
	    ArrayList<String> list = new ArrayList<String>();

	    list.add("michele");
	    list.add("andrea");
	    list.add("luca");
	    
	    INode child1 = service.createNode(root, "child1", "instrument", list);
	    INode child2 = service.createNode(root, "child2", "instrument", null);

	    service.createNode(child1, "pippo", "instrument", null);
	    
	    // service.dumpTree();
	    
	    service.renameNode(child1.getId(), "Child1");
	    service.renameNode(child2.getId(), "Child2");
	    service.renameNode(root.getId(), "Root");

	    // service.dumpTree();
	    
	    // service.removeNode(child1.getId());
	    
	    // service.dumpTree();
	    	    
	    root = service.getNode(root.getId());
	    
	    System.out.println(service.getChildrenOf(root.getId()));
		
	    System.out.println(service.search("%Child%"));

	}

}
