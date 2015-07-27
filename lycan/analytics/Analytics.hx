package lycan.analytics;

#if flurryanalytics
import ru.zzzzzzerg.linden.Flurry;
#end

// TODO implement steamworks stats for this too
class Analytics {
	public static function init(appId:String, appVersion:String) {
		#if flurryanalytics
		Flurry.onStartSession(appId);
		
		Flurry.setVersionName(appVersion);
		Flurry.setReportLocation(false);
		Flurry.setCaptureUncaughtExceptions(true);
		Flurry.setLogEvents(true);
		
		#if debug
		Flurry.setLogEnabled(true);
		Flurry.setLogLevel(2);
		#else
		Flurry.setLogEnabled(false);
		#end
		
		#end
	}
	
	public static function endSession():Void {
		#if flurryanalytics
		Flurry.onEndSession();
		#end
	}
	
	// Note there will be an implementation-defined limit to the number of parameters that can be passed here
	public static function logEvent(id:String, ?params:Dynamic = null):Void {
		#if flurryanalytics
		Flurry.logEvent(id, params, false);
		#end
	}
	
	public static function startTimedEvent(id:String, ?params:Dynamic = null):Void {
		#if flurryanalytics
		Flurry.logEvent(id, params, true);
		#end
	}
	
	public static function endTimedEvent(id:String, ?params:Dynamic = null):Void {
		#if flurryanalytics
		Flurry.endTimedEvent(id, params);
		#end
	}
}