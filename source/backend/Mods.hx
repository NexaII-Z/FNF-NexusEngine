package backend;

import haxe.Json;

typedef ModsList =
{
	enabled:Array<String>,
	disabled:Array<String>,
	all:Array<String>
};

/**
 * Finds and orders the mods in the mods/ folder.
 * modsList.txt remembers which mods are switched on:  one "<folder>|<1 or 0>" per line.
 */
class Mods
{
	static public var currentModDirectory:String = '';

	/** Folder names inside mods/ that belong to the engine, not to a mod. */
	public static var ignoreModFolders:Array<String> = [
		'characters',
		'custom_events',
		'custom_notetypes',
		'data',
		'songs',
		'music',
		'sounds',
		'shaders',
		'videos',
		'images',
		'stages',
		'weeks',
		'fonts',
		'scripts',
		'achievements'
	];

	private static var globalMods:Array<String> = [];

	inline public static function getGlobalMods()
		return globalMods;

	/** Collects the enabled mods whose pack.json says "runsGlobally". */
	inline public static function pushGlobalMods()
	{
		globalMods = [];
		for (mod in parseList().enabled)
		{
			var pack:Dynamic = getPack(mod);
			if (pack != null && pack.runsGlobally) globalMods.push(mod);
		}
		return globalMods;
	}

	inline public static function getModDirectories():Array<String>
	{
		var list:Array<String> = [];
		#if MODS_ALLOWED
		var modsFolder:String = Paths.mods();
		if (FileSystem.exists(modsFolder))
		{
			for (folder in Paths.readDirectory(modsFolder))
			{
				var path:String = haxe.io.Path.join([modsFolder, folder]);
				if (FileSystem.isDirectory(path) && !ignoreModFolders.contains(folder.toLowerCase()) && !list.contains(folder))
					list.push(folder);
			}
		}
		#end
		return list;
	}

	// ---- merged lists (characterList.txt, introText.txt, ...) ------------------------------------

	/** Reads `path` from the base game and every active mod and merges the lines (base game first). */
	inline public static function mergeAllTextsNamed(path:String, defaultDirectory:String = null, allowDuplicates:Bool = false)
	{
		if (defaultDirectory == null) defaultDirectory = Paths.getSharedPath();
		defaultDirectory = defaultDirectory.trim();
		if (!defaultDirectory.endsWith('/')) defaultDirectory += '/';
		if (!defaultDirectory.startsWith('assets/')) defaultDirectory = 'assets/$defaultDirectory';

		var files:Array<String> = directoriesWithFile(defaultDirectory, path);

		// the base game's own file always goes first
		var baseFile:String = baseGamePath(defaultDirectory, path);
		if (files.contains(baseFile))
		{
			files.remove(baseFile);
			files.insert(0, baseFile);
		}

		var merged:Array<String> = [];
		for (file in files)
			for (value in CoolUtil.coolTextFile(file))
				if ((allowDuplicates || !merged.contains(value)) && value.length > 0)
					merged.push(value);
		return merged;
	}

	/** Every folder that has `fileToFind`: the base game first, then global mods, mods/, and the current mod. */
	inline public static function directoriesWithFile(path:String, fileToFind:String, mods:Bool = true)
	{
		var found:Array<String> = [];

		var baseFile:String = baseGamePath(path, fileToFind);
		#if sys
		if (FileSystem.exists(baseFile))
		#end
			found.push(baseFile);

		#if MODS_ALLOWED
		if (mods)
		{
			for (mod in Mods.getGlobalMods())
				addIfExists(found, Paths.mods(mod + '/' + fileToFind));

			addIfExists(found, Paths.mods(fileToFind));

			if (Mods.currentModDirectory != null && Mods.currentModDirectory.length > 0)
				addIfExists(found, Paths.mods(Mods.currentModDirectory + '/' + fileToFind));
		}
		#end
		return found;
	}

	/** Base game files go through the Nexus layout (weeks/, stages/, characters/, data/). */
	public static function baseGamePath(directory:String, file:String):String
	{
		var shared:String = Paths.getSharedPath();
		if (directory == shared || directory == 'assets/shared/')
			return shared + NexusLayout.redirect(file);
		return directory + file;
	}

	public static function addIfExists(list:Array<String>, path:String):Void
	{
		#if sys
		if (FileSystem.exists(path) && !list.contains(path)) list.push(path);
		#end
	}

	// ---- pack.json -----------------------------------------------------------------------------------

	public static function getPack(?folder:String = null):Dynamic
	{
		#if MODS_ALLOWED
		if (folder == null) folder = Mods.currentModDirectory;

		var path:String = Paths.mods(folder + '/pack.json');
		if (FileSystem.exists(path))
		{
			try
			{
				#if sys
				var raw:String = File.getContent(path);
				#else
				var raw:String = Assets.getText(path);
				#end
				if (raw != null && raw.length > 0) return tjson.TJSON.parse(raw);
			}
			catch (e:Dynamic)
			{
				trace(e);
			}
		}
		#end
		return null;
	}

	// ---- modsList.txt ----------------------------------------------------------------------------------

	public static var updatedOnState:Bool = false;

	inline public static function parseList():ModsList
	{
		if (!updatedOnState) updateModList();
		var list:ModsList = {enabled: [], disabled: [], all: []};

		#if MODS_ALLOWED
		try
		{
			for (line in CoolUtil.coolTextFile('modsList.txt'))
			{
				if (line.trim().length < 1) continue;

				var parts:Array<String> = line.split("|");
				list.all.push(parts[0]);
				if (parts[1] == "1") list.enabled.push(parts[0]);
				else list.disabled.push(parts[0]);
			}
		}
		catch (e)
		{
			trace(e);
		}
		#end
		return list;
	}

	private static function updateModList():Void
	{
		#if MODS_ALLOWED
		var entries:Array<Array<Dynamic>> = []; // [folder, enabled]
		var known:Array<String> = [];

		// Keep the order (and on/off state) of mods that are already listed and still exist.
		try
		{
			for (line in CoolUtil.coolTextFile('modsList.txt'))
			{
				var parts:Array<String> = line.split("|");
				var folder:String = parts[0];
				if (isModFolder(folder) && !known.contains(folder))
				{
					known.push(folder);
					entries.push([folder, (parts[1] == "1")]);
				}
			}
		}
		catch (e)
		{
			trace(e);
		}

		// New mod folders are switched on by default.
		for (folder in getModDirectories())
		{
			if (isModFolder(folder) && !ignoreModFolders.contains(folder.toLowerCase()) && !known.contains(folder))
			{
				known.push(folder);
				entries.push([folder, true]);
			}
		}

		File.saveContent('modsList.txt', [for (entry in entries) entry[0] + '|' + (entry[1] ? '1' : '0')].join('\n'));
		updatedOnState = true;
		#end
	}

	static function isModFolder(folder:String):Bool
	{
		#if MODS_ALLOWED
		return folder.trim().length > 0 && FileSystem.exists(Paths.mods(folder)) && FileSystem.isDirectory(Paths.mods(folder));
		#else
		return false;
		#end
	}

	public static function loadTopMod():Void
	{
		Mods.currentModDirectory = '';

		#if MODS_ALLOWED
		var enabled:Array<String> = Mods.parseList().enabled;
		if (enabled != null && enabled[0] != null)
			Mods.currentModDirectory = enabled[0];
		#end
	}
}
