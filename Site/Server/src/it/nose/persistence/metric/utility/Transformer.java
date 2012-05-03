package it.nose.persistence.metric.utility;

import it.nose.persistence.metric.model.Metric;
import it.nose.persistence.metric.model.MetricSerie;

import java.util.Date;

import com.mongodb.BasicDBObject;
import com.mongodb.DBObject;
import com.mongodb.ObjectId;

public class Transformer {

	public static DBObject transformMetricSerieInDBObject(MetricSerie metricSerie) {
		BasicDBObject object = new BasicDBObject();
		object.put("device", metricSerie.getDevice());
		object.put("type", metricSerie.getType());
		object.put("metadata", new BasicDBObject(metricSerie.getMetadata()));
		if ( metricSerie.getId() != null )
			object.put("_id", new ObjectId(metricSerie.getId()));
		return object;
	}
	
	@SuppressWarnings("unchecked")
	public static MetricSerie transformDBObjectInMetricSerie(DBObject object) {
		
		if ( object == null )
			return null;
		
		String device = (String) object.get("device");
		String type = (String) object.get("type");
		DBObject metadata = (DBObject) object.get("metadata");

		MetricSerie metric = new MetricSerie(device, type);

		ObjectId id = (ObjectId) object.get("_id");
		if ( id != null )
			metric.setId(id.toString());

		if ( metadata != null )
			metric.setMetadata(metadata.toMap());
		
		return metric;
		
	}

	public static DBObject transformMetricInDBObject(Metric metric) {
		BasicDBObject object = new BasicDBObject();
		object.put("date", metric.getDate().getTime());
		object.put("device", metric.getDevice());
		object.put("type", metric.getType());
		object.put("status", metric.getStatus());
		object.put("value", metric.getValue());
		if ( metric.getId() != null )
			object.put("_id", new ObjectId(metric.getId()));
		return object;
	}

	public static Metric transformDBObjectInMetric(DBObject object) {
		
		if ( object == null )
			return null;
		
		Date date = new Date((Long) object.get("date"));
		String device = (String) object.get("device");
		String type = (String) object.get("type");
		int status = (Integer) object.get("status");
		double value = (Double) object.get("value"); 

		Metric metric = new Metric(date, device, type, status, value);

		ObjectId id = (ObjectId) object.get("_id");
		if ( id != null )
			metric.setId(id.toString());
		
		return metric;
		
	}

}
