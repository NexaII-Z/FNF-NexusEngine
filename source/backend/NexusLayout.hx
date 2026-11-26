package backend;

/**
 * Where the built-in (base game) content lives inside assets/shared.
 *
 * Nexus keeps its data folders together under  assets/shared/nexus/ :
 *
 *   assets/shared/nexus/weeks/       week definitions + weekList.txt
 *   assets/shared/nexus/stages/      stage definitions
 *   assets/shared/nexus/characters/  character definitions
 *   assets/shared/nexus/data/        charts (data/<song>/...) and lists
 *
 * Code keeps asking for "weeks/x.json", "characters/bf.json", "data/song/song.json";
 * Paths.getSharedPath() sends those requests through redirect(), so nothing else needs to know
 * where the files really are. Mod folders are not affected.
 */
class NexusLayout
{
	public static inline var ROOT:String = 'nexus/';

	/** Top-level folders that were moved under ROOT. */
	public static final MOVED:Array<String> = ['weeks', 'stages', 'characters', 'data'];

	/** "weeks/week1.json" -> "nexus/weeks/week1.json"; everything else is returned unchanged. */
	public static function redirect(file:String):String
	{
		if (file == null) return file;

		for (folder in MOVED)
			if (file == folder || file.startsWith(folder + '/'))
				return ROOT + file;

		return file;
	}

	/** The reverse of redirect(), handy for tools that display the logical path. */
	public static function logical(file:String):String
	{
		return (file != null && file.startsWith(ROOT)) ? file.substr(ROOT.length) : file;
	}
}
