package it.nose;

import static org.junit.Assert.*;
import it.nose.persistence.PersistenceException;
import it.nose.persistence.metric.MetricDB;
import it.nose.persistence.metric.model.Metric;
import it.nose.persistence.metric.model.Status;
import it.nose.persistence.metric.utility.Transformer;

import java.util.Date;

import org.junit.After;
import org.junit.Before;
import org.junit.Test;

import com.mongodb.DBCursor;
import com.mongodb.DBObject;

public class MetricsTest {

	private static String deviceToken = "device";
	private static String measureType = "metrics";
	
	private MetricDB metrics;
		
	@Before
	public void setup() throws PersistenceException {
		this.metrics = new MetricDB("test_");
	
		for ( int i = 0; i < 100; i ++ ) {

			Metric metric = new Metric();
			metric.setDate(new Date(i * 1000));
			metric.setDevice(deviceToken);
			metric.setType(measureType);
			metric.setValue(i);
			
			metrics.insertMetric(metric);
			
		}
		
	}
	
	@After
	public void tearDown() {
		this.metrics.dropDB();
	}
	
	@Test
	public void testData() throws PersistenceException {
		DBCursor cursor = metrics.getMetricsInDateInterval(0, 100 * 1000 + 1, deviceToken, measureType);
		int last = 99;
		while ( cursor.hasNext() ) {
			DBObject object = cursor.next();
			Metric metric = Transformer.transformDBObjectInMetric(object);
			assertTrue(metric.getDate().getTime() == last * 1000);
			assertTrue(metric.getValue() == last);
			last --;
		}
	}
	
	@Test
	public void cleanAll() throws PersistenceException {
		metrics.dropDataOfDevice("fake" + deviceToken, measureType);
		DBCursor cursor = metrics.getMetricsInDateInterval(0, 100 * 1000 + 1, deviceToken, measureType);
		assertFalse(cursor.count() == 0);
		metrics.dropDataOfDevice(deviceToken, measureType);
		cursor = metrics.getMetricsInDateInterval(0, 100 * 1000 + 1, deviceToken, measureType);
		assertTrue(cursor.count() == 0);
	}
	
	@Test
	public void testFirst() throws PersistenceException {
		DBObject object = metrics.getFirstMetric(deviceToken, measureType);
		Metric metric = Transformer.transformDBObjectInMetric(object);
		assertTrue(metric.getDate().getTime() == 0);
		assertTrue(metric.getValue() == 0);
	}

	@Test
	public void testLast() throws PersistenceException {
		DBObject object = metrics.getLastMetric(deviceToken, measureType);
		Metric metric = Transformer.transformDBObjectInMetric(object);
		assertTrue(metric.getDate().getTime() == 99 * 1000);
		assertTrue(metric.getValue() == 99);
	}

	@Test
	public void testBadFirstAndLast() throws PersistenceException {
		assertNull(metrics.getFirstMetric("fake" + deviceToken, measureType));
		assertNull(metrics.getLastMetric("fake" + deviceToken, measureType));
	}
	
	@Test
	public void testSetStatus() throws PersistenceException {
		DBObject object = metrics.getLastMetric(deviceToken, measureType);
		Metric metric = Transformer.transformDBObjectInMetric(object);
		metrics.setStatus(metric.getId(), Status.VALID);
		object = metrics.getLastMetric(deviceToken, measureType);
		metric = Transformer.transformDBObjectInMetric(object);
		assertTrue(metric.getStatus() == Status.VALID);
		object = metrics.getFirstMetric(deviceToken, measureType);
		metric = Transformer.transformDBObjectInMetric(object);
		assertTrue(metric.getStatus() == Status.TO_VALIDATE);
	}
	
}
