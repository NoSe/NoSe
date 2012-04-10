package org.nose.tree;

import java.util.List;


public interface TreeService {
		
	public INode createNode(INode parent, String name, String type, Object metadata) throws Exception;
		
	public void renameNode(Long nodeID, String name);

	public void removeNode(Long nodeID);
	
	public List<Long> search(String text);
	
	public List<INode> getChildrenOf(Long nodeID);

	public INode getNode(Long id);

	public void dumpTree() throws Exception;

}
