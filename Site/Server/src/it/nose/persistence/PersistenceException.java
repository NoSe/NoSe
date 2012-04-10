package it.nose.persistence;

public class PersistenceException extends Exception {

	private static final long serialVersionUID = 1L;

	public PersistenceException() {
	}

	public PersistenceException(String arg0) {
		super(arg0);
	}

	public PersistenceException(Throwable arg0) {
		super(arg0);
	}

	public PersistenceException(String arg0, Throwable arg1) {
		super(arg0, arg1);
	}

}
