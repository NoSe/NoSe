package it.nose;

import static org.junit.Assert.assertArrayEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;
import it.nose.persistence.PersistenceException;
import it.nose.persistence.auth.RbacDB;
import it.nose.persistence.auth.model.Permission;

import java.net.UnknownHostException;

import org.junit.After;
import org.junit.Before;
import org.junit.Test;

public class TestRbac {
	
	private RbacDB rbac;
	
	@Before
	public void setup() throws PersistenceException {
		
		this.rbac = new RbacDB("test_");
		
		// Clear the database
		rbac.clear();
		
		rbac.createRole("admin", new Permission[]{
				new Permission("create", new String[]{ "pages", "posts", "users" }),
				new Permission("update", new String[]{ "pages", "posts", "users" }),
				new Permission("update_others", new String[]{ "pages", "posts" }),
				new Permission("delete", new String[]{ "pages", "posts", "users" }),
				new Permission("read", new String[]{ "pages", "posts", "users" })
		});

		rbac.createRole("writer", new Permission[]{
				new Permission("create", new String[]{ "pages", "posts" }),
				new Permission("update", new String[]{ "pages", "posts" }),
				new Permission("update_others", new String[]{}),
				new Permission("delete", new String[]{}),
				new Permission("read", new String[]{ "pages", "posts" })
		});

		rbac.assignRole("michele", "admin");
		rbac.assignRole("andrea", "writer");
	}
	
	@After
	public void tearDown() {
		this.rbac.dropDB();
	}
		
	@Test
	public void testRoles() throws PersistenceException, UnknownHostException {
		assertArrayEquals(new String[]{"admin"}, rbac.getUserRoles("michele").toArray());
		assertArrayEquals(new String[]{}, rbac.getUserRoles("luca").toArray());
		assertArrayEquals(new String[]{"writer"}, rbac.getUserRoles("andrea").toArray());
	}

	@Test
	public void testPermissions() throws PersistenceException {
		assertFalse(rbac.hasUserPermission("andrea", "create", "users"));
		assertTrue(rbac.hasUserPermission("michele", "create", "users"));
		assertTrue(rbac.hasUserPermission("michele", "update_others", "posts"));
		assertFalse(rbac.hasUserPermission("andrea", "update_others", "posts"));
	}

	@Test
	public void testRemoval() throws PersistenceException {
		rbac.removeRole("michele", "admin");
		assertArrayEquals(new String[]{}, rbac.getUserRoles("michele").toArray());
		assertFalse(rbac.hasUserPermission("michele", "create", "users"));
		assertFalse(rbac.hasUserPermission("michele", "update_others", "posts"));
	}
	
	@Test
	public void testCreation() throws PersistenceException {
		rbac.createRole("writer", new Permission[] {
				new Permission("pippo", new String[]{ "pluto" }),
		});
		assertTrue(rbac.hasUserPermission("andrea", "pippo", "pluto"));
		assertFalse(rbac.hasUserPermission("andrea", "create", "pages"));
	}
	
}
