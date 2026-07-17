import haxe.DynamicAccess;
import haxe.Json;
import Reflect;
import funkin.save.Save;
import funkin.Paths;
import funkin.util.assets.DataAssets;
import funkin.modding.PolymodHandler;
import StringTools;

typedef LanguageRaw =
{
	var ?name:String;
	var ?special:Array<String>;
	var ?flags:DynamicAccess<Dynamic>;
	var translation_credits:String;
	var lang:DynamicAccess<String>;
	var ?font_replacement:DynamicAccess<String>;
}

@:structInit class Language
{
	public var name:Null<String> = null;
	
	public var special:Null<Array<String>> = null;
	
	public var translationCredits:String = '';
	
	public var lang:Map<String, String> = [];
	
	public var flags:Map<String, String> = [];
	
	public var fontReplacements:Null<Map<String, String>> = null;
	
	public static function fromRaw(raw:Null<LanguageRaw>):Null<Language>
	{
		if (raw == null) return null;
		var lang:Language = {};
		
		lang.name = raw.name;
		lang.special = raw.special;
		lang.translationCredits = raw.translation_credits;
		lang.lang = [for (key => text in raw.lang) key => text];
		
		if (raw.flags != null) lang.flags = [for (key => text in raw.flags) key => text];
		if (raw.font_replacement != null) lang.fontReplacements = [for (key => text in raw.font_replacement) key => text];
		
		return lang;
	}
}

/**
 * The masterclass for Language support.
**/
@:nullSafety
class Lang
{
	public static var current:Null<Language> = null;
	public static var fallback:Null<Language> = null;
	
	static var defaultLanguage:String = 'english';
	
	public static function reloadLangFile():Void
	{
		fallback = loadLang(defaultLanguage);
		
		current = (Save.instance.modOptions["Language"] == defaultLanguage ? fallback : loadLang(Save.instance.modOptions["Language"]));
	}

	/**
	 * Merges two dynamic objects.
	 * This operation will directly modify `obj` in place if can be merged, or return `with` otherwise.
	 * If `obj` and `with` are Json objects, `with` will add and/or overwrite fields.
	 * 
	 * @param obj The initial object
	 * @param with The object to merge `obj` with
	 */
	public static function merge(obj:Dynamic, with:Dynamic):Dynamic
	{
		// um ,.. yeag
		
		if (obj == null || !Reflect.isObject(obj))
		{
			return with;
		}
		else if (with == null || !Reflect.isObject(with))
		{
			return obj;
		}
		
		for (field in Reflect.fields(with))
		{
			Reflect.setField(obj, field, merge(Reflect.field(obj, field), Reflect.field(with, field)));
		}
		
		return obj;
	}
	
	public static function loadLang(lang:String):Null<Language>
	{
		var mergedLang:Null<LanguageRaw> = null;
		
		var directories:Array<String> = [];
		
		for (mod in PolymodHandler.getAllMods())
			directories.push('mods/${mod.dirName}/');
			
		for (dir in directories)
		{
			var path:String = '${dir}lang/$lang.json';
			
			if (Assets.exists(path))
			{
				mergedLang = merge(mergedLang, Json.parse(Assets.getText(path)));
			}
		}
		
		if (mergedLang == null)
		{
			return null;
		}
		
		return (mergedLang?.name == null ? null : Language.fromRaw(mergedLang));
	}
	
	public static function getAvailableLanguages():Array<String>
	{
		// LOADS ALL LANGUAGES AVAILABLE IN LANG FOLDERS
		
		final files = DataAssets.listDataFilesInPath('lang/', '.json');
		
		var LANGUAGES:Array<String> = [];
		
		for (file in files)
		{
			final lang:String = file;
			
			if (!LANGUAGES.contains(lang)) LANGUAGES.push(lang);
		}
		
		LANGUAGES.sort((a, b) -> (b > a ? -1 : 1));
		
		return LANGUAGES;
	}
	
	public static inline function getFont(fnt:String):String
	{
		return current?.fontReplacements?.get(fnt) ?? fnt;
	}
	
	public static inline function hasSpecial(flag:String):Bool
	{
		final s = current?.special;
		return s != null ? s.contains(flag) : false;
	}
	
	public static inline function hasFlag(flag:String):Bool
	{
		return ((current ?? fallback)?.flags.exists(flag) ?? false);
	}
	
	public static inline function getFlag(flag:String):Dynamic
	{
		return (current ?? fallback)?.flags.get(flag);
	}
	
	/**
	 * For RTL languages, reverses the line order of multiline FlxText.
	 * Fixes visual-order Arabic text getting wrapped with lines in wrong reading order.
	**/
	public static function arabicTextFix(textObj:flixel.text.FlxText):Void
	{
		if (!hasSpecial('rightToLeft')) return;
		
		var tf = textObj.textField;
		if (tf.numLines <= 1) return;
		
		var lines:Array<String> = [];
		for (i in 0...tf.numLines)
		{
			lines.push(StringTools.rtrim(tf.getLineText(i)));
		}
		lines.reverse();
		textObj.text = lines.join("\n");
	}
	
	/**
	 * Gets a string from said language!
	 * if string doesn't exist in selected language, tries to receieve it from english, and if english doesn't have it, return [MISSING `line`] instead
	**/
	public static inline function str(line:String, ?fallbackString:String):Null<String>
	{
		return (current?.lang.get(line) ?? fallback?.lang.get(line) ?? fallbackString ?? '<MISSING_$line>');
	}
}
