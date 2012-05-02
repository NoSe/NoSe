package it.nose.gui.bean;

import java.io.Serializable;

import com.mongodb.DBObject;

public class TreeNode implements Serializable {
	
	private static final long serialVersionUID = 1L;

	private String id;
	
	private String description;

	public TreeNode(DBObject node) {
		this.id = node.get("_id").toString();
		this.description = node.get("path").toString();
	}
	
	public String getId() {
		return id;
	}

	public String getDescription() {
		return description;
	}

	@Override
	public String toString() {
		return getDescription();
	}

}
