CutscenePlayer:getSingleton():registerCutscene("ZombieSurvivalCutscene", {
	name = "Intro";
	startscene = "init_Scene";
	debug = true;

	-- Init Scene
	{
		uid = "init_Scene";
		letterbox = true;
		{
			action = "General.fade";
			fadein = false;
			time = 0;
			starttick = 0;
		};
		{
			action = "General.weather";
			time = {9,0};
			farclipdistance = 2000;
			fogdistance = 10;
			clouds = true;
			weather = 8;
			starttick = 0;
		};
		{
			action = "Object.create";
			id = "object_1";
			model = 3863;
			pos = {-32.4, 1377.8, 9.3};
			rot = 274;
			starttick = 0;
		};
		{
			action = "Ped.create";
			id = "guy_1";
			model = 162;
			pos = {-31.64, 1377.67, 9.17};
			rot = 90;
			starttick = 0;
		};
		{
			action = "Ped.create";
			id = "localPlayer";
			model = 1;
			pos = {-45.905, 1376.090, 10.208};
			rot = -85;
			starttick = 0;
		};
		{
			action = "Camera.set";
			starttick = 0;
			pos = {-41.4, 1366.4, 11.2};
			lookat = {-41.2, 1367.3, 11.1};
			fov = 70;
		};
		{
			action = "General.change_scene";
			scene = "1_Scene";
			starttick = 250;
		};
	};

	-- Scene 1
	{
		uid = "1_Scene";
		letterbox = true;
		{
			action = "General.fade";
			fadein = true;
			time = 1000;
			starttick = 0;
		};
		{
			action = "Ped.setAnimation";
			starttick = 0;
			id = "guy_1";
			animBlock = "SMOKING";
			anim = "M_smklean_loop";
			looped = false;
		};
		{
			action = "Ped.setAnimation";
			starttick = 1750;
			id = "guy_1";
			animBlock = "ped";
			anim = "IDLE_chat";
			looped = true;
		};
		{
			action = "Graphic.setLetterBoxText";
			starttick = 1750;
			duration = 3000;
			text = "Fremder: Hallo mein Freund. Komm mal her!";
		};
		{
			action = "Ped.setAnimation";
			starttick = 4750;
			id = "guy_1";
			animBlock = nil;
			anim = nil;
		};
		{
			action = "Ped.setPedControlState";
			starttick = 4250;
			id = "localPlayer";
			control = "forwards";
			state = true
		};
		{
			action = "Ped.setPedControlState";
			starttick = 6450;
			id = "localPlayer";
			control = "forwards";
			state = false
		};
		{
			action = "Ped.setAnimation";
			starttick = 6500;
			id = "guy_1";
			animBlock = "ped";
			anim = "IDLE_chat";
			looped = true;
		};
		{
			action = "Graphic.setLetterBoxText";
			starttick = 6500;
			duration = 3000;
			text = "Fremder: Ich will dir was anbieten, hast du Interesse an bisschen Spaß?";
		};
		{
			action = "Graphic.setLetterBoxText";
			starttick = 9500;
			duration = 3000;
			text = "Fremder: Das ist was besonderes aus meinem Garten, nennt sich \"Orange Haze\"";
		};
		{
			action = "Ped.setAnimation";
			starttick = 11500;
			id = "guy_1";
			animBlock = "DEALER";
			anim = "DEALER_DEAL";
			looped = false;
		};
		{
			action = "Ped.setAnimation";
			starttick = 14500;
			id = "guy_1";
			animBlock = "ped";
			anim = "IDLE_chat";
			looped = true;
		};
		{
			action = "Graphic.setLetterBoxText";
			starttick = 14500;
			duration = 5000;
			text = "Fremder: Ich hab dir was hingelegt, der erste Joint ist sogar kostenlos!";
		};
		{
			action = "Ped.setAnimation";
			starttick = 19500;
			id = "guy_1";
			animBlock = nil;
			anim = nil;
		};
		{
			action = "Ped.setAnimation";
			starttick = 19500;
			id = "localPlayer";
			animBlock = "smoking";
			anim = "M_smkstnd_loop";
			looped = false;
		};
		{
			action = "Graphic.setLetterBoxText";
			starttick = 24500;
			duration = 2000;
			text = "Fremder: Viel Spaß! Und pass auf die Zomb...";
		};
		{
			action = "General.fade";
			fadein = false;
			starttick = 24500;
			time = 2500;
		};
		{
			action = "General.finish";
			starttick = 27000;
		}
	};

})
