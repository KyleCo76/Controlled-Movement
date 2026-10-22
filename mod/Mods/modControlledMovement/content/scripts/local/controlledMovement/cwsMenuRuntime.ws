// Own native menu pages. XML aliases preserve Player storage and isolate Roach.
@addMethod(CWS_State)
public function CWS_SettingGroup(key : name) : name
{
    if (StrBeginsWith(NameToString(key), "CWS_Speed"))
        return 'CWS_Steps';
    switch (key)
    {
        case 'CWS_Count':
        case 'CWS_FavoriteA':
        case 'CWS_FavoriteB': return 'CWS_Steps';
        case 'CWS_TrueStepSize':
        case 'CWS_TrueStepMax': return 'CWS_TrueStepsOptions';
        case 'CWS_SprintThreshold':
        case 'CWS_CapUnavailable': return 'CWS_FluidControlsOptions';
        case 'CWS_IncreaseCurve':
        case 'CWS_DecreaseCurve':
        case 'CWS_IncreaseTimeMs':
        case 'CWS_DecreaseTimeMs':
        case 'CWS_StopDestination': return 'CWS_FluidMovementOptions';
        case 'CWS_RequireModifier': return 'CWS_Controls';
    }
    return 'ControlledWalkSpeed';
}

// Horse display pages share one independent physical configuration group.
function CWS_HorseSettingGroup(key : name) : name
{
    if (StrBeginsWith(NameToString(key), "CWS_HorseSpeed"))
        return 'CWS_HorseSteps';
    switch (key)
    {
        case 'CWS_HorseCount':
        case 'CWS_HorseFavoriteA':
        case 'CWS_HorseFavoriteB': return 'CWS_HorseSteps';
        case 'CWS_HorseTrueStepSize':
        case 'CWS_HorseTrueStepMin':
        case 'CWS_HorseTrueStepMax': return 'CWS_HorseTrueStepsOptions';
        case 'CWS_HorseStartSpeed':
        case 'CWS_HorseIncreaseCurve':
        case 'CWS_HorseDecreaseCurve':
        case 'CWS_HorseIncreaseTimeMs':
        case 'CWS_HorseDecreaseTimeMs':
        case 'CWS_HorseStopDestination': return 'CWS_HorseFluidMovementOptions';
    }
    return 'CWS_Horse';
}

// Numeric selectors expose zero-based menu indices while saved values remain canonical.
function CWS_SelectorOffset(key : name) : int
{
    if (key == 'CWS_Count' || key == 'CWS_HorseCount') return 3;
    if (key == 'CWS_FavoriteA' || key == 'CWS_FavoriteB'
        || key == 'CWS_HorseFavoriteA' || key == 'CWS_HorseFavoriteB') return 1;
    return 0;
}

function CWS_SelectorStoredValue(key : name, value : string) : string
{
    var offset, index : int;
    offset = CWS_SelectorOffset(key);
    if (offset == 0 || value == "") return value;
    index = StringToInt(value, -999);
    if (IntToString(index) != value) return value;
    return IntToString(index + offset);
}

function CWS_SelectorMenuValue(key : name, value : string) : string
{
    var offset, index : int;
    offset = CWS_SelectorOffset(key);
    if (offset == 0 || value == "") return value;
    index = StringToInt(value, -999);
    if (IntToString(index) != value) return value;
    return IntToString(index - offset);
}

// Preset values generated from tools/presets.json; resolve each setting through its display group.
@addMethod(CWS_State)
public function CWS_ApplyPresetValues(config : CInGameConfigWrapper, presetIndex : int)
{
    if (presetIndex == 0)
    {
        CWS_Write(config, 'CWS_Enabled', "true");
        CWS_Write(config, 'CWS_TrueSteps', "false");
        CWS_Write(config, 'CWS_TrueStepSize', "5");
        CWS_Write(config, 'CWS_TrueStepMax', "1.00");
        CWS_Write(config, 'CWS_Count', "8");
        CWS_Write(config, 'CWS_FavoriteA', "4");
        CWS_Write(config, 'CWS_FavoriteB', "8");
        CWS_Write(config, 'CWS_Speed01', "0.11");
        CWS_Write(config, 'CWS_Speed02', "0.30");
        CWS_Write(config, 'CWS_Speed03', "0.40");
        CWS_Write(config, 'CWS_Speed04', "0.60");
        CWS_Write(config, 'CWS_Speed05', "0.70");
        CWS_Write(config, 'CWS_Speed06', "0.80");
        CWS_Write(config, 'CWS_Speed07', "0.90");
        CWS_Write(config, 'CWS_Speed08', "1.00");
        CWS_Write(config, 'CWS_MotionDiagnostics', "false");
        CWS_Write(config, 'CWS_DecreaseTimeMs', "10");
        CWS_Write(config, 'CWS_StopDestination', "0");
        CWS_Write(config, 'CWS_DecreaseCurve', "1");
        CWS_Write(config, 'CWS_FluidControls', "false");
        CWS_Write(config, 'CWS_CapUnavailable', "true");
        CWS_Write(config, 'CWS_SmoothFavorites', "false");
        CWS_Write(config, 'CWS_IncreaseTimeMs', "20");
        CWS_Write(config, 'CWS_IncreaseCurve', "1");
        CWS_Write(config, 'CWS_SmoothStarting', "true");
        CWS_Write(config, 'CWS_SmoothSteps', "true");
        CWS_Write(config, 'CWS_SprintThreshold', "1.00");
        CWS_Write(config, 'CWS_ResetAtStop', "false");
    }
    if (presetIndex == 1)
    {
        CWS_Write(config, 'CWS_Enabled', "true");
        CWS_Write(config, 'CWS_TrueSteps', "true");
        CWS_Write(config, 'CWS_TrueStepSize', "10");
        CWS_Write(config, 'CWS_TrueStepMax', "1.49");
        CWS_Write(config, 'CWS_Count', "8");
        CWS_Write(config, 'CWS_FavoriteA', "4");
        CWS_Write(config, 'CWS_FavoriteB', "8");
        CWS_Write(config, 'CWS_Speed01', "0.11");
        CWS_Write(config, 'CWS_Speed02', "0.30");
        CWS_Write(config, 'CWS_Speed03', "0.40");
        CWS_Write(config, 'CWS_Speed04', "0.60");
        CWS_Write(config, 'CWS_Speed05', "0.70");
        CWS_Write(config, 'CWS_Speed06', "0.80");
        CWS_Write(config, 'CWS_Speed07', "0.90");
        CWS_Write(config, 'CWS_Speed08', "1.00");
        CWS_Write(config, 'CWS_MotionDiagnostics', "false");
        CWS_Write(config, 'CWS_DecreaseTimeMs', "15");
        CWS_Write(config, 'CWS_StopDestination', "1");
        CWS_Write(config, 'CWS_DecreaseCurve', "1");
        CWS_Write(config, 'CWS_FluidControls', "true");
        CWS_Write(config, 'CWS_CapUnavailable', "true");
        CWS_Write(config, 'CWS_SmoothFavorites', "true");
        CWS_Write(config, 'CWS_IncreaseTimeMs', "20");
        CWS_Write(config, 'CWS_IncreaseCurve', "2");
        CWS_Write(config, 'CWS_SmoothStarting', "true");
        CWS_Write(config, 'CWS_SmoothSteps', "true");
        CWS_Write(config, 'CWS_SprintThreshold', "1.36");
        CWS_Write(config, 'CWS_ResetAtStop', "true");
    }
}

@addMethod(CWS_HorseState)
public function CWSH_ApplyPresetValues(config : CInGameConfigWrapper, presetIndex : int)
{
    if (presetIndex == 0)
    {
        config.SetVarValue(CWS_HorseSettingGroup('CWS_HorseEnabled'), 'CWS_HorseEnabled', CWS_SelectorMenuValue('CWS_HorseEnabled', "true"));
        config.SetVarValue(CWS_HorseSettingGroup('CWS_HorseTrueSteps'), 'CWS_HorseTrueSteps', CWS_SelectorMenuValue('CWS_HorseTrueSteps', "false"));
        config.SetVarValue(CWS_HorseSettingGroup('CWS_HorseTrueStepSize'), 'CWS_HorseTrueStepSize', CWS_SelectorMenuValue('CWS_HorseTrueStepSize', "10"));
        config.SetVarValue(CWS_HorseSettingGroup('CWS_HorseTrueStepMax'), 'CWS_HorseTrueStepMax', CWS_SelectorMenuValue('CWS_HorseTrueStepMax', "8.00"));
        config.SetVarValue(CWS_HorseSettingGroup('CWS_HorseCount'), 'CWS_HorseCount', CWS_SelectorMenuValue('CWS_HorseCount', "10"));
        config.SetVarValue(CWS_HorseSettingGroup('CWS_HorseFavoriteA'), 'CWS_HorseFavoriteA', CWS_SelectorMenuValue('CWS_HorseFavoriteA', "3"));
        config.SetVarValue(CWS_HorseSettingGroup('CWS_HorseFavoriteB'), 'CWS_HorseFavoriteB', CWS_SelectorMenuValue('CWS_HorseFavoriteB', "8"));
        config.SetVarValue(CWS_HorseSettingGroup('CWS_HorseSpeed01'), 'CWS_HorseSpeed01', CWS_SelectorMenuValue('CWS_HorseSpeed01', "0.40"));
        config.SetVarValue(CWS_HorseSettingGroup('CWS_HorseSpeed02'), 'CWS_HorseSpeed02', CWS_SelectorMenuValue('CWS_HorseSpeed02', "0.50"));
        config.SetVarValue(CWS_HorseSettingGroup('CWS_HorseSpeed03'), 'CWS_HorseSpeed03', CWS_SelectorMenuValue('CWS_HorseSpeed03', "1.00"));
        config.SetVarValue(CWS_HorseSettingGroup('CWS_HorseSpeed04'), 'CWS_HorseSpeed04', CWS_SelectorMenuValue('CWS_HorseSpeed04', "1.50"));
        config.SetVarValue(CWS_HorseSettingGroup('CWS_HorseSpeed05'), 'CWS_HorseSpeed05', CWS_SelectorMenuValue('CWS_HorseSpeed05', "2.00"));
        config.SetVarValue(CWS_HorseSettingGroup('CWS_HorseSpeed06'), 'CWS_HorseSpeed06', CWS_SelectorMenuValue('CWS_HorseSpeed06', "2.50"));
        config.SetVarValue(CWS_HorseSettingGroup('CWS_HorseSpeed07'), 'CWS_HorseSpeed07', CWS_SelectorMenuValue('CWS_HorseSpeed07', "3.00"));
        config.SetVarValue(CWS_HorseSettingGroup('CWS_HorseSpeed08'), 'CWS_HorseSpeed08', CWS_SelectorMenuValue('CWS_HorseSpeed08', "4.00"));
        config.SetVarValue(CWS_HorseSettingGroup('CWS_HorseMotionDiagnostics'), 'CWS_HorseMotionDiagnostics', CWS_SelectorMenuValue('CWS_HorseMotionDiagnostics', "false"));
        config.SetVarValue(CWS_HorseSettingGroup('CWS_HorseSmoothSteps'), 'CWS_HorseSmoothSteps', CWS_SelectorMenuValue('CWS_HorseSmoothSteps', "true"));
        config.SetVarValue(CWS_HorseSettingGroup('CWS_HorseSmoothFavorites'), 'CWS_HorseSmoothFavorites', CWS_SelectorMenuValue('CWS_HorseSmoothFavorites', "true"));
        config.SetVarValue(CWS_HorseSettingGroup('CWS_HorseSmoothStarting'), 'CWS_HorseSmoothStarting', CWS_SelectorMenuValue('CWS_HorseSmoothStarting', "true"));
        config.SetVarValue(CWS_HorseSettingGroup('CWS_HorseIncreaseCurve'), 'CWS_HorseIncreaseCurve', CWS_SelectorMenuValue('CWS_HorseIncreaseCurve', "4"));
        config.SetVarValue(CWS_HorseSettingGroup('CWS_HorseDecreaseCurve'), 'CWS_HorseDecreaseCurve', CWS_SelectorMenuValue('CWS_HorseDecreaseCurve', "1"));
        config.SetVarValue(CWS_HorseSettingGroup('CWS_HorseIncreaseTimeMs'), 'CWS_HorseIncreaseTimeMs', CWS_SelectorMenuValue('CWS_HorseIncreaseTimeMs', "5"));
        config.SetVarValue(CWS_HorseSettingGroup('CWS_HorseDecreaseTimeMs'), 'CWS_HorseDecreaseTimeMs', CWS_SelectorMenuValue('CWS_HorseDecreaseTimeMs', "3"));
        config.SetVarValue(CWS_HorseSettingGroup('CWS_HorseResetAtStop'), 'CWS_HorseResetAtStop', CWS_SelectorMenuValue('CWS_HorseResetAtStop', "false"));
        config.SetVarValue(CWS_HorseSettingGroup('CWS_HorseStopDestination'), 'CWS_HorseStopDestination', CWS_SelectorMenuValue('CWS_HorseStopDestination', "0"));
        config.SetVarValue(CWS_HorseSettingGroup('CWS_HorseSpeed09'), 'CWS_HorseSpeed09', CWS_SelectorMenuValue('CWS_HorseSpeed09', "6.00"));
        config.SetVarValue(CWS_HorseSettingGroup('CWS_HorseSpeed10'), 'CWS_HorseSpeed10', CWS_SelectorMenuValue('CWS_HorseSpeed10', "8.00"));
        config.SetVarValue(CWS_HorseSettingGroup('CWS_HorseStartSpeed'), 'CWS_HorseStartSpeed', CWS_SelectorMenuValue('CWS_HorseStartSpeed', "0.40"));
        config.SetVarValue(CWS_HorseSettingGroup('CWS_HorseTrueStepMin'), 'CWS_HorseTrueStepMin', CWS_SelectorMenuValue('CWS_HorseTrueStepMin', "0.40"));
    }
    if (presetIndex == 1)
    {
        config.SetVarValue(CWS_HorseSettingGroup('CWS_HorseEnabled'), 'CWS_HorseEnabled', CWS_SelectorMenuValue('CWS_HorseEnabled', "true"));
        config.SetVarValue(CWS_HorseSettingGroup('CWS_HorseTrueSteps'), 'CWS_HorseTrueSteps', CWS_SelectorMenuValue('CWS_HorseTrueSteps', "true"));
        config.SetVarValue(CWS_HorseSettingGroup('CWS_HorseTrueStepSize'), 'CWS_HorseTrueStepSize', CWS_SelectorMenuValue('CWS_HorseTrueStepSize', "20"));
        config.SetVarValue(CWS_HorseSettingGroup('CWS_HorseTrueStepMax'), 'CWS_HorseTrueStepMax', CWS_SelectorMenuValue('CWS_HorseTrueStepMax', "5.00"));
        config.SetVarValue(CWS_HorseSettingGroup('CWS_HorseCount'), 'CWS_HorseCount', CWS_SelectorMenuValue('CWS_HorseCount', "10"));
        config.SetVarValue(CWS_HorseSettingGroup('CWS_HorseFavoriteA'), 'CWS_HorseFavoriteA', CWS_SelectorMenuValue('CWS_HorseFavoriteA', "5"));
        config.SetVarValue(CWS_HorseSettingGroup('CWS_HorseFavoriteB'), 'CWS_HorseFavoriteB', CWS_SelectorMenuValue('CWS_HorseFavoriteB', "8"));
        config.SetVarValue(CWS_HorseSettingGroup('CWS_HorseSpeed01'), 'CWS_HorseSpeed01', CWS_SelectorMenuValue('CWS_HorseSpeed01', "0.40"));
        config.SetVarValue(CWS_HorseSettingGroup('CWS_HorseSpeed02'), 'CWS_HorseSpeed02', CWS_SelectorMenuValue('CWS_HorseSpeed02', "0.50"));
        config.SetVarValue(CWS_HorseSettingGroup('CWS_HorseSpeed03'), 'CWS_HorseSpeed03', CWS_SelectorMenuValue('CWS_HorseSpeed03', "1.00"));
        config.SetVarValue(CWS_HorseSettingGroup('CWS_HorseSpeed04'), 'CWS_HorseSpeed04', CWS_SelectorMenuValue('CWS_HorseSpeed04', "1.50"));
        config.SetVarValue(CWS_HorseSettingGroup('CWS_HorseSpeed05'), 'CWS_HorseSpeed05', CWS_SelectorMenuValue('CWS_HorseSpeed05', "2.00"));
        config.SetVarValue(CWS_HorseSettingGroup('CWS_HorseSpeed06'), 'CWS_HorseSpeed06', CWS_SelectorMenuValue('CWS_HorseSpeed06', "2.50"));
        config.SetVarValue(CWS_HorseSettingGroup('CWS_HorseSpeed07'), 'CWS_HorseSpeed07', CWS_SelectorMenuValue('CWS_HorseSpeed07', "3.00"));
        config.SetVarValue(CWS_HorseSettingGroup('CWS_HorseSpeed08'), 'CWS_HorseSpeed08', CWS_SelectorMenuValue('CWS_HorseSpeed08', "4.00"));
        config.SetVarValue(CWS_HorseSettingGroup('CWS_HorseMotionDiagnostics'), 'CWS_HorseMotionDiagnostics', CWS_SelectorMenuValue('CWS_HorseMotionDiagnostics', "false"));
        config.SetVarValue(CWS_HorseSettingGroup('CWS_HorseSmoothSteps'), 'CWS_HorseSmoothSteps', CWS_SelectorMenuValue('CWS_HorseSmoothSteps', "true"));
        config.SetVarValue(CWS_HorseSettingGroup('CWS_HorseSmoothFavorites'), 'CWS_HorseSmoothFavorites', CWS_SelectorMenuValue('CWS_HorseSmoothFavorites', "true"));
        config.SetVarValue(CWS_HorseSettingGroup('CWS_HorseSmoothStarting'), 'CWS_HorseSmoothStarting', CWS_SelectorMenuValue('CWS_HorseSmoothStarting', "true"));
        config.SetVarValue(CWS_HorseSettingGroup('CWS_HorseIncreaseCurve'), 'CWS_HorseIncreaseCurve', CWS_SelectorMenuValue('CWS_HorseIncreaseCurve', "4"));
        config.SetVarValue(CWS_HorseSettingGroup('CWS_HorseDecreaseCurve'), 'CWS_HorseDecreaseCurve', CWS_SelectorMenuValue('CWS_HorseDecreaseCurve', "2"));
        config.SetVarValue(CWS_HorseSettingGroup('CWS_HorseIncreaseTimeMs'), 'CWS_HorseIncreaseTimeMs', CWS_SelectorMenuValue('CWS_HorseIncreaseTimeMs', "7"));
        config.SetVarValue(CWS_HorseSettingGroup('CWS_HorseDecreaseTimeMs'), 'CWS_HorseDecreaseTimeMs', CWS_SelectorMenuValue('CWS_HorseDecreaseTimeMs', "4"));
        config.SetVarValue(CWS_HorseSettingGroup('CWS_HorseResetAtStop'), 'CWS_HorseResetAtStop', CWS_SelectorMenuValue('CWS_HorseResetAtStop', "true"));
        config.SetVarValue(CWS_HorseSettingGroup('CWS_HorseStopDestination'), 'CWS_HorseStopDestination', CWS_SelectorMenuValue('CWS_HorseStopDestination', "1"));
        config.SetVarValue(CWS_HorseSettingGroup('CWS_HorseSpeed09'), 'CWS_HorseSpeed09', CWS_SelectorMenuValue('CWS_HorseSpeed09', "6.00"));
        config.SetVarValue(CWS_HorseSettingGroup('CWS_HorseSpeed10'), 'CWS_HorseSpeed10', CWS_SelectorMenuValue('CWS_HorseSpeed10', "8.00"));
        config.SetVarValue(CWS_HorseSettingGroup('CWS_HorseStartSpeed'), 'CWS_HorseStartSpeed', CWS_SelectorMenuValue('CWS_HorseStartSpeed', "0.80"));
        config.SetVarValue(CWS_HorseSettingGroup('CWS_HorseTrueStepMin'), 'CWS_HorseTrueStepMin', CWS_SelectorMenuValue('CWS_HorseTrueStepMin', "0.60"));
    }
}

@addMethod(CWS_SwimState)
public function CWSS_ApplyPresetValues(config : CInGameConfigWrapper, presetIndex : int)
{
    if (presetIndex != 0) return;
    config.SetVarValue(CWS_SwimSettingGroup('CWS_SwimEnabled'), 'CWS_SwimEnabled', CWS_SwimMenuValue('CWS_SwimEnabled', "true"));
    config.SetVarValue(CWS_SwimSettingGroup('CWS_SwimTrueSteps'), 'CWS_SwimTrueSteps', CWS_SwimMenuValue('CWS_SwimTrueSteps', "true"));
    config.SetVarValue(CWS_SwimSettingGroup('CWS_SwimShowSpeedChanges'), 'CWS_SwimShowSpeedChanges', CWS_SwimMenuValue('CWS_SwimShowSpeedChanges', "false"));
    config.SetVarValue(CWS_SwimSettingGroup('CWS_SwimFavoriteA'), 'CWS_SwimFavoriteA', CWS_SwimMenuValue('CWS_SwimFavoriteA', "4"));
    config.SetVarValue(CWS_SwimSettingGroup('CWS_SwimFavoriteB'), 'CWS_SwimFavoriteB', CWS_SwimMenuValue('CWS_SwimFavoriteB', "8"));
    config.SetVarValue(CWS_SwimSettingGroup('CWS_SwimStartSpeed'), 'CWS_SwimStartSpeed', CWS_SwimMenuValue('CWS_SwimStartSpeed', "0.60"));
    config.SetVarValue(CWS_SwimSettingGroup('CWS_SwimCount'), 'CWS_SwimCount', CWS_SwimMenuValue('CWS_SwimCount', "8"));
    config.SetVarValue(CWS_SwimSettingGroup('CWS_SwimSpeed01'), 'CWS_SwimSpeed01', CWS_SwimMenuValue('CWS_SwimSpeed01', "0.60"));
    config.SetVarValue(CWS_SwimSettingGroup('CWS_SwimSpeed02'), 'CWS_SwimSpeed02', CWS_SwimMenuValue('CWS_SwimSpeed02', "0.60"));
    config.SetVarValue(CWS_SwimSettingGroup('CWS_SwimSpeed03'), 'CWS_SwimSpeed03', CWS_SwimMenuValue('CWS_SwimSpeed03', "0.60"));
    config.SetVarValue(CWS_SwimSettingGroup('CWS_SwimSpeed04'), 'CWS_SwimSpeed04', CWS_SwimMenuValue('CWS_SwimSpeed04', "0.60"));
    config.SetVarValue(CWS_SwimSettingGroup('CWS_SwimSpeed05'), 'CWS_SwimSpeed05', CWS_SwimMenuValue('CWS_SwimSpeed05', "0.80"));
    config.SetVarValue(CWS_SwimSettingGroup('CWS_SwimSpeed06'), 'CWS_SwimSpeed06', CWS_SwimMenuValue('CWS_SwimSpeed06', "1.00"));
    config.SetVarValue(CWS_SwimSettingGroup('CWS_SwimSpeed07'), 'CWS_SwimSpeed07', CWS_SwimMenuValue('CWS_SwimSpeed07', "1.25"));
    config.SetVarValue(CWS_SwimSettingGroup('CWS_SwimSpeed08'), 'CWS_SwimSpeed08', CWS_SwimMenuValue('CWS_SwimSpeed08', "1.49"));
    config.SetVarValue(CWS_SwimSettingGroup('CWS_SwimSpeed09'), 'CWS_SwimSpeed09', CWS_SwimMenuValue('CWS_SwimSpeed09', "2.00"));
    config.SetVarValue(CWS_SwimSettingGroup('CWS_SwimSpeed10'), 'CWS_SwimSpeed10', CWS_SwimMenuValue('CWS_SwimSpeed10', "2.00"));
    config.SetVarValue(CWS_SwimSettingGroup('CWS_SwimTrueStepSize'), 'CWS_SwimTrueStepSize', CWS_SwimMenuValue('CWS_SwimTrueStepSize', "10"));
    config.SetVarValue(CWS_SwimSettingGroup('CWS_SwimTrueStepMin'), 'CWS_SwimTrueStepMin', CWS_SwimMenuValue('CWS_SwimTrueStepMin', "0.60"));
    config.SetVarValue(CWS_SwimSettingGroup('CWS_SwimTrueStepMax'), 'CWS_SwimTrueStepMax', CWS_SwimMenuValue('CWS_SwimTrueStepMax', "1.49"));
    config.SetVarValue(CWS_SwimSettingGroup('CWS_SwimStartMatch'), 'CWS_SwimStartMatch', CWS_SwimMenuValue('CWS_SwimStartMatch', "true"));
    config.SetVarValue(CWS_SwimSettingGroup('CWS_SwimStartValue'), 'CWS_SwimStartValue', CWS_SwimMenuValue('CWS_SwimStartValue', "1.00"));
}

@addField(CR4IngameMenu)
private var CWS_currentPage : string;
@addField(CR4IngameMenu)
private var CWS_dependencyCache : array<int>;
@addField(CR4IngameMenu)
private var CWS_applyingPreset : bool;

@addMethod(CR4IngameMenu)
public function CWS_PresetIsApplying() : bool
{
    return CWS_applyingPreset;
}

@addMethod(CR4IngameMenu)
public function CWS_PageGroup(id : string) : name
{
    switch (id)
    {
        case "cm_general": return 'ControlledWalkSpeed';
        case "cm_steps": return 'CWS_Steps';
        case "cm_true_steps": return 'CWS_TrueStepsOptions';
        case "cm_fluid_controls": return 'CWS_FluidControlsOptions';
        case "cm_fluid_movement": return 'CWS_FluidMovementOptions';
        case "cm_roach_general": return 'CWS_Horse';
        case "cm_roach_steps": return 'CWS_HorseSteps';
        case "cm_roach_true_steps": return 'CWS_HorseTrueStepsOptions';
        case "cm_roach_fluid_movement": return 'CWS_HorseFluidMovementOptions';
        case "cm_swim_general": return 'CWS_Swimming';
        case "cm_swim_speeds": return 'CWS_SwimmingSpeeds';
        case "cm_swim_true_steps": return 'CWS_SwimmingTrueStepsOptions';
        case "cm_controls": return 'CWS_Controls';
    }
    return '';
}

@addMethod(CR4IngameMenu)
public function CWS_IsMenuPage(id : string) : bool
{
    return CWS_PageGroup(id) != '';
}

@wrapMethod(CR4IngameMenu)
function OnConfigUI()
{
    CWS_currentPage = "";
    // Establish neighbor values before even a main-menu settings edit.
    CWS_GetState().CWS_Load(true);
    CWS_GetHorseState().CWSH_Load(true);
    CWS_GetSwimState().CWSS_Load(true);
    wrappedMethod();
}

@wrapMethod(CR4IngameMenu)
function OnClosingMenu()
{
    CWS_currentPage = "";
    wrappedMethod();
    CWS_ResetGesture();
    CWS_GetState().CWS_Load();
    CWS_GetHorseState().CWSH_Load();
    CWS_GetSwimState().CWSS_Load();
    CWS_GetState().CWS_ValueReadoutPoll();
}

@wrapMethod(CR4IngameMenu)
function OnShowOptionSubmenu(actionType : int, menuTag : int, id : string)
{
    wrappedMethod(actionType, menuTag, id);
    CWS_currentPage = "";
    CWS_dependencyCache.Clear();
    if (CWS_IsMenuPage(id))
    {
        CWS_currentPage = id;
        if (StrBeginsWith(id, "cm_swim_"))
            CWS_GetSwimState().CWSS_Load(true);
        else if (StrBeginsWith(id, "cm_roach_"))
            CWS_GetHorseState().CWSH_Load(true);
        else
            CWS_GetState().CWS_Load(true);
        CWS_RefreshMenuDependencies();
    }
}

@wrapMethod(CR4IngameMenu)
function OnOptionPanelNavigateBack()
{
    CWS_currentPage = "";
    return wrappedMethod();
}

// Publish after the predecessor; ordinary slider motion never refreshes dependencies.
@wrapMethod(CR4IngameMenu)
function OnOptionValueChanged(groupId : int, optionName : name, optionValue : string)
{
    var result : bool;
    result = wrappedMethod(groupId, optionName, optionValue);
    if (CWS_IsMenuPage(CWS_currentPage))
    {
        if (optionName == 'CWS_SwimEnabled' || optionName == 'CWS_SwimTrueSteps'
            || optionName == 'CWS_Enabled' || optionName == 'CWS_TrueSteps'
            || optionName == 'CWS_FluidControls' || optionName == 'CWS_SmoothSteps'
            || optionName == 'CWS_SmoothFavorites' || optionName == 'CWS_SmoothStarting'
            || optionName == 'CWS_ResetAtStop'
            || optionName == 'CWS_HorseEnabled' || optionName == 'CWS_HorseTrueSteps'
            || optionName == 'CWS_HorseSmoothSteps' || optionName == 'CWS_HorseSmoothFavorites'
            || optionName == 'CWS_HorseSmoothStarting' || optionName == 'CWS_HorseResetAtStop')
            CWS_RefreshMenuDependencies();
    }
    return result;
}

@addMethod(CR4IngameMenu)
public function CWS_RefreshMenuDependencies()
{
    var cwsState : CWS_State;
    var horseState : CWS_HorseState;
    var swimState : CWS_SwimState;
    var group, key : name;
    var i, flag, changed : int;
    var disabled : bool;
    var dataArray : CScriptedFlashArray;
    var optionValueObject : CScriptedFlashObject;
    group = CWS_PageGroup(CWS_currentPage);
    if (group == '' || !m_flashValueStorage)
        return;
    if (group == 'CWS_Controls')
    {
        dataArray = m_flashValueStorage.CreateTempFlashArray();
        optionValueObject = m_flashValueStorage.CreateTempFlashObject();
        optionValueObject.SetMemberFlashUInt("tag", NameToFlashUInt('CWS_RequireModifier'));
        optionValueObject.SetMemberFlashBool("disabled", false);
        dataArray.PushBackFlashObject(optionValueObject);
        m_flashValueStorage.SetFlashArray("options.update_disabled", dataArray);
        return;
    }
    if (StrBeginsWith(CWS_currentPage, "cm_swim_"))
    {
        swimState = CWS_GetSwimState();
        while (CWS_dependencyCache.Size() < swimState.CWSS_SettingCount())
            CWS_dependencyCache.PushBack(-1);
        dataArray = m_flashValueStorage.CreateTempFlashArray();
        for (i = 0; i < swimState.CWSS_SettingCount(); i += 1)
        {
            key = swimState.CWSS_SettingKey(i);
            if (CWS_SwimSettingGroup(key) != group) continue;
            disabled = !swimState.enabled;
            if (key == 'CWS_SwimEnabled') disabled = false;
            else if (key == 'CWS_SwimCount') disabled = disabled || swimState.trueSteps;
            else if (key == 'CWS_SwimTrueStepSize' || key == 'CWS_SwimTrueStepMin' || key == 'CWS_SwimTrueStepMax')
                disabled = disabled || !swimState.trueSteps;
            flag = 0;
            if (disabled) flag = 1;
            if (CWS_dependencyCache[i] == flag) continue;
            CWS_dependencyCache[i] = flag;
            optionValueObject = m_flashValueStorage.CreateTempFlashObject();
            optionValueObject.SetMemberFlashUInt("tag", NameToFlashUInt(key));
            optionValueObject.SetMemberFlashBool("disabled", disabled);
            dataArray.PushBackFlashObject(optionValueObject);
            changed += 1;
        }
    }
    else if (StrBeginsWith(CWS_currentPage, "cm_roach_"))
    {
        horseState = CWS_GetHorseState();
        while (CWS_dependencyCache.Size() < horseState.CWSH_SettingCount())
            CWS_dependencyCache.PushBack(-1);
        dataArray = m_flashValueStorage.CreateTempFlashArray();
        for (i = 0; i < horseState.CWSH_SettingCount(); i += 1)
        {
            key = horseState.CWSH_SettingKey(i);
            if (CWS_HorseSettingGroup(key) != group)
                continue;
            disabled = !horseState.enabled;
            if (key == 'CWS_HorseEnabled')
                disabled = false;
            else if (key == 'CWS_HorseCount')
                disabled = disabled || horseState.trueSteps;
            else if (key == 'CWS_HorseTrueStepSize' || key == 'CWS_HorseTrueStepMin' || key == 'CWS_HorseTrueStepMax')
                disabled = disabled || !horseState.trueSteps;
            else if (key == 'CWS_HorseStartSpeed')
                disabled = disabled || !horseState.smoothStarting;
            else if (key == 'CWS_HorseIncreaseTimeMs' || key == 'CWS_HorseIncreaseCurve')
                disabled = disabled || !(horseState.smoothSteps || horseState.smoothFavorites || horseState.smoothStarting);
            else if (key == 'CWS_HorseDecreaseTimeMs' || key == 'CWS_HorseDecreaseCurve')
                disabled = disabled || !(horseState.smoothSteps || horseState.smoothFavorites);
            else if (key == 'CWS_HorseStopDestination')
                disabled = disabled || !horseState.resetAtStop;
            flag = 0;
            if (disabled)
                flag = 1;
            if (CWS_dependencyCache[i] == flag)
                continue;
            CWS_dependencyCache[i] = flag;
            optionValueObject = m_flashValueStorage.CreateTempFlashObject();
            optionValueObject.SetMemberFlashUInt("tag", NameToFlashUInt(key));
            optionValueObject.SetMemberFlashBool("disabled", disabled);
            dataArray.PushBackFlashObject(optionValueObject);
            changed += 1;
        }
    }
    else
    {
        cwsState = CWS_GetState();
        while (CWS_dependencyCache.Size() < cwsState.CWS_SettingCount())
            CWS_dependencyCache.PushBack(-1);
        dataArray = m_flashValueStorage.CreateTempFlashArray();
        for (i = 0; i < cwsState.CWS_SettingCount(); i += 1)
        {
            key = cwsState.CWS_SettingKey(i);
            if (cwsState.CWS_SettingGroup(key) != group)
                continue;
            disabled = !cwsState.enabled;
            if (key == 'CWS_Enabled')
                disabled = false;
            else if (key == 'CWS_Count')
                disabled = disabled || cwsState.trueSteps;
            else if (key == 'CWS_TrueStepSize' || key == 'CWS_TrueStepMax')
                disabled = disabled || !cwsState.trueSteps;
            else if (key == 'CWS_SprintThreshold' || key == 'CWS_CapUnavailable')
                disabled = disabled || !cwsState.fluidControls;
            else if (key == 'CWS_IncreaseTimeMs' || key == 'CWS_IncreaseCurve')
                disabled = disabled || !(cwsState.smoothSteps || cwsState.smoothFavorites || cwsState.smoothStarting);
            else if (key == 'CWS_DecreaseTimeMs' || key == 'CWS_DecreaseCurve')
                disabled = disabled || !(cwsState.smoothSteps || cwsState.smoothFavorites);
            else if (key == 'CWS_StopDestination')
                disabled = disabled || !cwsState.resetAtStop;
            flag = 0;
            if (disabled)
                flag = 1;
            if (CWS_dependencyCache[i] == flag)
                continue;
            CWS_dependencyCache[i] = flag;
            optionValueObject = m_flashValueStorage.CreateTempFlashObject();
            optionValueObject.SetMemberFlashUInt("tag", NameToFlashUInt(key));
            optionValueObject.SetMemberFlashBool("disabled", disabled);
            dataArray.PushBackFlashObject(optionValueObject);
            changed += 1;
        }
    }
    if (changed > 0)
        m_flashValueStorage.SetFlashArray("options.update_disabled", dataArray);
}

@addMethod(CR4IngameMenu)
public function CWS_UpdateSettingValues(keys : array<name>, values : array<string>, optional allPages : bool)
{
    var i : int;
    var group : name;
    group = CWS_PageGroup(CWS_currentPage);
    if (!m_fxUpdateOptionValue || (!allPages && group == ''))
        return;
    for (i = 0; i < keys.Size(); i += 1)
    {
        if (allPages && keys[i] == 'CWS_RequireModifier')
            continue;
        if (allPages || (StrBeginsWith(NameToString(keys[i]), "CWS_Swim") && CWS_SwimSettingGroup(keys[i]) == group)
            || (StrBeginsWith(NameToString(keys[i]), "CWS_Horse") && CWS_HorseSettingGroup(keys[i]) == group)
            || (!StrBeginsWith(NameToString(keys[i]), "CWS_Swim") && !StrBeginsWith(NameToString(keys[i]), "CWS_Horse") && CWS_GetState().CWS_SettingGroup(keys[i]) == group))
            m_fxUpdateOptionValue.InvokeSelfTwoArgs(FlashArgUInt(NameToFlashUInt(keys[i])), FlashArgString(CWS_SwimMenuValue(keys[i], values[i])));
    }
}

@wrapMethod(CR4IngameMenu)
function UpdatePresetOptions(groupId : name, applyLocks : bool)
{
    if ((groupId == 'ControlledWalkSpeed' || groupId == 'CWS_Horse' || groupId == 'CWS_Swimming') && CWS_applyingPreset)
        return;
    if (groupId == 'CWS_Swimming')
        CWS_GetSwimState().CWSS_RefreshMenu(true);
    else if (groupId == 'ControlledWalkSpeed')
        CWS_GetState().CWS_RefreshMenuValues();
    else if (groupId == 'CWS_Horse')
        CWS_GetHorseState().CWSH_RefreshMenu();
    wrappedMethod(groupId, applyLocks);
}

@wrapMethod(CR4IngameMenu)
function OnPresetApplied(groupId : name, targetPresetIndex : int)
{
    var cwsState : CWS_State;
    var horseState : CWS_HorseState;
    var swimState : CWS_SwimState;
    var config : CInGameConfigWrapper;
    var sharedModifier : string;
    var owned : bool;
    owned = groupId == 'ControlledWalkSpeed' || groupId == 'CWS_Horse' || groupId == 'CWS_Swimming';
    if (owned)
    {
        config = theGame.GetInGameConfigWrapper();
        sharedModifier = config.GetVarValue('CWS_Controls', 'CWS_RequireModifier');
        CWS_applyingPreset = true;
    }
    wrappedMethod(groupId, targetPresetIndex);
    if (owned)
    {
        // Native defaults may reset aliases through their physical storage group.
        // Restore the shared choice before either profile normalizes its values.
        if (config.GetVarValue('CWS_Controls', 'CWS_RequireModifier') != sharedModifier)
            config.SetVarValue('CWS_Controls', 'CWS_RequireModifier', sharedModifier);
        if (groupId == 'CWS_Swimming')
        {
            swimState = CWS_GetSwimState();
            swimState.CWSS_StateSuspend();
            swimState.CWSS_ApplyPresetValues(config, targetPresetIndex);
            swimState.CWSS_Load(true);
        }
        else if (groupId == 'ControlledWalkSpeed')
        {
            cwsState = CWS_GetState();
            cwsState.CWS_ApplyPresetValues(config, targetPresetIndex);
            cwsState.CWS_Load(true);
        }
        else
        {
            horseState = CWS_GetHorseState();
            horseState.CWSH_ApplyPresetValues(config, targetPresetIndex);
            horseState.CWSH_Load(true);
        }
        CWS_applyingPreset = false;
        CWS_ResetGesture();
        UpdatePresetOptions(groupId, false);
        CWS_RefreshMenuDependencies();
    }
}
