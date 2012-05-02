package it.nose.gui.panels;

import it.nose.persistence.metric.MetricSerieDB;
import it.nose.persistence.metric.model.MetricSerie;

import com.vaadin.data.util.BeanContainer;
import com.vaadin.ui.Table;

public class MetricSerieWindow extends Table {
	
	private static final long serialVersionUID = 1L;

	public MetricSerieWindow() {
		super("All metrics");
				
		BeanContainer<String, MetricSerie> container = new BeanContainer<String, MetricSerie>(MetricSerie.class);
		container.setBeanIdProperty("id");
		
		try {
			
			for ( MetricSerie serie : MetricSerieDB.instance().getMetricSeries()) {
				container.addBean(serie);
			}

			setContainerDataSource(container);
		    
		} catch (Throwable t) {
			t.printStackTrace();
		}
		
		setSizeFull();
			    
	}

}
