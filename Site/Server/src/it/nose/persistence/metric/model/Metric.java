package it.nose.persistence.metric.model;

import java.io.Serializable;
import java.util.Date;

import javax.xml.bind.annotation.XmlAccessType;
import javax.xml.bind.annotation.XmlAccessorType;
import javax.xml.bind.annotation.XmlAttribute;
import javax.xml.bind.annotation.XmlRootElement;

@XmlRootElement
@XmlAccessorType(XmlAccessType.FIELD)
public class Metric implements Serializable {
	
	private static final long serialVersionUID = 1L;
	
	@XmlAttribute
	private String id;
		
	@XmlAttribute
	private Date date;
	
	@XmlAttribute
	private String device;
	
	@XmlAttribute
	private String type;
	
	@XmlAttribute
	private int status;
	
	@XmlAttribute
	private double value;
	
	public Metric() {
	}
	
	public Metric(Date date, String device, String type, double value) {
		this(date, device, type, Status.TO_VALIDATE, value);
	}

	public Metric(Date date, String device, String type, int status, double value) {
		super();
		this.date = date;
		this.device = device;
		this.type = type;
		this.status = status;
		this.value = value;
	}
	
	public String getId() {
		return id;
	}

	public void setId(String id) {
		this.id = id;
	}

	public Date getDate() {
		return date;
	}

	public void setDate(Date date) {
		this.date = date;
	}

	public String getDevice() {
		return device;
	}

	public void setDevice(String device) {
		this.device = device;
	}

	public String getType() {
		return type;
	}

	public void setType(String type) {
		this.type = type;
	}

	public int getStatus() {
		return status;
	}

	public void setStatus(int status) {
		this.status = status;
	}

	public double getValue() {
		return value;
	}

	public void setValue(double value) {
		this.value = value;
	}

	@Override
	public String toString() {
		return "Metric [date=" + date + ", device=" + device + ", type=" + type
				+ ", status=" + status + ", value=" + value + "]";
	}

}
