package it.nose.gui;

import it.nose.gui.bean.DateChangeEvent;
import it.nose.gui.bean.DateChangeListener;
import it.nose.gui.bean.PlotConfig;
import it.nose.gui.panels.DateSelectionPanel;
import it.nose.gui.panels.MetricSerieWindow;
import it.nose.gui.panels.PlotPanel;
import it.nose.persistence.PersistenceException;
import it.nose.persistence.metric.MetricDB;
import it.nose.persistence.metric.MetricSerieDB;
import it.nose.persistence.metric.model.MetricSerie;

import java.util.Date;
import java.util.GregorianCalendar;

import com.vaadin.ui.Accordion;
import com.vaadin.ui.HorizontalLayout;
import com.vaadin.ui.Label;
import com.vaadin.ui.Window;

public class ApplicationWindow extends Window implements DateChangeListener {
	
	private static final long serialVersionUID = 1L;
	
	private PlotConfig plotConfig;
	
	private static final int MONTHS_BACK = 2;
	
	public ApplicationWindow() {
		super();
		
		// Create configuration for that window
		try {
			plotConfig = getConfig();
		} catch (PersistenceException e) {
			e.printStackTrace();
			addComponent(new Label("Error in plot panel: " + e.getMessage()));
			return;
		}
		
		HorizontalLayout layout = createPlotPanel(plotConfig);
		
		addComponent(layout);
		
//		HorizontalLayout layout = new HorizontalLayout();
//
//		TreePanel treeWindow = new TreePanel();
//		Panel panel = new Panel();
//		panel.setWidth("100%");
//		panel.setHeight("100%");
//		panel.setScrollable(true);
//		panel.addComponent(treeWindow);
//		
//		TabSheet tabs = new TabSheet();
//		
//		try {
//
//
//			
//
//			// Set main window
//			tabs.addTab(plotWindow, "Plot");
//
//		} catch (PersistenceException e) {
//			e.printStackTrace();
//			Label label = new Label("Error getting data: " + e.getMessage());
//			tabs.addTab(label);
//		}
//		
//		tabs.addTab(new MetricSerieWindow(), "All metrics");
//		tabs.setWidth("600px");
//		tabs.setHeight("100%");
//
//		layout.addComponent(tabs);
//		layout.addComponent(panel);
//		
////		CustomLayout cl = new CustomLayout("pippo.txt");
////		layout.addComponent(cl);
//		
	}

	private HorizontalLayout createPlotPanel(PlotConfig plotConfig) {

		HorizontalLayout layout = new HorizontalLayout();
		
		layout.addComponent(new PlotPanel(plotConfig));
		
		layout.addComponent(createSidePlotPanel(plotConfig));
		
		return layout;
		
	}
	
	private Accordion createSidePlotPanel(PlotConfig plotConfig) {
				
		// Create the Accordion.
		Accordion accordion = new Accordion();
		 
		// Have it take all space available in the layout.
		accordion.setWidth("400px");
	
		// Date panel (add this class as listener for changes)
		DateSelectionPanel datePanel = new DateSelectionPanel(new Date(plotConfig.getFrom()), new Date(plotConfig.getTo()), "dd/MM/yyyy");
		datePanel.addDataChangeListener(this);

		// Add the components as tabs in the Accordion.
		accordion.addTab(datePanel, "Date Range", null);
		
		accordion.addTab(new Label("Some detail on plots"), "Detail", null);

		MetricSerieWindow metricSeries = new MetricSerieWindow();
		accordion.addTab(metricSeries, "All Metrics", null);
		 				
		return accordion;
		
	}

	private PlotConfig getConfig() throws PersistenceException {
		
		long from = (Long) MetricDB.instance().getFirstMetric(null, null).get("date");
		long to = (Long) MetricDB.instance().getLastMetric(null, null).get("date");
		
		GregorianCalendar date = new GregorianCalendar();
		date.setTime(new Date(to));
		date.add(GregorianCalendar.MONTH, - MONTHS_BACK);
		long months_back = date.getTimeInMillis();
		
		if ( months_back > from )
			from = months_back;
		
		PlotConfig config = new PlotConfig(from, to, 1000 * 60 * 60);

		for ( MetricSerie serie : MetricSerieDB.instance().getMetricSeries()) {
			config.addMetricSerie(serie);
			
			System.out.println("Added: " + serie);
		}
		
		return config;
	}

	@Override
	public void dateChanged(DateChangeEvent evt) {
		plotConfig.setFrom(evt.getFrom().getTime());
		plotConfig.setTo(evt.getTo().getTime());
		plotConfig.notifyModelChanged();
	}
	
//	// Date row
//	HorizontalLayout dateLayout = new HorizontalLayout(); 
//	
//	final StyleCalendar leftCalendar = new StyleCalendar();
//	leftCalendar.setImmediate(true);
//    leftCalendar.addListener(new Property.ValueChangeListener() {
//
//        private static final long serialVersionUID = -4914236743301835604L;
//
//        @Override
//        public void valueChange(ValueChangeEvent event) {
//            Date selected = (Date) event.getProperty().getValue();
//            DateFormat df = DateFormat.getDateInstance(DateFormat.MEDIUM, leftCalendar.getLocale());
////            dateLabel.setValue("Date selected " + df.format(selected));
//        }
//    });
//    dateLayout.addComponent(leftCalendar);
//    
//	final StyleCalendar rightCalendar = new StyleCalendar();
//	rightCalendar.setImmediate(true);
//	rightCalendar.addListener(new Property.ValueChangeListener() {
//
//        private static final long serialVersionUID = -4914236743301835604L;
//
//        @Override
//        public void valueChange(ValueChangeEvent event) {
//            Date selected = (Date) event.getProperty().getValue();
//            DateFormat df = DateFormat.getDateInstance(DateFormat.MEDIUM, leftCalendar.getLocale());
////            dateLabel.setValue("Date selected " + df.format(selected));
//        }
//    });
//    dateLayout.addComponent(rightCalendar);
//    
//    this.addComponent(dateLayout);

}
