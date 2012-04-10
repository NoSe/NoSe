package it.nose.test;

import it.nose.persistence.PersistenceException;
import it.nose.persistence.metric.MetricSerieDB;
import it.nose.persistence.metric.model.MetricSerie;

public class MetricSerieDump {

	public static void dumpAll() throws PersistenceException {
		System.out.println("List of Metric Series:");
		for ( MetricSerie serie : MetricSerieDB.instance().getMetricSeries() ) {
			System.out.println("\t- " + serie);
		}
	}
	
	/**
	 * @param args
	 * @throws PersistenceException 
	 */
	public static void main(String[] args) throws PersistenceException {
		
		dumpAll();
		
		MetricSerie serie = MetricSerieDB.instance().getMetricSerie("device", "metrics", true);
		serie.getMetadata().put("Location", "Roma");
		MetricSerieDB.instance().save(serie);

		dumpAll();
		
		serie.getMetadata().clear();
		MetricSerieDB.instance().save(serie);
		
		dumpAll();
		
		MetricSerieDB.instance().synchronizeAllMetricSeries();

		dumpAll();

	}

}
