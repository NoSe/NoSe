package it.nose.persistence.auth.model;

public class Permission {
	
	private String name;
	
	private String[] resources;

	public Permission(String name, String[] resources) {
		super();
		this.name = name;
		this.resources = resources;
	}

	public String getName() {
		return name;
	}

	public void setName(String name) {
		this.name = name;
	}

	public String[] getResources() {
		return resources;
	}

	public void setResources(String[] resources) {
		this.resources = resources;
	}

}
