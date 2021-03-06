package lycan.leaderboards;

#if googleplayleaderboards

import extension.googleplaygames.GooglePlayGames;
import extension.googleplaygames.GooglePlayGravity;
import extension.googleplaygames.GooglePlayLeaderboardTimespan;
import extension.googleplaygames.GooglePlayListener;

class GooglePlayLeaderboards {
	public static var get(default, never):GooglePlayLeaderboards = new GooglePlayLeaderboards();
	
	private function new() {
		GooglePlayGames.init();
	}
	
	public function setListener(listener:GooglePlayListener):Void {
		GooglePlayGames.setListener(listener);
	}
	
	public function signIn():Void {
		GooglePlayGames.signIn();
	}
	
	public function signOut():Void {
		GooglePlayGames.signOut();
	}
	
	public function openLeaderboard(id:String, timespan:LeaderboardTimespan = DAILY):Void {
		if (id.length > 0) {
			GooglePlayGames.showLeaderboard(id, timespan);
		} else {
			GooglePlayGames.showLeaderboards();
		}
	}
	
	public function openAchievements():Void {
		GooglePlayGames.showAchievements();
	}
	
	public function submitScore(leaderboardId:String, score:Int, ?scoreTag:String = ""):Void {
		GooglePlayGames.submitScore(leaderboardId, score, scoreTag);
	}
	
	public function incrementAchievement(id:String, numSteps:Int):Void {
		GooglePlayGames.incrementAchievement(id, numSteps);
	}
	
	public function revealAchievement(id:String):Void {
		GooglePlayGames.revealAchievement(id);
	}
	
	public function revealAchievementImmediate(id:String):Void {
		GooglePlayGames.revealAchievementImmediate(id);
	}
	
	public function setAchievementSteps(id:String, numSteps:Int):Void {
		GooglePlayGames.setAchievementSteps(id, numSteps);
	}
	
	public function unlockAchievement(id:String):Void {
		GooglePlayGames.unlockAchievement(id);
	}
	
	public function setGravityForPopups(horizontalGravity:HorizontalGravity, verticalGravity:VerticalGravity):Void {
		GooglePlayGames.setGravityForPopups(horizontalGravity, verticalGravity);
	}
}

#end