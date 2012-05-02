package it.nose.gui.window;

import org.vaadin.vol.Area;
import org.vaadin.vol.Marker;
import org.vaadin.vol.MarkerLayer;
import org.vaadin.vol.OpenLayersMap;
import org.vaadin.vol.OpenStreetMapLayer;
import org.vaadin.vol.Point;
import org.vaadin.vol.Popup;
import org.vaadin.vol.Popup.PopupStyle;

import com.vaadin.event.MouseEvents.ClickEvent;
import com.vaadin.event.MouseEvents.ClickListener;
import com.vaadin.ui.Component;
import com.vaadin.ui.Window;

public class MapWindow extends Window {
	
	private static final long serialVersionUID = 1L;

	public MapWindow() {
		super();

		setWidth("100%");
		setHeight("100%");

		addComponent(getMap());
		
	}
	
	private Component getMap() {

		final OpenLayersMap map = new OpenLayersMap();

		OpenStreetMapLayer osm = new OpenStreetMapLayer();

        map.addLayer(osm);

        map.setCenter(22.30083, 60.452541);
        
        // VectorLayer vectorLayer = new VectorLayer();

        Point[] points = new Point[3];
        points[0] = new Point(22.29, 60.45);
        points[1] = new Point(22.30, 60.46);
        points[2] = new Point(22.31, 60.45);        	
        
        Area area = new Area();
        area.setPoints(points);
        
        // Define a Marker Layer
        MarkerLayer markerLayer = new MarkerLayer();

        final Marker marker = new Marker(22.30083, 60.452541);
        // URL of marker Icon
        marker.setIcon("http://dev.vaadin.com/chrome/site/vaadin-trac.png", 60, 20);
        
     // Add some server side integration when clicking a marker
        marker.addClickListener(new ClickListener() {
        	
			private static final long serialVersionUID = 1L;

			public void click(ClickEvent event) {
                final Popup popup = new Popup(marker.getLon(), marker.getLat(), "Vaadin HQ is <em>here</em>!");
                popup.setAnchor(marker);
                popup.setPopupStyle(PopupStyle.FRAMED_CLOUD);
//                popup.addListener(new CloseListener() {
//
//					private static final long serialVersionUID = 1L;
//
//					@Override
//					public void windowClose(CloseEvent e) {
//	                     map.removeComponent(popup);
//					}
//
//
//                });
                map.addPopup(popup);
            }
        });

        // Add the marker to the marker Layer
        markerLayer.addMarker(marker);
        map.setCenter(22.30, 60.452);
        map.setZoom(15);

        map.setSizeFull();
        
        return map;
        
	}
	
}
