package org.nose.test;

import java.util.Date;
import java.util.LinkedList;
import java.util.List;

import org.nose.utility.Metric;

import com.mongodb.BasicDBObject;
import com.mongodb.DBObject;
import com.mongodb.util.JSON;

public class TestData {

	/**
	 * @param args
	 */
	public static void main(String[] args) {

		List<DBObject> list = new LinkedList<DBObject>();
		
		list.add(Metric.makeMetric(new Date(), 33.0, "ciao"));
		list.add(Metric.makeMetric(new Date(), 33.0, "ciao"));
		list.add(Metric.makeMetric(new Date(), 33.0, "ciao"));
		list.add(Metric.makeMetric(new Date(), 33.0, "ciao"));
		list.add(Metric.makeMetric(new Date(), 33.0, "ciao"));
		
		BasicDBObject o = new BasicDBObject("data", list);
		
		String data = o.get("data").toString();
		
    	Object value = JSON.parse(data);
    	
    	System.out.println(value.getClass());
    	
    	if (!( value instanceof List )) {
    		return;
    	}
    	@SuppressWarnings("unchecked")
		List<DBObject> l = (List<DBObject>) value;
    	
    	for ( DBObject obj : l ) {
        	System.out.println("- " + obj);
        	System.out.println(obj.get("date").getClass());
    	}
		
	}

}
