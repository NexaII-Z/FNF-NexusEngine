package states;

import backend.WeekData;
import backend.Mods;

import flixel.ui.FlxButton;
import flixel.FlxBasic;
import flixel.graphics.FlxGraphic;
import flash.geom.Rectangle;
import lime.utils.Assets;
import haxe.Json;

import flixel.util.FlxSpriteUtil;
import flixel.util.FlxGradient;
import objects.AttachedSprite;
import options.ModSettingsSubState;
import flixel.addons.transition.FlxTransitionableState;

class ModsMenuState extends MusicBeatState
{
	var bg:FlxSprite;
	var icon:FlxSprite;
	var modName:Alphabet;
	var modDesc:FlxText;
	var modRestartText:FlxText;
	var modsList:ModsList = null;

	var bgList:FlxSprite;
	var buttonReload:MenuButton;
	//var buttonModFolder:MenuButton;
	var buttonEnableAll:MenuButton;
	var buttonDisableAll:MenuButton;
	var buttons:Array<MenuButton> = [];
	var settingsButton:MenuButton;

	var bgTitle:FlxSprite;
	var bgDescription:FlxSprite;
	var bgButtons:FlxSprite;

	var modsGroup:FlxTypedGroup<ModItem>;
	var curSelectedMod:Int = 0;
	
	var hoveringOnMods:Bool = true;
	var curSelectedButton:Int = 0; ///-1 = Enable/Disable All, -2 = Reload
	var modNameInitialY:Float = 0;

	var noModsSine:Float = 0;
	var noModsTxt:FlxText;

	var _lastControllerMode:Bool = false;
	var startMod:String = null;

	public static var accentColor:FlxColor = 0xFF665AFF;
	public static final PANEL_COLOR:FlxColor = 0xFF0B0B14;
	public static final GOOD_COLOR:FlxColor = 0xFF2FBF71;
	public static final BAD_COLOR:FlxColor = 0xFFE5484D;

	var accentSprites:Array<FlxSprite> = [];
	var statusPill:FlxSprite;
	var statusText:FlxText;
	var modCounter:FlxText;
	var modFolderText:FlxText;

	function addBorder(x:Float, y:Float, w:Int, h:Int, alpha:Float = 0.55):FlxSprite
	{
		var border = FlxSpriteUtil.drawRoundRect(new FlxSprite(x, y).makeGraphic(w, h, FlxColor.TRANSPARENT, true), 1, 1, w - 2, h - 2, 28, 28, FlxColor.TRANSPARENT, {thickness: 2, color: FlxColor.WHITE});
		border.alpha = alpha;
		accentSprites.push(border);
		add(border);
		return border;
	}

	public function new(startMod:String = null)
	{
		this.startMod = startMod;
		super();
	}
	override function create()
	{
		var daButton:String = "BACKSPACE";

		if (controls.mobileC)
			daButton = 'B';
		
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();
		persistentUpdate = false;

		modsList = Mods.parseList();
		Mods.currentModDirectory = modsList.all[0] != null ? modsList.all[0] : '';

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xFF665AFF;
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);
		bg.screenCenter();

		var shade = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height, [FlxColor.fromRGB(0, 0, 0, 60), FlxColor.fromRGB(0, 0, 0, 205)], 1, 90);
		shade.scrollFactor.set();
		add(shade);

		bgList = FlxSpriteUtil.drawRoundRect(new FlxSprite(40, 40).makeGraphic(340, 440, FlxColor.TRANSPARENT, true), 0, 0, 340, 440, 28, 28, PANEL_COLOR);
		bgList.alpha = 0.8;

		modsGroup = new FlxTypedGroup<ModItem>();

		for (i => mod in modsList.all)
		{
			if(startMod == mod) curSelectedMod = i;

			var modItem:ModItem = new ModItem(mod);
			if(modsList.disabled.contains(mod)) modItem.setEnabled(false);
			modsGroup.add(modItem);
		}

		var mod:ModItem = modsGroup.members[curSelectedMod];
		if(mod != null) bg.color = mod.bgColor;

		//
		var buttonX = bgList.x;
		var buttonWidth = Std.int(bgList.width);
		var buttonHeight = 80;
		var daY = 0;
		
		if(controls.mobileC)
			daY = 70;
		else
			daY = 20;

		buttonReload = new MenuButton(buttonX, bgList.y + bgList.height + daY, buttonWidth, buttonHeight, "RELOAD", reload);
		add(buttonReload);
		
		var myY = buttonReload.y + buttonReload.bg.height + 20;
		/*buttonModFolder = new MenuButton(buttonX, myY, buttonWidth, buttonHeight, "MODS FOLDER", function() {
			var modFolder = Paths.mods();
			if(!FileSystem.exists(modFolder))
			{
				trace('created missing folder');
				FileSystem.createDirectory(modFolder);
			}
			CoolUtil.openFolder(modFolder);
		});
		add(buttonModFolder);*/

		buttonEnableAll = new MenuButton(buttonX, myY, buttonWidth, buttonHeight, "ENABLE ALL", function() {
			buttonEnableAll.ignoreCheck = false;
			for (mod in modsGroup.members)
			{
				if(modsList.disabled.contains(mod.folder))
				{
					modsList.disabled.remove(mod.folder);
					modsList.enabled.push(mod.folder);
					mod.setEnabled(true);
				}
			}
			updateModDisplayData();
			checkToggleButtons();
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
		});
		buttonEnableAll.bg.color = GOOD_COLOR;
		buttonEnableAll.focusChangeCallback = function(focus:Bool) if(!focus) buttonEnableAll.bg.color = GOOD_COLOR;
		
		if(!controls.mobileC)
			add(buttonEnableAll);

		buttonDisableAll = new MenuButton(buttonX, myY, buttonWidth, buttonHeight, "DISABLE ALL", function() {
			buttonDisableAll.ignoreCheck = false;
			for (mod in modsGroup.members)
			{
				if(modsList.enabled.contains(mod.folder))
				{
					modsList.enabled.remove(mod.folder);
					modsList.disabled.push(mod.folder);
					mod.setEnabled(false);
				}
			}
			updateModDisplayData();
			checkToggleButtons();
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
		});
		buttonDisableAll.bg.color = BAD_COLOR;
		buttonDisableAll.focusChangeCallback = function(focus:Bool) if(!focus) buttonDisableAll.bg.color = BAD_COLOR;
		
		if(!controls.mobileC)
			add(buttonDisableAll);
		
		checkToggleButtons();

		if(modsList.all.length < 1)
		{
			buttonDisableAll.visible = buttonDisableAll.enabled = false;
			buttonEnableAll.visible = true;

			var myX = bgList.x + bgList.width + 20;
			noModsTxt = new FlxText(myX, 0, FlxG.width - myX - 20, "NO MODS INSTALLED\nPRESS " + daButton + " TO EXIT OR INSTALL A MOD", 48);
			if(FlxG.random.bool(0.1)) noModsTxt.text += '\nBITCH.'; //meanie
			noModsTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			noModsTxt.borderSize = 2;
			add(noModsTxt);
			noModsTxt.screenCenter(Y);

			add(bgList);
			addBorder(bgList.x, bgList.y, 340, 440);

			var txt = new FlxText(bgList.x + 15, bgList.y + 15, bgList.width - 30, "No Mods found.", 16);
			txt.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE);
			add(txt);

			FlxG.autoPause = false;
			changeSelectedMod();

			#if mobile
			addTouchPad("NONE", "B");
			#end
			
			return super.create();
		}
		//

		bgTitle = FlxSpriteUtil.drawRoundRect(new FlxSprite(bgList.x + bgList.width + 20, 40).makeGraphic(840, 180, FlxColor.TRANSPARENT, true), 0, 0, 840, 180, 28, 28, PANEL_COLOR);
		bgTitle.alpha = 0.8;
		add(bgTitle);
		addBorder(bgTitle.x, bgTitle.y, 840, 180);

		icon = new FlxSprite(bgTitle.x + 15, bgTitle.y + 15);
		add(icon);

		modNameInitialY = icon.y + 70;
		modName = new Alphabet(icon.x + 165, modNameInitialY, "", true);
		modName.scaleY = 0.8;
		add(modName);

		statusPill = FlxSpriteUtil.drawRoundRect(new FlxSprite(icon.x + 165, bgTitle.y + 137).makeGraphic(120, 28, FlxColor.TRANSPARENT, true), 0, 0, 120, 28, 28, 28, FlxColor.WHITE);
		statusPill.color = GOOD_COLOR;
		add(statusPill);

		statusText = new FlxText(statusPill.x, statusPill.y + 5, 120, "ENABLED", 16);
		statusText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.BLACK, CENTER);
		add(statusText);

		modFolderText = new FlxText(statusPill.x + 136, statusPill.y + 5, 440, "", 16);
		modFolderText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT);
		modFolderText.alpha = 0.55;
		add(modFolderText);

		modCounter = new FlxText(bgTitle.x + bgTitle.width - 175, bgTitle.y + 18, 150, "", 20);
		modCounter.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, RIGHT);
		modCounter.alpha = 0.6;
		add(modCounter);

		bgDescription = FlxSpriteUtil.drawRoundRect(new FlxSprite(bgTitle.x, bgTitle.y + 200).makeGraphic(840, 450, FlxColor.TRANSPARENT, true), 0, 0, 840, 450, 28, 28, PANEL_COLOR);
		bgDescription.alpha = 0.8;
		add(bgDescription);

		modDesc = new FlxText(bgDescription.x + 20, bgDescription.y + 20, bgDescription.width - 40, "", 24);
		modDesc.setFormat(Paths.font("vcr.ttf"), 24, 0xFFE9E9F2, LEFT);
		add(modDesc);

		var myHeight = 100;
		modRestartText = new FlxText(bgDescription.x + 20, bgDescription.y + bgDescription.height - myHeight - 25, bgDescription.width - 40, "* Moving or Toggling On/Off this Mod will restart the game.", 16);
		modRestartText.setFormat(Paths.font("vcr.ttf"), 16, 0xFFFFB84D, RIGHT);
		add(modRestartText);

		bgButtons = FlxSpriteUtil.drawRoundRectComplex(new FlxSprite(bgDescription.x, bgDescription.y + bgDescription.height - myHeight).makeGraphic(840, myHeight, FlxColor.TRANSPARENT, true), 0, 0, 840, myHeight, 0, 0, 14, 14, FlxColor.WHITE);
		bgButtons.color = FlxColor.BLACK;
		bgButtons.alpha = 0.2;
		add(bgButtons);
		addBorder(bgDescription.x, bgDescription.y, 840, 450);

		var buttonsX = bgButtons.x + 320;
		var buttonsY = bgButtons.y + 10;

		var button = new MenuButton(buttonsX, buttonsY, 80, 80, Paths.image('modsMenuButtons'), function() moveModToPosition(0), 54, 54); //Move to the top
		button.icon.animation.add('icon', [0]);
		button.icon.animation.play('icon', true);
		add(button);
		buttons.push(button);

		var button = new MenuButton(buttonsX + 100, buttonsY, 80, 80, Paths.image('modsMenuButtons'), function() moveModToPosition(curSelectedMod - 1), 54, 54); //Move up
		button.icon.animation.add('icon', [1]);
		button.icon.animation.play('icon', true);
		add(button);
		buttons.push(button);

		var button = new MenuButton(buttonsX + 200, buttonsY, 80, 80, Paths.image('modsMenuButtons'), function() moveModToPosition(curSelectedMod + 1), 54, 54); //Move down
		button.icon.animation.add('icon', [2]);
		button.icon.animation.play('icon', true);
		add(button);
		buttons.push(button);
		
		if(modsList.all.length < 2)
		{
			for (button in buttons)
				button.enabled = false;
		}

		settingsButton = new MenuButton(buttonsX + 300, buttonsY, 80, 80, Paths.image('modsMenuButtons'), function() //Settings
		{
			var curMod:ModItem = modsGroup.members[curSelectedMod];
			if(curMod != null && curMod.settings != null && curMod.settings.length > 0)
			{
				openSubState(new ModSettingsSubState(curMod.settings, curMod.folder, curMod.name));
			}
		}, 54, 54);

		settingsButton.icon.animation.add('icon', [3]);
		settingsButton.icon.animation.play('icon', true);
		add(settingsButton);
		buttons.push(settingsButton);

		if(modsGroup.members[curSelectedMod].settings == null || modsGroup.members[curSelectedMod].settings.length < 1)
			settingsButton.enabled = false;

		var button = new MenuButton(buttonsX + 400, buttonsY, 80, 80, Paths.image('modsMenuButtons'), function() //On/Off
		{
			var curMod:ModItem = modsGroup.members[curSelectedMod];
			var mod:String = curMod.folder;
			if(!modsList.disabled.contains(mod)) //Enable
			{
				modsList.enabled.remove(mod);
				modsList.disabled.push(mod);
			}
			else //Disable
			{
				modsList.disabled.remove(mod);
				modsList.enabled.push(mod);
			}
			curMod.setEnabled(!modsList.disabled.contains(mod));

			if(curMod.mustRestart) waitingToRestart = true;
			updateModDisplayData();
			checkToggleButtons();
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
		}, 54, 54);
		button.icon.animation.add('icon', [4]);
		button.icon.animation.play('icon', true);
		add(button);
		buttons.push(button);
		button.focusChangeCallback = function(focus:Bool) {
			if(!focus)
				button.bg.color = modsList.enabled.contains(modsGroup.members[curSelectedMod].folder) ? GOOD_COLOR : BAD_COLOR;
		};

		if(modsList.all.length < 1)
		{
			for (btn in buttons) btn.enabled = false;
			button.focusChangeCallback = null;
		}
		
		add(bgList);
		addBorder(bgList.x, bgList.y, 340, 440);
		add(modsGroup);
		_lastControllerMode = controls.controllerMode;

		changeSelectedMod();

		var bottomBG = new FlxSprite(0, FlxG.height - 26).makeGraphic(FlxG.width, 26, PANEL_COLOR);
		bottomBG.alpha = 0.9;
		add(bottomBG);

		var bottomLine = new FlxSprite(0, FlxG.height - 28).makeGraphic(FlxG.width, 2, FlxColor.WHITE, true);
		bottomLine.alpha = 0.55;
		accentSprites.push(bottomLine);
		add(bottomLine);

		var hintStr:String = controls.mobileC ? "Press " + daButton + " To Leave" : "UP / DOWN: Select     SHIFT: Fast Scroll     DRAG: Reorder     " + daButton + ": Leave";
		var bottomText = new FlxText(bottomBG.x, bottomBG.y + 4, FlxG.width, hintStr, 16);
		bottomText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER);
		bottomText.alpha = 0.8;
		bottomText.scrollFactor.set();
		add(bottomText);

		#if mobile
		addTouchPad("UP_DOWN", "B");
		touchPad.y -= 215; // so that you can press the buttons.
		#end
		
		if(controls.mobileC)
			touchPad.alpha = 0.3;
		
		super.create();
	}
	
	var nextAttempt:Float = 1;
	var holdingMod:Bool = false;
	var mouseOffsets:FlxPoint = new FlxPoint();
	var holdingElapsed:Float = 0;
	var gottaClickAgain:Bool = false;

	var holdTime:Float = 0;
	var exiting:Bool = false;
	override function update(elapsed:Float)
	{
		var acc:FlxColor = FlxColor.interpolate(bg.color, FlxColor.WHITE, 0.35);
		accentColor = acc;
		for (spr in accentSprites) spr.color = acc;

		if(controls.BACK && hoveringOnMods && !exiting)
		{
			exiting = true;
			if(colorTween != null) {
				colorTween.cancel();
			}
			saveTxt();

			FlxG.sound.play(Paths.sound('cancelMenu'));
			if(waitingToRestart)
			{
				//MusicBeatState.switchState(new TitleState());
				TitleState.initialized = false;
				TitleState.closedState = false;
				FlxG.sound.music.fadeOut(0.3);
				if(FreeplayState.vocals != null)
				{
					FreeplayState.vocals.fadeOut(0.3);
					FreeplayState.vocals = null;
				}
				FlxG.camera.fade(FlxColor.BLACK, 0.5, false, FlxG.resetGame, false);
			}
			else MusicBeatState.switchState(new MainMenuState());

			persistentUpdate = false;
			FlxG.autoPause = ClientPrefs.data.autoPause;
			FlxG.mouse.visible = false;
			return;
		}

		if(Math.abs(FlxG.mouse.deltaX) > 10 || Math.abs(FlxG.mouse.deltaY) > 10)
		{
			controls.controllerMode = false;
			if(!FlxG.mouse.visible) FlxG.mouse.visible = true;
		}
		
		if(controls.controllerMode != _lastControllerMode)
		{
			if(controls.controllerMode) FlxG.mouse.visible = false;
			_lastControllerMode = controls.controllerMode;
		}

		if(controls.UI_DOWN_R || controls.UI_UP_R) holdTime = 0;

		if(modsList.all.length > 0)
		{
			if(controls.controllerMode && holdingMod)
			{
				holdingMod = false;
				holdingElapsed = 0;
				updateItemPositions();
			}
			var lastMode = hoveringOnMods;
			if(modsList.all.length > 1)
			{
				if(!controls.mobileC && FlxG.mouse.justPressed)
				{
					for (i in centerMod-2...centerMod+3)
					{
						var mod = modsGroup.members[i];
						if(mod != null && mod.visible && FlxG.mouse.overlaps(mod))
						{
							hoveringOnMods = true;
							var button = getButton();
							button.ignoreCheck = button.onFocus = false;
							mouseOffsets.x = FlxG.mouse.x - mod.x;
							mouseOffsets.y = FlxG.mouse.y - mod.y;
							curSelectedMod = i;
							changeSelectedMod();
							break;
						}
					}
					hoveringOnMods = true;
					var button = getButton();
					button.ignoreCheck = button.onFocus = false;
					gottaClickAgain = false;
				}

				if(hoveringOnMods)
				{
					var shiftMult:Int = (FlxG.keys.pressed.SHIFT || FlxG.gamepads.anyPressed(LEFT_SHOULDER) || FlxG.gamepads.anyPressed(RIGHT_SHOULDER)) ? 4 : 1;
					if(controls.UI_DOWN_P)
						changeSelectedMod(shiftMult);
					else if(controls.UI_UP_P)
						changeSelectedMod(-shiftMult);
					else if(FlxG.mouse.wheel != 0)
						changeSelectedMod(-FlxG.mouse.wheel * shiftMult, true);
					else if(FlxG.keys.justPressed.HOME || FlxG.keys.justPressed.END ||
						FlxG.gamepads.anyJustPressed(LEFT_TRIGGER) || FlxG.gamepads.anyJustPressed(RIGHT_TRIGGER))
					{
						if(FlxG.keys.justPressed.END || FlxG.gamepads.anyJustPressed(RIGHT_TRIGGER)) curSelectedMod = modsList.all.length-1;
						else curSelectedMod = 0;
						changeSelectedMod();
					}
					else if(controls.UI_UP || controls.UI_DOWN)
					{
						var lastHoldTime:Float = holdTime;
						holdTime += elapsed;
						if(holdTime > 0.5 && Math.floor(lastHoldTime * 8) != Math.floor(holdTime * 8)) changeSelectedMod(shiftMult * (controls.UI_UP ? -1 : 1));
					}

					else if(FlxG.mouse.pressed && !controls.mobileC && !gottaClickAgain)
					{
						var curMod:ModItem = modsGroup.members[curSelectedMod];
						if(curMod != null)
						{
							if(!holdingMod && FlxG.mouse.justMoved && FlxG.mouse.overlaps(curMod)) holdingMod = true;

							if(holdingMod)
							{
								var moved:Bool = false;
								for (i in centerMod-2...centerMod+3)
								{
									var mod = modsGroup.members[i];
									if(mod != null && mod.visible && FlxG.mouse.overlaps(mod) && curSelectedMod != i)
									{
										moveModToPosition(i);
										moved = true;
										break;
									}
								}
								
								if(!moved)
								{
									var factor:Float = -1;
									if(FlxG.mouse.y < bgList.y)
										factor = Math.abs(Math.max(0.2, Math.min(0.5, 0.5 - (bgList.y - FlxG.mouse.y) / 100)));
									else if(FlxG.mouse.y > bgList.y + bgList.height)
										factor = Math.abs(Math.max(0.2, Math.min(0.5, 0.5 - (FlxG.mouse.y - bgList.y - bgList.height) / 100)));
		
									if(factor >= 0)
									{
										holdingElapsed += elapsed;
										if(holdingElapsed >= factor)
										{
											holdingElapsed = 0;
											var newPos = curSelectedMod;
											if(FlxG.mouse.y < bgList.y) newPos--;
											else newPos++;
											moveModToPosition(Std.int(Math.max(0, Math.min(modsGroup.length - 1, newPos))));
										}
									}
								}
								curMod.x = FlxG.mouse.x - mouseOffsets.x;
								curMod.y = FlxG.mouse.y - mouseOffsets.y;
							}
						}
						
					}
					else if(FlxG.mouse.justReleased && !controls.mobileC && holdingMod)
					{
						holdingMod = false;
						holdingElapsed = 0;
						updateItemPositions();
					}
				}
			}

			if(lastMode == hoveringOnMods)
			{
				if(hoveringOnMods)
				{
					if(controls.UI_RIGHT_P)
					{
						hoveringOnMods = false;
						var button = getButton();
						button.ignoreCheck = button.onFocus = false;
						curSelectedButton = 0;
						changeSelectedButton();
					}
				}
				else 
				{
					if(controls.BACK)
					{
						hoveringOnMods = true;
						var button = getButton();
						button.ignoreCheck = button.onFocus = false;
						changeSelectedMod();
					}
					else if(controls.ACCEPT)
					{
						var button = getButton();
						if(button.onClick != null) button.onClick();
					}
					else if(curSelectedButton < 0)
					{
						if(controls.UI_UP_P)
						{
							switch(curSelectedButton)
							{
								case -2:
									curSelectedMod = 0;
									hoveringOnMods = true;
									var button = getButton();
									button.ignoreCheck = button.onFocus = false;
									changeSelectedMod();
								case -1:
									changeSelectedButton(-1);
							}
						}
						else if(controls.UI_DOWN_P)
						{
							switch(curSelectedButton)
							{
								case -2:
									changeSelectedButton(1);
								case -1:
									curSelectedMod = 0;
									hoveringOnMods = true;
									var button = getButton();
									button.ignoreCheck = button.onFocus = false;
									changeSelectedMod();
							}
						}
						else if(controls.UI_RIGHT_P)
						{
							var button = getButton();
							button.ignoreCheck = button.onFocus = false;
							curSelectedButton = 0;
							changeSelectedButton();
						}
					}
					else if(controls.UI_LEFT_P)
						changeSelectedButton(-1);
					else if(controls.UI_RIGHT_P)
						changeSelectedButton(1);
				}
			}
		}
		else
		{
			noModsSine += 180 * elapsed;
			noModsTxt.alpha = 1 - Math.sin((Math.PI * noModsSine) / 180);
			
			// Keep refreshing mods list every 2 seconds until you add a mod on the folder
			nextAttempt -= elapsed;
			if(nextAttempt < 0)
			{
				nextAttempt = 1;
				@:privateAccess
				Mods.updateModList();
				modsList = Mods.parseList();
				if(modsList.all.length > 0)
				{
					trace('mod(s) found! reloading');
					reload();
				}
			}
		}
		super.update(elapsed);
	}

	function changeSelectedButton(add:Int = 0)
	{
		var max = buttons.length - 1;
		
		var button = getButton();
		button.ignoreCheck = button.onFocus = false;

		curSelectedButton += add;
		if(curSelectedButton < -2)
			curSelectedButton = -2;
		else if(curSelectedButton > max)
			curSelectedButton = max;

		var button = getButton();
		button.ignoreCheck = button.onFocus = true;

		var curMod:ModItem = modsGroup.members[curSelectedMod];
		if(curMod != null) curMod.selectBg.visible = false;
		if(curSelectedButton < 0)
		{
			bgButtons.color = FlxColor.BLACK;
			bgButtons.alpha = 0.2;
		}
		else
		{
			bgButtons.color = FlxColor.WHITE;
			bgButtons.alpha = 0.8;
		}

		FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
	}

	function getButton()
	{
		switch(curSelectedButton)
		{
			case -2: return buttonReload;
			case -1: return buttonEnableAll.enabled ? buttonEnableAll : buttonDisableAll;
		}

		if(modsList.all.length < 1) return buttonReload; //prevent possible crash from my irresponsibility
		return buttons[Std.int(Math.max(0, Math.min(buttons.length-1, curSelectedButton)))];
	}

	function changeSelectedMod(add:Int = 0, isMouseWheel:Bool = false)
	{
		var max = modsList.all.length - 1;
		if(max < 0) return;

		if(hoveringOnMods)
		{
			var button = getButton();
			button.ignoreCheck = button.onFocus = false;
		}

		var lastSelected = curSelectedMod;
		curSelectedMod += add;

		var limited:Bool = false;
		if(curSelectedMod < 0)
		{
			curSelectedMod = 0;
			limited = true;
		}
		else if(curSelectedMod > max)
		{
			curSelectedMod = max;
			limited = true;
		}
		
		if(!controls.mobileC && !isMouseWheel && limited && Math.abs(add) == 1)
		{
			if(add < 0) // pressed up on first mod
			{
				curSelectedMod = lastSelected;
				hoveringOnMods = false;
				curSelectedButton = -1;
				changeSelectedButton();
				return;
			}
			else // pressed down on last mod
			{
				curSelectedMod = lastSelected;
				hoveringOnMods = false;
				curSelectedButton = -2;
				changeSelectedButton();
				return;
			}
		}
		
		holdingMod = false;
		holdingElapsed = 0;
		gottaClickAgain = true;
		updateModDisplayData();
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
		
		if(hoveringOnMods)
		{
			var curMod:ModItem = modsGroup.members[curSelectedMod];
			if(curMod != null) curMod.selectBg.visible = true;
			bgButtons.color = FlxColor.BLACK;
			bgButtons.alpha = 0.2;
		}
	}

	var colorTween:FlxTween = null;
	function updateModDisplayData()
	{
		var curMod:ModItem = modsGroup.members[curSelectedMod];
		if(curMod == null) return;

		if(colorTween != null)
		{
			colorTween.cancel();
			colorTween.destroy();
		}
		colorTween = FlxTween.color(bg, 1, bg.color, curMod.bgColor, {onComplete: function(twn:FlxTween) colorTween = null});

		if(Math.abs(centerMod - curSelectedMod) > 2)
		{
			if(centerMod < curSelectedMod)
				centerMod = curSelectedMod - 2;
			else centerMod = curSelectedMod + 2;
		}
		updateItemPositions();

		icon.loadGraphic(curMod.icon.graphic, true, 150, 150);
		icon.antialiasing = curMod.icon.antialiasing;

		if(curMod.totalFrames > 0)
		{
			icon.animation.add("icon", [for (i in 0...curMod.totalFrames) i], curMod.iconFps);
			icon.animation.play("icon");
			icon.animation.curAnim.curFrame = curMod.icon.animation.curAnim.curFrame;
		}

		if(modName.scaleX != 0.8) modName.setScale(0.8);
		modName.text = curMod.name;
		var newScale = Math.min(620 / (modName.width / 0.8), 0.8);
		modName.setScale(newScale, Math.min(newScale * 1.35, 0.8));
		modName.y = modNameInitialY - (modName.height / 2);
		modRestartText.visible = curMod.mustRestart;
		modDesc.text = curMod.desc;

		var isOn:Bool = !modsList.disabled.contains(curMod.folder);
		statusPill.color = isOn ? GOOD_COLOR : BAD_COLOR;
		statusText.text = isOn ? "ENABLED" : "DISABLED";
		modFolderText.text = 'mods/' + curMod.folder;
		modCounter.text = StringTools.lpad(Std.string(curSelectedMod + 1), "0", 2) + " / " + StringTools.lpad(Std.string(modsList.all.length), "0", 2);

		for (button in buttons) if(button.focusChangeCallback != null) button.focusChangeCallback(button.onFocus);
		settingsButton.enabled = (curMod.settings != null && curMod.settings.length > 0);
	}

	var centerMod:Int = 2;
	function updateItemPositions()
	{
		var maxVisible = Math.max(4, centerMod + 2);
		var minVisible = Math.max(0, centerMod - 2);
		for (i => mod in modsGroup.members)
		{
			if(mod == null)
			{
				trace('Mod #$i is null, maybe it was ' + modsList.all[i]);
				continue;
			}

			mod.visible = (i >= minVisible && i <= maxVisible);
			mod.x = bgList.x + 5;
			mod.y = bgList.y + (86 * (i - centerMod + 2)) + 5;
			
			mod.alpha = 0.6;
			if(i == curSelectedMod) mod.alpha = 1;
			mod.selectBg.visible = (i == curSelectedMod && hoveringOnMods);
		}
	}

	var waitingToRestart:Bool = false;
	function moveModToPosition(?mod:String = null, position:Int = 0)
	{
		if(mod == null) mod = modsList.all[curSelectedMod];
		if(position >= modsList.all.length) position = 0;
		else if(position < 0) position = modsList.all.length-1;

		trace('Moved mod $mod to position $position');
		var id:Int = modsList.all.indexOf(mod);
		if(position == id) return;

		var curMod:ModItem = modsGroup.members[id];
		if(curMod == null) return;

		if(curMod.mustRestart || modsGroup.members[position].mustRestart) waitingToRestart = true;

		modsGroup.remove(curMod, true);
		modsList.all.remove(mod);
		//if(position > id) position--;
		modsGroup.insert(position, curMod);
		modsList.all.insert(position, mod);

		curSelectedMod = position;
		updateModDisplayData();
		updateItemPositions();
		
		if(!hoveringOnMods)
		{
			var curMod:ModItem = modsGroup.members[curSelectedMod];
			if(curMod != null) curMod.selectBg.visible = false;
		}
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
	}

	function checkToggleButtons()
	{
		buttonEnableAll.visible = buttonEnableAll.enabled = buttonEnableAll.active = modsList.disabled.length > 0;
		buttonDisableAll.visible = buttonDisableAll.enabled = buttonDisableAll.active = !buttonEnableAll.visible;
	}

	function reload()
	{
		saveTxt();
		FlxG.autoPause = ClientPrefs.data.autoPause;
		FlxTransitionableState.skipNextTransIn = true;
		FlxTransitionableState.skipNextTransOut = true;
		var curMod:ModItem = modsGroup.members[curSelectedMod];
		MusicBeatState.switchState(new ModsMenuState(curMod != null ? curMod.folder : null));
	}
	
	function saveTxt()
	{
		var fileStr:String = '';
		for (mod in modsList.all)
		{
			if(mod.trim().length < 1) continue;

			if(fileStr.length > 0) fileStr += '\n';

			var on = '1';
			if(modsList.disabled.contains(mod)) on = '0';
			fileStr += '$mod|$on';
		}

		var path:String = 'modsList.txt';
		File.saveContent(path, fileStr);
	}
}

class ModItem extends FlxSpriteGroup
{
	public var rowBg:FlxSprite;
	public var selectBg:FlxSprite;
	public var dot:FlxSprite;
	public var icon:FlxSprite;
	public var text:FlxText;
	public var totalFrames:Int = 0;

	// options
	public var name:String = 'Unknown Mod';
	public var desc:String = 'No description provided.';
	public var iconFps:Int = 10;
	public var bgColor:FlxColor = 0xFF665AFF;
	public var pack:Dynamic = null;
	public var folder:String = 'unknownMod';
	public var mustRestart:Bool = false;
	public var settings:Array<Dynamic> = null;

	public function new(folder:String)
	{
		super();

		this.folder = folder;
		pack = Mods.getPack(folder);

		var path:String = Paths.mods('$folder/data/settings.json');
		if(FileSystem.exists(path))
		{
			var data:String = File.getContent(path);
			try
			{
				//trace('trying to load settings: $folder');
				settings = tjson.TJSON.parse(data);
			}
			catch(e:Dynamic)
			{
				var errorTitle = 'Mod name: ' + Mods.currentModDirectory;
				var errorMsg = 'An error occurred: $e';
				CoolUtil.showPopUp(errorMsg, errorTitle);
			}
		}

		rowBg = FlxSpriteUtil.drawRoundRect(new FlxSprite().makeGraphic(330, 78, FlxColor.TRANSPARENT, true), 0, 0, 330, 78, 24, 24, FlxColor.WHITE);
		rowBg.color = FlxColor.BLACK;
		rowBg.alpha = 0.35;
		add(rowBg);

		selectBg = new FlxSprite().loadGraphicFromSprite(rowBg);
		selectBg.alpha = 0.9;
		selectBg.visible = false;
		add(selectBg);

		dot = FlxSpriteUtil.drawCircle(new FlxSprite(304, 32).makeGraphic(14, 14, FlxColor.TRANSPARENT, true), -1, -1, 6, FlxColor.WHITE);
		dot.color = ModsMenuState.GOOD_COLOR;
		add(dot);

		icon = new FlxSprite(4, 2);
		icon.antialiasing = ClientPrefs.data.antialiasing;
		add(icon);

		text = new FlxText(90, 0, 205, "", 16);
		text.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		text.borderSize = 2;
		
		add(text);

		var isPixel = false;
		var bmp = Paths.cacheBitmap(Paths.mods('$folder/pack.png'));
		if(bmp == null)
		{
			bmp = Paths.cacheBitmap(Paths.mods('$folder/pack-pixel.png'));
			isPixel = true;
		}

		if(bmp != null)
		{
			icon.loadGraphic(bmp, true, 150, 150);
			if(isPixel) icon.antialiasing = false;
		}
		else icon.loadGraphic(Paths.image('unknownMod'), true, 150, 150);
		icon.scale.set(0.5, 0.5);
		icon.updateHitbox();
		
		this.name = folder;
		if(pack != null)
		{
			if(pack.name != null) this.name = pack.name;
			if(pack.description != null) this.desc = pack.description;
			if(pack.iconFramerate != null) this.iconFps = pack.iconFramerate;
			if(pack.color != null)
			{
				this.bgColor = FlxColor.fromRGB(pack.color[0] != null ? pack.color[0] : 170,
												pack.color[1] != null ? pack.color[1] : 0,
												pack.color[2] != null ? pack.color[2] : 255);
			}
			this.mustRestart = (pack.restart == true);
		}
		text.text = this.name;
		text.y = Std.int((78 - text.height) / 2);
		selectBg.color = FlxColor.interpolate(bgColor, FlxColor.WHITE, 0.2);

		if(bmp != null)
		{
			totalFrames = Math.floor(bmp.width / 150) * Math.floor(bmp.height / 150);
			icon.animation.add("icon", [for (i in 0...totalFrames) i], iconFps);
			icon.animation.play("icon");
		}
		}

	public function setEnabled(on:Bool)
	{
		icon.color = on ? FlxColor.WHITE : 0xFFFF6666;
		text.color = on ? FlxColor.WHITE : FlxColor.GRAY;
		dot.color = on ? ModsMenuState.GOOD_COLOR : ModsMenuState.BAD_COLOR;
	}
}

class MenuButton extends FlxSpriteGroup
{
	public var bg:FlxSprite;
	public var border:FlxSprite;
	public var textOn:Alphabet;
	public var textOff:Alphabet;
	public var icon:FlxSprite;
	public var onClick:Void->Void = null;
	public var enabled(default, set):Bool = true;
	public function new(x:Float, y:Float, width:Int, height:Int, ?text:String = null, ?img:FlxGraphic = null, onClick:Void->Void = null, animWidth:Int = 0, animHeight:Int = 0)
	{
		super(x, y);
		
		bg = FlxSpriteUtil.drawRoundRect(new FlxSprite().makeGraphic(width, height, FlxColor.TRANSPARENT), 0, 0, width, height, 24, 24, FlxColor.WHITE);
		bg.color = ModsMenuState.PANEL_COLOR;
		add(bg);

		border = FlxSpriteUtil.drawRoundRect(new FlxSprite().makeGraphic(width, height, FlxColor.TRANSPARENT, true), 1, 1, width - 2, height - 2, 24, 24, FlxColor.TRANSPARENT, {thickness: 2, color: FlxColor.WHITE});
		add(border);

		if(text != null)
		{
			textOn = new Alphabet(0, 0, "", false);
			textOn.setScale(0.6);
			textOn.text = text;
			textOn.alpha = 0.6;
			textOn.visible = false;
			centerOnBg(textOn);
			textOn.y -= 30;
			add(textOn);
			
			textOff = new Alphabet(0, 0, "", true);
			textOff.setScale(0.52);
			textOff.text = text;
			textOff.alpha = 0.6;
			centerOnBg(textOff);
			add(textOff);
		}
		else if(img != null)
		{
			icon = new FlxSprite();
			if(animWidth > 0 || animHeight > 0) icon.loadGraphic(img, true, animWidth, animHeight);
			else icon.loadGraphic(img);
			centerOnBg(icon);
			add(icon);
		}

		this.onClick = onClick;
		setButtonVisibility(false);
	}

	public var focusChangeCallback:Bool->Void = null;
	public var onFocus(default, set):Bool = false;
	public var ignoreCheck:Bool = false;
	private var _needACheck:Bool = false;
	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if(!enabled)
		{
			onFocus = false;
			return;
		}

		if (Controls.instance.mobileC) {
			if(!ignoreCheck)
				onFocus = TouchUtil.overlaps(this);

			if(onFocus && TouchUtil.justReleased)
				onFocus = false;

			if(onFocus && onClick != null && TouchUtil.justPressed)
				onClick();

			if(_needACheck) {
				_needACheck = false;
				setButtonVisibility(TouchUtil.overlaps(this));
			}
		} else {
			if(!ignoreCheck && !Controls.instance.controllerMode && FlxG.mouse.justMoved && FlxG.mouse.visible)
				onFocus = FlxG.mouse.overlaps(this);

			if(onFocus && onClick != null && FlxG.mouse.justPressed)
				onClick();

			if(_needACheck) {
				_needACheck = false;
				if(!Controls.instance.controllerMode)
					setButtonVisibility(FlxG.mouse.overlaps(this));
			}
		}
	}

	function set_onFocus(newValue:Bool)
	{
		var lastFocus:Bool = onFocus;
		onFocus = newValue;
		if(onFocus != lastFocus && enabled) setButtonVisibility(onFocus);
		return newValue;
	}

	function set_enabled(newValue:Bool)
	{
		enabled = newValue;
		setButtonVisibility(false);
		alpha = enabled ? 1 : 0.4;

		_needACheck = enabled;
		return newValue;
	}

	public function setButtonVisibility(focusVal:Bool)
	{
		alpha = 1;
		bg.color = focusVal ? FlxColor.WHITE : ModsMenuState.PANEL_COLOR;
		bg.alpha = focusVal ? 0.92 : 0.8;
		border.color = focusVal ? ModsMenuState.accentColor : FlxColor.WHITE;
		border.alpha = focusVal ? 1 : 0.25;

		var focusAlpha = focusVal ? 1 : 0.6;
		if(textOn != null && textOff != null)
		{
			textOn.alpha = textOff.alpha = focusAlpha;
			textOn.visible = focusVal;
			textOff.visible = !focusVal;
		}
		else if(icon != null)
		{
			icon.alpha = focusAlpha;
			icon.color = focusVal ? FlxColor.BLACK : FlxColor.WHITE;
		}

		if(!enabled) alpha = 0.4;
		if(focusChangeCallback != null) focusChangeCallback(focusVal);
	}

	public function centerOnBg(spr:FlxSprite)
	{
		spr.x = bg.width/2 - spr.width/2;
		spr.y = bg.height/2 - spr.height/2;
	}
}
