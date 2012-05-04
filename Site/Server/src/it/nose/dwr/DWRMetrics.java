package it.nose.dwr;

import it.nose.persistence.PersistenceException;
import it.nose.persistence.metric.MetricDB;
import it.nose.persistence.metric.model.Metric;
import it.nose.persistence.metric.utility.Transformer;

import java.util.ArrayList;
import java.util.List;

import com.mongodb.DBObject;

public class DWRMetrics {
	
	private MetricDB metrics;
	
	public DWRMetrics() {
		this.metrics = new MetricDB();
	}

	public List<Metric> getMetrics(long from, long to, String device, String type) {
		
		try {
			List<DBObject> list = metrics.getMetricsInDateInterval(from, to, "device", "metrics").toArray();
			List<Metric> ret = new ArrayList<Metric>(list.size());
			for ( DBObject object : list) {
				ret.add(Transformer.transformDBObjectInMetric(object));
			}
			return ret;
		} catch (PersistenceException e) {
			e.printStackTrace();
		}
		
		return null;
	}
	
	public void markMetric(String id, int status) {
		try {
			metrics.setStatus(id, status);
		} catch (PersistenceException e) {
			e.printStackTrace();
		}
	}
	
}
