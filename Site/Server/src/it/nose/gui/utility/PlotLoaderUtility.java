package it.nose.gui.utility;

import it.nose.gui.bean.PlotConfig;
import it.nose.persistence.PersistenceException;
import it.nose.persistence.metric.MetricDB;
import it.nose.persistence.metric.model.MetricSerie;

import java.io.Serializable;
import java.util.HashMap;
import java.util.LinkedHashSet;
import java.util.Map;

import com.invient.vaadin.charts.InvientCharts.DateTimePoint;
import com.invient.vaadin.charts.InvientCharts.DateTimeSeries;
import com.invient.vaadin.charts.InvientCharts.Series;
import com.invient.vaadin.charts.InvientCharts.SeriesType;
import com.invient.vaadin.charts.InvientChartsConfig.AreaConfig;
import com.mongodb.DBCursor;
import com.mongodb.DBObject;

public class PlotLoaderUtility implements Serializable {

	private static final long serialVersionUID = 1L;
		
	public static Map<Series, LinkedHashSet<DateTimePoint>> loadData(PlotConfig config) {

		Map<Series, LinkedHashSet<DateTimePoint>> series = new HashMap<Series, LinkedHashSet<DateTimePoint>>();

		AreaConfig seriesDataCfg = new AreaConfig();
		seriesDataCfg.setPointInterval((double) config.getDelta());
		seriesDataCfg.setPointStart((double) config.getFrom());

		for ( MetricSerie serie : config.getSeries() ) {

			try {
				
				DateTimeSeries chartSeries = new DateTimeSeries(
						serie.getDevice() + " (" + serie.getType() + ")", 
						SeriesType.AREA, 
						seriesDataCfg);

				LinkedHashSet<DateTimePoint> points = new LinkedHashSet<DateTimePoint>();

				String deviceToken = serie.getDevice();
				String measureType = serie.getType();

				DBCursor cursor = MetricDB.instance().getMetricsInDateInterval(
						config.getFrom(), 
						config.getTo(), 
						deviceToken, 
						measureType);

				while ( cursor.hasNext() ) {

					DBObject metric = cursor.next();
					double value = (Double) metric.get("value");
					points.add(new DateTimePoint(chartSeries, value));

				}
				
				chartSeries.setSeriesPoints(points);
				series.put(chartSeries, points);

			}
			catch ( PersistenceException e ) {
				e.printStackTrace();
			}

		}
		
		return series;

	}

}
