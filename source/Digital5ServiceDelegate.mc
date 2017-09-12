using Toybox.Background;
using Toybox.System;
using Toybox.Application as App;
using Toybox.Communications as Comm;
using Toybox.WatchUi as Ui;

(:background)
class Digital5ServiceDelegate extends System.ServiceDelegate {
    var showSunriseSunset;
    var apiKey;
    
    function initialize() {
        //System.println("initialize()");
        ServiceDelegate.initialize();
        showSunriseSunset = App.getApp().getProperty("SunriseSunset");
        apiKey            = App.getApp().getProperty("DarkSkyApiKey");
    }
    
    function onTemporalEvent() {
        //System.println("onTemporalEvent()");
        var location = Activity.getActivityInfo().currentLocation;
        if (null == location) {
            var lat = App.getApp().getProperty("UserLat").toFloat();
            var lng = App.getApp().getProperty("UserLng").toFloat();
            if (null != lat && null != lng) {
                if (apiKey.length() > 0) {
                    requestWeather(lat, lng, apiKey);
                } else {
                    requestSunriseSunset(lat, lng);
                }
            } else {
                Background.exit("NA");
            }
        } else {
            if (apiKey.length() > 0) {
                requestWeather(location.toDegrees()[0], location.toDegrees()[1], apiKey);
            } else {
                requestSunriseSunset(location.toDegrees()[0], location.toDegrees()[1]);
            }
        }
    }

    function requestSunriseSunset(lat, lng) {
        //System.println("requestSunriseSunset(" + lat.toString() + ", " + lng.toString() + ")");
        var url     = "https://api.sunrise-sunset.org/json?lat=" + lat.toString() + "&lng=" + lng.toString();
        var params  = {};
        var options = {
            :methods => Comm.HTTP_REQUEST_METHOD_GET,
            :headers => { "Content-Type" => Comm.REQUEST_CONTENT_TYPE_JSON },
            :responseType => Comm.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };
        if (System.getDeviceSettings().phoneConnected) {
            //System.println("makeWebRequest for Sunrise/Sunset");
            Comm.makeWebRequest(url, params, options, method(:onReceive));
        }
    }

    function requestWeather(lat, lng, apiKey) {
        //System.println("requestWeather(" + lat.toString() + ", " + lng.toString() + ", " + apiKey + ")");
        var now     = Time.now().value(); // Unix epoch seconds
        var url     = "https://api.darksky.net/forecast/" + apiKey + "/" + lat.toString() + "," + lng.toString() + "," + now;
        var params  = { "exclude" => "currently,minutely,hourly,alerts,flags", "units" => "si" };
        var options = {
            :methods      => Comm.HTTP_REQUEST_METHOD_GET,
            :headers      => { "Content-Type" => Comm.REQUEST_CONTENT_TYPE_JSON },
            :responseType => Comm.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };
        if (System.getDeviceSettings().phoneConnected) {
            //System.println("makeWebRequest for Weather");
            Comm.makeWebRequest(url, params, {}, method(:onReceive));
        }
    }

    function onReceive(responseCode, data) {
        //System.println("onReceive(" + responseCode + ", " + data + ")");
        if (responseCode == 200) {
            if (data instanceof Lang.String) {
                if (data.equals("Forbidden")) { Background.exit("WRONG KEY"); }
            }
            if (apiKey.length() > 0) {
                //System.println("Write data to dictionary");
                var daily = data.get("daily");
                var days  = daily.get("data");
                var today = days[0];
                var dict = {
                    "icon"    => today.get("icon"),
                    "sunrise" => today.get("sunriseTime"),
                    "sunset"  => today.get("sunsetTime"),
                    "minTemp" => today.get("temperatureMin"),
                    "maxTemp" => today.get("temperatureMax")
                };
                System.println("Dictionary: " + dict);
                Background.exit(dict);
            } else {
                Background.exit(data);
            }
        } else {
            Background.exit("FAIL");
        }    
    }
}