package it.nose.test;

import java.io.File;

import com.mongodb.BasicDBObject;
import com.mongodb.DBObject;

import it.nose.persistence.PersistenceException;
import it.nose.persistence.tree.TreeDB;

public class TreeTest {
	
	private static void createTree(File file, DBObject parent) throws PersistenceException {
		
		DBObject node = TreeDB.instance().create();
		node.put("path", file.getAbsolutePath());
		
		if ( parent != null )
			node.put("parent", parent.get("_id"));

		if ( file.isDirectory() ) {

			node.put("type", "dir");
			TreeDB.instance().save(node);
			
			for ( File child : file.listFiles()) {
				createTree(child, node);
			}
			
		}
		else {
			
			node.put("type", "file");
			TreeDB.instance().save(node);
			
		}
	}
	
	private static void ensureRoot(String path) throws PersistenceException {
		DBObject root = TreeDB.instance().getRoot();
		if ( root == null ) {
			System.out.println("Root does not exists");
			root = TreeDB.instance().create();
			root.put("path", path);
			root.put("type", "dir");
			TreeDB.instance().save(root);
		}
		System.out.println("Root: " + root);
	}

	private static void printTabs(int tabs) {
		for ( int i = 0; i < tabs; i ++ )
			System.out.print("\t");
	}

	private static void dumpTree(DBObject node, int tabs) throws PersistenceException {
		printTabs(tabs);
		System.out.println(node);
		for ( DBObject child : TreeDB.instance().getChildren(node)) {
			dumpTree(child, tabs + 1);
		}
	}

	private static void dumpTree() throws PersistenceException {
		System.out.println("Tree:");
		dumpTree(TreeDB.instance().getRoot(), 0);
	}
	
	private static void dumpSearch(String regexp) throws PersistenceException {
		System.out.println("Search regular expression:");
		for ( DBObject child : TreeDB.instance().search(new BasicDBObject("path", new BasicDBObject("$regex", regexp)))) {
			System.out.println("Found: " + child);
		}		
	}
	
	/**
	 * @param args
	 * @throws PersistenceException 
	 */
	public static void main(String[] args) throws PersistenceException {
		
		// String path = "/home/michele/trunk";
		String path = "/Users/mastrogiovannim/Public";
		
		TreeDB.instance().clean();
		
		createTree(new File(path), null);

		dumpTree();
		
		dumpSearch(".*Drop.*");
		
	}
	
}
