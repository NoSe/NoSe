package it.nose.test;

import java.net.UnknownHostException;

import com.google.code.morphia.Datastore;
import com.google.code.morphia.Key;
import com.google.code.morphia.Morphia;
import com.google.code.morphia.annotations.Entity;
import com.google.code.morphia.annotations.Id;
import com.google.code.morphia.annotations.Property;
import com.google.code.morphia.query.Query;
import com.mongodb.MongoException;
import com.mongodb.ObjectId;

@Entity("bean")
class Bean {
	
	@Id
	private ObjectId id;
	
	@Property
	private String name;
	
	@Property
	private String surname;
	
	public Bean() {}
	
	public Bean(String name, String surname) {
		super();
		this.name = name;
		this.surname = surname;
	}

	public ObjectId getId() {
		return id;
	}

	public void setId(ObjectId id) {
		this.id = id;
	}

	public String getName() {
		return name;
	}

	public void setName(String name) {
		this.name = name;
	}

	public String getSurname() {
		return surname;
	}

	public void setSurname(String surname) {
		this.surname = surname;
	}

	@Override
	public String toString() {
		return "Bean [id=" + id + ", name=" + name + ", surname=" + surname
				+ "]";
	}
	
}

public class TestMorphia {

	/**
	 * @param args
	 * @throws MongoException 
	 * @throws UnknownHostException 
	 */
	public static void main(String[] args) throws UnknownHostException, MongoException {
		
		Morphia morphia = new Morphia();
		morphia.map(Bean.class);
		
		Datastore ds = morphia.createDatastore("hr");
		ds.ensureIndexes();
		ds.ensureCaps();

		// Clean the db
		ds.delete(ds.find(Bean.class));

		// Save a bean
		Key<Bean> bean = ds.save(new Bean("Michele", "Mastrogiovanni"));
		System.out.println(bean);
		
//		Bean bb = ds.find(Bean.class).get();
//		System.out.println(bb);
//		
//		Bean t1 = ds.getByKey(Bean.class, bean);
//		System.out.println(t1);
		
//		Bean t1 = ds.get(Bean.class, bb.getId());
//
//		Bean t2 = ds.get(Bean.class, bean.getId());
//		System.out.println(t2);

		Query<Bean> query = ds.find(Bean.class, "name =", "*ele*");
		for ( Bean b : query ) {
			System.out.println(b);
			
			Bean b1 = ds.find(Bean.class, "id", b.getId()).get();
			System.out.println("\t- " + b.getId() + ": " + b1);
		}
		
	}

}
