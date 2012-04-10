package it.nose.gui.window;

import java.net.URL;

import it.nose.NoseApplication;

import com.vaadin.terminal.ExternalResource;
import com.vaadin.ui.Button;
import com.vaadin.ui.Button.ClickEvent;
import com.vaadin.ui.Button.ClickListener;
import com.vaadin.ui.Component;
import com.vaadin.ui.CustomLayout;
import com.vaadin.ui.PasswordField;
import com.vaadin.ui.TextField;
import com.vaadin.ui.VerticalLayout;
import com.vaadin.ui.Window;

public class LoginWindow extends Window implements ClickListener {
	
	private static final long serialVersionUID = 1L;
	
	private TextField username;

	private PasswordField password;

	public LoginWindow() {
		super();
		
		VerticalLayout layout = new VerticalLayout();

		layout.setWidth("100%");
		layout.setHeight("100%");
		layout.setMargin(true);

		layout.addComponent(createLogin());
		
		this.setContent(layout);

	}
	
    private Component createLogin() {
    	
        // Create the custom layout and set it as a component in the current layout
        CustomLayout custom = new CustomLayout("../../sampler/layouts/examplecustomlayout");

        // Create components and bind them to the location tags
        // in the custom layout.
        username = new TextField();
        custom.addComponent(username, "username");

        password = new PasswordField();
        custom.addComponent(password, "password");

        Button ok = new Button("Login");
        custom.addComponent(ok, "okbutton");

        // Add login listener
        ok.addListener(this);

        return custom;

    }

	@Override
	public void buttonClick(ClickEvent event) {
		try {
			NoseApplication.getInstance().authenticate((String) username.getValue(), (String) password.getValue());
			URL url = NoseApplication.getInstance().getURL();
			String strURL = url.toString();
			strURL = strURL.substring(0, strURL.length() - 1);
			this.open (new ExternalResource(strURL));
		} catch (Exception e) {
			showNotification(e.toString());
		}
	}

}
