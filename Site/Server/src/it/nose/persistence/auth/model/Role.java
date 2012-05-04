package it.nose.persistence.auth.model;

public class Role {
	
	private String name;
	
	private Permission[] permissions;
	
	public Role(String name, Permission[] permissions) {
		super();
		this.name = name;
		this.permissions = permissions;
	}

	public String getName() {
		return name;
	}

	public void setName(String name) {
		this.name = name;
	}

	public Permission[] getPermissions() {
		return permissions;
	}

	public void setPermissions(Permission[] permissions) {
		this.permissions = permissions;
	}

}
