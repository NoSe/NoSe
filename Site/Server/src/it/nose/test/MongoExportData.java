package it.nose.test;

import it.nose.persistence.PersistenceException;
import it.nose.persistence.metric.MetricDB;
import it.nose.persistence.metric.utility.DateUtility;

import java.util.Date;


import com.mongodb.DBCursor;
import com.mongodb.DBObject;

public class MongoExportData {

	/**
	 * @param args
	 * @throws PersistenceException 
	 */
	public static void main(String[] args) throws PersistenceException {
		
		String deviceToken = "device";
		
		String measureType = "metrics";

		Date now = new Date();
		
		Date from = DateUtility.getPastWeek(now, 2);

		Date to = DateUtility.getPastWeek(now, 1);
		
		System.out.println("From: " + from.getTime());

		System.out.println("To: " + to.getTime());

		DBCursor cursor = MetricDB.instance().getMetricsInDateInterval(from.getTime(), to.getTime(), deviceToken, measureType);
		
		while ( cursor.hasNext() ) {
			
			DBObject object = cursor.next();
			System.out.println(object);
			
		}
		
		System.out.println("Ciao");
		
	}

}
