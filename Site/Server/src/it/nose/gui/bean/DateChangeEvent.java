package it.nose.gui.bean;

import java.util.Date;
import java.util.EventObject;

public class DateChangeEvent extends EventObject {

	private static final long serialVersionUID = 1L;
	
	private Date from;

	private Date to;

	public DateChangeEvent(Object source, Date from, Date to) {
		super(source);
		this.from = from;
		this.to = to;
	}

	public Date getFrom() {
		return from;
	}

	public void setFrom(Date from) {
		this.from = from;
	}

	public Date getTo() {
		return to;
	}

	public void setTo(Date to) {
		this.to = to;
	}
	
}

