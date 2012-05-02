package it.nose;

import it.nose.gui.ApplicationWindow;
import it.nose.gui.TreeWindow;
import it.nose.gui.window.LoginWindow;

import com.vaadin.Application;
import com.vaadin.service.ApplicationContext;

public class NoseApplication extends Application implements ApplicationContext.TransactionListener {

	private static final long serialVersionUID = 1L;

	private static ThreadLocal<NoseApplication> currentApplication = new ThreadLocal<NoseApplication>();
	
	private String currentUser = null;

	public void init() {
		getContext().addTransactionListener(this);
		setMainWindow(new TreeWindow());
	}

	public void transactionStart(Application application, Object o) {
		if ( application == NoseApplication.this ) {
			currentApplication.set(this);
		}
	}

	public void transactionEnd (Application application, Object o) {
		if ( application == NoseApplication.this ) {
			currentApplication.set(null);
			currentApplication.remove ();
		}
	}

	public static NoseApplication getInstance() {
		return currentApplication.get();
	}
	
	public void authenticate(String username, String password) throws Exception {
		currentUser = username;
		setMainWindow(new ApplicationWindow());
	}
	
	public String getCurrentUser() {
		return currentUser;
	}

}
