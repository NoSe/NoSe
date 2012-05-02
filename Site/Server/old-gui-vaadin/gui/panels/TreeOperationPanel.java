package it.nose.gui.panels;

import com.vaadin.ui.Button;
import com.vaadin.ui.VerticalLayout;

public class TreeOperationPanel extends VerticalLayout {

	private static final long serialVersionUID = 1L;

	private Button remove;
	
	private Button append;
	
	public TreeOperationPanel() {
		super();
		
		remove = new Button("Remove node");
		append = new Button("Append node");
		
		addComponent(remove);
		addComponent(append);
		
	}
	

}
