package it.nose.test;

import it.nose.persistence.PersistenceException;
import it.nose.persistence.metric.MetricDB;
import it.nose.persistence.metric.model.Status;

public class MongoSetStatus {

	/**
	 * @param args
	 * @throws PersistenceException 
	 */
	public static void main(String[] args) throws PersistenceException {
		
		String id = "4f351703eef8b0e43d154581";

		System.out.println(MetricDB.instance().getMetric(id));
		
		MetricDB.instance().setStatus(id, Status.VALID);

		System.out.println(MetricDB.instance().getMetric(id));

//		MongoService.instance().setStatus(id, Status.TO_VALIDATE);
//
//		System.out.println(MongoService.instance().getMetric(id));

	}

}
