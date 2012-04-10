package it.nose.gui.panels;

import it.nose.gui.bean.TreeNode;
import it.nose.persistence.PersistenceException;
import it.nose.persistence.tree.TreeDB;

import java.util.Collection;
import java.util.List;

import org.vaadin.peter.contextmenu.ContextMenu;
import org.vaadin.peter.contextmenu.ContextMenu.ClickEvent;
import org.vaadin.peter.contextmenu.ContextMenu.ContextMenuItem;

import com.mongodb.DBObject;
import com.vaadin.data.util.HierarchicalContainer;
import com.vaadin.event.ItemClickEvent;
import com.vaadin.event.ItemClickEvent.ItemClickListener;
import com.vaadin.event.MouseEvents;
import com.vaadin.event.Transferable;
import com.vaadin.event.dd.DragAndDropEvent;
import com.vaadin.event.dd.DropHandler;
import com.vaadin.event.dd.acceptcriteria.AcceptCriterion;
import com.vaadin.terminal.gwt.client.ui.dd.VerticalDropLocation;
import com.vaadin.ui.AbstractSelect.VerticalLocationIs;
import com.vaadin.ui.Panel;
import com.vaadin.ui.Tree;
import com.vaadin.ui.Tree.CollapseEvent;
import com.vaadin.ui.Tree.ExpandEvent;
import com.vaadin.ui.Tree.TreeDragMode;
import com.vaadin.ui.Tree.TreeTargetDetails;
import com.vaadin.ui.VerticalLayout;
import com.vaadin.ui.Window.Notification;

public class TreePanel extends Panel implements DropHandler, ItemClickListener, Tree.ExpandListener, Tree.CollapseListener {

	private static final long serialVersionUID = 1L;

	private HierarchicalContainer container;

	private Tree tree;

	private ContextMenu menu;
	
	private TreeNode treeNodeRightClick;
	
	private TreeNode currentSelectedNode;

	public TreePanel() {
		super();

		VerticalLayout layout = new VerticalLayout();

		container = new HierarchicalContainer();

		try {

			// Make root node
			DBObject root = TreeDB.instance().getRoot();
			System.out.println("Added: " + root);
			TreeNode treeNode = new TreeNode(root);
			container.addItem(treeNode);
			container.setChildrenAllowed(treeNode, ( root.get("type").equals("dir")));
			System.out.println("Added: " + treeNode);

		} catch (PersistenceException e) {
			e.printStackTrace();
		}

		tree = new Tree("Chart Type", container);

		// Add tree
		layout.addComponent(tree);

		// tree.setImmediate(true);

		// tree.setSelectable(true);
		// tree.setNullSelectionAllowed(false);

		tree.addListener((ItemClickListener) this);
		tree.addListener((Tree.ExpandListener) this);
		tree.addListener((Tree.CollapseListener) this);

		// Size full
		// tree.setSizeFull();
		// tree.setMargin(true);

		addComponent(layout);

		tree.setDragMode(TreeDragMode.NODE);
		tree.setDropHandler(this);

		contextMenu();

	}

	private void contextMenu() {

		this.menu = new ContextMenu();

		// Generate main level items
		ContextMenuItem photos = menu.addItem("Add folder");
		ContextMenuItem albums = menu.addItem("Albums");
		ContextMenuItem report = menu.addItem("Report");

		// Generate sub item to photos menu
		ContextMenuItem topRated = photos.addItem("Top rated");

		// photos.setIcon(new FileResource(new File("photos.png")));

		// Enable separator line under this item
		photos.setSeparatorVisible(true);

		// Show notification when menu items are clicked
		menu.addListener(new ContextMenu.ClickListener() {

			private static final long serialVersionUID = 1L;

			@Override
			public void contextItemClick(ClickEvent event) {

				// Get reference to clicked item
				ContextMenuItem clickedItem = event.getClickedItem();

				// Do something with the reference
				getApplication().getMainWindow().showNotification(treeNodeRightClick.toString());

			}

		});

		addComponent(menu);

	}

	@Override
	public void drop(DragAndDropEvent event) {

		// Wrapper for the object that is dragged
		Transferable t = event.getTransferable();

		// Make sure the drag source is the same tree
		if (t.getSourceComponent() != tree)
			return;

		TreeTargetDetails target = (TreeTargetDetails) event.getTargetDetails();

		// Get ids of the dragged item and the target item
		TreeNode sourceItemId = (TreeNode) t.getData("itemId");
		TreeNode targetItemId = (TreeNode) target.getItemIdOver();

		// On which side of the target the item was dropped 
		VerticalDropLocation location = target.getDropLocation();

		try {

			DBObject sourceTreeNode = TreeDB.instance().getNode(sourceItemId.getId());
			DBObject targetTreeNode = TreeDB.instance().getNode(targetItemId.getId());

			System.out.println("Moving: " + sourceTreeNode + " " + location + " " + targetTreeNode);

			// Drop right on an item -> make it a child
			if (location == VerticalDropLocation.MIDDLE) {

				TreeDB.instance().addChildren(sourceTreeNode, targetTreeNode);

				tree.setParent(sourceItemId, targetItemId);
				tree.setChildrenAllowed(targetItemId, true);

			}

		} catch (PersistenceException e) {
			e.printStackTrace();
		}

	}

	@Override
	public AcceptCriterion getAcceptCriterion() {
		return VerticalLocationIs.MIDDLE;
	}

	@Override
	public void itemClick(ItemClickEvent event) {

		if ( event.getButton() == MouseEvents.ClickEvent.BUTTON_RIGHT ) {
	
			treeNodeRightClick = (TreeNode) event.getItemId();

			if ( currentSelectedNode != null ) {
				tree.unselect(currentSelectedNode);
				tree.select(treeNodeRightClick);
				tree.requestRepaint();
				currentSelectedNode = treeNodeRightClick;
			}
			
			menu.show(event.getClientX(), event.getClientY());
						
		}
		else {
			
			currentSelectedNode = (TreeNode) event.getItemId();
			
			getWindow().showNotification("Node selected: " + event.getItemId() + " (" + event.getItemId().getClass() + ")", Notification.TYPE_HUMANIZED_MESSAGE);
		}

	}

	@Override
	public void nodeExpand(ExpandEvent event) {

		// Get selected node
		TreeNode treeNode = (TreeNode) event.getItemId();

		System.out.println("Node expand: " + treeNode.getDescription() + ", " + treeNode.getId());

		try {

			// Get its children list
			DBObject node = TreeDB.instance().getNode(treeNode.getId());
			List<DBObject> children = TreeDB.instance().getChildren(node);

			// tree.setChildrenAllowed(treeNode, ( node.get("type").equals("dir")));

			for ( DBObject child : children ) {
				TreeNode treeChild = new TreeNode(child);
				container.addItem(treeChild);
				container.setParent(treeChild, treeNode);
				container.setChildrenAllowed(treeChild, ( child.get("type").equals("dir")));
			}

		} catch (PersistenceException e) {

			// tree.setChildrenAllowed(event.getItemId(), false);
			e.printStackTrace();
			return;

		}

	}

	@Override
	public void nodeCollapse(CollapseEvent event) {

		Collection<?> children = container.getChildren(event.getItemId());
		if ( children == null || children.size() == 0 )
			return;

		for ( Object child : children.toArray() ) {
			System.out.println("Remove node: " + child);
			container.removeItemRecursively(child);
		}

	}

}
