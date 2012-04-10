package it.nose.services.rest;

import it.nose.persistence.PersistenceException;
import it.nose.persistence.metric.MetricDB;
import it.nose.persistence.metric.model.Metric;
import it.nose.persistence.metric.utility.Transformer;

import java.util.ArrayList;
import java.util.Date;
import java.util.List;

import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;
import javax.ws.rs.QueryParam;
import javax.ws.rs.core.MediaType;

import com.mongodb.DBCursor;
import com.mongodb.DBObject;

@Path("/data")
public class DataService {
	
	@GET
	@Path("/clean")
	@Produces({ MediaType.TEXT_PLAIN })	
	public String addMetric(
			@QueryParam("device") String device,
			@QueryParam("type") String type) {
		
		try {
			MetricDB.instance().dropDataOfDevice(null, null);
		} catch (PersistenceException e) {
			e.printStackTrace();
			return "Error: " + e.getMessage();
		}
		
		return "OK";

	}

	@GET
	@Path("/import")
	@Produces({ MediaType.APPLICATION_XML, MediaType.APPLICATION_JSON })	
	public Metric addMetric(
			@QueryParam("date") long date,
			@QueryParam("device") String device,
			@QueryParam("type") String type,
			@QueryParam("status") int status,
			@QueryParam("value") double value) {
		
		Metric metric = new Metric();
		metric.setDate(new Date(date));
		metric.setDevice(device);
		metric.setType(type);
		metric.setStatus(status);
		metric.setValue(value);
		
		DBObject object = null;
		
		try {
			object = MetricDB.instance().insertMetric(metric);
		} catch (PersistenceException e) {
			e.printStackTrace();
		}
		
		return Transformer.transformDBObjectInMetric(object);

	}
	
	@GET
	@Path("/export")
	@Produces({ MediaType.APPLICATION_XML, MediaType.APPLICATION_JSON })	
	public List<Metric> getMetrics(
			@QueryParam("from") long from, 
			@QueryParam("to") long to,
			@QueryParam("device") String device,
			@QueryParam("type") String type) {
		
		DBCursor cursor = null;
		
		try {
			cursor = MetricDB.instance().getMetricsInDateInterval(from, to, device, type);
		} catch (PersistenceException e) {
			e.printStackTrace();
			return null;
		}

		List<Metric> ret = new ArrayList<Metric>();

		while ( cursor.hasNext() ) {
			
			DBObject object = cursor.next();
			Metric metric = Transformer.transformDBObjectInMetric(object);
			ret.add(metric);
			
		}

		return ret;
		
	}

	@GET
	@Path("/get")
	@Produces({ MediaType.APPLICATION_XML, MediaType.APPLICATION_JSON })	
	public Metric getMetric(@QueryParam("id") String id) {

		DBObject object = null;
		
		try {
			object = MetricDB.instance().getMetric(id);
		} catch (PersistenceException e) {
			e.printStackTrace();
		}
		
		return Transformer.transformDBObjectInMetric(object);
		
	}

	@GET
	@Path("/set-status")
	@Produces({ MediaType.APPLICATION_XML, MediaType.APPLICATION_JSON })	
	public Metric setStatus(
			@QueryParam("id") String id, 
			@QueryParam("status") int status) {

		DBObject object = null;
		
		try {
			object = MetricDB.instance().setStatus(id, status);
		} catch (PersistenceException e) {
			e.printStackTrace();
		}
		
		return Transformer.transformDBObjectInMetric(object);
		
	}
}
