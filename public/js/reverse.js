function initializeReverse(api_key) {
  var map = L.mapotempo.map('map').setView([44.837778, -0.579197], 13);

  var marker = undefined;

  map.on('click', function(e) {
    if (marker) {
      map.removeLayer(marker);
    }
    marker = null;
    $.ajax({
      url: '0.1/reverse.json?api_key=' + api_key,
      method: 'GET',
      data: {
        lat: e.latlng.lat,
        lng: e.latlng.lng
      },
      context: document.body
    }).done(function(resp) {
      if (resp.features.length) {
        resp.features.forEach(function(feat) {
          if (feat.geometry && feat.geometry.coordinates) {
            marker = L.marker(feat.geometry.coordinates.reverse())
              .addTo(map)
              .bindPopup('<div>' + feat.properties.geocoding.name + '</div><div>' + feat.properties.geocoding.postcode + ' ' + feat.properties.geocoding.city + '</div><div>Score: ' + feat.properties.geocoding.score.toFixed(2) + '</div>')
              .openPopup();
          }
        });
      }
      else {
        alert("No result");
      }
    }).fail(function(resp) {
      alert("An error has occured: " + JSON.stringify(resp));
    });
  });
}
