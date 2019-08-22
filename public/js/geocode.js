function initializeGeocode(api_key) {
  var map = L.mapotempo.map('map').setView([44.837778, -0.579197], 13);

  var markers = [];
  var markersGroup = L.layerGroup();
  var geocode_url = '0.1/geocode.json?api_key=' + api_key

  $('#geocoder-form').on('submit', function(e) {
    e.preventDefault();
    $.ajax({
      url: geocode_url,
      method: 'GET',
      data: {
        country: $('#country').val(),
        query: $('#q').val()
      },
      context: document.body
    }).done(function(resp) {
      geocodeHandler(resp);
    });
  });

  $("#q").autocomplete({
    source: function(request, response) {
      markers.length = 0;
      markersGroup.clearLayers();
      $.ajax({
        url: geocode_url,
        dataType: "json",
        method: 'PATCH',
        data: {
          country: $('#country').val(),
          query: request.term
        },
        context: document.body,
        success: function(data) {
          response(data.features.map(function(feature) {
            return feature.properties.geocoding;
          }));
        }
      }).done(function(resp) {
        geocodeHandler(resp);
      });
    },
    minLength: 3,
    delay: 500,
    select: function(e, ui) {
      $.ajax({
        url: geocode_url,
        method: 'GET',
        data: {
          country: $('#country').val(),
          query: ui.item.value
        },
        success: function(data) {
          return data.features.map(function(feature) {
            return feature.properties.geocoding;
          });
        },
        context: document.body
      }).done(function(resp) {
        geocodeHandler(resp);
      });
    }
  });

  var geocodeHandler = function geocodeHandler(resp) {
    markers.length = 0;
    markersGroup.clearLayers();
    if (resp.features.length) {
      resp.features.forEach(function(feat) {
        if (feat.geometry && feat.geometry.coordinates) {
          markers.push(L.marker(feat.geometry.coordinates.reverse())
            .bindPopup('<div>' + feat.properties.geocoding.name + '</div><div>' + (feat.properties.geocoding.postcode || '') + ' ' + feat.properties.geocoding.city + '</div><div>Score: ' + feat.properties.geocoding.score.toFixed(2) + '</div>'));
        }
      });
      if (markers.length) {
        markersGroup = L.layerGroup(markers);
        markersGroup.addTo(map);
        var bounds = new L.LatLngBounds(markers.map(function(marker) {
          return marker.getLatLng();
        }));
        L.Icon.Default.extend({});
        markers[0]
          .setIcon(new L.Icon({
            iconUrl: 'marker-icon-yellow.png',
            shadowUrl: 'marker-shadow.png',
            iconSize: [25, 41],
            iconAnchor: [12, 41],
            popupAnchor: [1, -34],
            tooltipAnchor: [16, -28],
            shadowSize: [41, 41]
          }))
          .setZIndexOffset(1000)
          .openPopup();
        map.fitBounds(bounds, {
          padding: [30, 30]
        });
      }
    }
    else {
      alert("No result");
    }
  };
}
