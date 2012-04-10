package it.nose.services.rest;

import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;
import javax.ws.rs.core.MediaType;

@Path("/test")
public class TestJsonService {

	@GET
	@Path("/get")
	@Produces({ MediaType.TEXT_XML })
	public String test() {

		return "Hello World!";

	}

}
