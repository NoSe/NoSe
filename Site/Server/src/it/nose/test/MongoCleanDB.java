package it.nose.test;

import it.nose.persistence.PersistenceException;
import it.nose.persistence.metric.MetricDB;

public class MongoCleanDB {

	/**
	 * @param args
	 * @throws PersistenceException 
	 */
	public static void main(String[] args) throws PersistenceException {

		MetricDB.instance().dropDataOfDevice("pippo", "temperature");

		MetricDB.instance().dropDataOfDevice(null, null);

	}

}
