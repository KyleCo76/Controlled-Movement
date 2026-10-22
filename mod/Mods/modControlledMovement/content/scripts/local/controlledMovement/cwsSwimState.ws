// Independent swimming configuration and session selection, in integer hundredths.
class CWS_SwimState extends CObject
{
    public var enabled, trueSteps, showSpeedChanges, startMatch : bool;
    public var count, selected, favoriteA, favoriteB : int;
    public var trueStepSize, trueStepMin, trueStepMax, startSpeedUnits, startValueUnits : int;
    public var speeds : array<float>;
    private var initialized, loading, refreshing, savePending : bool;
    private var trueUnits, staticOverride, commandRevision : int;

    public function CWSS_SettingCount() : int { return 22; }

    public function CWSS_SpeedKey(index : int) : name
    {
        switch(index)
        {
            case 0: return 'CWS_SwimSpeed01';
            case 1: return 'CWS_SwimSpeed02';
            case 2: return 'CWS_SwimSpeed03';
            case 3: return 'CWS_SwimSpeed04';
            case 4: return 'CWS_SwimSpeed05';
            case 5: return 'CWS_SwimSpeed06';
            case 6: return 'CWS_SwimSpeed07';
            case 7: return 'CWS_SwimSpeed08';
            case 8: return 'CWS_SwimSpeed09';
        }
        return 'CWS_SwimSpeed10';
    }

    public function CWSS_SettingKey(index : int) : name
    {
        if(index >= 7 && index < 17) return CWSS_SpeedKey(index - 7);
        switch(index)
        {
            case 0: return 'CWS_SwimEnabled';
            case 1: return 'CWS_SwimTrueSteps';
            case 2: return 'CWS_SwimShowSpeedChanges';
            case 3: return 'CWS_SwimFavoriteA';
            case 4: return 'CWS_SwimFavoriteB';
            case 5: return 'CWS_SwimStartSpeed';
            case 6: return 'CWS_SwimCount';
            case 17: return 'CWS_SwimTrueStepSize';
            case 18: return 'CWS_SwimTrueStepMin';
            case 19: return 'CWS_SwimTrueStepMax';
            case 20: return 'CWS_SwimStartMatch';
        }
        return 'CWS_SwimStartValue';
    }

    private function CWSS_DefaultSpeed(index : int) : float
    {
        switch(index)
        {
            case 0: return 0.60f;
            case 1: return 0.60f;
            case 2: return 0.60f;
            case 3: return 0.60f;
            case 4: return 0.80f;
            case 5: return 1.00f;
            case 6: return 1.25f;
            case 7: return 1.49f;
            case 8: return 2.00f;
        }
        return 2.00f;
    }

    private function CWSS_Read(key : name) : string
    {
        return CWS_SwimStoredValue(key, theGame.GetInGameConfigWrapper().GetVarValue(CWS_SwimSettingGroup(key), key));
    }

    private function CWSS_Write(key : name, value : string) : bool
    {
        var config : CInGameConfigWrapper;
        config = theGame.GetInGameConfigWrapper();
        value = CWS_SwimMenuValue(key, value);
        if(config.GetVarValue(CWS_SwimSettingGroup(key), key) == value) return false;
        config.SetVarValue(CWS_SwimSettingGroup(key), key, value);
        savePending = true;
        return true;
    }

    private function CWSS_Bool(value : bool) : string
    {
        if(value) return "true";
        return "false";
    }

    // Reject partial native parses before conversion, including nonfinite spellings.
    private function CWSS_Numeric(raw : string, integerOnly : bool) : bool
    {
        var i, digits, dots : int;
        var character : string;
        if(StrLen(raw) == 0) return false;
        for(i = 0; i < StrLen(raw); i += 1)
        {
            character = StrMid(raw, i, 1);
            if(StrFindFirst("0123456789", character) >= 0) digits += 1;
            else if(character == "." && !integerOnly && dots == 0) dots += 1;
            else if(i != 0 || (character != "+" && character != "-")) return false;
        }
        return digits > 0;
    }

    private function CWSS_Int(key : name, fallback : int, lower : int, upper : int) : int
    {
        var raw : string;
        var value : float;
        raw = CWSS_Read(key);
        if(!CWSS_Numeric(raw, true)) return fallback;
        value = StringToFloat(raw, (float)fallback);
        if(value - value != 0.0f) return fallback;
        return RoundF(ClampF(value, (float)lower, (float)upper));
    }

    private function CWSS_Units(key : name, fallback : float) : int
    {
        var raw : string;
        var value : float;
        raw = CWSS_Read(key);
        value = fallback;
        if(CWSS_Numeric(raw, false)) value = StringToFloat(raw, fallback);
        if(value - value != 0.0f) value = fallback;
        return RoundF(ClampF(value, 0.60f, 2.00f) * 100.0f);
    }

    public function CWSS_Value(index : int) : string
    {
        if(index >= 7 && index < 17) return FloatToStringPrec(speeds[index - 7], 2);
        switch(index)
        {
            case 0: return CWSS_Bool(enabled);
            case 1: return CWSS_Bool(trueSteps);
            case 2: return CWSS_Bool(showSpeedChanges);
            case 3: return IntToString(favoriteA);
            case 4: return IntToString(favoriteB);
            case 5: return FloatToStringPrec((float)startSpeedUnits / 100.0f, 2);
            case 6: return IntToString(count);
            case 17: return IntToString(trueStepSize);
            case 18: return FloatToStringPrec((float)trueStepMin / 100.0f, 2);
            case 19: return FloatToStringPrec((float)trueStepMax / 100.0f, 2);
            case 20: return CWSS_Bool(startMatch);
        }
        return FloatToStringPrec((float)startValueUnits / 100.0f, 2);
    }

    public function CWSS_Load(optional deferSave : bool)
    {
        var i, units, previous : int;
        var wasTrue, hadOverride : bool;
        if(loading || !theGame.GetInGameConfigWrapper()) return;
        if(initialized)
        {
            previous = CWSS_SelectedUnits();
            wasTrue = trueSteps;
            hadOverride = staticOverride != 0;
        }
        loading = true;
        enabled = CWSS_Read('CWS_SwimEnabled') != "false";
        trueSteps = CWSS_Read('CWS_SwimTrueSteps') != "false";
        showSpeedChanges = CWSS_Read('CWS_SwimShowSpeedChanges') == "true";
        favoriteA = CWSS_Int('CWS_SwimFavoriteA', 4, 1, 10);
        favoriteB = CWSS_Int('CWS_SwimFavoriteB', 8, 1, 10);
        startSpeedUnits = CWSS_Units('CWS_SwimStartSpeed', 0.60f);
        count = CWSS_Int('CWS_SwimCount', 8, 3, 10);
        trueStepSize = CWSS_Int('CWS_SwimTrueStepSize', 10, 1, 100);
        trueStepMin = CWSS_Units('CWS_SwimTrueStepMin', 0.60f);
        trueStepMax = Max(trueStepMin, CWSS_Units('CWS_SwimTrueStepMax', 1.49f));
        startMatch = CWSS_Read('CWS_SwimStartMatch') != "false";
        startValueUnits = CWSS_Units('CWS_SwimStartValue', 1.00f);
        speeds.Clear();
        for(i = 0; i < 10; i += 1)
        {
            units = CWSS_Units(CWSS_SpeedKey(i), CWSS_DefaultSpeed(i));
            if(i > 0) units = Max(units, RoundF(speeds[i - 1] * 100.0f));
            speeds.PushBack((float)units / 100.0f);
        }
        for(i = 0; i < CWSS_SettingCount(); i += 1) CWSS_Write(CWSS_SettingKey(i), CWSS_Value(i));
        if(!initialized) CWSS_ResetSpawn();
        else if(trueSteps || wasTrue || hadOverride) CWSS_SetSelectedUnits(previous, false);
        else selected = Max(1, Min(count, selected));
        initialized = true;
        loading = false;
        if(savePending && !deferSave)
        {
            savePending = false;
            theGame.SaveUserSettings();
        }
    }

    public function CWSS_Enabled() : bool { return enabled; }
    public function CWSS_CanUseControls() : bool { return enabled && initialized && !loading; }

    public function CWSS_ClampUnits(units : int) : int
    {
        if(trueSteps) return Max(trueStepMin, Min(trueStepMax, units));
        return Max(60, Min(200, units));
    }

    public function CWSS_SelectedUnits() : int
    {
        if(trueSteps) return CWSS_ClampUnits(trueUnits);
        if(staticOverride != 0) return staticOverride;
        return RoundF(speeds[Max(1, Min(count, selected)) - 1] * 100.0f);
    }

    // Compatibility helper only; native startup is unchanged in this preview.
    public function CWSS_SeedUnits() : int { return Min(CWSS_ClampUnits(startSpeedUnits), CWSS_SelectedUnits()); }
    public function CWSS_CommandRevision() : int { return commandRevision; }

    // Push-off playback from idle: the chosen value, or the fixed Swim start speed.
    public function CWSS_StartUnits() : int
    {
        if(startMatch) return CWSS_SelectedUnits();
        return startValueUnits;
    }

    public function CWSS_SetSelectedUnits(units : int, isCommand : bool)
    {
        var i : int;
        if(isCommand) commandRevision += 1;
        units = CWSS_ClampUnits(units);
        if(trueSteps) trueUnits = units;
        else
        {
            staticOverride = units;
            for(i = 0; i < count; i += 1)
            {
                if(RoundF(speeds[i] * 100.0f) != units) continue;
                selected = i + 1;
                staticOverride = 0;
                return;
            }
        }
    }

    public function CWSS_RequestAdjust(direction : int)
    {
        var current, nextUnits, i : int;
        if(direction == 0) return;
        current = CWSS_SelectedUnits();
        nextUnits = current;
        if(trueSteps)
        {
            nextUnits = current - current % trueStepSize;
            if(direction > 0) nextUnits += trueStepSize;
            else if(nextUnits == current) nextUnits -= trueStepSize;
        }
        else if(direction > 0)
        {
            for(i = 0; i < count; i += 1)
                if(RoundF(speeds[i] * 100.0f) > current) { nextUnits = RoundF(speeds[i] * 100.0f); break; }
        }
        else
        {
            for(i = count - 1; i >= 0; i -= 1)
                if(RoundF(speeds[i] * 100.0f) < current) { nextUnits = RoundF(speeds[i] * 100.0f); break; }
        }
        CWSS_SetSelectedUnits(nextUnits, true);
    }

    public function CWSS_RequestFavorite(useB : bool)
    {
        var index : int;
        index = favoriteA;
        if(useB) index = favoriteB;
        if(!trueSteps) index = Min(count, index);
        CWSS_SetSelectedUnits(RoundF(speeds[index - 1] * 100.0f), true);
    }

    public function CWSS_ResetSpawn()
    {
        staticOverride = 0;
        selected = Max(1, Min(count, favoriteA));
        trueUnits = Max(trueStepMin, Min(trueStepMax, RoundF(speeds[favoriteA - 1] * 100.0f)));
    }

    public function CWSS_RefreshMenu(optional allPages : bool)
    {
        var menu : CR4IngameMenu;
        var keys : array<name>;
        var values : array<string>;
        var i : int;
        menu = theGame.GetGuiManager().GetIngameMenu();
        if(!menu || refreshing) return;
        for(i = 0; i < CWSS_SettingCount(); i += 1)
        {
            keys.PushBack(CWSS_SettingKey(i));
            values.PushBack(CWSS_Read(CWSS_SettingKey(i)));
        }
        refreshing = true;
        menu.CWS_UpdateSettingValues(keys, values, allPages);
        refreshing = false;
    }

    public function CWSS_ConfigValueMatches(key : name, value : string) : bool
    {
        var i : int;
        for (i = 0; i < CWSS_SettingCount(); i += 1)
            if (CWSS_SettingKey(i) == key) return CWSS_Value(i) == value;
        return true;
    }

    public function CWSS_ConfigChanged(key : name)
    {
        var i, units : int;
        var owned : bool;
        if(loading || refreshing) return;
        for(i = 0; i < CWSS_SettingCount(); i += 1)
            if(CWSS_SettingKey(i) == key) owned = true;
        if(!owned) return;
        loading = true;
        if(key == 'CWS_SwimTrueStepMin')
            CWSS_Write(key, FloatToStringPrec((float)Min(trueStepMax, CWSS_Units(key, 0.60f)) / 100.0f, 2));
        else if(key == 'CWS_SwimTrueStepMax')
            CWSS_Write(key, FloatToStringPrec((float)Max(trueStepMin, CWSS_Units(key, 1.49f)) / 100.0f, 2));
        for(i = 0; i < 10; i += 1)
        {
            if(CWSS_SpeedKey(i) != key) continue;
            units = CWSS_Units(key, CWSS_DefaultSpeed(i));
            if(i > 0) units = Max(units, RoundF(speeds[i - 1] * 100.0f));
            if(i < 9) units = Min(units, RoundF(speeds[i + 1] * 100.0f));
            CWSS_Write(key, FloatToStringPrec((float)units / 100.0f, 2));
        }
        loading = false;
        CWSS_Load(theGame.GetGuiManager().IsAnyMenu());
        CWSS_RefreshMenu();
    }
}

@addField(CR4Game) private var CWS_SwimData : CWS_SwimState;

@addMethod(CR4Game)
function CWS_SwimObject() : CWS_SwimState
{
    if(!CWS_SwimData)
    {
        CWS_SwimData = new CWS_SwimState in this;
        CWS_SwimData.CWSS_Load();
    }
    return CWS_SwimData;
}

function CWS_GetSwimState() : CWS_SwimState { return theGame.CWS_SwimObject(); }

function CWS_SwimSettingGroup(key : name) : name
{
    switch (key)
    {
        case 'CWS_SwimEnabled': return 'CWS_Swimming';
        case 'CWS_SwimTrueSteps': return 'CWS_Swimming';
        case 'CWS_SwimShowSpeedChanges': return 'CWS_Swimming';
        case 'CWS_SwimFavoriteA': return 'CWS_SwimmingSpeeds';
        case 'CWS_SwimFavoriteB': return 'CWS_SwimmingSpeeds';
        case 'CWS_SwimStartSpeed': return 'CWS_SwimmingSpeeds';
        case 'CWS_SwimCount': return 'CWS_SwimmingSpeeds';
        case 'CWS_SwimSpeed01': return 'CWS_SwimmingSpeeds';
        case 'CWS_SwimSpeed02': return 'CWS_SwimmingSpeeds';
        case 'CWS_SwimSpeed03': return 'CWS_SwimmingSpeeds';
        case 'CWS_SwimSpeed04': return 'CWS_SwimmingSpeeds';
        case 'CWS_SwimSpeed05': return 'CWS_SwimmingSpeeds';
        case 'CWS_SwimSpeed06': return 'CWS_SwimmingSpeeds';
        case 'CWS_SwimSpeed07': return 'CWS_SwimmingSpeeds';
        case 'CWS_SwimSpeed08': return 'CWS_SwimmingSpeeds';
        case 'CWS_SwimSpeed09': return 'CWS_SwimmingSpeeds';
        case 'CWS_SwimSpeed10': return 'CWS_SwimmingSpeeds';
        case 'CWS_SwimTrueStepSize': return 'CWS_SwimmingTrueStepsOptions';
        case 'CWS_SwimTrueStepMin': return 'CWS_SwimmingTrueStepsOptions';
        case 'CWS_SwimTrueStepMax': return 'CWS_SwimmingTrueStepsOptions';
        case 'CWS_SwimStartMatch': return 'CWS_SwimmingSpeeds';
        case 'CWS_SwimStartValue': return 'CWS_SwimmingSpeeds';
    }
    return '';
}

function CWS_SwimOptionOffset(key : name) : int
{
    if (key == 'CWS_SwimCount') return 3;
    if (key == 'CWS_SwimFavoriteA' || key == 'CWS_SwimFavoriteB') return 1;
    return 0;
}

function CWS_SwimStoredValue(key : name, value : string) : string
{
    var offset, index : int;
    offset = CWS_SwimOptionOffset(key);
    if (offset == 0 || value == "") return value;
    index = StringToInt(value, -999);
    if (IntToString(index) != value) return value;
    return IntToString(index + offset);
}

function CWS_SwimMenuValue(key : name, value : string) : string
{
    var offset, index : int;
    offset = CWS_SwimOptionOffset(key);
    if (offset == 0 || value == "") return value;
    index = StringToInt(value, -999);
    if (IntToString(index) != value) return value;
    return IntToString(index - offset);
}

