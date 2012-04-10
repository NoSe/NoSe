package it.nose.gui.bean;

import it.nose.persistence.metric.model.MetricSerie;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.List;
import java.util.Observable;

public class PlotConfig extends Observable implements Serializable {
	
	private static final long serialVersionUID = 1L;

	private List<MetricSerie> series;
	
	private long from;
	
	private long to;
	
	private long delta;
		
	public PlotConfig(long from, long to, long delta) {
		super();
		this.from = from;
		this.to = to;
		this.delta = delta;
		this.series = new ArrayList<MetricSerie>();
	}
	
	public void notifyModelChanged() {
		setChanged();
		notifyObservers();
	}

	public List<MetricSerie> getSeries() {
		return series;
	}

	public void addMetricSerie(MetricSerie serie) {
		for ( MetricSerie metricSerie : series )
			if ( metricSerie.equals(serie))
				return;
		series.add(serie);
	}

	public void deleteMetricSerie(MetricSerie serie) {
		series.remove(serie);
	}
	
	public long getDelta() {
		return delta;
	}

	public long getFrom() {
		return from;
	}

	public void setFrom(long from) {
		this.from = from;
	}

	public long getTo() {
		return to;
	}

	public void setTo(long to) {
		this.to = to;
	}

}
