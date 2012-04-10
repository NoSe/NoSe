package it.nose.persistence.metric.model;

import java.io.Serializable;

public class Status implements Serializable {
	
	private static final long serialVersionUID = 1L;
	
	public static final int TO_VALIDATE = 0;
	
	public static final int VALID = 1;
	
	public static final int NOT_VALID = -1;
				
};
