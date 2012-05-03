package it.nose.persistence.auth;

import it.nose.persistence.AbstractMongoDB;
import it.nose.persistence.PersistenceException;

import com.mongodb.BasicDBObject;
import com.mongodb.DBCollection;
import com.mongodb.DBObject;

public class AuthDB extends AbstractMongoDB {
	
	private static AuthDB instance;
	
	private static String dbName = "nose";

	private static String dbCollection = "auth";

	public static AuthDB instance() {
		if ( instance == null )
			instance = new AuthDB();
		return instance;
	}
	
	private AuthDB() {
		super(dbName, dbCollection);
	}

	public boolean isAuthorized(String username, String password) throws PersistenceException {
		BasicDBObject query = new BasicDBObject();
		query.put("username", username);
		query.put("password", password);
		DBCollection collection = getCollection();
		DBObject object = collection.findOne(query);
		return object != null;
	}
	
	public boolean deleteUser(String username, String password) throws PersistenceException {
		
		BasicDBObject query = new BasicDBObject();
		query.put("username", username);
		query.put("password", password);
		DBCollection collection = getCollection();
		DBObject object = collection.findOne(query);
		
		if ( object == null )
			return false;
		
		collection.remove(object);
		
		return true;
		
	}

	public DBObject registerUser(String username, String password) throws PersistenceException {

		if ( existsUser(username) )
			return null;

		DBObject object = new BasicDBObject();
		object.put("username", username);
		object.put("password", password);
		DBCollection collection = getCollection();
		collection.insert(object);
		return object;
		
	}
	
	public boolean updatePassword(String username, String oldPassword, String newPassword) throws PersistenceException {

		BasicDBObject query = new BasicDBObject();
		query.put("username", username);
		query.put("password", oldPassword);
		DBCollection collection = getCollection();
		DBObject object = collection.findOne(query);
		
		if ( object == null )
			return false;
		
		object.put("password", newPassword);
		collection.save(object);
		
		return object != null;

	}
	
	public boolean existsUser(String username) throws PersistenceException {
		BasicDBObject query = new BasicDBObject();
		query.put("username", username);
		DBCollection collection = getCollection();
		DBObject object = collection.findOne(query);
		return object != null;
	}
	
}
