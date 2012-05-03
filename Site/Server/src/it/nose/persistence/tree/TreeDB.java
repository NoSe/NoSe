package it.nose.persistence.tree;

import it.nose.persistence.AbstractMongoDB;
import it.nose.persistence.PersistenceException;

import java.util.List;

import com.mongodb.BasicDBObject;
import com.mongodb.DBCollection;
import com.mongodb.DBCursor;
import com.mongodb.DBObject;
import com.mongodb.MongoException;
import com.mongodb.ObjectId;

public class TreeDB extends AbstractMongoDB {
	
	private static TreeDB instance;
	
	private static String dbName = "nose";

	private static String dbCollection = "tree";
	
	public static TreeDB instance() {
		if ( instance == null )
			instance = new TreeDB();
		return instance;
	}
	
	private TreeDB() {
		super(dbName, dbCollection);
	}
	
	public DBObject getNode(String id) throws PersistenceException {
		DBObject object = new BasicDBObject("_id", new ObjectId(id));
		DBCollection collection = getCollection();
		return collection.findOne(object);
	}
	
	public List<DBObject> search(DBObject query) throws PersistenceException {
		DBCollection collection = getCollection();
		DBCursor cursor = collection.find(query);
		return cursor.toArray();
	}

	public DBObject create() throws PersistenceException {
		DBObject object = new BasicDBObject();
		DBCollection collection = getCollection();
		collection.save(object);
		return object;
	}
			
	public DBObject getRoot() throws PersistenceException {
		BasicDBObject query = new BasicDBObject("parent", null);
		DBCollection collection = getCollection();
		DBCursor cursor = collection.find(query);
		if ( !cursor.hasNext() )
			return null;
		return cursor.next();
	}
	
	public void addChildren(DBObject node, DBObject parent) throws PersistenceException {
		node.put("parent", parent.get("_id"));
		DBCollection collection = getCollection();
		collection.save(node);
	}
	
	public List<DBObject> getChildren(DBObject node) throws PersistenceException {
		BasicDBObject query = new BasicDBObject("parent", node.get("_id"));
		DBCollection collection = getCollection();
		DBCursor cursor = collection.find(query);
		return cursor.toArray();
	}

	public void save(DBObject node) throws PersistenceException {
		DBCollection collection = getCollection();
		collection.save(node);
	}
	
	public void delete(DBObject node) throws PersistenceException {
		DBCollection collection = getCollection();
		collection.remove(node);		
	}
	
	public void clean() throws MongoException, PersistenceException {
		getCollection().remove(new BasicDBObject());
	}
	
}
