package it.nose.persistence.metric.model;

import java.io.Serializable;
import java.util.HashMap;
import java.util.Map;

public class MetricSerie implements Serializable {
	
	private static final long serialVersionUID = 1L;

	private String id;
	
	private String device;
	
	private String type;
	
	private Map<String, String> metadata = new HashMap<String, String>();

	public MetricSerie() {
	}

	public MetricSerie(String device, String type) {
		super();
		this.device = device;
		this.type = type;
	}

	public String getId() {
		return id;
	}

	public void setId(String id) {
		this.id = id;
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

	public Map<String, String> getMetadata() {
		return metadata;
	}

	public void setMetadata(Map<String, String> metadata) {
		this.metadata = metadata;
	}
	
	@Override
	public int hashCode() {
		final int prime = 31;
		int result = 1;
		result = prime * result + ((device == null) ? 0 : device.hashCode());
		result = prime * result + ((type == null) ? 0 : type.hashCode());
		return result;
	}

	@Override
	public boolean equals(Object obj) {
		if (this == obj)
			return true;
		if (obj == null)
			return false;
		if (getClass() != obj.getClass())
			return false;
		MetricSerie other = (MetricSerie) obj;
		if (device == null) {
			if (other.device != null)
				return false;
		} else if (!device.equals(other.device))
			return false;
		if (type == null) {
			if (other.type != null)
				return false;
		} else if (!type.equals(other.type))
			return false;
		return true;
	}

	@Override
	public String toString() {
		return "MetricSerie [id=" + id + ", device=" + device + ", type="
				+ type + ", metadata=" + metadata + "]";
	}
	
}
