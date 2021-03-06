local WARFRONTS_GRUNT_ACTORS_HORDE =
{
	grunt1 = 83860, -- ORCMALE_HD.m2 (Grunt)
	grunt2 = 87186, -- TROLLFEMALE_HD.m2 (Witch Doctor)
	grunt3 = 85979, -- BLOODELFFEMALE_HD.m2 (Warcaster)
	grunt4 = 81941, -- GOBLINMALE.m2 (Wistel)
	grunt5 = 83958, -- TROLLMALE_HD.m2 (Axe Thrower)
	grunt6 = 84011, -- TAURENFEMALE_HD.m2 (Warrior)
	grunt7 = 83858, -- ORCFEMALE_HD.m2 (Grunt)
	grunt8 = 83766, -- ORCMALE_HD.m2 (Peon)
}

local WARFRONTS_GRUNT_ACTORS_ALLIANCE =
{
	grunt1 = 86715, -- humanguard_m.m2 (human male footman)
	grunt2 = 86833, -- DWARFFEMALE_HD.m2 (dwarf female rifleman)
	grunt3 = 84310, -- GNOMEFEMALE_HD.m2 (gnome female engineer)
	grunt4 = 86989, -- HUMANFEMALE_HD.m2 (human female priest)
	grunt5 = 86823, -- DWARFMALE_HD.m2 (dwarf male rifleman)
	grunt6 = 86814, -- humanknight_m.m2 (human male knight)
	grunt7 = 87004, -- HUMANFEMALE_HD.m2 (human female sorceress)
	grunt8 = 87528, -- draeneipeacekeeper_m.m2 (draenei male paladin)
}

WarfrontsPartyPoseMixin = CreateFromMixins(PartyPoseMixin);

function WarfrontsPartyPoseMixin:PlayRewardsAnimations()
	self.RewardAnimations.RewardFrame:Show();
	if (self:CanResumeAnimation()) then
		self:PlayNextRewardAnimation();
	end
	self.isPlayingRewards = true;
end

function WarfrontsPartyPoseMixin:AddActor(scene, displayID, name)
	local actor = scene:GetActorByTag(name);
	if (actor) then
		if (actor:SetModelByCreatureDisplayID(displayID)) then
			self:SetupShadow(actor);
		end
	end
end

function WarfrontsPartyPoseMixin:AddModelSceneActors(playerFactionGroup)
	local actors = playerFactionGroup == "Horde" and WARFRONTS_GRUNT_ACTORS_HORDE or WARFRONTS_GRUNT_ACTORS_ALLIANCE;
	for scriptTag, displayID in pairs(actors) do
		self:AddActor(self.ModelScene, displayID, scriptTag);
	end
end

function WarfrontsPartyPoseMixin:SetLeaveButtonText()
	self.LeaveButton:SetText(WARFRONTS_LEAVE);
end

do
	local warfrontsStyleData =
	{
		-- Behavior
		registerForWidgets = false,
		addModelSceneActors = true,
		partyCategory = LE_PARTY_CATEGORY_HOME,

		-- Theme
		Horde =
		{
			topperOffset = -37,
			borderPaddingX = 30,
			borderPaddingY = 20,
			Topper = "scoreboard-horde-header",
			TitleBG = "scoreboard-header-horde",
			ModelSceneBG = "scoreboard-background-warfronts-horde",
			nineSliceLayout = "PartyPoseKit",
			nineSliceTextureKitName = "horde",
		},

		Alliance =
		{
			topperOffset = -28,
			borderPaddingX = 30,
			borderPaddingY = 20,
			Topper = "scoreboard-alliance-header",
			TitleBG = "scoreboard-header-alliance",
			ModelSceneBG = "scoreboard-background-warfronts-alliance",
			nineSliceLayout = "PartyPoseKit",
			nineSliceTextureKitName = "alliance",
		},
	}

	function WarfrontsPartyPoseMixin:LoadScreenData(mapID, winner)
		PartyPoseMixin.LoadScreenData(self, mapID, winner, warfrontsStyleData);
	end
end

function WarfrontsPartyPoseMixin:OnLoad()
	self:RegisterEvent("SCENARIO_COMPLETED");
	self:RegisterEvent("QUEST_LOOT_RECEIVED");
	self:RegisterEvent("QUEST_CURRENCY_LOOT_RECEIVED");
	PartyPoseMixin.OnLoad(self);
	self.isPlayingRewards = false;
end

function WarfrontsPartyPoseMixin:OnHide()
	self.questID = nil;
	self.isPlayingRewards = false;
end

function WarfrontsPartyPoseMixin:OnEvent(event, ...)
	PartyPoseMixin.OnEvent(self, event, ...);
	if (event == "UI_MODEL_SCENE_INFO_UPDATED") then
		self:AddModelSceneActors(UnitFactionGroup("player"));
	elseif (event == "SCENARIO_COMPLETED") then
		self.pendingRewardData = {};
		self.questID = ...;
	elseif (event == "QUEST_LOOT_RECEIVED") then
		local questID, rewardItemLink, quantity = ...;
		if (questID == self.questID) then
			local item = Item:CreateFromItemLink(rewardItemLink);
			item:ContinueOnItemLoad(function()
				local id = item:GetItemID();
				local quality = item:GetItemQuality();
				local texture = item:GetItemIcon();
				local name = item:GetItemName();
				self:AddReward(name, texture, quality, id, "item", rewardItemLink, quantity, quantity, false);
				if (not self.isPlayingRewards) then
					self:PlayRewardsAnimations();
				end
			end);
		end
	elseif (event == "QUEST_CURRENCY_LOOT_RECEIVED") then
		local questID, currencyId, quantity = ...;
		if (questID == self.questID) then
			local name, _, texture, _, _, _, _, quality = GetCurrencyInfo(currencyId);
			local originalQuantity = quantity;
			local isCurrencyContainer = C_CurrencyInfo.IsCurrencyContainer(currencyId, quantity);
			name, texture, quantity, quality = CurrencyContainerUtil.GetCurrencyContainerInfo(currencyId, quantity, name, texture, quality);
			self:AddReward(name, texture, quality, currencyId, "currency", currencyLink, quantity, originalQuantity, isCurrencyContainer);
			if (not self.isPlayingRewards) then
				self:PlayRewardsAnimations();
			end
		end
	end
end