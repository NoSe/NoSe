package org.nose.utility;
import java.util.Date;

import com.mongodb.BasicDBObject;
import com.mongodb.DBObject;

public class Metric {
	
	public static final int STATUS_TO_VALIDATE = 0;
	public static final int STATUS_ACCEPTED = 1;
	public static final int STATUS_REJECTED = 2;

	public static DBObject makeMetric(Date date, double value, String ID) {
		BasicDBObject object = new BasicDBObject();
		object.put("value", value);
		object.put("date", date);
		object.put("ID", ID);
		object.put("status", STATUS_TO_VALIDATE);
		return object;
	}
	
	public static int getStatus(DBObject object) {
		return (Integer) object.get("status");
	}
	
}
