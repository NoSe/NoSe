package it.nose;

import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;
import it.nose.persistence.PersistenceException;
import it.nose.persistence.auth.AuthDB;

import org.junit.After;
import org.junit.Before;
import org.junit.Test;

public class AuthTest {
	
	private AuthDB auth;
	
	@Before
	public void setup() throws PersistenceException {
		
		this.auth = new AuthDB("test_");
		
		auth.registerUser("micmastr", "apriti80");

	}
	
	@After
	public void tearDown() {
		this.auth.dropDB();
	}
	
	@Test
	public void testRegistration() throws PersistenceException {
		assertTrue(auth.registerUser("andrea", "pippo") != null);
	}
	
	@Test
	public void testAuthorization() throws PersistenceException {
		assertTrue(auth.isAuthorized("micmastr", "apriti80"));
	}

	@Test
	public void testUnauthorized() throws PersistenceException {
		assertFalse(auth.isAuthorized("micmastr", "pippo"));
	}

	@Test
	public void testPasswordChange() throws PersistenceException {
		assertTrue(auth.updatePassword("micmastr", "apriti80", "pluto"));
		assertTrue(auth.isAuthorized("micmastr", "pluto"));
	}

	@Test
	public void testBadPasswordChange() throws PersistenceException {
		assertFalse(auth.updatePassword("micmastr", "nonricordo", "pluto"));
	}
	
	@Test
	public void testUserDeletion() throws PersistenceException {
		assertTrue(auth.deleteUser("micmastr", "apriti80"));
	}

	@Test
	public void testBadUserDeletion1() throws PersistenceException {
		assertFalse(auth.deleteUser("micmastr", "pluto"));
	}

	@Test
	public void testBadUserDeletion2() throws PersistenceException {
		assertFalse(auth.deleteUser("unexisting", "---"));
	}

}
