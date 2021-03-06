package it.nose.persistence;

import java.net.UnknownHostException;

import com.mongodb.BasicDBObject;
import com.mongodb.DB;
import com.mongodb.DBAddress;
import com.mongodb.DBCollection;
import com.mongodb.Mongo;
import com.mongodb.MongoException;

public class AbstractMongoDB {

	private static Mongo mongo;
	
	private String dbName;

	private String dbCollection;

	public AbstractMongoDB(String dbName, String dbCollection) {
		this(null, dbName, dbCollection);
	}

	public AbstractMongoDB(DBAddress address, String dbName, String dbCollection) {
		try {
			if ( mongo == null ) {
				if ( address == null )
					mongo = new Mongo();
				else
					mongo = new Mongo(address);
			}
			this.dbName = dbName;
			this.dbCollection = dbCollection;
			// System.out.println("Mongo connection: open");
		} catch (UnknownHostException e) {
			e.printStackTrace();
		} catch (MongoException e) {
			e.printStackTrace();
		}
	}
	
	public void dropDB() {
		DB db = mongo.getDB( dbName );
		if ( db == null )
			return;
		mongo.dropDatabase(dbName);
	}

	public DBCollection getCollection() throws PersistenceException {
		DB db = mongo.getDB( dbName );
		DBCollection coll = db.getCollection( dbCollection );
		if ( coll != null )
			return coll;
		coll = db.createCollection(dbCollection, new BasicDBObject());
		if ( coll == null )
			throw new PersistenceException("Cannot get collection '" + dbCollection + "' from MongoDB");
		return coll;
	}

	public Mongo getMongo() {
		return mongo;
	}

	public String getDbName() {
		return dbName;
	}

	public String getDbCollection() {
		return dbCollection;
	}

}
