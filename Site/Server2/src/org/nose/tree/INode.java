package org.nose.tree;

public class INode {

	private Long id;
	
	private String name;
	
	private String type;
	
	private String metadata;
	
	public INode(Node node) {
		this.id = node.getId();
		this.name = node.getName();
		this.type = node.getType();
		this.metadata = node.getJsonMetadata();
	}

	public Long getId() {
		return id;
	}

	public void setId(Long id) {
		this.id = id;
	}

	public String getName() {
		return name;
	}

	public void setName(String name) {
		this.name = name;
	}

	public String getType() {
		return type;
	}

	public void setType(String type) {
		this.type = type;
	}

	public String getMetadata() {
		return metadata;
	}

	public void setMetadata(String metadata) {
		this.metadata = metadata;
	}

	@Override
	public String toString() {
		return "INode [id=" + id + ", name=" + name + ", type=" + type
				+ ", metadata=" + metadata + "]";
	}	
}
