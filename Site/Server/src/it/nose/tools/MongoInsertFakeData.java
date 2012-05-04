package it.nose.tools;

import it.nose.persistence.PersistenceException;
import it.nose.persistence.metric.MetricDB;
import it.nose.persistence.metric.MetricSerieDB;
import it.nose.persistence.metric.model.Metric;
import it.nose.persistence.metric.model.MetricSerie;
import it.nose.persistence.metric.utility.DateUtility;
import it.nose.persistence.metric.utility.Transformer;

import java.net.UnknownHostException;
import java.util.Date;
import java.util.Random;

import com.mongodb.BasicDBObject;
import com.mongodb.DBCollection;
import com.mongodb.DBCursor;
import com.mongodb.DBObject;
import com.mongodb.MongoException;

/**
 * This simple test class help to fill up data into MongoDB.
 * Given the code of an interface, it will verify if there are
 * data in the MongoDB. If no data are contained, the class will
 * add fake data starting from one year in the past to the present:
 * a metric per hour.
 * 
 * If there are some data, the system will add data from the last
 * measurement to the present.
 * 
 * @author Michele Mastrogiovanni
 */
public class MongoInsertFakeData {
	
	private MetricDB metrics;

	private MetricSerieDB metricsSerie;

	public static void main(String[] args) throws UnknownHostException, MongoException, PersistenceException {
		new MongoInsertFakeData();
	}
	
	public MongoInsertFakeData() throws PersistenceException {
		
		this.metrics = new MetricDB();
		
		String deviceToken = "device";
		String measureType = "metrics";
		
		// Clean all (fake data)
		metrics.dropDataOfDevice(null, null);
		// metrics.dropDataOfDevice(deviceToken, measureType);
		
		// Last date found
		DBObject object = metrics.getLastMetric(deviceToken, measureType);
		
		System.out.println("Last metric found: " + object);
				
		Metric metric = Transformer.transformDBObjectInMetric(object);
		
		System.out.println("Last metric found: " + metric);
		
		Date lastDate = null;
		
		if ( metric != null )
			lastDate = metric.getDate();
		
		System.out.println("Last date found: " + lastDate);
		
		if ( lastDate == null )
			lastDate = DateUtility.getHourDate(DateUtility.getPastYear(new Date()));
		
		fillUpData(lastDate, deviceToken, measureType);
		
		dumpAllData(deviceToken, measureType);
		
		System.out.println("Metric: '" + deviceToken + "', Type: '" + measureType + "'");
		System.out.println("First date: " + new Date((Long) metrics.getFirstMetric(deviceToken, measureType).get("date")));
		System.out.println("Last date: " + new Date((Long) metrics.getLastMetric(deviceToken, measureType).get("date")));
				
	}
	
	private void dumpAllData(String deviceToken, String measureType) throws PersistenceException {
		
		System.out.println("------------------ ALL DATA --------------------");
		
		DBCollection collection = metrics.getCollection();
		
		BasicDBObject query = new BasicDBObject();
		query.put("device", deviceToken);
		query.put("type", measureType);
		
		DBCursor cursor = collection.find(query).sort(new BasicDBObject("date", "-1"));
		while ( cursor.hasNext() ) {
			DBObject object = cursor.next();
			System.out.println(object);
		}
		
	}
	
	private void fillUpData(Date from, String device, String type) throws MongoException, PersistenceException {
		
		metricsSerie = new MetricSerieDB();
		MetricSerie serie = metricsSerie.getMetricSerie(device, type, true);
		System.out.println("Metric serie: " + serie);
		
		// Date nextDate = DateUtility.getHourDate(DateUtility.getNextHour(from));
		Date nextDate = DateUtility.getHourDate(DateUtility.getNextDay(from));

		while ( nextDate.getTime() < new Date().getTime() ) {
			
			Metric metric = new Metric(nextDate, 
					device, 
					type, 
					new Random().nextDouble() * 50 + 50);
			
			DBObject object = null;
			
			try {
				object = metrics.insertMetric(metric);
			} catch (PersistenceException e) {
				e.printStackTrace();
				break;
			}
			
			System.out.println("Inserted: " + object);
			
			// nextDate = DateUtility.getHourDate(DateUtility.getNextHour(nextDate));
			nextDate = DateUtility.getHourDate(DateUtility.getNextDay(nextDate));
		}
		
	}
		
}
