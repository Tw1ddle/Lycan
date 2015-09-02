package lycan.assets;

#if macro

import haxe.ds.StringMap;
import haxe.macro.Context;
import haxe.macro.Expr;
import sys.FileSystem;

using StringTools;
using Lambda;

// How to search through the folders when indexing items
@:enum abstract FolderSearchMode(String) {
	var TOP_LEVEL_ONLY = "TOP_LEVEL_ONLY";
	var RECURSIVE = "RECURSIVE";
}

// The actual name and values to index e.g. just the filename, or the full path (relative to the top level directory)
@:enum abstract IndexingMode(String) {
	var FILE_NAME = "FILE_NAME";
	var FULL_PATH = "FULL_PATH";
}

// How to deal with duplicate items i.e. two files with the same name
@:enum abstract DuplicateHandlingMode(String) {
	var DISCARD = "DISCARD";
	// var INCLUDE; // Will lead to compile time error due to duplicate class field declaration
}

@:enum abstract IndexType(String) {
	var INLINE_STRINGS = "INLINE_STRINGS";
	var STRING_ARRAY = "STRING_ARRAY";
}

// Generates a lookup class for assets
class AssetIndexBuilder {
	macro public static function buildIndex(directories:Array<String>, ?searchMode:String, ?indexingMode:String, ?duplicateHandlingMode:String, ?indexType:String, ?matchNames:String):Array<Field> {
		if (searchMode == null) {
			searchMode = cast RECURSIVE;
		}
		if (indexingMode == null) {
			indexingMode = cast FILE_NAME;
		}
		if (duplicateHandlingMode == null) {
			duplicateHandlingMode = cast DISCARD;
		}
		if (indexType == null) {
			indexType = cast STRING_ARRAY;
		}
		
		var assetFieldMap = new StringMap<Field>();
		
		for (path in directories) {
			var fileIndex:Array<FileReference> = getFileReferences(path, searchMode, indexingMode, duplicateHandlingMode, matchNames);
			
			// TODO handle duplicates
			
			switch(indexType) {
				case IndexType.INLINE_STRINGS:
					for (index in fileIndex) {
						assetFieldMap.set(index.fieldName, {
							name: index.fieldName,
							doc: index.fieldDocumentation,
							access: [Access.APublic, Access.AStatic, Access.AInline],
							kind: FieldType.FVar(macro:String, macro $v{index.fieldValue}),
							pos: Context.currentPos()
						});
					}
				case IndexType.STRING_ARRAY:
					var files:Array<String> = new Array<String>();
					for (index in fileIndex) {
						files.push(index.fieldValue);
					}
					assetFieldMap.set("index", {
						name: "INDEX",
						doc: "Index of autogenerated asset paths",
						access: [Access.APublic, Access.AStatic],
						kind: FieldType.FVar(macro:Array<String>, Context.makeExpr(files, Context.currentPos()) ),
						pos: Context.currentPos()
					});
			}
		}
		
		var fields:Array<Field> = Context.getBuildFields();
		for (it in assetFieldMap.iterator()) {
			fields.push(it);
		}
		
		// Sort fields alphabetically
		fields.sort(function(a:Field, b:Field):Int {
			var a = a.name.toLowerCase();
			var b = b.name.toLowerCase();
			
			if (a < b) {
				return -1;
			} else if (a > b) {
				return 1;
			} else {
				return 0;
			}
		});
		
		return fields;
	}
	
	private static function getFileReferences(directory:String, searchMode:String, indexingMode:String, duplicateHandlingMode:String, matchNames:String):Array<FileReference> {
		if (!directory.endsWith("/")) {
			directory += "/";
		}
		
		var references:Array<FileReference> = [];
		var directoryInfo:Array<String> = FileSystem.readDirectory(directory);
		
		var matcher:EReg = null;
		
		if(matchNames != null) {
			matcher = new EReg(matchNames, "i");
		}
		
		for (name in directoryInfo) {
			var isDirectory:Bool = FileSystem.isDirectory(directory + name);
			
			if (!isDirectory) {
				if (matcher != null) {
					if (!matcher.match(name)) {
						continue;
					}
				}
				
				var ref;
				switch(indexingMode) {
					case IndexingMode.FILE_NAME:
						ref = new FileReference(name);
					case IndexingMode.FULL_PATH:
						ref = new FileReference(directory + name);
				}
				
				switch(duplicateHandlingMode) {
					case DuplicateHandlingMode.DISCARD:
						var hasRef = Lambda.has(references, ref);
						if (!hasRef) {
							references.push(ref);
						}
				}
			} else {
				if (searchMode == cast FolderSearchMode.RECURSIVE) {
					references = references.concat(getFileReferences(directory + name + "/", searchMode, indexingMode, duplicateHandlingMode, matchNames));
				}
			}
		}
		
		return references;
	}
}

private class FileReference {
	public var fieldName:String;
	public var fieldValue:String;
	public var fieldDocumentation:String;
	
	public function new(value:String) {
		// Replace some symbols with underscores, since HaXe variables cannot contain these symbols.
		fieldName = value.split("-").join("_").split(".").join("__");
		var split: Array<String> = fieldName.split("/");
		fieldName = split[split.length - 1];
		
		validateValue(value);
		fieldValue = value;

		// Auto generate documentation
		fieldDocumentation = "\"" + value + "\" (auto generated).";
	}
	
	private static function validateValue(value:String):Void
	{
		// Check if file name should work on all platforms
		// Note that some platforms have a lot of restrictions
		// For example, Windows won't accept names like COM, AUX, NUL, COM1 to COM9, LPT1 to LPT9
		var nameValidation:EReg = ~/[a-z0-9_]+\.[a-z][a-z][a-z]?/;
		
		if (!nameValidation.match(value)) {
			Context.warning("Warning : [ " + value + " ] may be an invalid filename on some systems ", Context.currentPos() );
		}
	}
}

#end