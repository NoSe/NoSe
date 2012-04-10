package it.nose.test;

import it.nose.persistence.PersistenceException;
import it.nose.persistence.auth.AuthDB;

public class AuthTest {

	/**
	 * @param args
	 * @throws PersistenceException 
	 */
	public static void main(String[] args) throws PersistenceException {
		
		if ( AuthDB.instance().registerUser("micmastr", "apriti80") != null ) {
			System.out.println("User registered");
		}
		
		for ( int i = 0; i < 2; i ++ ) {

			System.out.println("Authorized: " + AuthDB.instance().isAuthorized("micmastr", "pluto"));
			System.out.println("Authorized: " + AuthDB.instance().isAuthorized("micmastr", "apriti80"));
			System.out.println("Passwd changed: " + AuthDB.instance().updatePassword("micmastr", "apriti80", "pluto"));

		}

		System.out.println("Deleted: " + AuthDB.instance().deleteUser("micmastr", "pluto"));
		
	}

}
