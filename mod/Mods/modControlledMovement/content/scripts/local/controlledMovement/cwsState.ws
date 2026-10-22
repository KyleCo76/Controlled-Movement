// Configuration, two selection modes, shared exploration scope and one owned HUD value.
// Original project code. Speeds are relative movement requests, not metres per second.
class CWS_State extends CObject
{
    public var enabled : bool;
    public var requireModifier : bool;
    public var showSpeedChanges : bool;
    public var trueSteps : bool;
    public var fluidControls : bool;
    public var sprintThreshold : int;
    public var capUnavailable : bool;
    public var smoothSteps : bool;
    public var smoothFavorites : bool;
    public var smoothStarting : bool;
    public var increaseCurve : int;
    public var decreaseCurve : int;
    public var increaseTimeMs : int;
    public var decreaseTimeMs : int;
    public var resetAtStop : bool;
    public var stopDestination : int;
    public var trueStepSize : int;
    public var trueStepMax : int;
    private var CWS_trueUnits : int;
    private var CWS_hasTrueSelection : bool;
    private var CWS_staticOverrideUnits : int;
    private var CWS_noticeOwner : CR4Player;
    private var CWS_noticeHorse : bool;
    private var CWS_noticeSwimming : bool;
    private var CWS_noticeModule : CR4HudModuleMessage;
    public var count : int;
    public var selected : int;
    public var favoriteA : int;
    public var favoriteB : int;
    public var speeds : array<float>;
    private var CWS_loading : bool;
    private var CWS_savePending : bool;
    private var CWS_refreshingMenu : bool;

    // Compatibility entry points for unchanged input/menu/lifecycle callers.
    // Their ownership is numerical; they never select an animation route.
    public function CWS_GraphRelease()
    {
        CWS_SuspendMotion();
    }

    public function CWS_GraphPoll()
    {
        if (CWS_motionPlayer && !CWS_MotionSessionOwned(theGame.GetEngineTimeAsSeconds()))
            CWS_SuspendMotion();
    }

    public function CWS_PresentValueChange(units : int, optional horseNotice : bool, optional swimmingNotice : bool)
    {
        var player : CR4Player;
        var hud : CR4ScriptedHud;
        var module : CR4HudModuleMessage;
        player = (CR4Player)thePlayer;
        hud = (CR4ScriptedHud)theGame.GetHud();
        if (!player || !hud)
            return;
        module = (CR4HudModuleMessage)hud.GetHudModule("MessageModule");
        if (!module || !module.CWS_ValueDisplayReady())
            return;
        if (CWS_noticeOwner && CWS_noticeOwner != player)
            CWS_CancelValueReadout();
        player.CWS_QueueValueNotice(units, horseNotice, swimmingNotice);
        CWS_noticeHorse = horseNotice;
        CWS_noticeSwimming = swimmingNotice;
        CWS_noticeOwner = player;
        CWS_noticeModule = module;
        module.CWS_RefreshValueNotice(player);
    }

    public function CWS_CancelValueReadout()
    {
        // A displayed head must survive until its normal hidden acknowledgement.
        if (CWS_noticeOwner && (!CWS_noticeModule || !CWS_noticeModule.CWS_IsDisplayingValueNotice(CWS_noticeOwner)))
            CWS_noticeOwner.CWS_EraseQueuedValueNotice();
        CWS_noticeOwner = NULL;
        CWS_noticeModule = NULL;
    }

    public function CWS_ValueReadoutPoll()
    {
        var eligible : bool;
        if(CWS_noticeSwimming)
            eligible = CWS_GetSwimState().showSpeedChanges && CWSS_ProfileActive() && CWS_noticeOwner == thePlayer;
        else if(CWS_noticeHorse)
            eligible = CWS_GetHorseState().showSpeedChanges && CWS_HorseCanInput(CWS_noticeOwner);
        else
            eligible = showSpeedChanges && CWS_IsEligible(CWS_noticeOwner);
        if (CWS_noticeOwner && (!theGame.CWS_Input || !eligible))
            CWS_CancelValueReadout();
    }

    public function CWS_DefaultSpeed(index : int) : float
    {
        switch (index)
        {
            case 0: return 0.11f;
            case 1: return 0.30f;
            case 2: return 0.60f;
            case 3: return 0.80f;
            case 4: return 0.90f;
            case 5: return 1.00f;
            case 6: return 1.20f;
        }
        return 1.49f;
    }

    public function CWS_SpeedKey(index : int) : name
    {
        switch (index)
        {
            case 0: return 'CWS_Speed01';
            case 1: return 'CWS_Speed02';
            case 2: return 'CWS_Speed03';
            case 3: return 'CWS_Speed04';
            case 4: return 'CWS_Speed05';
            case 5: return 'CWS_Speed06';
            case 6: return 'CWS_Speed07';
        }
        return 'CWS_Speed08';
    }

    public function CWS_ClampIndex(index : int) : int
    {
        return Max(1, Min(count, index));
    }

    public function CWS_Select(index : int)
    {
        var previous : float;
        if (!CWS_commandSelecting)
            CWS_CancelMotion();
        previous = CWS_SelectedSpeed();
        if (trueSteps)
        {
            index = Max(1, Min(8, index));
            CWS_trueUnits = CWS_ClampTrueUnits(RoundF(speeds[index - 1] * 100.0f));
            CWS_hasTrueSelection = true;
        }
        else
        {
            selected = CWS_ClampIndex(index);
            CWS_staticOverrideUnits = 0;
        }
        CWS_SelectionChanged(previous);
    }

    public function CWS_StaticSelectedSpeed() : float
    {
        if (CWS_staticOverrideUnits != 0)
            return (float)CWS_staticOverrideUnits / 100.0f;
        return speeds[CWS_ClampIndex(selected) - 1];
    }

    public function CWS_SetStaticOverride(units : int)
    {
        var i : int;
        // Exact temporary destinations never rewrite the configured ladder.
        if (!CWS_commandSelecting)
            CWS_CancelMotion();
        CWS_staticOverrideUnits = units;
        if (units == 0)
            return;
        for (i = 0; i < count; i += 1)
        {
            if (RoundF(speeds[i] * 100.0f) == units)
            {
                selected = i + 1;
                CWS_staticOverrideUnits = 0;
            }
        }
    }

    public function CWS_ClampTrueUnits(units : int) : int
    {
        return Max(11, Min(trueStepMax, units));
    }

    public function CWS_AcceptSwimSelection(units : int)
    {
        var previous : float;
        var revision : int;
        previous = CWS_SelectedSpeed();
        CWS_SuspendMotion();
        CWS_commandRevision += 1;
        revision = CWS_commandRevision;
        CWS_commandSelecting = true;
        if(trueSteps)
        {
            CWS_trueUnits = CWS_ClampTrueUnits(units);
            CWS_hasTrueSelection = true;
        }
        else CWS_SetStaticOverride(Max(11, Min(149, units)));
        CWS_SelectionChanged(previous);
        if(revision == CWS_commandRevision) CWS_commandSelecting = false;
    }

    // Ticks follow a fixed grid; clipped endpoints never shift its alignment.
    public function CWS_Adjust(direction : int)
    {
        var previous : float;
        var increment, nextUnits, i : int;
        if (!CWS_commandSelecting)
            CWS_CancelMotion();
        if (direction == 0)
            return;
        if (!trueSteps)
        {
            if (CWS_staticOverrideUnits != 0)
            {
                // Rejoin the ordered active ladder on either side of the fallback.
                if (direction > 0)
                {
                    for (i = 0; i < count; i += 1)
                    {
                        if (speeds[i] > CWS_StaticSelectedSpeed())
                        {
                            CWS_Select(i + 1);
                            return;
                        }
                    }
                }
                else if (direction < 0)
                {
                    for (i = count - 1; i >= 0; i -= 1)
                    {
                        if (speeds[i] < CWS_StaticSelectedSpeed())
                        {
                            CWS_Select(i + 1);
                            return;
                        }
                    }
                }
                return;
            }
            CWS_Select(selected + direction);
            return;
        }
        previous = CWS_SelectedSpeed();
        increment = Max(1, Min(100, trueStepSize));
        nextUnits = CWS_trueUnits - CWS_trueUnits % increment;
        if (direction > 0)
            nextUnits += increment;
        else if (nextUnits == CWS_trueUnits)
            nextUnits -= increment;
        CWS_trueUnits = CWS_ClampTrueUnits(nextUnits);
        CWS_hasTrueSelection = true;
        CWS_SelectionChanged(previous);
    }

    public function CWS_ResetSelectionForSpawn()
    {
        var previous : float;
        CWS_SuspendMotion();
        previous = CWS_SelectedSpeed();
        CWS_staticOverrideUnits = 0;
        selected = CWS_ClampIndex(favoriteA);
        CWS_trueUnits = CWS_ClampTrueUnits(RoundF(speeds[Max(1, Min(8, favoriteA)) - 1] * 100.0f));
        CWS_hasTrueSelection = trueSteps;
        CWS_SelectionChanged(previous);
    }

    public function CWS_SelectedUnits() : int
    {
        if (trueSteps)
            return CWS_ClampTrueUnits(CWS_trueUnits);
        return RoundF(CWS_StaticSelectedSpeed() * 100.0f);
    }

    private function CWS_SelectionChanged(previous : float)
    {
        if (!CWS_commandSelecting)
            CWS_CancelMotion();
        if (CWS_SelectedSpeed() == previous)
            return;
        if (!CWS_commandSelecting)
            CWS_GraphPoll();
        if (showSpeedChanges && CWS_IsEligible((CR4Player)thePlayer))
            CWS_PresentValueChange(CWS_SelectedUnits());
    }

    public function CWS_SelectFavorite(useB : bool)
    {
        if (useB)
            CWS_Select(favoriteB);
        else
            CWS_Select(favoriteA);
    }

    public function CWS_ResolveFavoriteSpeed(useB : bool) : float
    {
        var index : int;
        var value : float;
        index = favoriteA;
        if (useB)
            index = favoriteB;
        if (trueSteps)
            return (float)CWS_ClampTrueUnits(RoundF(speeds[Max(1, Min(8, index)) - 1] * 100.0f)) / 100.0f;
        value = speeds[CWS_ClampIndex(index) - 1];
        return value;
    }

    public function CWS_SelectedSpeed() : float
    {
        if (trueSteps)
            return (float)CWS_ClampTrueUnits(CWS_trueUnits) / 100.0f;
        return CWS_StaticSelectedSpeed();
    }

    // Native restrictions limit applied pace, never the chosen destination.
    public function CWS_LimitPace(value : float) : float
    {
        if (CWS_FluidCapped())
            return MinF(value, 1.0f);
        return value;
    }

    public function CWS_TargetSpeed() : float
    {
        return CWS_LimitPace(CWS_SelectedSpeed());
    }

    public function CWS_NormalizeSpeed(value : float, fallback : float) : float
    {
        // NaN fails both ordered comparisons; infinities clamp to the range.
        if (!(value >= 0.0f) && !(value < 0.0f))
            value = fallback;
        value = ClampF(value, 0.11f, 1.49f);
        return (float)RoundF(value * 100.0f) / 100.0f;
    }

    private function CWS_Write(config : CInGameConfigWrapper, key : name, value : string) : bool
    {
        value = CWS_SelectorMenuValue(key, value);
        if (config.GetVarValue(CWS_SettingGroup(key), key) == value)
            return false;
        config.SetVarValue(CWS_SettingGroup(key), key, value);
        return true;
    }

    public function CWS_Load(optional deferSave : bool)
    {
        var config : CInGameConfigWrapper;
        var value : float;
        var raw : string;
        var i : int;
        var changed : bool;
        var firstSelection : bool;
        var previous : float;

        if (CWS_loading)
            return;
        if (speeds.Size() == 8)
            previous = CWS_SelectedSpeed();
        CWS_SuspendMotion();
        CWS_GraphRelease();
        config = theGame.GetInGameConfigWrapper();
        if (!config)
            return;
        CWS_loading = true;
        raw = config.GetVarValue(CWS_SettingGroup('CWS_Enabled'), 'CWS_Enabled');
        enabled = raw != "false";
        requireModifier = config.GetVarValue(CWS_SettingGroup('CWS_RequireModifier'), 'CWS_RequireModifier') != "false";
        showSpeedChanges = config.GetVarValue(CWS_SettingGroup('CWS_MotionDiagnostics'), 'CWS_MotionDiagnostics') == "true";
        trueSteps = config.GetVarValue(CWS_SettingGroup('CWS_TrueSteps'), 'CWS_TrueSteps') == "true";
        fluidControls = config.GetVarValue(CWS_SettingGroup('CWS_FluidControls'), 'CWS_FluidControls') == "true";
        sprintThreshold = Max(100, Min(149, RoundF(CWS_NormalizeSpeed(StringToFloat(config.GetVarValue(CWS_SettingGroup('CWS_SprintThreshold'), 'CWS_SprintThreshold'), 1.35f), 1.35f) * 100.0f)));
        capUnavailable = config.GetVarValue(CWS_SettingGroup('CWS_CapUnavailable'), 'CWS_CapUnavailable') != "false";
        smoothSteps = config.GetVarValue(CWS_SettingGroup('CWS_SmoothSteps'), 'CWS_SmoothSteps') == "true";
        smoothStarting = config.GetVarValue(CWS_SettingGroup('CWS_SmoothStarting'), 'CWS_SmoothStarting') == "true";
        smoothFavorites = config.GetVarValue(CWS_SettingGroup('CWS_SmoothFavorites'), 'CWS_SmoothFavorites') == "true";
        increaseCurve = StringToInt(config.GetVarValue(CWS_SettingGroup('CWS_IncreaseCurve'), 'CWS_IncreaseCurve'), 1);
        if (increaseCurve < 0 || increaseCurve > 3)
            increaseCurve = 1;
        decreaseCurve = StringToInt(config.GetVarValue(CWS_SettingGroup('CWS_DecreaseCurve'), 'CWS_DecreaseCurve'), 1);
        if (decreaseCurve < 0 || decreaseCurve > 3)
            decreaseCurve = 1;
        increaseTimeMs = Max(1, Min(100, StringToInt(config.GetVarValue(CWS_SettingGroup('CWS_IncreaseTimeMs'), 'CWS_IncreaseTimeMs'), 20)));
        decreaseTimeMs = Max(1, Min(100, StringToInt(config.GetVarValue(CWS_SettingGroup('CWS_DecreaseTimeMs'), 'CWS_DecreaseTimeMs'), 10)));
        resetAtStop = config.GetVarValue(CWS_SettingGroup('CWS_ResetAtStop'), 'CWS_ResetAtStop') == "true";
        stopDestination = StringToInt(config.GetVarValue(CWS_SettingGroup('CWS_StopDestination'), 'CWS_StopDestination'), 0);
        if (stopDestination != 0 && stopDestination != 1)
            stopDestination = 0;
        CWS_FluidPoll();
        trueStepSize = Max(1, Min(100, StringToInt(config.GetVarValue(CWS_SettingGroup('CWS_TrueStepSize'), 'CWS_TrueStepSize'), 1)));
        trueStepMax = RoundF(CWS_NormalizeSpeed(StringToFloat(config.GetVarValue(CWS_SettingGroup('CWS_TrueStepMax'), 'CWS_TrueStepMax'), 1.49f), 1.49f) * 100.0f);
        count = Max(3, Min(8, StringToInt(CWS_SelectorStoredValue('CWS_Count', config.GetVarValue(CWS_SettingGroup('CWS_Count'), 'CWS_Count')), 8)));
        favoriteA = Max(1, Min(8, StringToInt(CWS_SelectorStoredValue('CWS_FavoriteA', config.GetVarValue(CWS_SettingGroup('CWS_FavoriteA'), 'CWS_FavoriteA')), 3)));
        favoriteB = Max(1, Min(8, StringToInt(CWS_SelectorStoredValue('CWS_FavoriteB', config.GetVarValue(CWS_SettingGroup('CWS_FavoriteB'), 'CWS_FavoriteB')), 6)));
        speeds.Clear();
        for (i = 0; i < 8; i += 1)
        {
            value = StringToFloat(config.GetVarValue(CWS_SettingGroup(CWS_SpeedKey(i)), CWS_SpeedKey(i)), CWS_DefaultSpeed(i));
            value = CWS_NormalizeSpeed(value, CWS_DefaultSpeed(i));
            if (i > 0)
                value = MaxF(value, speeds[i - 1]);
            speeds.PushBack(value);
            if (CWS_Write(config, CWS_SpeedKey(i), FloatToStringPrec(value, 2)))
                changed = true;
        }
        if (enabled)
            raw = "true";
        else
            raw = "false";
        if (CWS_Write(config, 'CWS_Enabled', raw))
            changed = true;
        if (requireModifier)
            raw = "true";
        else
            raw = "false";
        if (CWS_Write(config, 'CWS_RequireModifier', raw))
            changed = true;
        raw = "false";
        if (showSpeedChanges)
            raw = "true";
        if (CWS_Write(config, 'CWS_MotionDiagnostics', raw))
            changed = true;
        raw = "false";
        if (trueSteps)
            raw = "true";
        if (CWS_Write(config, 'CWS_TrueSteps', raw))
            changed = true;
        raw = "false";
        if (fluidControls)
            raw = "true";
        if (CWS_Write(config, 'CWS_FluidControls', raw))
            changed = true;
        if (CWS_Write(config, 'CWS_SprintThreshold', FloatToStringPrec((float)sprintThreshold / 100.0f, 2)))
            changed = true;
        raw = "false";
        if (capUnavailable)
            raw = "true";
        if (CWS_Write(config, 'CWS_CapUnavailable', raw))
            changed = true;
        raw = "false";
        if (smoothSteps)
            raw = "true";
        if (CWS_Write(config, 'CWS_SmoothSteps', raw))
            changed = true;
        raw = "false";
        if (smoothFavorites)
            raw = "true";
        if (CWS_Write(config, 'CWS_SmoothFavorites', raw))
            changed = true;
        raw = "false";
        if (smoothStarting)
            raw = "true";
        if (CWS_Write(config, 'CWS_SmoothStarting', raw))
            changed = true;
        raw = "false";
        if (resetAtStop)
            raw = "true";
        if (CWS_Write(config, 'CWS_ResetAtStop', raw))
            changed = true;
        if (CWS_Write(config, 'CWS_IncreaseCurve', IntToString(increaseCurve)))
            changed = true;
        if (CWS_Write(config, 'CWS_DecreaseCurve', IntToString(decreaseCurve)))
            changed = true;
        if (CWS_Write(config, 'CWS_IncreaseTimeMs', IntToString(increaseTimeMs)))
            changed = true;
        if (CWS_Write(config, 'CWS_DecreaseTimeMs', IntToString(decreaseTimeMs)))
            changed = true;
        if (CWS_Write(config, 'CWS_StopDestination', IntToString(stopDestination)))
            changed = true;
        if (CWS_Write(config, 'CWS_TrueStepSize', IntToString(trueStepSize)))
            changed = true;
        if (CWS_Write(config, 'CWS_TrueStepMax', FloatToStringPrec((float)trueStepMax / 100.0f, 2)))
            changed = true;
        if (CWS_Write(config, 'CWS_Count', IntToString(count)))
            changed = true;
        if (CWS_Write(config, 'CWS_FavoriteA', IntToString(favoriteA)))
            changed = true;
        if (CWS_Write(config, 'CWS_FavoriteB', IntToString(favoriteB)))
            changed = true;
        firstSelection = selected <= 0;
        if (firstSelection)
            selected = CWS_ClampIndex(favoriteA);
        else
            selected = CWS_ClampIndex(selected);
        if (trueSteps && !CWS_hasTrueSelection)
        {
            if (firstSelection)
                CWS_trueUnits = CWS_ClampTrueUnits(RoundF(speeds[Max(1, Min(8, favoriteA)) - 1] * 100.0f));
            else
                CWS_trueUnits = CWS_ClampTrueUnits(RoundF(CWS_StaticSelectedSpeed() * 100.0f));
            CWS_hasTrueSelection = true;
        }
        CWS_trueUnits = CWS_ClampTrueUnits(CWS_trueUnits);
        CWS_loading = false;
        if (changed)
            CWS_savePending = true;
        if (CWS_savePending && !deferSave)
        {
            CWS_savePending = false;
            theGame.SaveUserSettings();
        }
        CWS_SelectionChanged(previous);
        CWS_ValueReadoutPoll();
    }

    public function CWS_SettingCount() : int
    {
        return 29;
    }

    // Preserve existing indices and append the new preferences.
    public function CWS_SettingKey(index : int) : name
    {
        if (index < 8)
            return CWS_SpeedKey(index);
        switch (index)
        {
            case 8: return 'CWS_Enabled';
            case 9: return 'CWS_RequireModifier';
            case 10: return 'CWS_MotionDiagnostics';
            case 11: return 'CWS_TrueSteps';
            case 12: return 'CWS_TrueStepSize';
            case 13: return 'CWS_TrueStepMax';
            case 14: return 'CWS_Count';
            case 15: return 'CWS_FavoriteA';
            case 16: return 'CWS_FavoriteB';
            case 17: return 'CWS_FluidControls';
            case 18: return 'CWS_SprintThreshold';
            case 19: return 'CWS_CapUnavailable';
            case 20: return 'CWS_SmoothSteps';
            case 21: return 'CWS_SmoothFavorites';
            case 22: return 'CWS_IncreaseTimeMs';
            case 23: return 'CWS_DecreaseTimeMs';
            case 24: return 'CWS_ResetAtStop';
            case 25: return 'CWS_StopDestination';
            case 26: return 'CWS_SmoothStarting';
            case 27: return 'CWS_IncreaseCurve';
            case 28: return 'CWS_DecreaseCurve';
        }
        return '';
    }

    // Publish current values only; presets do not own slider ranges or later edits.
    public function CWS_RefreshMenuValues()
    {
        var config : CInGameConfigWrapper;
        var menu : CR4IngameMenu;
        var keys : array<name>;
        var values : array<string>;
        var i : int;
        config = theGame.GetInGameConfigWrapper();
        menu = theGame.GetGuiManager().GetIngameMenu();
        if (CWS_refreshingMenu || !config || !menu)
            return;
        for (i = 0; i < CWS_SettingCount(); i += 1)
        {
            keys.PushBack(CWS_SettingKey(i));
            values.PushBack(config.GetVarValue(CWS_SettingGroup(CWS_SettingKey(i)), CWS_SettingKey(i)));
        }
        CWS_refreshingMenu = true;
        menu.CWS_UpdateSettingValues(keys, values, true);
        CWS_refreshingMenu = false;
    }

    public function CWS_ConfigChanged(key : name)
    {
        var config : CInGameConfigWrapper;
        var menu : CR4IngameMenu;
        var value : float;
        var i, j : int;
        var ours : bool;
        var before : array<string>;
        var keys : array<name>;
        var values : array<string>;
        var after : string;
        var setting : name;

        if (CWS_loading || CWS_refreshingMenu)
            return;
        for (i = 0; i < CWS_SettingCount(); i += 1)
        {
            if (key == CWS_SettingKey(i))
                ours = true;
        }
        if (!ours)
            return;
        config = theGame.GetInGameConfigWrapper();
        if (!config)
            return;
        for (i = 0; i < CWS_SettingCount(); i += 1)
            before.PushBack(config.GetVarValue(CWS_SettingGroup(CWS_SettingKey(i)), CWS_SettingKey(i)));
        for (i = 0; i < 8; i += 1)
        {
            if (key == CWS_SpeedKey(i))
            {
                ours = true;
                value = CWS_NormalizeSpeed(StringToFloat(config.GetVarValue(CWS_SettingGroup(key), key), speeds[i]), speeds[i]);
                // Keep the entered value. Raise later slots or lower earlier
                // slots only as needed to preserve order; equality is valid.
                CWS_loading = true;
                CWS_Write(config, key, FloatToStringPrec(value, 2));
                for (j = i - 1; j >= 0; j -= 1)
                {
                    if (speeds[j] <= value)
                        break;
                    CWS_Write(config, CWS_SpeedKey(j), FloatToStringPrec(value, 2));
                }
                for (j = i + 1; j < 8; j += 1)
                {
                    if (speeds[j] >= value)
                        break;
                    CWS_Write(config, CWS_SpeedKey(j), FloatToStringPrec(value, 2));
                }
                CWS_loading = false;
            }
        }
        CWS_ResetGesture();
        CWS_Load(theGame.GetGuiManager().IsAnyMenu());
        menu = theGame.GetGuiManager().GetIngameMenu();
        if (!menu || !theGame.GetGuiManager().IsAnyMenu())
            return;
        for (i = 0; i < CWS_SettingCount(); i += 1)
        {
            setting = CWS_SettingKey(i);
            after = config.GetVarValue(CWS_SettingGroup(setting), setting);
            // Formatting alone does not need to touch an active slider.
            if (before[i] != after && StringToFloat(before[i], -1000.0f) != StringToFloat(after, -2000.0f))
            {
                keys.PushBack(setting);
                values.PushBack(after);
            }
        }
        if (keys.Size() > 0)
        {
            CWS_refreshingMenu = true;
            menu.CWS_UpdateSettingValues(keys, values);
            CWS_refreshingMenu = false;
        }
    }
}

@addField(CR4Game)
private var CWS_StateData : CWS_State;

@addMethod(CR4Game)
public function CWS_StateObject() : CWS_State
{
    if (!CWS_StateData)
    {
        CWS_StateData = new CWS_State in this;
        CWS_StateData.CWS_Load();
    }
    return CWS_StateData;
}

function CWS_GetState() : CWS_State
{
    return theGame.CWS_StateObject();
}

function CWS_IsEligible(player : CR4Player) : bool
{
    var context : name;
    var witcher : W3PlayerWitcher;
    var ciri : W3ReplacerCiri;
    if (!player || player != thePlayer || !theGame || !theInput)
        return false;
    witcher = (W3PlayerWitcher)player;
    ciri = (W3ReplacerCiri)player;
    if (!witcher && !ciri)
        return false;
    if (!CWS_GetState().enabled || !theInput.LastUsedPCInput())
        return false;
    if (!theGame.IsActive() || theGame.IsPaused() || theGame.IsFading() || theGame.IsBlackscreen())
        return false;
    if (theGame.GetGuiManager().IsAnyMenu() || player.IsUITakeInput())
        return false;
    context = theInput.GetContext();
    if (context != 'Exploration' && context != 'Exploration_Replacer_Ciri')
        return false;
    if (player.GetCurrentStateName() != 'Exploration' || !player.substateManager)
        return false;
    if (player.substateManager.GetStateCur() != 'Idle' || player.GetPlayerCombatStance() != PCS_Normal)
        return false;
    if (!player.IsAlive() || !player.GetIsMovable() || !player.GetBIsInputAllowed() || !player.CanUpdateMovement())
        return false;
    if (player.IsInCombat() || player.IsInCombatAction() || player.IsCombatMusicEnabled())
        return false;
    if (player.IsInGameplayScene() || theGame.IsCurrentlyPlayingNonGameplayScene() || player.modifyPlayerSpeed)
        return false;
    if (player.IsSwimming() || player.IsOnBoat() || player.GetUsedVehicle() || player.IsInAir())
        return false;
    if (player.HasBuff(EET_OverEncumbered) || player.IsCameraControlDisabled('Finisher'))
        return false;
    if (!player.IsActionAllowed(EIAB_RunAndSprint) || !player.IsActionAllowed(EIAB_Sprint))
        return false;
    if ((player.GetIsSprinting() && !player.CWS_HasOwnedSprint())
        || player.GetIsSprintToggled() || player.IsSprintActionPressed()
        || (player.CWS_HasOwnedSprint() && player.CWS_ManualSprint()))
        return false;
    return true;
}

@wrapMethod(CR4Player)
function OnSpawned(spawnData : SEntitySpawnData)
{
    var witcher : W3PlayerWitcher;
    var ciri : W3ReplacerCiri;
    CWS_GetState().CWS_SuspendMotion();
    CWS_GetState().CWS_FluidRelease();
    CWS_GetState().CWS_GraphRelease();
    CWS_GetState().CWS_CancelValueReadout();
    wrappedMethod(spawnData);
    witcher = (W3PlayerWitcher)this;
    ciri = (W3ReplacerCiri)this;
    if (witcher || ciri)
    {
        CWS_GetState().CWS_Load();
        CWS_GetState().CWS_ResetSelectionForSpawn();
        CWS_ResetGesture();
    }
}

@wrapMethod(CR4Game)
function OnConfigValueChanged(varName : name, value : string) : void
{
    var menu : CR4IngameMenu;
    wrappedMethod(varName, value);
    menu = GetGuiManager().GetIngameMenu();
    if(menu && menu.CWS_PresetIsApplying()) return;
    if(StrBeginsWith(NameToString(varName), "CWS_Swim"))
    {
        if (!CWS_GetSwimState().CWSS_ConfigValueMatches(varName, CWS_SwimStoredValue(varName, value)))
            CWS_GetSwimState().CWSS_StateSuspend();
        CWS_GetSwimState().CWSS_ConfigChanged(varName);
    }
    else if(StrBeginsWith(NameToString(varName), "CWS_Horse"))
        CWS_HorseObject().CWSH_ConfigChanged(varName);
    else if (StrBeginsWith(NameToString(varName), "CWS_"))
        CWS_StateObject().CWS_ConfigChanged(varName);
}

// Queue ownership is exact-string and actor-bound. Updating the current entry
// preserves its existing Flash lifecycle; native notifications are never purged.
@addField(CR4Player)
private var CWS_valueNoticeText : string;

@addMethod(CR4Player)
public function CWS_QueueValueNotice(units : int, optional horseNotice : bool, optional swimmingNotice : bool)
{
    var i : int;
    var value : string;
    value = "CM speed: ";
    if(swimmingNotice) value = "CM Swimming speed: ";
    else if(horseNotice) value = "CM Roach speed: ";
    value = value + IntToString(units) + " (" + FloatToStringPrec((float)units / 100.0f, 2) + ")";
    if (CWS_valueNoticeText != "")
    {
        for (i = 0; i < HudMessages.Size(); i += 1)
        {
            if (HudMessages[i] == CWS_valueNoticeText)
            {
                HudMessages[i] = value;
                CWS_valueNoticeText = value;
                return;
            }
        }
    }
    CWS_valueNoticeText = value;
    HudMessages.PushBack(value);
}

@addMethod(CR4Player)
public function CWS_GetValueNotice() : string
{
    return CWS_valueNoticeText;
}

@addMethod(CR4Player)
public function CWS_HasValueNoticeAtHead() : bool
{
    return CWS_valueNoticeText != "" && HudMessages.Size() > 0 && HudMessages[0] == CWS_valueNoticeText;
}

@addMethod(CR4Player)
public function CWS_ForgetValueNotice()
{
    CWS_valueNoticeText = "";
}

@addMethod(CR4Player)
public function CWS_EraseQueuedValueNotice()
{
    var i : int;
    if (CWS_valueNoticeText != "")
    {
        for (i = 0; i < HudMessages.Size(); i += 1)
        {
            if (HudMessages[i] == CWS_valueNoticeText)
            {
                HudMessages.Erase(i);
                break;
            }
        }
    }
    CWS_valueNoticeText = "";
}

@addField(CR4HudModuleMessage)
private var CWS_valueMessageOwned : bool;
@addField(CR4HudModuleMessage)
private var CWS_valueMessagePlayer : CR4Player;
@addField(CR4HudModuleMessage)
private var CWS_valueMessageText : string;
@addField(CR4HudModuleMessage)
private var CWS_valueHideHandling : bool;

@addMethod(CR4HudModuleMessage)
public function CWS_ValueDisplayReady() : bool
{
    if (_flashValueStorage)
        return true;
    return false;
}

@addMethod(CR4HudModuleMessage)
public function CWS_IsDisplayingValueNotice(player : CR4Player) : bool
{
    return _bDuringDisplay && CWS_valueMessageOwned && CWS_valueMessagePlayer == player
        && player.CWS_HasValueNoticeAtHead() && player.CWS_GetValueNotice() == CWS_valueMessageText;
}

@addMethod(CR4HudModuleMessage)
public function CWS_RefreshValueNotice(player : CR4Player)
{
    if (!_flashValueStorage || CWS_valueHideHandling)
        return;
    if (!_bDuringDisplay)
    {
        if (CheckPendingMessages())
            DisplayPendingMessage();
        return;
    }
    if (CWS_valueMessageOwned && CWS_valueMessagePlayer == player && player == thePlayer
        && player.CWS_HasValueNoticeAtHead())
    {
        // Set the expected head before entering Flash, which may call back.
        CWS_valueMessageText = player.CWS_GetValueNotice();
        _flashValueStorage.SetFlashString('hud.message', CWS_valueMessageText);
    }
}

@wrapMethod(CR4HudModuleMessage)
function DisplayPendingMessage()
{
    // Defer a new display requested synchronously by the old hide callback.
    if (CWS_valueHideHandling)
        return;
    CWS_valueMessagePlayer = (CR4Player)thePlayer;
    CWS_valueMessageOwned = CWS_valueMessagePlayer && CWS_valueMessagePlayer.CWS_HasValueNoticeAtHead();
    CWS_valueMessageText = "";
    if (CWS_valueMessageOwned)
        CWS_valueMessageText = CWS_valueMessagePlayer.CWS_GetValueNotice();
    wrappedMethod();
}

@wrapMethod(CR4HudModuleMessage)
function OnMessageHidden()
{
    var owned : bool;
    var player : CR4Player;
    var completedText : string;
    if (CWS_valueHideHandling)
        return false;
    owned = CWS_valueMessageOwned;
    player = CWS_valueMessagePlayer;
    completedText = CWS_valueMessageText;
    CWS_valueMessageOwned = false;
    CWS_valueMessagePlayer = NULL;
    CWS_valueMessageText = "";
    if (owned)
        CWS_valueHideHandling = true;
    if (!owned || (player && player == thePlayer && player.CWS_HasValueNoticeAtHead()
        && player.CWS_GetValueNotice() == completedText))
    {
        // Forget the completed record before native/Flash can enqueue a new one.
        if (owned)
            player.CWS_ForgetValueNotice();
        wrappedMethod();
    }
    else
    {
        // The displayed CM head was removed/corrected, or the actor changed.
        // Vanilla would now pop an unrelated current head; retire only our display.
        _bDuringDisplay = false;
        if (player && player != thePlayer)
            player.CWS_EraseQueuedValueNotice();
        if (_flashValueStorage)
            _flashValueStorage.SetFlashString('hud.message', "");
    }
    if (owned)
        CWS_valueHideHandling = false;
}

// Base/Ciri result observation. Geralt's outer wrapper owns its final decision.
@wrapMethod(CR4Player)
function CanSprint(speed : float) : bool
{
    var allowed : bool;
    allowed = wrappedMethod(speed);
    if (!CWS_InDerivedSprint())
    {
        CWS_RecordSprintPermission(allowed);
        if (CWS_IsSprintProbe())
            return false;
    }
    return allowed;
}
