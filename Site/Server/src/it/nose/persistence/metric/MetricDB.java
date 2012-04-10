package it.nose.persistence.metric;

import it.nose.persistence.AbstractMongoDB;
import it.nose.persistence.PersistenceException;
import it.nose.persistence.metric.model.Metric;
import it.nose.persistence.metric.model.MetricSerie;
import it.nose.persistence.metric.utility.Transformer;

import java.util.HashSet;
import java.util.List;
import java.util.Set;

import com.mongodb.BasicDBList;
import com.mongodb.BasicDBObject;
import com.mongodb.DBCollection;
import com.mongodb.DBCursor;
import com.mongodb.DBObject;
import com.mongodb.util.Pair;

/**
 * This class is responsible to save/load/query NoSe data
 * from Mongo db.
 * 
 * @author Michele Mastrogiovanni
 */
public class MetricDB extends AbstractMongoDB {
	
	private static MetricDB instance;
	
	private static String dbName = "org.nose.db";

	private static String dbCollection = "org.nose.collection";
	
	public static MetricDB instance() {
		if ( instance == null )
			instance = new MetricDB();
		return instance;
	}
	
	private MetricDB() {
		super(dbName, dbCollection);
	}
			
	public void dropDataOfDevice(String device, String type) throws PersistenceException {
		BasicDBObject query = new BasicDBObject();
		if ( device != null )
			query.put("device", device);
		if ( type != null )
			query.put("type", type);
		DBCollection coll = getCollection();
		coll.remove(query);
	}
	
	public DBObject insertMetric(Metric metric) throws PersistenceException {
		DBObject object = Transformer.transformMetricInDBObject(metric);
		DBCollection collection = getCollection();
		collection.insert(object);
		return object;
	}

	public DBObject getFirstMetric(String device, String type) throws PersistenceException {
		
		BasicDBObject query = new BasicDBObject();
		if ( device != null )
			query.put("device", device);
		if ( type != null )
		query.put("type", type);
		
		DBCollection collection = getCollection();
		DBCursor cursor = collection.find(query).sort(new BasicDBObject("date", 1)).limit(1);
		
		if ( !cursor.hasNext() )
			return null;
		
		return cursor.next();
		
	}

	public DBObject getLastMetric(String device, String type) throws PersistenceException {
		
		BasicDBObject query = new BasicDBObject();
		
		if ( device != null )
			query.put("device", device);
		if ( type != null )
			query.put("type", type);
		
		DBCollection collection = getCollection();
		DBCursor cursor = collection.find(query).sort(new BasicDBObject("date", -1)).limit(1);
		
		if ( !cursor.hasNext() )
			return null;
		
		return cursor.next();
		
	}
	
	public DBCursor getMetricsInDateInterval(long from, long to, String device, String type) throws PersistenceException {
		BasicDBObject query = new BasicDBObject();
		query.put("device", device);
		query.put("type", type);
		query.put("date", new BasicDBObject("$gt", from).append("$lte", to));
		DBCollection collection = getCollection();
		return collection.find(query).sort(new BasicDBObject("date", -1));
	}
	
	public DBObject getMetric(String id) throws PersistenceException {
		BasicDBObject query = new BasicDBObject();
		query.put("_id", id);
		DBCollection collection = getCollection();
		return collection.findOne();
	}

	public DBObject setStatus(String id, int status) throws PersistenceException {
		BasicDBObject query = new BasicDBObject();
		query.put("_id", id);
		DBCollection collection = getCollection();
		DBObject object = collection.findOne();
		object.put("status", status);
		collection.save(object);
		return object;
	}
	
	public Set<Pair<String, String>> getAllDeviceAndType() throws PersistenceException {
		Set<Pair<String, String>> set = new HashSet<Pair<String, String>>();
		DBCursor cursor = getCollection().find(new BasicDBObject(), new BasicDBObject("device", 1).append("type", 1));
		while ( cursor.hasNext() ) {
			DBObject metric = cursor.next();
			Pair<String, String> pair = new Pair<String, String>((String) metric.get("device"), (String) metric.get("type"));
			set.add(pair);
		}
		return set;
	}

	public DBCursor getMetricsInDateInterval(long from, long to, List<MetricSerie> series) throws PersistenceException {
		BasicDBList list = new BasicDBList();
		for ( MetricSerie serie : series ) {
			list.add(new BasicDBObject("device", serie.getDevice()).append("type", serie.getType()));
		}
		BasicDBObject query = new BasicDBObject("$or", list).append("date", new BasicDBObject("$gt", from).append("$lte", to));
		return getCollection().find(query);
	}

}
