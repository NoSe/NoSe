package org.nose.tree;

import java.io.Serializable;
import java.util.Set;

import javax.persistence.CascadeType;
import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;
import javax.persistence.ManyToOne;
import javax.persistence.OneToMany;
import javax.persistence.SequenceGenerator;
import javax.persistence.Table;

@Entity
@Table(name = "node")
public class Node implements Serializable {
	
	private static final long serialVersionUID = 1L;

	private Long id;
	
	private String name;
	
	private Node parent;
	
	private String type;
	
	private String jsonMetadata;
	
	private Set<Node> subFolders;
	
	public Node() {
	}

	@Id
	@SequenceGenerator(name = "pk_sequence", sequenceName = "entity_id_seq")
	@GeneratedValue(strategy=GenerationType.SEQUENCE,generator="pk_sequence")
	@Column(name="id", unique = true, nullable = false)
	public Long getId() {
		return id;
	}

	public void setId(Long id) {
		this.id = id;
	}

	@Column(name="name")
	public String getName() {
		return name;
	}

	public void setName(String name) {
		this.name = name;
	}

	@ManyToOne
	public Node getParent() {
		return parent;
	}

	public void setParent(Node parent) {
		this.parent = parent;
	}

	@OneToMany(mappedBy="parent", cascade = CascadeType.ALL)
	public Set<Node> getSubFolders() {
		return subFolders;
	}

	public void setSubFolders(Set<Node> subFolders) {
		this.subFolders = subFolders;
	}

	@Column(name = "type")
	public String getType() {
		return type;
	}

	public void setType(String type) {
		this.type = type;
	}

	@Column(name = "metadata")
	public String getJsonMetadata() {
		return jsonMetadata;
	}

	public void setJsonMetadata(String jsonMetadata) {
		this.jsonMetadata = jsonMetadata;
	}

	@Override
	public String toString() {
		return "Node { id=" + id + ", name=" + name + ", type=" + type
				+ ", jsonMetadata=" + jsonMetadata + " }";
	}
	
	
	
}
