// Independent Roach configuration and session selection. Units are hundredths.
// Native horse gait and actor ownership live in cwsHorseMovement, not this profile.
class CWS_HorseState extends CObject
{
    public var enabled, trueSteps, showSpeedChanges : bool;
    public var smoothSteps, smoothFavorites, smoothStarting, resetAtStop : bool;
    public var count, selected, favoriteA, favoriteB : int;
    public var trueStepSize, trueStepMin, trueStepMax, trueUnits, staticOverride : int;
    public var startSpeedUnits : int;
    public var increaseCurve, decreaseCurve, increaseTimeMs, decreaseTimeMs, stopDestination : int;
    public var speeds : array<float>;
    private var initialized, hasTrueSelection, loading, savePending, refreshing : bool;

    public function CWSH_SpeedKey(index : int) : name
    {
        switch(index)
        {
            case 0: return 'CWS_HorseSpeed01';
            case 1: return 'CWS_HorseSpeed02';
            case 2: return 'CWS_HorseSpeed03';
            case 3: return 'CWS_HorseSpeed04';
            case 4: return 'CWS_HorseSpeed05';
            case 5: return 'CWS_HorseSpeed06';
            case 6: return 'CWS_HorseSpeed07';
            case 7: return 'CWS_HorseSpeed08';
            case 8: return 'CWS_HorseSpeed09';
        }
        return 'CWS_HorseSpeed10';
    }

    public function CWSH_SettingCount() : int { return 29; }

    public function CWSH_SettingKey(index : int) : name
    {
        if(index < 8) return CWSH_SpeedKey(index);
        switch(index)
        {
            case 8: return 'CWS_HorseEnabled';
            case 9: return 'CWS_HorseTrueSteps';
            case 10: return 'CWS_HorseTrueStepSize';
            case 11: return 'CWS_HorseTrueStepMax';
            case 12: return 'CWS_HorseCount';
            case 13: return 'CWS_HorseFavoriteA';
            case 14: return 'CWS_HorseFavoriteB';
            case 15: return 'CWS_HorseMotionDiagnostics';
            case 16: return 'CWS_HorseSmoothSteps';
            case 17: return 'CWS_HorseSmoothFavorites';
            case 18: return 'CWS_HorseSmoothStarting';
            case 19: return 'CWS_HorseIncreaseCurve';
            case 20: return 'CWS_HorseDecreaseCurve';
            case 21: return 'CWS_HorseIncreaseTimeMs';
            case 22: return 'CWS_HorseDecreaseTimeMs';
            case 23: return 'CWS_HorseResetAtStop';
            case 25: return 'CWS_HorseSpeed09';
            case 26: return 'CWS_HorseSpeed10';
            case 27: return 'CWS_HorseStartSpeed';
            case 28: return 'CWS_HorseTrueStepMin';
        }
        return 'CWS_HorseStopDestination';
    }

    private function CWSH_DefaultSpeed(index : int) : float
    {
        switch(index)
        {
            case 0: return 0.40f;
            case 1: return 0.50f;
            case 2: return 1.00f;
            case 3: return 1.50f;
            case 4: return 2.00f;
            case 5: return 2.50f;
            case 6: return 3.00f;
            case 7: return 4.00f;
            case 8: return 6.00f;
        }
        return 8.00f;
    }

    private function CWSH_NormalUnits(value : float, fallback : float) : int
    {
        if(value - value != 0.0f) value = fallback;
        return RoundF(ClampF(value, 0.40f, 8.00f) * 100.0f);
    }

    private function CWSH_Read(key : name) : string
    {
        return CWS_SelectorStoredValue(key, theGame.GetInGameConfigWrapper().GetVarValue(CWS_HorseSettingGroup(key), key));
    }

    private function CWSH_Write(key : name, value : string) : bool
    {
        var config : CInGameConfigWrapper;
        config = theGame.GetInGameConfigWrapper();
        value = CWS_SelectorMenuValue(key, value);
        if(config.GetVarValue(CWS_HorseSettingGroup(key), key) == value) return false;
        config.SetVarValue(CWS_HorseSettingGroup(key), key, value);
        return true;
    }

    private function CWSH_Bool(value : bool) : string
    {
        if(value) return "true";
        return "false";
    }

    public function CWSH_Value(index : int) : string
    {
        if(index < 8) return FloatToStringPrec(speeds[index], 2);
        switch(index)
        {
            case 8: return CWSH_Bool(enabled);
            case 9: return CWSH_Bool(trueSteps);
            case 10: return IntToString(trueStepSize);
            case 11: return FloatToStringPrec((float)trueStepMax / 100.0f, 2);
            case 12: return IntToString(count);
            case 13: return IntToString(favoriteA);
            case 14: return IntToString(favoriteB);
            case 15: return CWSH_Bool(showSpeedChanges);
            case 16: return CWSH_Bool(smoothSteps);
            case 17: return CWSH_Bool(smoothFavorites);
            case 18: return CWSH_Bool(smoothStarting);
            case 19: return IntToString(increaseCurve);
            case 20: return IntToString(decreaseCurve);
            case 21: return IntToString(increaseTimeMs);
            case 22: return IntToString(decreaseTimeMs);
            case 23: return CWSH_Bool(resetAtStop);
            case 25: return FloatToStringPrec(speeds[8], 2);
            case 26: return FloatToStringPrec(speeds[9], 2);
            case 27: return FloatToStringPrec((float)startSpeedUnits / 100.0f, 2);
            case 28: return FloatToStringPrec((float)trueStepMin / 100.0f, 2);
        }
        return IntToString(stopDestination);
    }

    public function CWSH_Load(optional deferSave : bool)
    {
        var i, units : int;
        var previous, value : float;
        if(loading || !theGame.GetInGameConfigWrapper()) return;
        if(initialized) previous = CWSH_SelectedSpeed();
        loading = true;
        CWSH_Suspend();
        CWSH_ReleaseGraph();
        enabled = CWSH_Read('CWS_HorseEnabled') != "false";
        trueSteps = CWSH_Read('CWS_HorseTrueSteps') == "true";
        showSpeedChanges = CWSH_Read('CWS_HorseMotionDiagnostics') == "true";
        smoothSteps = CWSH_Read('CWS_HorseSmoothSteps') != "false";
        smoothFavorites = CWSH_Read('CWS_HorseSmoothFavorites') != "false";
        smoothStarting = CWSH_Read('CWS_HorseSmoothStarting') != "false";
        resetAtStop = CWSH_Read('CWS_HorseResetAtStop') == "true";
        count = Max(3, Min(10, StringToInt(CWSH_Read('CWS_HorseCount'), 10)));
        favoriteA = Max(1, Min(10, StringToInt(CWSH_Read('CWS_HorseFavoriteA'), 3)));
        favoriteB = Max(1, Min(10, StringToInt(CWSH_Read('CWS_HorseFavoriteB'), 8)));
        trueStepSize = Max(1, Min(100, StringToInt(CWSH_Read('CWS_HorseTrueStepSize'), 10)));
        trueStepMin = CWSH_NormalUnits(StringToFloat(CWSH_Read('CWS_HorseTrueStepMin'), 0.40f), 0.40f);
        trueStepMax = Max(trueStepMin, CWSH_NormalUnits(StringToFloat(CWSH_Read('CWS_HorseTrueStepMax'), 8.0f), 8.0f));
        startSpeedUnits = CWSH_NormalUnits(StringToFloat(CWSH_Read('CWS_HorseStartSpeed'), 0.40f), 0.40f);
        increaseCurve = StringToInt(CWSH_Read('CWS_HorseIncreaseCurve'), 4);
        decreaseCurve = StringToInt(CWSH_Read('CWS_HorseDecreaseCurve'), 1);
        if(increaseCurve < 0 || increaseCurve > 4) increaseCurve = 4;
        if(decreaseCurve < 0 || decreaseCurve > 3) decreaseCurve = 1;
        increaseTimeMs = Max(1, Min(100, StringToInt(CWSH_Read('CWS_HorseIncreaseTimeMs'), 5)));
        decreaseTimeMs = Max(1, Min(100, StringToInt(CWSH_Read('CWS_HorseDecreaseTimeMs'), 3)));
        stopDestination = StringToInt(CWSH_Read('CWS_HorseStopDestination'), 0);
        if(stopDestination != 0 && stopDestination != 1) stopDestination = 0;
        speeds.Clear();
        for(i = 0; i < 10; i += 1)
        {
            units = CWSH_NormalUnits(StringToFloat(CWSH_Read(CWSH_SpeedKey(i)), CWSH_DefaultSpeed(i)), CWSH_DefaultSpeed(i));
            value = (float)units / 100.0f;
            if(i > 0) value = MaxF(value, speeds[i - 1]);
            speeds.PushBack(value);
        }
        for(i = 0; i < CWSH_SettingCount(); i += 1)
            if(CWSH_Write(CWSH_SettingKey(i), CWSH_Value(i))) savePending = true;
        if(!initialized)
        {
            selected = Max(1, Min(count, favoriteA));
            trueUnits = RoundF(speeds[favoriteA - 1] * 100.0f);
            hasTrueSelection = trueSteps;
        }
        else
        {
            selected = Max(1, Min(count, selected));
            if(trueSteps && !hasTrueSelection)
            {
                trueUnits = RoundF(previous * 100.0f);
                hasTrueSelection = true;
            }
        }
        trueUnits = Max(trueStepMin, Min(trueStepMax, trueUnits));
        initialized = true;
        loading = false;
        if(savePending && !deferSave)
        {
            savePending = false;
            theGame.SaveUserSettings();
        }
    }

    public function CWSH_SelectedUnits() : int
    {
        if(trueSteps) return Max(trueStepMin, Min(trueStepMax, trueUnits));
        if(staticOverride != 0) return staticOverride;
        return RoundF(speeds[Max(1, Min(count, selected)) - 1] * 100.0f);
    }

    public function CWSH_SelectedSpeed() : float { return (float)CWSH_SelectedUnits() / 100.0f; }

    public function CWSH_Select(index : int)
    {
        if(trueSteps)
        {
            trueUnits = Max(trueStepMin, Min(trueStepMax, RoundF(speeds[Max(1, Min(10, index)) - 1] * 100.0f)));
            hasTrueSelection = true;
        }
        else
        {
            selected = Max(1, Min(count, index));
            staticOverride = 0;
        }
    }

    public function CWSH_SelectFavorite(useB : bool)
    {
        if(useB) CWSH_Select(favoriteB);
        else CWSH_Select(favoriteA);
    }

    public function CWSH_Adjust(direction : int)
    {
        var nextUnits, i : int;
        if(direction == 0) return;
        if(trueSteps)
        {
            nextUnits = CWSH_SelectedUnits() - CWSH_SelectedUnits() % trueStepSize;
            if(direction > 0) nextUnits += trueStepSize;
            else if(nextUnits == CWSH_SelectedUnits()) nextUnits -= trueStepSize;
            trueUnits = Max(trueStepMin, Min(trueStepMax, nextUnits));
            hasTrueSelection = true;
        }
        else if(staticOverride == 0) CWSH_Select(selected + direction);
        else if(direction > 0)
        {
            for(i = 0; i < count; i += 1)
                if(speeds[i] * 100.0f > (float)staticOverride) { CWSH_Select(i + 1); return; }
        }
        else
        {
            for(i = count - 1; i >= 0; i -= 1)
                if(speeds[i] * 100.0f < (float)staticOverride) { CWSH_Select(i + 1); return; }
        }
    }

    public function CWSH_RequestAdjust(direction : int)
    {
        var previous : int;
        CWSH_CancelStopReset();
        previous = CWSH_SelectedUnits();
        CWSH_Adjust(direction);
        if(previous == CWSH_SelectedUnits()) return;
        commandSerial += 1;
        CWSH_Retarget(CWSH_SelectedSpeed(), smoothSteps);
        CWSH_Notify(CWSH_SelectedUnits());
    }

    public function CWSH_RequestFavorite(useB : bool)
    {
        var previous : int;
        CWSH_CancelStopReset();
        previous = CWSH_SelectedUnits();
        CWSH_SelectFavorite(useB);
        if(previous == CWSH_SelectedUnits()) return;
        commandSerial += 1;
        CWSH_Retarget(CWSH_SelectedSpeed(), smoothFavorites);
        CWSH_Notify(CWSH_SelectedUnits());
    }

    public function CWSH_Stop()
    {
        var previous, destination, index : int;
        CWSH_Suspend();
        startReady = true;
        if(!resetAtStop) return;
        previous = CWSH_SelectedUnits();
        destination = 40;
        if(trueSteps) destination = trueStepMin;
        if(stopDestination == 0)
        {
            index = favoriteA;
            if(!trueSteps) index = Min(count, index);
            destination = RoundF(speeds[index - 1] * 100.0f);
            if(trueSteps) destination = Max(trueStepMin, Min(trueStepMax, destination));
        }
        if(previous <= destination) return;
        if(trueSteps) trueUnits = destination;
        else staticOverride = destination;
        CWSH_Notify(destination);
    }

    public function CWSH_ResetSpawn()
    {
        CWSH_Suspend();
        CWSH_ReleaseGraph();
        staticOverride = 0;
        selected = Max(1, Min(count, favoriteA));
        trueUnits = Max(trueStepMin, Min(trueStepMax, RoundF(speeds[favoriteA - 1] * 100.0f)));
        hasTrueSelection = trueSteps;
    }

    public function CWSH_Notify(units : int)
    {
        if(showSpeedChanges && CWS_HorseCanInput((CR4Player)thePlayer))
            CWS_GetState().CWS_PresentValueChange(units, true);
    }

    public function CWSH_RefreshMenu()
    {
        var menu : CR4IngameMenu;
        var keys : array<name>;
        var values : array<string>;
        var i : int;
        menu = theGame.GetGuiManager().GetIngameMenu();
        if(!menu || refreshing) return;
        for(i = 0; i < CWSH_SettingCount(); i += 1)
        {
            keys.PushBack(CWSH_SettingKey(i));
            values.PushBack(CWS_SelectorMenuValue(CWSH_SettingKey(i), CWSH_Read(CWSH_SettingKey(i))));
        }
        refreshing = true;
        menu.CWS_UpdateSettingValues(keys, values, true);
        refreshing = false;
    }

    public function CWSH_ConfigChanged(key : name)
    {
        var i, j, bound : int;
        var value : float;
        var before, values : array<string>;
        var keys : array<name>;
        var menu : CR4IngameMenu;
        if(loading || refreshing) return;
        for(i = 0; i < CWSH_SettingCount(); i += 1) before.PushBack(CWSH_Read(CWSH_SettingKey(i)));
        // An edited bound wins; an unordered saved pair instead raises its maximum on load.
        if(key == 'CWS_HorseTrueStepMin' || key == 'CWS_HorseTrueStepMax')
        {
            loading = true;
            if(key == 'CWS_HorseTrueStepMin')
            {
                bound = CWSH_NormalUnits(StringToFloat(CWSH_Read(key), (float)trueStepMin / 100.0f), (float)trueStepMin / 100.0f);
                if(bound > trueStepMax) CWSH_Write('CWS_HorseTrueStepMax', FloatToStringPrec((float)bound / 100.0f, 2));
            }
            else
            {
                bound = CWSH_NormalUnits(StringToFloat(CWSH_Read(key), (float)trueStepMax / 100.0f), (float)trueStepMax / 100.0f);
                if(bound < trueStepMin) CWSH_Write('CWS_HorseTrueStepMin', FloatToStringPrec((float)bound / 100.0f, 2));
            }
            CWSH_Write(key, FloatToStringPrec((float)bound / 100.0f, 2));
            loading = false;
        }
        for(i = 0; i < 10; i += 1)
        {
            if(key != CWSH_SpeedKey(i)) continue;
            value = (float)CWSH_NormalUnits(StringToFloat(CWSH_Read(key), speeds[i]), speeds[i]) / 100.0f;
            loading = true;
            CWSH_Write(key, FloatToStringPrec(value, 2));
            for(j = i - 1; j >= 0; j -= 1)
            {
                if(speeds[j] <= value) break;
                CWSH_Write(CWSH_SpeedKey(j), FloatToStringPrec(value, 2));
            }
            for(j = i + 1; j < 10; j += 1)
            {
                if(speeds[j] >= value) break;
                CWSH_Write(CWSH_SpeedKey(j), FloatToStringPrec(value, 2));
            }
            loading = false;
        }
        CWS_ResetGesture();
        CWSH_Load(theGame.GetGuiManager().IsAnyMenu());
        menu = theGame.GetGuiManager().GetIngameMenu();
        if(!menu || !theGame.GetGuiManager().IsAnyMenu()) return;
        for(i = 0; i < CWSH_SettingCount(); i += 1)
        {
            if(before[i] != CWSH_Read(CWSH_SettingKey(i)) && StringToFloat(before[i], -1000.0f) != StringToFloat(CWSH_Read(CWSH_SettingKey(i)), -2000.0f))
            {
                keys.PushBack(CWSH_SettingKey(i));
                values.PushBack(CWS_SelectorMenuValue(CWSH_SettingKey(i), CWSH_Read(CWSH_SettingKey(i))));
            }
        }
        if(keys.Size() > 0) menu.CWS_UpdateSettingValues(keys, values);
    }
}

@addField(CR4Game) private var CWS_HorseData : CWS_HorseState;

@addMethod(CR4Game)
function CWS_HorseObject() : CWS_HorseState
{
    if(!CWS_HorseData)
    {
        CWS_HorseData = new CWS_HorseState in this;
        CWS_HorseData.CWSH_Load();
    }
    return CWS_HorseData;
}

function CWS_GetHorseState() : CWS_HorseState { return theGame.CWS_HorseObject(); }
