package it.nose.persistence.metric.utility;

import java.util.Date;
import java.util.GregorianCalendar;

public class DateUtility {
	
	public static Date getHourDate(Date date) {
		GregorianCalendar calendar = new GregorianCalendar();
		calendar.setTime(date);
		calendar.set(GregorianCalendar.MILLISECOND, 0);
		calendar.set(GregorianCalendar.SECOND, 0);
		calendar.set(GregorianCalendar.MINUTE, 0);
		return calendar.getTime();
	}

	public static Date getPastYear(Date date) {
		GregorianCalendar calendar = new GregorianCalendar();
		calendar.setTime(date);
		calendar.add(GregorianCalendar.YEAR, -1);
		return calendar.getTime();
	}

	public static Date getPastMonth(Date date) {
		GregorianCalendar calendar = new GregorianCalendar();
		calendar.setTime(date);
		calendar.add(GregorianCalendar.MONTH, -1);
		return calendar.getTime();
	}

	public static Date getPastWeek(Date date) {
		return getPastWeek(date, 1);
	}

	public static Date getPastWeek(Date date, int numWeeks) {
		GregorianCalendar calendar = new GregorianCalendar();
		calendar.setTime(date);
		calendar.add(GregorianCalendar.WEEK_OF_YEAR, -1 * numWeeks);
		return calendar.getTime();
	}

	public static Date getNextHour(Date date) {
		GregorianCalendar calendar = new GregorianCalendar();
		calendar.setTime(date);
		calendar.add(GregorianCalendar.HOUR, 1);
		return calendar.getTime();
	}

}
