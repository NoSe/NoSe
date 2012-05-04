package it.nose.persistence.auth;

import it.nose.persistence.AbstractMongoDB;
import it.nose.persistence.PersistenceException;
import it.nose.persistence.auth.model.Permission;

import java.util.Set;
import java.util.TreeSet;

import com.mongodb.BasicDBList;
import com.mongodb.BasicDBObject;
import com.mongodb.DBAddress;
import com.mongodb.DBObject;
import com.mongodb.MongoException;

public class RbacDB {
	
	private AbstractMongoDB users;
	private AbstractMongoDB roles;

	private static String dbName = "nose";
	
	private static String dbCollectionUsers = "rbac_users";
	private static String dbCollectionRoles = "rbac_roles";

	public RbacDB() {
		this(null, "");
	}

	public RbacDB(String prefix) {
		this(null, prefix);
	}
	
	public void dropDB() {
		users.dropDB();
		roles.dropDB();
	}

	public RbacDB(DBAddress address, String prefix) {
		users = new AbstractMongoDB(address, prefix + dbName, dbCollectionUsers);
		roles = new AbstractMongoDB(address, prefix + dbName, dbCollectionRoles);
	}
		
	public void clear() throws PersistenceException {
		users.getCollection().remove(new BasicDBObject());
		roles.getCollection().remove(new BasicDBObject());
	}
	
	public void createRole(String roleName, Permission[] permissions) throws MongoException, PersistenceException {
		BasicDBObject role = new BasicDBObject("name", roleName);
		DBObject roleBean = roles.getCollection().findOne(role);
		if ( roleBean == null )
			roleBean = role;
		BasicDBList pms = new BasicDBList();
		for ( Permission p : permissions ) {
			BasicDBList resources = new BasicDBList();
			for ( String resource : p.getResources() )
				resources.add(resource);
			BasicDBObject permission = new BasicDBObject("name", p.getName());
			permission.append("resources", resources);
			pms.add(permission);
		}
		roleBean.put("permissions", pms);
		roles.getCollection().save(roleBean);
	}
		
	private boolean hasRolePermission(String roleName, String operation, String resource) throws PersistenceException {
		BasicDBObject role = new BasicDBObject("name", roleName);
		DBObject roleBean = roles.getCollection().findOne(role);
		BasicDBList permissions = (BasicDBList) roleBean.get("permissions");
		if ( permissions == null )
			return false;
		for ( Object oPermission : permissions ) {
			DBObject permission = (DBObject) oPermission;
			if (!permission.get("name").equals(operation))
				continue;
			BasicDBList resources = (BasicDBList) permission.get("resources");
			if ( resources == null )
				continue;
			if ( resources.contains(resource))
				return true;
		}
		return false;
	}
	
	public boolean hasUserPermission(String user, String operation, String resource) throws PersistenceException {
		for ( String role : getUserRoles(user) )
			if ( hasRolePermission(role, operation, resource))
				return true;
		return false;
	}
	
	public void removeRole(String user, String role) throws PersistenceException {
		BasicDBObject userQuery = new BasicDBObject("user", user);
		DBObject userBean = users.getCollection().findOne(userQuery);
		if ( userBean == null )
			return;
		BasicDBList list = (BasicDBList) userBean.get("roles");
		if ( list == null )
			return;
		list.remove(role);
		userBean.put("roles", list);
		users.getCollection().save(userBean);
	}
	
	public void assignRole(String user, String role) throws PersistenceException {
		BasicDBObject userQuery = new BasicDBObject("user", user);
		DBObject userBean = users.getCollection().findOne(userQuery);
		if ( userBean == null )
			userBean = new BasicDBObject("user", user);
		BasicDBList list = (BasicDBList) userBean.get("roles");
		if ( list == null )
			list = new BasicDBList();
		list.add(role);
		userBean.put("roles", list);
		users.getCollection().save(userBean);
	}
	
	public Set<String> getUserRoles(String user) throws PersistenceException {
		BasicDBObject userQuery = new BasicDBObject("user", user);
		DBObject userBean = users.getCollection().findOne(userQuery);
		if ( userBean == null )
			return new TreeSet<String>();
		BasicDBList list = (BasicDBList) userBean.get("roles");
		if ( list == null )
			return new TreeSet<String>();
		Set<String> ret = new TreeSet<String>();
		for ( int i = 0; i < list.size(); i ++ )
			ret.add(list.get(i).toString());
		return ret;
	}
		
}
