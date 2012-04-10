package it.nose.test;

import java.util.Date;

import com.mongodb.DBCursor;
import com.mongodb.DBObject;

import it.nose.persistence.PersistenceException;
import it.nose.persistence.metric.MetricDB;
import it.nose.persistence.metric.MetricSerieDB;
import it.nose.persistence.metric.model.MetricSerie;

public class MongoDumpAllMetrics {

	public static long getDate(DBObject object) {
		return (Long) object.get("date");
	}
	
	/**
	 * @param args
	 * @throws PersistenceException 
	 */
	public static void main(String[] args) throws PersistenceException {
		
		for ( MetricSerie serie : MetricSerieDB.instance().getMetricSeries() ) {
			
			System.out.println("MetricSerie: " + serie);
			
			long start = getDate(MetricDB.instance().getFirstMetric(serie.getDevice(), serie.getType()));
			long stop = getDate(MetricDB.instance().getLastMetric(serie.getDevice(), serie.getType()));
			System.out.println("* Start: " + new Date(start) + ", Stop: " + new Date(stop));

			DBCursor cursor = MetricDB.instance().getMetricsInDateInterval(start, stop, serie.getDevice(), serie.getType());

			while ( cursor.hasNext() ) {
				
				System.out.println("\t- " + cursor.next());
				
			}
			
		}

	}

}
