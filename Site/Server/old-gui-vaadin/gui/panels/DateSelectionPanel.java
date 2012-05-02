package it.nose.gui.panels;

import it.nose.gui.bean.DateChangeEvent;
import it.nose.gui.bean.DateChangeListener;

import java.text.DateFormat;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.concurrent.CopyOnWriteArrayList;

import com.vaadin.event.FieldEvents.TextChangeEvent;
import com.vaadin.event.FieldEvents.TextChangeListener;
import com.vaadin.ui.Button;
import com.vaadin.ui.Button.ClickEvent;
import com.vaadin.ui.Button.ClickListener;
import com.vaadin.ui.Label;
import com.vaadin.ui.Panel;
import com.vaadin.ui.TextField;
import com.vaadin.ui.VerticalLayout;

public class DateSelectionPanel extends Panel implements TextChangeListener, ClickListener {

	private static final long serialVersionUID = 1L;

	private TextField startDate;

	private Label startDateLabel;

	private TextField endDate;

	private Label endDateLabel;
	
	private Date from;

	private Date to;

	private String format;
	
	private DateFormat formatter;
	
	private boolean changed;
	
	private Button refresh;

	private final CopyOnWriteArrayList<DateChangeListener> listeners;

	public DateSelectionPanel(Date from, Date to, String formatString) {
		super();

		this.from = from;
		this.to = to;
		this.format = formatString;
		this.formatter = new SimpleDateFormat(formatString);
		this.listeners = new CopyOnWriteArrayList<DateChangeListener>();
		this.changed = false;

		prepareUI();
		
	}
	
	public void addDataChangeListener(DateChangeListener l) {
		this.listeners.add(l);
	}

	public void removeDataChangeListener(DateChangeListener l) {
		this.listeners.remove(l);
	}

	protected void fireChangeEvent() {
		
		if (!isChanged())
			return;
		
		clearChanged();
		
		DateChangeEvent evt = new DateChangeEvent(this, this.from, this.to);
		for (DateChangeListener l : listeners) {
			l.dateChanged(evt);
		}
	}
	
	private void setChanged() {
		refresh.setEnabled(true);
		changed = true;
	}

	private boolean isChanged() {
		return changed;
	}
	
	private void clearChanged() {
		refresh.setEnabled(true);
		changed = false;
	}
	
	@Override
	public void textChange(TextChangeEvent event) {

		try {
			Date newDate = formatter.parse(event.getText());
			if ( event.getSource() == startDate ) {
				startDateLabel.setValue("");
				if (!newDate.equals(this.from)) {
					this.from = newDate;
					setChanged();
				}
			}
			else if ( event.getSource() == endDate ) {
				endDateLabel.setValue("");
				if (!newDate.equals(this.to)) {
					this.to = newDate;
					setChanged();
				}
			}
		} catch (ParseException e) {
			if ( event.getSource() == startDate ) {
				startDateLabel.setValue("Date format must be: " + this.format);
			}
			else if ( event.getSource() == endDate ) {
				endDateLabel.setValue("Date format must be: " + this.format);
			}
		}

	}

	private void prepareUI() {

		VerticalLayout layout = new VerticalLayout();

		setSizeFull();
		layout.setSizeFull();

		startDate = new TextField("Start Date");
		startDateLabel = new Label("");
		endDate = new TextField("End Date");
		endDateLabel = new Label("");

		layout.addComponent(startDate);
		layout.addComponent(startDateLabel);
		layout.addComponent(endDate);
		layout.addComponent(endDateLabel);

		refresh = new Button("Reload");
		refresh.addListener(this);
		refresh.setEnabled(false);
		layout.addComponent(refresh);

		startDate.addListener(this);
		endDate.addListener(this);

		startDate.setValue(formatter.format(this.from));
		endDate.setValue(formatter.format(this.to));

		addComponent(layout);

	}

	@Override
	public void buttonClick(ClickEvent event) {
		fireChangeEvent();
	}

}
