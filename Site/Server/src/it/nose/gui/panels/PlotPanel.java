package it.nose.gui.panels;


import it.nose.gui.bean.PlotConfig;
import it.nose.gui.utility.PlotLoaderUtility;

import java.util.ArrayList;
import java.util.Date;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Observable;
import java.util.Observer;

import com.invient.vaadin.charts.Color.RGB;
import com.invient.vaadin.charts.Color.RGBA;
import com.invient.vaadin.charts.Gradient;
import com.invient.vaadin.charts.Gradient.LinearGradient.LinearColorStop;
import com.invient.vaadin.charts.InvientCharts;
import com.invient.vaadin.charts.InvientCharts.ChartZoomEvent;
import com.invient.vaadin.charts.InvientCharts.ChartZoomListener;
import com.invient.vaadin.charts.InvientCharts.DateTimePoint;
import com.invient.vaadin.charts.InvientCharts.DateTimeSeries;
import com.invient.vaadin.charts.InvientCharts.PointSelectEvent;
import com.invient.vaadin.charts.InvientCharts.Series;
import com.invient.vaadin.charts.InvientCharts.SeriesType;
import com.invient.vaadin.charts.InvientChartsConfig;
import com.invient.vaadin.charts.InvientChartsConfig.AreaConfig;
import com.invient.vaadin.charts.InvientChartsConfig.AxisBase.AxisTitle;
import com.invient.vaadin.charts.InvientChartsConfig.AxisBase.DateTimePlotBand;
import com.invient.vaadin.charts.InvientChartsConfig.AxisBase.DateTimePlotBand.DateTimeRange;
import com.invient.vaadin.charts.InvientChartsConfig.AxisBase.Grid;
import com.invient.vaadin.charts.InvientChartsConfig.DateTimeAxis;
import com.invient.vaadin.charts.InvientChartsConfig.GeneralChartConfig.Margin;
import com.invient.vaadin.charts.InvientChartsConfig.GeneralChartConfig.ZoomType;
import com.invient.vaadin.charts.InvientChartsConfig.LineConfig;
import com.invient.vaadin.charts.InvientChartsConfig.NumberYAxis;
import com.invient.vaadin.charts.InvientChartsConfig.SeriesState;
import com.invient.vaadin.charts.InvientChartsConfig.SymbolMarker;
import com.invient.vaadin.charts.InvientChartsConfig.XAxis;
import com.invient.vaadin.charts.InvientChartsConfig.YAxis;
import com.invient.vaadin.charts.InvientChartsConfig.YAxisDataLabel;
import com.vaadin.ui.Panel;
import com.vaadin.ui.VerticalLayout;

public class PlotPanel extends Panel implements ChartZoomListener, Observer {

	private static final long serialVersionUID = 1L;

	private PlotConfig config;

	private Date masterChartMinDate;
	
	private Date masterChartMaxDate;
	
	private Date detailChartPointStartDate;
	
	private InvientCharts masterChart;

	private InvientCharts detailChart;

	private Map<Series, LinkedHashSet<DateTimePoint>> series;
	
	public PlotPanel(PlotConfig config) {
		super();

		// Register configuration and save itself as its observer
		this.config = config;
		this.config.addObserver(this);
		
		VerticalLayout layout = new VerticalLayout();
		
		layout.setSizeFull();
		layout.setMargin(true);
        		
		// Create the master chart (empty)
		createMasterChart();

		// Create detail chart (empty)
		createDetailChart();

		// Add master chart
		layout.addComponent(masterChart);

		// Add detail chart
		layout.addComponent(detailChart);
		layout.setMargin(true);

		this.addComponent(layout);
		
		// Reload data
		reloadData();

	}
	
	public void reloadData() {

		// Read data limits from configuration
		masterChartMinDate = new Date(config.getFrom());
		masterChartMaxDate = new Date(config.getTo());
		detailChartPointStartDate = new Date(config.getTo() - 1000 * 3600 * 24 * 7);

		// Remove master data
		clearAllMasterData();
		
		// Remove detail data
		clearAllDetailData();
		
		// Reload data making a new model
		this.series = PlotLoaderUtility.loadData(this.config);

		// Feed master chart with new data
		for ( Series serie : this.series.keySet()) {
			masterChart.addSeries(serie);
		}

		// Load detail chart data
		loadDetailChart(detailChartPointStartDate.getTime(), (double) config.getTo());

		// Refresh charts
		masterChart.refresh();
		detailChart.refresh();

	}
		
	private void clearAllDetailData() {
		if ( this.series == null )
			return;
		for ( Series series : this.series.keySet() ) {
			detailChart.removeSeries(series);
		}
	}

	private void clearAllMasterData() {
		if ( this.series == null )
			return;
		for ( Series series : this.series.keySet() ) {
			masterChart.removeSeries(series);
		}
	}

	@Override
	public void chartZoom(ChartZoomEvent chartZoomEvent) {
		
		double min = chartZoomEvent.getChartArea().getxAxisMin();
		double max = chartZoomEvent.getChartArea().getxAxisMax();

		// Clear all detail data
		clearAllDetailData();
		
		// Load detail chart data with new bounds
		loadDetailChart(min, max);
		
		detailChart.refresh();
		
		// Update plotbands
		DateTimeAxis masterDateTimeAxis = (DateTimeAxis) masterChart.getConfig().getXAxes().iterator().next();
		masterDateTimeAxis.removePlotBand("mask-before");
		DateTimePlotBand plotBandBefore = new DateTimePlotBand("mask-before");
		plotBandBefore.setRange(new DateTimeRange(masterChartMinDate, new Date((long) min)));
		plotBandBefore.setColor(new RGBA(0, 0, 0, 0.2f));
		masterDateTimeAxis.addPlotBand(plotBandBefore);

		masterDateTimeAxis.removePlotBand("mask-after");
		DateTimePlotBand plotBandAfter = new DateTimePlotBand("mask-after");
		plotBandAfter.setRange(new DateTimeRange(new Date((long) max), masterChartMaxDate));
		plotBandAfter.setColor(new RGBA(0, 0, 0, 0.2f));
		masterDateTimeAxis.addPlotBand(plotBandAfter);
		masterChart.refresh();
		
	}

//	private static Date getDateZeroTime(int year, int month, int day) {
//		Calendar cal = GregorianCalendar.getInstance();
//		cal.set(Calendar.YEAR, year);
//		cal.set(Calendar.MONTH, month);
//		cal.set(Calendar.DAY_OF_MONTH, day);
//		setZeroTime(cal);
//		return cal.getTime();
//	}

//	private static void setZeroTime(Calendar cal) {
//		cal.set(Calendar.HOUR, 0);
//		cal.set(Calendar.MINUTE, 0);
//		cal.set(Calendar.SECOND, 0);
//		cal.set(Calendar.MILLISECOND, 0);
//	}

	private void createMasterChart() {

		// Creation of master plot
		InvientChartsConfig chartConfig = new InvientChartsConfig();
		chartConfig.getGeneralChartConfig().setReflow(false);
		chartConfig.getGeneralChartConfig().setBorderWidth(0);
		chartConfig.getGeneralChartConfig().setMargin(new Margin());
		chartConfig.getGeneralChartConfig().getMargin().setLeft(50);
		chartConfig.getGeneralChartConfig().getMargin().setRight(20);
		chartConfig.getGeneralChartConfig().setZoomType(ZoomType.X);
		chartConfig.getGeneralChartConfig().setClientZoom(false);
		chartConfig.getGeneralChartConfig().setHeight(80);
		chartConfig.getTitle().setText("");

		// X-axis: max zoom: delta metrics 
		DateTimeAxis xAxis = new DateTimeAxis();
		xAxis.setShowLastLabel(true);
		xAxis.setMaxZoom((int) config.getDelta() * 3);
		
		// Plot band from begin to start detail zone
		DateTimePlotBand plotBand = new DateTimePlotBand("mask-before");
		plotBand.setRange(new DateTimeRange(masterChartMinDate, detailChartPointStartDate));
		plotBand.setColor(new RGBA(0, 0, 0, 0.2f));
		xAxis.addPlotBand(plotBand);
		xAxis.setTitle(new AxisTitle(""));

		// X-axis
		LinkedHashSet<XAxis> xAxes = new LinkedHashSet<InvientChartsConfig.XAxis>();
		xAxes.add(xAxis);
		chartConfig.setXAxes(xAxes);

		// Y-axis
		NumberYAxis yAxis = new NumberYAxis();
		yAxis.setShowFirstLabel(false);
		// yAxis.setMin(0.6);
		yAxis.setGrid(new Grid());
		yAxis.getGrid().setLineWidth(0);
		yAxis.setLabel(new YAxisDataLabel(false));
		yAxis.setTitle(new AxisTitle(""));

		// Y axis
		LinkedHashSet<YAxis> yAxes = new LinkedHashSet<InvientChartsConfig.YAxis>();
		yAxes.add(yAxis);
		chartConfig.setYAxes(yAxes);

		// Tooltip
		chartConfig.getTooltip().setFormatterJsFunc("function() { return false; }");

		// Legend and credits
		chartConfig.getLegend().setEnabled(false);
		chartConfig.getCredit().setEnabled(false);

		// Plot options
		AreaConfig areaCfg = new AreaConfig();
		List<LinearColorStop> colorStops = new ArrayList<Gradient.LinearGradient.LinearColorStop>();
		colorStops.add(new LinearColorStop(0, new RGB(69, 114, 167)));
		colorStops.add(new LinearColorStop(1, new RGBA(0, 0, 0, 0)));
		
		// Fill color
		areaCfg.setFillColor(new Gradient.LinearGradient(0, 0, 0, 70, colorStops));
		areaCfg.setLineWidth(1);
		areaCfg.setMarker(new SymbolMarker(false));
		areaCfg.setShadow(false);
		areaCfg.setEnableMouseTracking(false);
		areaCfg.setHoverState(new SeriesState());
		areaCfg.getHoverState().setLineWidth(1);
		chartConfig.addSeriesConfig(areaCfg);

		masterChart = new InvientCharts(chartConfig);
		
		// Register events
		masterChart.addListener(this);
		
	}

	private void createDetailChart() {
		
		// Detail Chart configuration
		InvientChartsConfig detailChartConfig = new InvientChartsConfig();
		detailChartConfig.getGeneralChartConfig().setMargin(new Margin());
		detailChartConfig.getGeneralChartConfig().getMargin().setBottom(120);
		detailChartConfig.getGeneralChartConfig().getMargin().setLeft(50);
		detailChartConfig.getGeneralChartConfig().getMargin().setRight(20);
		detailChartConfig.getGeneralChartConfig().setReflow(false);

		detailChartConfig.getCredit().setEnabled(false);
		// detailChartConfig.getTitle().setText("Historical USD to EUR Exchange Rate");
		// detailChartConfig.getSubtitle().setText("Select an area by dragging across the lower chart");

		DateTimeAxis detailXAxis = new DateTimeAxis();
		LinkedHashSet<XAxis> detailXAxes = new LinkedHashSet<InvientChartsConfig.XAxis>();
		detailXAxes.add(detailXAxis);
		detailChartConfig.setXAxes(detailXAxes);

		NumberYAxis detailYAxis = new NumberYAxis();
		detailYAxis.setTitle(new AxisTitle(""));
		LinkedHashSet<YAxis> detailYAxes = new LinkedHashSet<InvientChartsConfig.YAxis>();
		detailYAxes.add(detailYAxis);
		detailChartConfig.setYAxes(detailYAxes);

//		detailChartConfig
//		.getTooltip()
//		.setFormatterJsFunc(
//				"function() {"
//					+ " var point = this.points[0];"
//					+ " return '<b>'+ point.series.name +'</b><br/>' + "
//					+ " $wnd.Highcharts.dateFormat('%A %B %e %Y: %H', this.x) + ':<br/>' + "
//					+ " '1 USD = '+ $wnd.Highcharts.numberFormat(point.y, 2) +' EUR';"
//					+ "}");
//		detailChartConfig.getTooltip().setShared(true);
		
		detailChartConfig.getLegend().setEnabled(true);

		LineConfig lineCfg = new LineConfig();
		
		SymbolMarker marker = new SymbolMarker(SymbolMarker.Symbol.CIRCLE);
		lineCfg.setMarker(marker);
		
//		marker.setHoverState(new MarkerState());
//		marker.getHoverState().setEnabled(true);
//		marker.getHoverState().setRadius(3);

		detailChartConfig.addSeriesConfig(lineCfg);

		detailChart = new InvientCharts(detailChartConfig);

	}
	
	private void loadDetailChart(double min, double max) {

		for ( Entry<Series, LinkedHashSet<DateTimePoint>> entry : this.series.entrySet() ) {
			
			// Line instance configuration
			LineConfig lineSeriesCfg = new LineConfig();
			
			lineSeriesCfg.setPointStart((double) detailChartPointStartDate.getTime());
			lineSeriesCfg.setPointInterval((double) config.getDelta());

			// lineSeriesCfg.setColor(new RGB(69, 114, 167));
			
			DateTimeSeries detailSeries = new DateTimeSeries(entry.getKey().getName(), SeriesType.LINE, lineSeriesCfg);
			
			LinkedHashSet<DateTimePoint> detailPoints = new LinkedHashSet<InvientCharts.DateTimePoint>();

			for (DateTimePoint point : entry.getValue() ) {
				if (point.getX().getTime() >= min && point.getX().getTime() <= max) {
					detailPoints.add(new DateTimePoint(detailSeries, point.getY()));
				}
			}

			detailSeries.setSeriesPoints(detailPoints);
			detailChart.addSeries(detailSeries);
						
		}

	}

	@Override
	public void update(Observable observable, Object value) {
		if ( observable == this.config ) {
			this.reloadData();
		}
	}

}
