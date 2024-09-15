package funkin.menus;

import funkin.backend.chart.Chart;
import funkin.backend.chart.ChartData.ChartMetaData;
import haxe.io.Path;
import openfl.text.TextField;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import funkin.backend.FlxAnimate;
import lime.utils.Assets;
import funkin.game.HealthIcon;
import funkin.savedata.FunkinSave;
import funkin.backend.scripting.events.*;
import openfl.filters.GlowFilter;
import openfl.display.BlendMode;

using StringTools;

var realScaled = 0.8;//stuff from og freeplay

class FreeplayState extends MusicBeatState
{
	/**
	 * Array containing all of the songs metadatas
	 */
	public var songs:Array<ChartMetaData> = [];

	/**
	 * Currently selected song
	 */
	public var curSelected:Int = 0;
	/**
	 * Currently selected difficulty
	 */
	public var curDifficulty:Int = 1;
	/**
	 * Currently selected coop/opponent mode
	 */
	public var curCoopMode:Int = 0;

	/**
	 * Text containing the score info (PERSONAL BEST: 0)
	 */
	public var scoreText:FlxText;

	/**
	 * Text containing the current difficulty (< HARD >)
	 */
	public var diffText:FlxText;

	/**
	 * Text containing the current coop/opponent mode ([TAB] Co-Op mode)
	 */
	public var coopText:FlxText;

	/**
	 * Currently lerped score. Is updated to go towards `intendedScore`.
	 */
	public var lerpScore:Int = 0;
	/**
	 * Destination for the currently lerped score.
	 */
	public var intendedScore:Int = 0;

	/**
	 * Assigned FreeplaySonglist item.
	 */
	public var songList:FreeplaySonglist;
	/**
	 * Black background around the score, the difficulty text and the co-op text.
	 */
	public var scoreBG:FlxSprite;

	/**
	 * Triangle.
	 */
	public var triangle:FlxSprite;

	/**
	 * TriangleText.
	 */
	 public var triangleText:FlxAnimate;

	/**
	 * TriangleBeatDark.
	 */
	public var triangleBeatDark:FlxSprite;

	/**
	 * TriangleBeat.
	 */
	 public var triangleBeat:FlxSprite;

	/**
	 * TriangleGlow.
	 */
	 public var triangleGlow:FlxSprite;

	/**
	 * bgDad.
	 */
	 public var bgDad:FlxSprite;

	/**
	 * dj.
	 */
	 public var dj:FlxAnimate;

	/**
	 * blackBar.
	 */
	 public var blackBar:FlxSprite;

	/**
	 * freeplayText.
	 */
	 public var freeplayText:FlxSprite;

	/**
	 * ostName.
	 */
	 public var ostName:FlxText;

	/**
	 * ostName.
	 */
	 public var capsules:Array<FlxSpriteGroup> = [];

	/**
	 * Whenever the player can navigate and select
	 */
	public var canSelect:Bool = true;

	/**
	 * Group containing all of the alphabets
	 */
	public var grpSongs:FlxTypedGroup<Alphabet>;

	/**
	 * Whenever the currently selected song is playing.
	 */
	public var curPlaying:Bool = false;

	/**
	 * Array containing all of the icons.
	 */
	public var iconArray:Array<HealthIcon> = [];

	/**
	 * FlxInterpolateColor object for smooth transition between Freeplay colors.
	 */
	public var interpColor:FlxInterpolateColor;


	override function create()
	{
		CoolUtil.playMenuSong();
		songList = FreeplaySonglist.get();
		songs = songList.songs;

		for(k=>s in songs) {
			if (s.name == Options.freeplayLastSong) {
				curSelected = k;
			}
		}
		if (songs[curSelected] != null) {
			for(k=>diff in songs[curSelected].difficulties) {
				if (diff == Options.freeplayLastDifficulty) {
					curDifficulty = k;
				}
			}
		}

		DiscordUtil.call("onMenuLoaded", ["Freeplay"]);

		super.create();

		// LOAD CHARACTERS

		//left bg
		triangle = new FlxSprite().loadGraphic(Paths.image('menus/freeplay/triangle'));
		add(triangle);


		triangleText = new FlxAnimate(0,0,Path.withoutExtension(Paths.image('menus/freeplay/triangle')));//IMPROVE-NOTE use better path 
		triangleText.anim.play('BOYFRIEND ch backing');
		add(triangleText);
		
		triangleBeatDark = new FlxSprite(0,381).loadGraphic(Paths.image('menus/freeplay/beatdark'));
		triangleBeatDark.blend = BlendMode.MULTIPLY;
		triangleBeatDark.x = (triangle.width-200)/2-triangleBeatDark.width/2;
		triangleBeatDark.alpha = 0;
		add(triangleBeatDark);

		triangleBeat = new FlxSprite(0,326).loadGraphic(Paths.image('menus/freeplay/beatglow'));
		triangleBeat.blend = BlendMode.ADD;
		triangleBeat.x = (triangle.width-200)/2-triangleBeat.width/2;
		add(triangleBeat);

		triangleGlow = new FlxSprite(-30, -30).loadGraphic(Paths.image('menus/freeplay/triangleGlow'));
		triangleGlow.blend = BlendMode.ADD;
		triangleGlow.alpha = 0;
		add(triangleGlow);
		
		//right bg
		bgDad = new FlxSprite(triangle.width * 0.74, 0).loadGraphic(Paths.image('menus/freeplay/bg'));
		bgDad.setGraphicSize(0, FlxG.height);
		bgDad.updateHitbox();
		bgDad.antialiasing = true;
		add(bgDad);
		
		//DJ CODE, NOTE ITS NAMED "DJ" NOT BOYFRIEND BC IT CHANGES BETWEEN PICO AND BF 
		dj = new FlxAnimate(640, 366,Path.withoutExtension(Paths.image('menus/freeplay/freeplay-boyfriend')));//IMPROVE-NOTE use better path 
		djPlayAnim('Boyfriend DJ',0,0);
		dj.antialiasing = true;
		add(dj);

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		//random button
		songs.unshift({
			name:'random',
			displayName:'Random',
			bpm:100,
			beatsPerMeasure:4,
			stepsPerBeat:4,
			needVoices:false,
			icon:'bf',
			color: 0xFFFFFFFF,
			parsedColor: 0xFFFFFFFF,
			difficulties:['easy','hard','normal'],
			coopAllowed:false,
			opponentModeAllowed:false
		});

		for (i in 0...songs.length)
		{
			var capsuleGroup:FlxSpriteGroup = new FlxSpriteGroup();
			add(capsuleGroup);

			var capsule:FlxSprite = new FlxSprite(0,0);
			capsule.frames = Paths.getSparrowAtlas('menus/freeplay/freeplayCapsule');
			capsule.animation.addByPrefix('selected', 'mp3 capsule w backing0', 24);
			capsule.animation.addByPrefix('unselected', 'mp3 capsule w backing NOT SELECTED', 24);	
			capsule.animation.play('selected');
			capsule.antialiasing = true;
			capsule.scale.set(realScaled,realScaled);
			capsuleGroup.add(capsule);

			var titleTextBlur = new FlxText(capsule.width * 0.26, 45,0, song.displayName, Std.int(40 * realScaled));
			titleTextBlur.font = "5by7";
			titleTextBlur.color = 0xFF00ccff;
			titleTextBlur.shader = new CustomShader('GaussianBlurShader');
			//IMPROVE-NOTE something something low quailty option
			capsuleGroup.add(titleTextBlur);

			var text = new FlxText(capsule.width * 0.26, 45,0,song.displayName, Std.int(40 * realScaled));
			text.font = Paths.font("5by7.ttf");
			text.textField.filters = [
				new GlowFilter(0x00ccff, 1, 5, 5, 210, 2/*BitmapFilterQuality.MEDIUM*/),
			];
			capsuleGroup.add(text);

			var pixelIcon = new FlxSprite(160, 35).loadGraphic(Paths.image('menus/freeplay/icons/'+song.icon));
			pixelIcon.scale.x = pixelIcon.scale.y = 2;
			pixelIcon.antialiasing = false;
			pixelIcon.active = false;
			pixelIcon.origin.x = song.icon == 'parents-christmas' ? 140 : 100;
			pixelIcon.visible = song.name != 'random';//hide it DONT remove it
			capsuleGroup.add(pixelIcon);

			capsules.push(capsuleGroup);
		}

		//bar
		blackBar = new FlxSprite().makeGraphic(FlxG.width, 64, 0xFF000000);
		add(blackBar);
			
		freeplayText = new FlxText(8, 8, 0, 'FREEPLAY', 48);
		add(freeplayText);
		
		ostName = new FlxText(8, 8, FlxG.width - 8 - 8, 'OFFICIAL OST', 48);//should make this change
		ostName.alignment = "right";
		add(ostName);

		scoreText = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);
		scoreText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);

		scoreBG = new FlxSprite(scoreText.x - 6, 0).makeGraphic(1, 1, 0xFF000000);
		scoreBG.alpha = 0.6;
		add(scoreBG);

		diffText = new FlxText(scoreText.x, scoreText.y + 36, 0, "", 24);
		diffText.font = scoreText.font;
		add(diffText);

		coopText = new FlxText(diffText.x, diffText.y + diffText.height + 2, 0, "[TAB] Solo", 24);
		coopText.font = scoreText.font;
		add(coopText);

		add(scoreText);

		changeSelection(0, true);
		changeDiff(0, true);
		changeCoopMode(0, true);
	}

	function djPlayAnim(name,offsetX,offsetY){
		dj.anim.play(name,true);
		dj.offset.set(offsetX,offsetY);
	}

	#if PRELOAD_ALL
	/**
	 * How much time a song stays selected until it autoplays.
	 */
	public var timeUntilAutoplay:Float = 1;
	/**
	 * Whenever the song autoplays when hovered over.
	 */
	public var disableAutoPlay:Bool = false;
	/**
	 * Whenever the autoplayed song gets async loaded.
	 */
	public var disableAsyncLoading:Bool = #if desktop false #else true #end;
	/**
	 * Time elapsed since last autoplay. If this time exceeds `timeUntilAutoplay`, the currently selected song will play.
	 */
	public var autoplayElapsed:Float = 0;
	/**
	 * Whenever the currently selected song instrumental is playing.
	 */
	public var songInstPlaying:Bool = true;
	/**
	 * Path to the currently playing song instrumental.
	 */
	public var curPlayingInst:String = null;
	#end

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.sound.music != null && FlxG.sound.music.volume < 0.7)
		{
			FlxG.sound.music.volume += 0.5 * elapsed;
		}

		lerpScore = Math.floor(lerp(lerpScore, intendedScore, 0.4));

		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;

		if (canSelect) {
			changeSelection((controls.UP_P ? -1 : 0) + (controls.DOWN_P ? 1 : 0));
			changeDiff((controls.LEFT_P ? -1 : 0) + (controls.RIGHT_P ? 1 : 0));
			changeCoopMode((FlxG.keys.justPressed.TAB ? 1 : 0));
			// putting it before so that its actually smooth
			updateOptionsAlpha();
		}

		scoreText.text = "PERSONAL BEST:" + lerpScore;
		scoreBG.scale.set(Math.max(Math.max(diffText.width, scoreText.width), coopText.width) + 8, (coopText.visible ? coopText.y + coopText.height : 66));
		scoreBG.updateHitbox();
		scoreBG.x = FlxG.width - scoreBG.width;

		scoreText.x = coopText.x = scoreBG.x + 4;
		diffText.x = Std.int(scoreBG.x + ((scoreBG.width - diffText.width) / 2));

		interpColor.fpsLerpTo(songs[curSelected].parsedColor, 0.0625);

		#if PRELOAD_ALL
		var dontPlaySongThisFrame = false;
		autoplayElapsed += elapsed;
		if (!disableAutoPlay && !songInstPlaying && (autoplayElapsed > timeUntilAutoplay || FlxG.keys.justPressed.SPACE)) {
			if (curPlayingInst != (curPlayingInst = Paths.inst(songs[curSelected].name, songs[curSelected].difficulties[curDifficulty]))) {
				var huh:Void->Void = function() FlxG.sound.playMusic(curPlayingInst, 0);
				if(!disableAsyncLoading) Main.execAsync(huh);
				else huh();
			}
			songInstPlaying = true;
			if(disableAsyncLoading) dontPlaySongThisFrame = true;
		}
		#end


		if (controls.BACK)
		{
			CoolUtil.playMenuSFX(CANCEL, 0.7);
			FlxG.switchState(new MainMenuState());
		}

		#if sys
		if (FlxG.keys.justPressed.EIGHT && Sys.args().contains("-livereload"))
			convertChart();
		#end

		if (controls.ACCEPT #if PRELOAD_ALL && !dontPlaySongThisFrame #end)
			select();
	}

	var __opponentMode:Bool = false;
	var __coopMode:Bool = false;

	function updateCoopModes() {
		__opponentMode = false;
		__coopMode = false;
		if (songs[curSelected].coopAllowed && songs[curSelected].opponentModeAllowed) {
			__opponentMode = curCoopMode % 2 == 1;
			__coopMode = curCoopMode >= 2;
		} else if (songs[curSelected].coopAllowed) {
			__coopMode = curCoopMode == 1;
		} else if (songs[curSelected].opponentModeAllowed) {
			__opponentMode = curCoopMode == 1;
		}
	}

	/**
	 * Selects the current song.
	 */
	public function select() {
		updateCoopModes();

		if (songs[curSelected].difficulties.length <= 0) return;

		var event = event("onSelect", EventManager.get(FreeplaySongSelectEvent).recycle(songs[curSelected].name, songs[curSelected].difficulties[curDifficulty], __opponentMode, __coopMode));

		if (event.cancelled) return;

		Options.freeplayLastSong = songs[curSelected].name;
		Options.freeplayLastDifficulty = songs[curSelected].difficulties[curDifficulty];

		PlayState.loadSong(event.song, event.difficulty, event.opponentMode, event.coopMode);
		FlxG.switchState(new PlayState());
	}

	public function convertChart() {
		trace('Converting ${songs[curSelected].name} (${songs[curSelected].difficulties[curDifficulty]}) to Codename format...');
		var chart = Chart.parse(songs[curSelected].name, songs[curSelected].difficulties[curDifficulty]);
		Chart.save('${Main.pathBack}assets/songs/${songs[curSelected].name}', chart, songs[curSelected].difficulties[curDifficulty].toLowerCase());
	}

	/**
	 * Changes the current difficulty
	 * @param change How much to change.
	 * @param force Force the change if `change` is equal to 0
	 */
	public function changeDiff(change:Int = 0, force:Bool = false)
	{
		if (change == 0 && !force) return;

		var curSong = songs[curSelected];
		var validDifficulties = curSong.difficulties.length > 0;
		var event = event("onChangeDiff", EventManager.get(MenuChangeEvent).recycle(curDifficulty, validDifficulties ? FlxMath.wrap(curDifficulty + change, 0, curSong.difficulties.length-1) : 0, change));

		if (event.cancelled) return;

		curDifficulty = event.value;

		updateScore();

		if (curSong.difficulties.length > 1)
			diffText.text = '< ${curSong.difficulties[curDifficulty]} >';
		else
			diffText.text = validDifficulties ? curSong.difficulties[curDifficulty] : "-";
	}

	function updateScore() {
		if (songs[curSelected].difficulties.length <= 0) {
			intendedScore = 0;
			return;
		}
		updateCoopModes();
		var changes:Array<HighscoreChange> = [];
		if (__coopMode) changes.push(CCoopMode);
		if (__opponentMode) changes.push(COpponentMode);
		var saveData = FunkinSave.getSongHighscore(songs[curSelected].name, songs[curSelected].difficulties[curDifficulty], changes);
		intendedScore = saveData.score;
	}

	/**
	 * Array containing all labels for Co-Op / Opponent modes.
	 */
	public var coopLabels:Array<String> = [
		"[TAB] Solo",
		"[TAB] Opponent Mode",
		"[TAB] Co-Op Mode",
		"[TAB] Co-Op Mode (Switched)"
	];

	/**
	 * Change the current coop mode context.
	 * @param change How much to change
	 * @param force Force the change, even if `change` is equal to 0.
	 */
	public function changeCoopMode(change:Int = 0, force:Bool = false) {
		if (change == 0 && !force) return;
		if (!songs[curSelected].coopAllowed && !songs[curSelected].opponentModeAllowed) return;

		var bothEnabled = songs[curSelected].coopAllowed && songs[curSelected].opponentModeAllowed;
		var event = event("onChangeCoopMode", EventManager.get(MenuChangeEvent).recycle(curCoopMode, FlxMath.wrap(curCoopMode + change, 0, bothEnabled ? 3 : 1), change));

		if (event.cancelled) return;

		curCoopMode = event.value;

		updateScore();

		if (bothEnabled) {
			coopText.text = coopLabels[curCoopMode];
		} else {
			coopText.text = coopLabels[curCoopMode * (songs[curSelected].coopAllowed ? 2 : 1)];
		}
	}

	/**
	 * Change the current selection.
	 * @param change How much to change
	 * @param force Force the change, even if `change` is equal to 0.
	 */
	public function changeSelection(change:Int = 0, force:Bool = false)
	{
		if (change == 0 && !force) return;

		var bothEnabled = songs[curSelected].coopAllowed && songs[curSelected].opponentModeAllowed;
		var event = event("onChangeSelection", EventManager.get(MenuChangeEvent).recycle(curSelected, FlxMath.wrap(curSelected + change, 0, songs.length-1), change));
		if (event.cancelled) return;

		curSelected = event.value;
		if (event.playMenuSFX) CoolUtil.playMenuSFX(SCROLL, 0.7);

		changeDiff(0, true);

		#if PRELOAD_ALL
			autoplayElapsed = 0;
			songInstPlaying = false;
		#end

		coopText.visible = songs[curSelected].coopAllowed || songs[curSelected].opponentModeAllowed;
	}

	function updateOptionsAlpha() {
		var event = event("onUpdateOptionsAlpha", EventManager.get(FreeplayAlphaUpdateEvent).recycle(0.6, 0.45, 1, 1, 0.25));
		if (event.cancelled) return;

		for (i in 0...iconArray.length)
			iconArray[i].alpha = lerp(iconArray[i].alpha, #if PRELOAD_ALL songInstPlaying ? event.idlePlayingAlpha : #end event.idleAlpha, event.lerp);

		iconArray[curSelected].alpha = #if PRELOAD_ALL songInstPlaying ? event.selectedPlayingAlpha : #end event.selectedAlpha;

		for (i=>item in grpSongs.members)
		{
			item.targetY = i - curSelected;

			item.alpha = lerp(item.alpha, #if PRELOAD_ALL songInstPlaying ? event.idlePlayingAlpha : #end event.idleAlpha, event.lerp);

			if (item.targetY == 0)
				item.alpha =  #if PRELOAD_ALL songInstPlaying ? event.selectedPlayingAlpha : #end event.selectedAlpha;
		}
	}
}

class FreeplaySonglist {
	public var songs:Array<ChartMetaData> = [];

	public function new() {}

	public function getSongsFromSource(source:funkin.backend.assets.AssetsLibraryList.AssetSource, useTxt:Bool = true) {
		var path:String = Paths.txt('freeplaySonglist');
		var songsFound:Array<String> = [];
		if (useTxt && Paths.assetsTree.existsSpecific(path, "TEXT", source)) {
			songsFound = CoolUtil.coolTextFile(Paths.txt('freeplaySonglist'));
		} else {
			songsFound = Paths.getFolderDirectories('songs', false, source);
		}

		if (songsFound.length > 0) {
			for(s in songsFound)
				songs.push(Chart.loadChartMeta(s, "normal", source == MODS));
			return false;
		}
		return true;
	}

	public static function get(useTxt:Bool = true) {
		var songList = new FreeplaySonglist();

		if (songList.getSongsFromSource(MODS, useTxt))
			songList.getSongsFromSource(SOURCE, useTxt);

		return songList;
	}
}
