package;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import lime.app.Application;
import ui.AtlasMenuList;
import ui.MenuList;
import ui.OptionsState;
import ui.PreferencesMenu;
import ui.Prompt;

using StringTools;

#if discord_rpc
import Discord.DiscordClient;
#end
#if newgrounds
import io.newgrounds.NG;
import ui.NgPrompt;
#end

class MainMenuState extends MusicBeatState
{
	var menuItems:MainMenuList;

	var magenta:FlxSprite;
	var camFollow:FlxObject;

	override function create()
	{
		#if discord_rpc
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		if (!FlxG.sound.music.playing)
		{
			FlxG.sound.playMusic(Paths.music('freakyMenu'));
		}

		persistentUpdate = persistentDraw = true;

		var bg:FlxSprite = new FlxSprite(Paths.image('menus/main/menuBG'));
		bg.scrollFactor.x = 0;
		bg.scrollFactor.y = 0;
		bg.setGraphicSize(Std.int(bg.width * 1.2));
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = true;
		add(bg);

		camFollow = new FlxObject(0, 0, 1, 1);
		add(camFollow);

		magenta = new FlxSprite(Paths.image('menus/main/menuDesat'));
		magenta.scrollFactor.x = bg.scrollFactor.x;
		magenta.scrollFactor.y = bg.scrollFactor.y;
		magenta.setGraphicSize(Std.int(bg.width));
		magenta.updateHitbox();
		magenta.x = bg.x;
		magenta.y = bg.y;
		magenta.visible = false;
		magenta.antialiasing = true;
		magenta.color = 0xFFfd719b;
		if (PreferencesMenu.preferences.get('flashing-menu'))
			add(magenta);
		// magenta.scrollFactor.set();

		menuItems = new MainMenuList();
		add(menuItems);
		menuItems.onChange.add(onMenuItemChange);
		menuItems.onAcceptPress.add(function(_)
		{
			FlxFlicker.flicker(magenta, 1.1, 0.15, false, true);
		});

		menuItems.enabled = false; // disable for intro
		menuItems.createItem('story mode', function() startExitState(new StoryMenuState()));
		menuItems.createItem('freeplay', function() startExitState(new FreeplayState()));
		#if CAN_OPEN_LINKS
		var hasPopupBlocker = #if web true #else false #end;
		menuItems.createItem('donate', selectDonate, hasPopupBlocker);
		#end
		// menuItems.createItem('options', function() startExitState(new OptionsState()));

		// center vertically
		var spacing = 160;
		var top = (FlxG.height - (spacing * (menuItems.length - 1))) / 2;
		for (i in 0...menuItems.length)
		{
			var menuItem = menuItems.members[i];
			menuItem.x = FlxG.width / 2;
			menuItem.y = top + spacing * i;
		}

		FlxG.cameras.reset(new SwagCamera());
		FlxG.camera.follow(camFollow, null, 0.06);

		super.create();
	}

	override function finishTransIn()
	{
		super.finishTransIn();

		menuItems.enabled = true;
	}

	function onMenuItemChange(selected:MenuItem)
	{
		camFollow.setPosition(selected.getGraphicMidpoint().x, selected.getGraphicMidpoint().y);
	}

	#if CAN_OPEN_LINKS
	function selectDonate()
	{
		#if linux
		// Sys.command('/usr/bin/xdg-open', ["https://ninja-muffin24.itch.io/funkin", "&"]);
		Sys.command('/usr/bin/xdg-open', [
			"https://www.kickstarter.com/projects/funkin/friday-night-funkin-the-full-ass-game/",
			"&"
		]);
		#else
		// FlxG.openURL('https://ninja-muffin24.itch.io/funkin');

		FlxG.openURL('https://www.kickstarter.com/projects/funkin/friday-night-funkin-the-full-ass-game/');
		#end
	}
	#end

	public function openPrompt(prompt:Prompt, onClose:Void->Void)
	{
		menuItems.enabled = false;
		prompt.closeCallback = function()
		{
			menuItems.enabled = true;
			if (onClose != null)
				onClose();
		}

		openSubState(prompt);
	}

	function startExitState(state:FlxState)
	{
		menuItems.enabled = false; // disable for exit
		var duration = 0.4;
		menuItems.forEach(function(item)
		{
			if (menuItems.selectedIndex != item.ID)
			{
				FlxTween.tween(item, {alpha: 0}, duration, {ease: FlxEase.quadOut});
			}
			else
			{
				item.visible = false;
			}
		});

		new FlxTimer().start(duration, function(_) FlxG.switchState(state));
	}

	override function update(elapsed:Float)
	{
		// FlxG.camera.followLerp = CoolUtil.camLerpShit(0.06);

		if (FlxG.sound.music.volume < 0.8)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		if (_exiting)
			menuItems.enabled = false;

		if (controls.BACK && menuItems.enabled && !menuItems.busy)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			FlxG.switchState(new TitleState());
		}

		super.update(elapsed);
	}
}

private class MainMenuList extends MenuTypedList<MainMenuItem>
{
	public var atlas:FlxAtlasFrames;

	public function new()
	{
		atlas = Paths.getSparrowAtlas('menus/main/main_menu');
		super(Vertical);
	}

	public function createItem(x = 0.0, y = 0.0, name:String, callback, fireInstantly = false)
	{
		var item = new MainMenuItem(x, y, name, atlas, callback);
		item.fireInstantly = fireInstantly;
		item.ID = length;

		return addItem(name, item);
	}

	override function destroy()
	{
		super.destroy();
		atlas = null;
	}
}

private class MainMenuItem extends AtlasMenuItem
{
	public function new(x = 0.0, y = 0.0, name, atlas, callback)
	{
		super(x, y, name, atlas, callback);
		scrollFactor.set(0, 0);
	}

	override function changeAnim(anim:String)
	{
		super.changeAnim(anim);
		// position by center
		centerOrigin();
		offset.copyFrom(origin);
	}
}
