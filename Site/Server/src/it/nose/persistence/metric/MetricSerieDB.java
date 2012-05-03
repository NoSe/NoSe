package it.nose.persistence.metric;


import java.util.ArrayList;
import java.util.List;
import java.util.Set;

import it.nose.persistence.AbstractMongoDB;
import it.nose.persistence.PersistenceException;
import it.nose.persistence.metric.model.MetricSerie;
import it.nose.persistence.metric.utility.Transformer;

import com.mongodb.BasicDBObject;
import com.mongodb.DBCursor;
import com.mongodb.DBObject;
import com.mongodb.MongoException;
import com.mongodb.util.Pair;

public class MetricSerieDB extends AbstractMongoDB {
	
	private static MetricSerieDB instance;
	
	private static String dbName = "nose";

	private static String dbCollection = "series";
	
	public static MetricSerieDB instance() {
		if ( instance == null )
			instance = new MetricSerieDB();
		return instance;
	}
	
	private MetricSerieDB() {
		super(dbName, dbCollection);
	}
	
	/**
	 * Save a metric serie: if serie does not exist than create
	 * a new one
	 * 
	 * @param metric Metric serie
	 * @throws PersistenceException 
	 * @throws MongoException 
	 */
	public boolean save(MetricSerie metric) throws MongoException, PersistenceException {
		if ( metric.getDevice() == null )
			throw new IllegalArgumentException("Metric 'devices' cannot be null");
		if ( metric.getType() == null )
			throw new IllegalArgumentException("Metric 'type' cannot be null");
		DBObject query = new BasicDBObject("device", metric.getDevice()).append("type", metric.getType());
		DBObject metricSerie = getCollection().findOne(query);
		if ( metricSerie == null ) {
			metricSerie = query;
			if ( metric.getMetadata() != null )
				metricSerie.put("metadata", new BasicDBObject(metric.getMetadata()));
			getCollection().save(metricSerie);
			return true;
		}
		else {
			if ( metric.getMetadata() != null )
				metricSerie.put("metadata", new BasicDBObject(metric.getMetadata()));
			getCollection().save(metricSerie);
			return false;
		}
	}
	
	/**
	 * Return a metric if it exists or create a new one with such name
	 * 
	 * @param device Device name
	 * @param type Type of metric serie
	 * @param create If this flag is true, if metric is not found than 
	 * it creates a new one.
	 * @return Metric serie
	 */
	public MetricSerie getMetricSerie(String device, String type, boolean create) throws MongoException, PersistenceException {
		if ( device == null )
			throw new IllegalArgumentException("Metric 'devices' cannot be null");
		if ( type == null )
			throw new IllegalArgumentException("Metric 'type' cannot be null");
		DBObject query = new BasicDBObject("device", device).append("type", type);
		DBObject metricSerie = getCollection().findOne(query);
		if ( metricSerie == null ) {
				metricSerie = new BasicDBObject("device", device).append("type", type);
				getCollection().save(metricSerie);
		}
		return Transformer.transformDBObjectInMetricSerie(metricSerie);
	}
	
	public boolean delete(MetricSerie metric) throws MongoException, PersistenceException {
		if ( metric.getDevice() == null )
			throw new IllegalArgumentException("Metric 'devices' cannot be null");
		if ( metric.getType() == null )
			throw new IllegalArgumentException("Metric 'type' cannot be null");
		DBObject query = new BasicDBObject("device", metric.getDevice()).append("type", metric.getType());
		DBObject metricSerie = getCollection().findOne(query);
		if ( metricSerie == null )
			return false;
		getCollection().remove(metricSerie);
		return true;
	}

	public void synchronizeAllMetricSeries() throws PersistenceException {
		Set<Pair<String, String>> series = MetricDB.instance().getAllDeviceAndType();
		for ( Pair<String, String> serie : series ) {
			getMetricSerie(serie.first, serie.second, true);
		}
	}
	
	public List<MetricSerie> getMetricSeries() throws PersistenceException {
		List<MetricSerie> list = new ArrayList<MetricSerie>();
		DBCursor cursor = getCollection().find();
		while ( cursor.hasNext() ) {
			list.add(Transformer.transformDBObjectInMetricSerie(cursor.next()));
		}
		return list;
	}
	
}