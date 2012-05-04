package it.nose.test;

import it.nose.persistence.PersistenceException;
import it.nose.persistence.metric.MetricSerieDB;
import it.nose.persistence.metric.model.MetricSerie;

public class MetricSerieDump {
	
	private MetricSerieDB metricsSerie;
	
	public MetricSerieDump() throws PersistenceException {
		
		metricsSerie = new MetricSerieDB();
		
		dumpAll();
		
		MetricSerie serie = metricsSerie.getMetricSerie("device", "metrics", true);
		serie.getMetadata().put("Location", "Roma");
		metricsSerie.save(serie);

		dumpAll();
		
		serie.getMetadata().clear();
		metricsSerie.save(serie);
		
		dumpAll();
		
		metricsSerie.synchronizeAllMetricSeries();

		dumpAll();
	}
	
	public void dumpAll() throws PersistenceException {
		System.out.println("List of Metric Series:");
		for ( MetricSerie serie : metricsSerie.getMetricSeries() ) {
			System.out.println("\t- " + serie);
		}
	}
	
	/**
	 * @param args
	 * @throws PersistenceException 
	 */
	public static void main(String[] args) throws PersistenceException {
		new MetricSerieDump();
	}

}
