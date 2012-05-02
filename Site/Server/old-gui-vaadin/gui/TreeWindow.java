package it.nose.gui;

import it.nose.gui.bean.DateChangeEvent;
import it.nose.gui.bean.DateChangeListener;
import it.nose.gui.bean.PlotConfig;
import it.nose.gui.panels.DateSelectionPanel;
import it.nose.gui.panels.MetricSerieWindow;
import it.nose.gui.panels.PlotPanel;
import it.nose.gui.panels.TreePanel;
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

public class TreeWindow extends Window {
	
	private static final long serialVersionUID = 1L;
	
	public TreeWindow() {
		super();
		
		HorizontalLayout layout = new HorizontalLayout();
		
		layout.addComponent(new TreePanel());
		
		addComponent(layout);
		
	}
		
}
