package it.nose.test;

import java.net.UnknownHostException;

import com.google.code.morphia.Datastore;
import com.google.code.morphia.Key;
import com.google.code.morphia.Morphia;
import com.google.code.morphia.annotations.Entity;
import com.google.code.morphia.annotations.Id;
import com.google.code.morphia.annotations.Property;
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
		
		Datastore ds = morphia.createDatastore("hr");
		
		ds.ensureIndexes();
		ds.ensureCaps();

		// Clean the db
		ds.delete(ds.find(Bean.class));
		
		Key<Bean> bean = ds.save(new Bean("Michele", "Mastrogiovanni"));
		System.out.println(bean);
		
		Bean bb = ds.find(Bean.class).get();
		System.out.println(bb);
		
		Bean t = ds.get(Bean.class, bb.getId());
		System.out.println(t);
		
//		Query<Bean> query = ds.find(Bean.class);
//		for ( Bean b : query ) {
//			System.out.println(b);
//			
//			Bean b1 = ds.find(Bean.class, "id", b.getId()).get();
//			System.out.println("\t- " + b.getId() + ": " + b1);
//		}
		
	}

}
