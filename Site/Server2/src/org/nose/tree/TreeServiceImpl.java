package org.nose.tree;

import java.util.ArrayList;
import java.util.List;
import java.util.Set;

import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;

import org.codehaus.jackson.map.ObjectMapper;
import org.springframework.stereotype.Repository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

@Service("treeService")
@Repository
@Transactional(readOnly = false, propagation = Propagation.REQUIRED)
public class TreeServiceImpl implements TreeService {
	
	private EntityManager em;

	@Override
	public INode createNode(INode parent, String name, String type, Object metadata) throws Exception {
		
		Node parentNode = null;

		// Load parent node
		if ( parent != null )
			parentNode = (Node) em.find(Node.class, parent.getId());

		Node node = new Node();
		node.setName(name);
		node.setParent(parentNode);
		node.setType(type);
		
		if ( metadata != null ) {
			ObjectMapper mapper = new ObjectMapper();
			String meta = mapper.writeValueAsString(metadata);
			node.setJsonMetadata(meta);
		}
		
		em.persist(node);
		
		return new INode(node);
	}

	@Override
	public void dumpTree() throws Exception {
		Node node = (Node) em.createQuery("SELECT c FROM Node c WHERE c.parent = null").getSingleResult();
		dumpFolder(0, node);
	}

	private void dumpFolder(int tab, Node folder) throws Exception {
		for ( int i = 0; i < tab; i ++ ) { System.out.print("\t"); }
		System.out.println(folder);
		for ( Node f : folder.getSubFolders() ) {
			dumpFolder(tab + 1, f);
		}
	}

	@Override
	public void renameNode(Long nodeID, String name) {
		Node node = (Node) em.createQuery("SELECT c FROM Node c WHERE c.id = :id").setParameter("id", nodeID).getSingleResult();
		node.setName(name);
		em.persist(node);
	}

	@Override
	public void removeNode(Long nodeID) {
		Node node = (Node) em.createQuery("SELECT c FROM Node c WHERE c.id = :id").setParameter("id", nodeID).getSingleResult();
		em.remove(node);
	}

	public INode getNode(Long id) {
		return new INode(em.find(Node.class, id));
	}

	public List<INode> getChildrenOf(Long nodeID) {
		if ( nodeID == null ) {
			@SuppressWarnings("unchecked")
			List<Node> list = (List<Node>) em.createQuery("SELECT c FROM Node c WHERE c.parent = null").getResultList();
			ArrayList<INode> children = new ArrayList<INode>(list.size());
			for ( Node child : list ) {
				children.add(new INode(child));
			}
			return children;
		}
		else {
			Node parent = em.find(Node.class, nodeID);
			Set<Node> list = parent.getSubFolders();
			ArrayList<INode> children = new ArrayList<INode>(list.size());
			for ( Node child : list ) {
				children.add(new INode(child));
			}
			return children;
		}
	}

	@SuppressWarnings("unchecked")
	public List<Long> search(String text) {
		return (List<Long>) em.createQuery("SELECT c.id FROM Node c WHERE c.name LIKE :text").setParameter("text", text).getResultList();
	}

	public EntityManager getEntityManager() {
		return em;
	}

	@PersistenceContext
	public void setEntityManager(EntityManager em) {
		this.em = em;
	}

}