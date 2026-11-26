package backend;

import objects.Note;

typedef NoteTypeProperty =
{
	property:Array<String>,
	value:Dynamic
}

/**
 * Note types can be described with a plain text file (custom_notetypes/<name>.txt)
 * instead of a script. Each line looks like:
 *
 *     hitHealth = 0.1
 *     extraData.speed: 2
 *     scale.x = 1.5
 *
 * The file is parsed once and its properties are applied to every note of that type.
 */
class NoteTypesConfig
{
	private static var noteTypesData:Map<String, Array<NoteTypeProperty>> = new Map<String, Array<NoteTypeProperty>>();

	public static function clearNoteTypesData():Void
	{
		noteTypesData.clear();
	}

	public static function loadNoteTypeData(name:String):Array<NoteTypeProperty>
	{
		if (noteTypesData.exists(name)) return noteTypesData.get(name);

		var text:String = Paths.getTextFromFile('custom_notetypes/$name.txt');
		if (text == null || !text.contains(':') || !text.contains('='))
		{
			noteTypesData.set(name, null);
			return null;
		}

		var parsed:Array<NoteTypeProperty> = [];
		for (line in CoolUtil.listFromString(text))
		{
			var separator:Int = line.indexOf(':');
			if (separator < 0) separator = line.indexOf('=');
			if (separator < 0) continue;

			var path:Array<String> = [for (part in line.substr(0, separator).split('.')) part.trim()];
			parsed.push({
				property: path,
				value: interpretValue(line.substr(separator + 1).trim())
			});
		}

		noteTypesData.set(name, parsed);
		return parsed;
	}

	public static function applyNoteTypeData(note:Note, name:String):Void
	{
		var data:Array<NoteTypeProperty> = loadNoteTypeData(name);
		if (data == null || data.length < 1) return;

		for (entry in data)
		{
			var path:Array<String> = entry.property;
			try
			{
				if (path.length == 1)
				{
					assign(note, path[0], entry.value);
					continue;
				}

				if (path[0] == 'extraData')
				{
					note.extraData.set(path[1], entry.value);
					continue;
				}
				if (path[0] == 'noteType') continue;

				var target:Dynamic = note;
				for (i in 0...path.length - 1)
					target = fetch(target, path[i]);
				assign(target, path[path.length - 1], entry.value);
			}
			catch (e)
			{
				trace(e);
			}
		}
	}

	// ---- property access ("name" or "name[0][1]") ----------------------------------------

	static function splitIndexed(token:String):{name:String, indices:Array<Int>}
	{
		var open:Int = token.indexOf('[');
		if (open < 0) return {name: token, indices: []};

		var indices:Array<Int> = [];
		for (piece in token.substr(open).split('['))
		{
			if (piece.length < 1) continue;
			indices.push(Std.parseInt(piece.substr(0, piece.length - 1).trim()));
		}
		return {name: token.substr(0, open), indices: indices};
	}

	static function fetch(obj:Dynamic, token:String):Dynamic
	{
		var parts = splitIndexed(token);
		var current:Dynamic = (parts.name.length > 0) ? Reflect.getProperty(obj, parts.name) : obj;
		for (index in parts.indices) current = current[index];
		return current;
	}

	static function assign(obj:Dynamic, token:String, value:Dynamic):Void
	{
		var parts = splitIndexed(token);
		if (parts.indices.length < 1)
		{
			Reflect.setProperty(obj, parts.name, value);
			return;
		}

		var current:Dynamic = (parts.name.length > 0) ? Reflect.getProperty(obj, parts.name) : obj;
		for (i in 0...parts.indices.length - 1) current = current[parts.indices[i]];
		current[parts.indices[parts.indices.length - 1]] = value;
	}

	static function interpretValue(value:String):Any
	{
		var first:String = value.charAt(0);
		if (first == "'" || first == '"') return value.substring(1, value.length - 1);

		switch (value)
		{
			case 'true': return true;
			case 'false': return false;
			case 'null': return null;
		}

		return value.contains('.') ? Std.parseFloat(value) : Std.parseInt(value);
	}
}
