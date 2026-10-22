// Automatic input intent; native sprint state, timers and presentation agree.
@addField(CWS_State) private var CWS_sprintPlayer : CR4Player;
@addField(CWS_State) private var CWS_sprintCapped : bool;
@addMethod(CWS_State)
public function CWS_FluidCapped() : bool
{
    return enabled && fluidControls && capUnavailable && CWS_sprintCapped;
}
@addMethod(CWS_State)
public function CWS_SetFluidCap(capped : bool)
{
    CWS_sprintCapped = capped;
}
@addMethod(CWS_State)
public function CWS_RegisterFluidSprint(player : CR4Player)
{
    if (CWS_sprintPlayer && CWS_sprintPlayer != player)
        CWS_sprintPlayer.CWS_ReleaseFluidSprint(true);
    CWS_sprintPlayer = player;
}
@addMethod(CWS_State)
public function CWS_FluidRelease()
{
    if (CWS_sprintPlayer)
        CWS_sprintPlayer.CWS_ReleaseFluidSprint(true);
    CWS_sprintPlayer = NULL;
    CWS_sprintCapped = false;
}
@addMethod(CWS_State)
public function CWS_FluidPoll()
{
    if (!enabled || !fluidControls || !capUnavailable)
        CWS_sprintCapped = false;
    if (!CWS_sprintPlayer)
        return;
    if (CWS_sprintPlayer == thePlayer && CWS_sprintPlayer.CWS_ManualSprint())
        CWS_sprintPlayer.CWS_ReleaseFluidSprint(false);
    else if (!enabled || !fluidControls || !theGame.CWS_Input
        || CWS_sprintPlayer != thePlayer || !CWS_IsEligible(CWS_sprintPlayer)
        || CWS_sprintPlayer.IsInCombatActionFriendly() || CWS_sprintPlayer.GetBInteractionPressed())
        CWS_sprintPlayer.CWS_ReleaseFluidSprint(true);
    if (!CWS_sprintPlayer.CWS_HasOwnedSprint())
        CWS_sprintPlayer = NULL;
}

@addField(CPlayer) private var CWS_sprintOwned : bool;
@addField(CPlayer) private var CWS_sprintAttempt : bool;
@addField(CPlayer) private var CWS_sprintProbe : bool;
@addField(CPlayer) private var CWS_sprintAccepted : bool;
@addField(CPlayer) private var CWS_sprintSetterSerial : int;
@addField(CPlayer) private var CWS_sprintSetterDepth : int;
@addField(CPlayer) private var CWS_sprintDerivedDepth : int;

@addMethod(CPlayer)
public function CWS_ManualSprint() : bool
{
    return GetIsSprintToggled() || IsSprintActionPressed() || theInput.IsActionPressed('Sprint');
}
@addMethod(CPlayer)
public function CWS_HasOwnedSprint() : bool
{
    return CWS_sprintOwned && GetIsSprinting();
}
@addMethod(CPlayer)
public function CWS_PrepareFluidSprint(inputMagnitude : float)
{
    var settings : CWS_State;
    settings = CWS_GetState();
    CWS_sprintAttempt = false;
    CWS_sprintProbe = false;
    CWS_sprintAccepted = false;
    if (!settings.fluidControls || inputMagnitude <= 0.8f || CWS_ManualSprint())
        return;
    CWS_sprintProbe = settings.CWS_FluidCapped();
    CWS_sprintAttempt = CWS_sprintProbe || settings.CWS_PlayerSprintIntent();
}
@addMethod(CPlayer)
public function CWS_EndFluidCalculation()
{
    CWS_sprintAttempt = false;
    CWS_sprintProbe = false;
    CWS_sprintAccepted = false;
}
@addMethod(CPlayer)
public function CWS_AutomaticSprintRequested() : bool
{
    return CWS_IsNativeCalculation() && CWS_sprintAttempt && !CWS_ManualSprint();
}
@addMethod(CPlayer)
public function CWS_IsSprintProbe() : bool
{
    return CWS_IsNativeCalculation() && CWS_sprintProbe;
}
@addMethod(CPlayer)
public function CWS_BeginDerivedSprint()
{
    CWS_sprintDerivedDepth += 1;
}
@addMethod(CPlayer)
public function CWS_EndDerivedSprint()
{
    CWS_sprintDerivedDepth -= 1;
}
@addMethod(CPlayer)
public function CWS_InDerivedSprint() : bool
{
    return CWS_sprintDerivedDepth > 0;
}
@addMethod(CPlayer)
public function CWS_RecordSprintPermission(allowed : bool)
{
    if (!CWS_IsNativeCalculation() || !CWS_sprintAttempt || CWS_ManualSprint())
        return;
    CWS_sprintAccepted = allowed && !CWS_sprintProbe;
    if (CWS_GetState().capUnavailable)
        CWS_GetState().CWS_SetFluidCap(!allowed);
}
@addMethod(CPlayer)
public function CWS_SuspendFluidSprint()
{
    CWS_sprintAttempt = false;
    CWS_sprintAccepted = false;
    // A forced-fall bypass may precede the native fall state's entry consumer.
    // Retain that entry state, then use the existing native delayed-release timer.
    if (CWS_HasOwnedSprint() && !CWS_ManualSprint() && !disableSprintingTimerEnabled)
    {
        disableSprintingTimerEnabled = true;
        AddTimer('DisableSprintingTimer', 0.25f);
    }
}
@addMethod(CPlayer)
private function CWS_ClearFormerPlayerSprint(serial : int)
{
    if ((CR4Player)this == thePlayer || serial != CWS_sprintSetterSerial)
        return;
    // Native SetIsSprinting(false) targets global thePlayer's reaction and camera.
    // An abandoned CM-owned actor must instead clear only its own native state.
    isSprinting = false;
    sprintingTime = 0.0f;
    sprintingCamera = false;
    theGame.GetBehTreeReactionManager().RemoveReactionEvent(this, 'PlayerSprintAction');
    if (serial != CWS_sprintSetterSerial)
        return;
    ResumeStaminaRegen('Sprint');
    if (serial == CWS_sprintSetterSerial && !GetIsSprinting()
        && (GetBehaviorVariable('isSprinting') == 0.0f || GetBehaviorVariable('isSprinting') == 1.0f))
        SetBehaviorVariable('isSprinting', 0.0f);
}

@addMethod(CPlayer)
public function CWS_ReleaseFluidSprint(stop : bool)
{
    var owned : bool;
    var serial : int;
    serial = CWS_sprintSetterSerial;
    owned = CWS_sprintOwned;
    CWS_sprintOwned = false;
    CWS_EndFluidCalculation();
    if (owned && stop && serial == CWS_sprintSetterSerial
        && ((CR4Player)this != thePlayer || !CWS_ManualSprint()))
    {
        RemoveTimer('SprintingTimer');
        RemoveTimer('DisableSprintingTimer');
        disableSprintingTimerEnabled = false;
        if ((CR4Player)this != thePlayer)
            CWS_ClearFormerPlayerSprint(serial);
        else
            SetIsSprinting(false);
    }
}

@wrapMethod(CPlayer)
function SetIsSprinting(flag : bool)
{
    var automatic : bool;
    var serial : int;
    automatic = CWS_sprintSetterDepth == 0 && flag && CWS_IsNativeCalculation()
        && CWS_sprintAccepted && !CWS_ManualSprint() && (!GetIsSprinting() || CWS_sprintOwned);
    CWS_sprintSetterSerial += 1;
    serial = CWS_sprintSetterSerial;
    if (!automatic)
        CWS_sprintOwned = false;
    CWS_sprintSetterDepth += 1;
    wrappedMethod(flag);
    CWS_sprintSetterDepth -= 1;
    if (automatic && serial == CWS_sprintSetterSerial && GetIsSprinting() && !CWS_ManualSprint())
    {
        CWS_sprintOwned = true;
        CWS_GetState().CWS_RegisterFluidSprint((CR4Player)this);
    }
}

// Native body: Copyright 2015 CD PROJEKT S.A. All rights reserved.
// THE WITCHER is a trademark of CD PROJEKT S.A.; based on Andrzej Sapkowski prose.
// BEGIN modControlledMovement fluid native input gate
@replaceMethod(CR4Player)
function CanSprint( speed : float ) : bool
{
    if( speed <= 0.8f )
    {
        return false;
    }

    if ( CWS_AutomaticSprintRequested() )
    {
    }
    else if ( thePlayer.GetIsSprintToggled() )
    {
    }

    else if(GetLeftStickSprint() && theInput.LastUsedGamepad())
    {
        if(GetIsSprintToggled() && GetIsSprinting())
        {
        }
        else if(!GetIsSprintToggled())
            return false;
    }

    else if ( !sprintActionPressed )
    {
        return false;
    }
    else if( !theInput.IsActionPressed('Sprint') || ( theInput.LastUsedGamepad() && IsInsideInteraction() && GetHowLongSprintButtonWasPressed() < 0.12 ) )
    {
        return false;
    }

    if ( thePlayer.HasBuff( EET_OverEncumbered ) )
    {
        return false;
    }

    if ( !IsSwimming() )
    {
        if ( ShouldUseStaminaWhileSprinting() && !GetIsSprinting() && !IsInCombat() && GetStatPercents(BCS_Stamina) <= 0.9 )
        {
            return false;
        }
        if( ( !IsCombatMusicEnabled() || IsInFistFightMiniGame() ) && ( !IsActionAllowed(EIAB_RunAndSprint) || !IsActionAllowed(EIAB_Sprint) )  )
        {
            return false;
        }
        if( IsTerrainTooSteepToRunUp() )
        {
            return false;
        }
        if( IsInCombatAction() )
        {
            return false;
        }
        if( IsInAir() )
        {
            return false;
        }
        if( IsGuarded() )
        {
            return false;
        }
    }
    if( theGame.IsFocusModeActive() )
    {
        return false;
    }

    return true;
}
// END modControlledMovement fluid native input gate
