package;

import flixel.FlxG;
import flixel.graphics.frames.FlxAtlasFrames;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;
import lime.utils.Assets;
import flixel.FlxSprite;
#if MODS_ALLOWED
import sys.io.File;
import sys.FileSystem;
import flixel.graphics.FlxGraphic;
import openfl.display.BitmapData;
#end

import flash.media.Sound;

using StringTools;

class Paths
{
	inline public static var SOUND_EXT = #if web "mp3" #else "ogg" #end;
	inline public static var VIDEO_EXT = "mp4";

	#if MODS_ALLOWED
	#if (haxe >= "4.0.0")
	public static var customImagesLoaded:Map<String, Bool> = new Map();
	public static var customSoundsLoaded:Map<String, Sound> = new Map();
	#else
	public static var customImagesLoaded:Map<String, Bool> = new Map<String, Bool>();
	public static var customSoundsLoaded:Map<String, Sound> = new Map<String, Sound>();
	#end
	
	public static var ignoreModFolders:Array<String> = [
		'characters',
		'custom_events',
		'custom_notetypes',
		'data',
		'songs',
		'music',
		'sounds',
		'videos',
		'images',
		'stages',
		'weeks'
	];
	#end

	public static function destroyLoadedImages(ignoreCheck:Bool = false) {
		#if MODS_ALLOWED
		if(!ignoreCheck && ClientPrefs.imagesPersist) return; //If there's 20+ images loaded, do a cleanup just for preventing a crash

		for (key in customImagesLoaded.keys()) {
			var graphic:FlxGraphic = FlxG.bitmap.get(key);
			if(graphic != null) {
				graphic.bitmap.dispose();
				graphic.destroy();
				FlxG.bitmap.removeByKey(key);
			}
		}
		Paths.customImagesLoaded.clear();
		#end
	}

	static public var currentModDirectory:String = '';
	static var currentLevel:String;
	static public function setCurrentLevel(name:String)
	{
		currentLevel = name.toLowerCase();
	}

	public static function getPath(file:String, type:AssetType, ?library:Null<String> = null)
	{
		if (library != null)
			return getLibraryPath(file, library);

		if (currentLevel != null)
		{
			var levelPath:String = '';
			if(currentLevel != 'shared') {
				levelPath = getLibraryPathForce(file, currentLevel);
				if (OpenFlAssets.exists(levelPath, type))
					return levelPath;
			}

			levelPath = getLibraryPathForce(file, "shared");
			if (OpenFlAssets.exists(levelPath, type))
				return levelPath;
		}

		return getPreloadPath(file);
	}

	static public function getLibraryPath(file:String, library = "preload")
	{
		return if (library == "preload" || library == "default") getPreloadPath(file); else getLibraryPathForce(file, library);
	}

	inline static function getLibraryPathForce(file:String, library:String)
	{
		return '$library:assets/$library/$file';
	}

	inline public static function getPreloadPath(file:String = '')
	{
		return 'assets/$file';
	}

	inline static public function file(file:String, type:AssetType = TEXT, ?library:String)
	{
		return getPath(file, type, library);
	}

	inline static public function txt(key:String, ?library:String)
	{
		return getPath('data/$key.txt', TEXT, library);
	}

	inline static public function xml(key:String, ?library:String)
	{
		return getPath('data/$key.xml', TEXT, library);
	}

	inline static public function json(key:String, ?library:String)
	{
		return getPath('data/$key.json', TEXT, library);
	}

	inline static public function lua(key:String, ?library:String)
	{
		return getPath('$key.lua', TEXT, library);
	}

	static public function video(key:String)
	{
		#if MODS_ALLOWED
		var file:String = modsVideo(key);
		if(FileSystem.exists(file)) {
			return file;
		}
		#end
		return 'assets/videos/$key.$VIDEO_EXT';
	}

	static public function sound(key:String, ?library:String):Sound
	{
		var sound:Sound = returnSound('sounds', key, library);
		return sound;
	}

	inline static public function soundRandom(key:String, min:Int, max:Int, ?library:String)
	{
		return sound(key + FlxG.random.int(min, max), library);
	}

	inline static public function music(key:String, ?library:String):Sound
	{
		var file:Sound = returnSound('music', key, library);
		return file;
	}

	inline static public function voices(song:String):Any
	{
		var songKey:String = '${formatToSongPath(song)}/Voices';
		var voices = returnSound('songs', songKey);
		return voices;
	}

	inline static public function inst(song:String):Any
	{
		var songKey:String = '${formatToSongPath(song)}/Inst';
		var inst = returnSound('songs', songKey);
		return inst;
	}


public static var localTrackedAssets:Array<String> = [];
	public static var currentTrackedSounds:Map<String, Sound> = [];

public static function returnSound(path:String, key:String, ?library:String)
	{
		
		// I hate this so god damn much
		var gottenPath:String = getPath('$path/$key.$SOUND_EXT', SOUND, library);
		gottenPath = gottenPath.substring(gottenPath.indexOf(':') + 1, gottenPath.length);
		// trace(gottenPath);
		if (!currentTrackedSounds.exists(gottenPath))
			{
				var folder:String = '';
				if (path == 'songs')
					folder = 'songs:';

				currentTrackedSounds.set(gottenPath, OpenFlAssets.getSound(folder + getPath('$path/$key.$SOUND_EXT', SOUND, library)));
			}
		
		localTrackedAssets.push(gottenPath);
		return currentTrackedSounds.get(gottenPath);
	}


	#if MODS_ALLOWED
	inline static private function returnSongFile(file:String):Sound
	{
		if(FileSystem.exists(file)) {
			if(!customSoundsLoaded.exists(file)) {
				customSoundsLoaded.set(file, Sound.fromFile(file));
			}
			return customSoundsLoaded.get(file);
		}
		return null;
	}
	#end

	inline static public function image(key:String, ?library:String):Dynamic
	{
		
		return getPath('images/$key.png', IMAGE, library);
	}
	
	static public function getTextFromFile(key:String, ?ignoreMods:Bool = false):String
	{
		#if sys
		

		if (FileSystem.exists(getPreloadPath(key)))
			return File.getContent(getPreloadPath(key));

		if (currentLevel != null)
		{
			var levelPath:String = '';
			if(currentLevel != 'shared') {
				levelPath = getLibraryPathForce(key, currentLevel);
				if (FileSystem.exists(levelPath))
					return File.getContent(levelPath);
			}

			levelPath = getLibraryPathForce(key, 'shared');
			if (FileSystem.exists(levelPath))
				return File.getContent(levelPath);
		}
		#end
		return Assets.getText(getPath(key, TEXT));
	}

	inline static public function font(key:String)
	{
		return 'assets/fonts/$key';
	}

	inline static public function fileExists(key:String, type:AssetType, ?ignoreMods:Bool = false, ?library:String)
	{
		
		
		if(OpenFlAssets.exists(Paths.getPath(key, type))) {
			return true;
		}
		return false;
	}

	inline static public function getSparrowAtlas(key:String, ?library:String)
	{
		
		return FlxAtlasFrames.fromSparrow(image(key, library), file('images/$key.xml', library));
		
	}

	inline static public function getPackerAtlas(key:String, ?library:String)
	{
		
		return FlxAtlasFrames.fromSpriteSheetPacker(image(key, library), file('images/$key.txt', library));
		
	}

	inline static public function formatToSongPath(path:String) {
		var invalidChars = ~/[~&\\;:<>#]/;
		var hideChars = ~/[.,'"%?!]/;

		var path = invalidChars.split(path.replace(' ', '-')).join("-");
		return hideChars.split(path).join("").toLowerCase();
	}

	#if MODS_ALLOWED
	static public function addCustomGraphic(key:String):FlxGraphic {
		if(FileSystem.exists(modsImages(key))) {
			if(!customImagesLoaded.exists(key)) {
				var newBitmap:BitmapData = BitmapData.fromFile(modsImages(key));
				var newGraphic:FlxGraphic = FlxGraphic.fromBitmapData(newBitmap, false, key);
				newGraphic.persist = true;
				FlxG.bitmap.addGraphic(newGraphic);
				customImagesLoaded.set(key, true);
			}
			return FlxG.bitmap.get(key);
		}
		return null;
	}

	inline static public function mods(key:String = '') {
		return 'mods/' + key;
	}

	inline static public function modsJson(key:String) {
		return modFolders('data/' + key + '.json');
	}

	inline static public function modsVideo(key:String) {
		return modFolders('videos/' + key + '.' + VIDEO_EXT);
	}

	inline static public function modsMusic(key:String) {
		return modFolders('music/' + key + '.' + SOUND_EXT);
	}

	inline static public function modsSounds(key:String) {
		return modFolders('sounds/' + key + '.' + SOUND_EXT);
	}

	inline static public function modsSongs(key:String) {
		return modFolders('songs/' + key + '.' + SOUND_EXT);
	}

	inline static public function modsImages(key:String) {
		return modFolders('images/' + key + '.png');
	}

	inline static public function modsXml(key:String) {
		return modFolders('images/' + key + '.xml');
	}

	inline static public function modsTxt(key:String) {
		return modFolders('images/' + key + '.txt');
	}

	static public function modFolders(key:String) {
		if(currentModDirectory != null && currentModDirectory.length > 0) {
			var fileToCheck:String = mods(currentModDirectory + '/' + key);
			if(FileSystem.exists(fileToCheck)) {
				return fileToCheck;
			}
		}
		return 'mods/' + key;
	}

	static public function getModDirectories():Array<String> {
		var list:Array<String> = [];
		var modsFolder:String = Paths.mods();
		if(FileSystem.exists(modsFolder)) {
			for (folder in FileSystem.readDirectory(modsFolder)) {
				var path = haxe.io.Path.join([modsFolder, folder]);
				if (sys.FileSystem.isDirectory(path) && !Paths.ignoreModFolders.contains(folder) && !list.contains(folder)) {
					list.push(folder);
				}
			}
		}
		return list;
	}
	#end
}
