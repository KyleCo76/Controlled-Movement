// Remappable step commands, WalkToggle favorites and scoped native wheel ownership.
// Gesture state is deliberately unsaved. Only the settings layer owns selection.
@addField(CPlayerInput) var CWS_Held : bool;
@addField(CPlayerInput) var CWS_NativeHeld : bool;
@addField(CPlayerInput) var CWS_SwallowRelease : bool;
@addField(CPlayerInput) var CWS_UsedWheel : bool;
@addField(CPlayerInput) var CWS_SecondTap : bool;
@addField(CPlayerInput) var CWS_Waiting : bool;
@addField(CPlayerInput) var CWS_PressTime : float;
@addField(CPlayerInput) var CWS_CancelledPressTime : float;
@addField(CPlayerInput) var CWS_Deadline : float;
@addField(CPlayerInput) var CWS_GesturePlayer : CR4Player;
@addField(CPlayerInput) var CWS_GestureContext : name;
@addField(CPlayerInput) var CWS_GestureHorse : W3HorseComponent;
@addField(CPlayerInput) var CWS_LastPoll : float;
@addField(CPlayerInput) var CWS_HasPoll : bool;
@addField(CR4Game) var CWS_Input : CPlayerInput;

@addMethod(CR4Game)
function CWS_SetInput(input : CPlayerInput)
{
    // theGame is a const global reference; assignment belongs to its owner method.
    CWS_Input = input;
}

@addMethod(CPlayerInput)
function CWS_ResetInputGesture()
{
    // Keep ownership of an interrupted press until its release is consumed.
    if (CWS_Held)
    {
        CWS_SwallowRelease = true;
        CWS_CancelledPressTime = CWS_PressTime;
    }
    CWS_Held = false;
    CWS_UsedWheel = false;
    CWS_SecondTap = false;
    CWS_Waiting = false;
    CWS_PressTime = 0.0f;
    CWS_Deadline = 0.0f;
    CWS_GesturePlayer = NULL;
    CWS_GestureContext = '';
    CWS_GestureHorse = NULL;
}

function CWS_ResetGesture()
{
    if (theGame && theGame.CWS_Input)
        theGame.CWS_Input.CWS_ResetInputGesture();
}

@addMethod(CPlayerInput)
function CWS_TickGesture(now : float, eligible : bool)
{
    if (!eligible)
    {
        CWS_ResetInputGesture();
        return;
    }
    if ((CWS_Held && now < CWS_PressTime)
        || (CWS_Waiting && now < CWS_PressTime))
    {
        CWS_ResetInputGesture();
        return;
    }
    // At the exact deadline a second press still qualifies.
    if (CWS_Waiting && now > CWS_Deadline)
    {
        CWS_Waiting = false;
        CWS_RequestActiveFavorite(false);
    }
}

@addMethod(CPlayerInput)
function CWS_PressGesture(now : float)
{
    // A wheel callback may already have claimed this same input frame.
    if (CWS_Held)
        return;
    CWS_TickGesture(now, true);
    CWS_NativeHeld = false;
    CWS_SwallowRelease = false;
    CWS_SecondTap = CWS_Waiting && now <= CWS_Deadline;
    CWS_Waiting = false;
    CWS_Held = true;
    CWS_UsedWheel = false;
    CWS_PressTime = now;
}

@addMethod(CPlayerInput)
function CWS_ReleaseGesture(now : float)
{
    var qualified : bool;
    var selectB : bool;

    if (CWS_SwallowRelease)
    {
        CWS_SwallowRelease = false;
        return;
    }
    if (!CWS_Held)
        return;

    qualified = !CWS_UsedWheel && now >= CWS_PressTime
        && now <= CWS_PressTime + 0.3f;
    selectB = CWS_SecondTap;
    CWS_Held = false;
    CWS_UsedWheel = false;
    CWS_SecondTap = false;
    if (!qualified)
    {
        CWS_Waiting = false;
        return;
    }
    if (selectB)
    {
        CWS_Waiting = false;
        CWS_RequestActiveFavorite(true);
    }
    else
    {
        CWS_Waiting = true;
        CWS_PressTime = now;
        CWS_Deadline = now + 0.3f;
    }
}

@addMethod(CPlayerInput)
function CWS_UseWheel(direction : int)
{
    if (direction == 0 || (CWS_GetState().requireModifier && (!CWS_Held || CWS_SwallowRelease)))
        return;
    CWS_UsedWheel = true;
    CWS_SecondTap = false;
    CWS_Waiting = false;
    CWS_RequestActiveStep(direction);
}

@addMethod(CPlayerInput)
function CWS_CanContinueGesture() : bool
{
    if (!theGame || theGame.CWS_Input != this)
        return false;
    if (!CWS_IsEligible((CR4Player)thePlayer) && !CWS_HorseCanInput((CR4Player)thePlayer) && !CWSS_ProfileActive())
        return false;
    if ((CWS_Held || CWS_Waiting)
        && (CWS_GesturePlayer != (CR4Player)thePlayer
            || CWS_GestureContext != theInput.GetContext()
            || (CWS_GestureHorse && CWS_GestureHorse != thePlayer.GetUsedHorseComponent())))
        return false;
    return true;
}

@addMethod(CPlayerInput)
function CWS_CaptureGestureContext(now : float)
{
    CWS_GesturePlayer = (CR4Player)thePlayer;
    CWS_GestureContext = theInput.GetContext();
    CWS_GestureHorse = NULL;
    if(CWS_GestureContext == 'Horse' || CWS_GestureContext == 'Horse_Replacer_Ciri')
        CWS_GestureHorse = thePlayer.GetUsedHorseComponent();
    CWS_LastPoll = now;
    CWS_HasPoll = true;
}

@addMethod(CPlayerInput)
function CWS_PollInput(now : float)
{
    CWS_GetState().CWS_ObserveMotionInput((CR4Player)thePlayer, now);
    CWS_GetState().CWS_FluidPoll();
    CWS_GetState().CWS_GraphPoll();
    CWS_GetState().CWS_ValueReadoutPoll();
    CWS_GetHorseState().CWSH_Poll();
    // A stopped callback stream must not resume an old favorite or chord.
    if (CWS_HasPoll && (CWS_Held || CWS_Waiting)
        && (now < CWS_LastPoll || now > CWS_LastPoll + 0.5f))
        CWS_ResetInputGesture();
    CWS_LastPoll = now;
    CWS_HasPoll = true;
    CWS_TickGesture(now, CWS_CanContinueGesture());

    // Leave a current release edge for its listener. A later inactive sample
    // means that the listener never received the matching release.
    if (CWS_Held && !theInput.IsActionPressed('WalkToggle')
        && !theInput.IsActionJustReleased('WalkToggle'))
        CWS_ResetInputGesture();
}

@addMethod(CPlayerInput)
function CWS_ClaimWheelChord(now : float) : bool
{
    CWS_PollInput(now);
    if (!CWS_CanContinueGesture())
        return false;
    if (!CWS_GetState().requireModifier)
    {
        // Capture only an actual fresh Walk/Run press if its callback arrives
        // later in this frame, so it cannot erase this adjustment's tap cancel.
        // Ordinary direct input never invents a modifier press.
        if (!CWS_Held && theInput.IsActionPressed('WalkToggle')
            && theInput.IsActionJustPressed('WalkToggle')
            && (!CWS_SwallowRelease || now > CWS_CancelledPressTime))
        {
            CWS_CaptureGestureContext(now);
            CWS_PressGesture(now);
        }
        CWS_UsedWheel = CWS_Held;
        CWS_SecondTap = false;
        CWS_Waiting = false;
        return true;
    }
    if (!theInput.IsActionPressed('WalkToggle'))
        return false;
    if (CWS_SwallowRelease)
    {
        // A genuinely new press recovers from a lost old release, even when
        // this wheel listener precedes OnCommWalkToggle. Never resurrect the
        // cancelled press in its original input frame.
        if (!theInput.IsActionJustPressed('WalkToggle') || now <= CWS_CancelledPressTime)
            return false;
        CWS_SwallowRelease = false;
    }
    if (!CWS_Held)
    {
        // Same-frame callback ordering is unspecified. Claim only a fresh
        // press; a modifier held across a context change is never adopted.
        if (!theInput.IsActionJustPressed('WalkToggle'))
            return false;
        CWS_CaptureGestureContext(now);
        CWS_PressGesture(now);
    }
    CWS_UsedWheel = true;
    CWS_SecondTap = false;
    CWS_Waiting = false;
    return true;
}

@wrapMethod(CPlayerInput)
function Initialize(isFromLoad : bool, optional previousInput : CPlayerInput)
{
    var oldInput : CPlayerInput;

    CWS_GetState().CWS_SuspendMotion();
    CWS_GetState().CWS_FluidRelease();
    CWS_GetState().CWS_GraphRelease();
    CWS_GetState().CWS_CancelValueReadout();
    CWS_GetHorseState().CWSH_Suspend();
    CWS_GetHorseState().CWSH_ReleaseGraph();
    wrappedMethod(isFromLoad, previousInput);
    oldInput = theGame.CWS_Input;
    if (oldInput && oldInput != this)
    {
        oldInput.CWS_ResetInputGesture();
        theInput.UnregisterListener(oldInput, 'CWSWheel');
        theInput.UnregisterListener(oldInput, 'CWSIncrease');
        theInput.UnregisterListener(oldInput, 'CWSDecrease');
        theInput.UnregisterListener(oldInput, 'CWSIncreaseNoModifier');
        theInput.UnregisterListener(oldInput, 'CWSDecreaseNoModifier');
    }
    CWS_ResetInputGesture();
    CWS_HasPoll = false;
    theGame.CWS_SetInput(this);
    // Initialize also runs after load. Keep exactly one mod-owned listener.
    theInput.UnregisterListener(this, 'CWSWheel');
    theInput.UnregisterListener(this, 'CWSIncrease');
    theInput.UnregisterListener(this, 'CWSDecrease');
    theInput.UnregisterListener(this, 'CWSIncreaseNoModifier');
    theInput.UnregisterListener(this, 'CWSDecreaseNoModifier');
    theInput.RegisterListener(this, 'OnCWSIncrease', 'CWSIncrease');
    theInput.RegisterListener(this, 'OnCWSDecrease', 'CWSDecrease');
    theInput.RegisterListener(this, 'OnCWSIncreaseNoModifier', 'CWSIncreaseNoModifier');
    theInput.RegisterListener(this, 'OnCWSDecreaseNoModifier', 'CWSDecreaseNoModifier');
}

@wrapMethod(CPlayerInput)
function Destroy()
{
    CWS_ResetInputGesture();
    CWS_NativeHeld = false;
    theInput.UnregisterListener(this, 'CWSWheel');
    theInput.UnregisterListener(this, 'CWSIncrease');
    theInput.UnregisterListener(this, 'CWSDecrease');
    theInput.UnregisterListener(this, 'CWSIncreaseNoModifier');
    theInput.UnregisterListener(this, 'CWSDecreaseNoModifier');
    if (theGame.CWS_Input == this)
    {
        CWS_GetState().CWS_SuspendMotion();
        CWS_GetState().CWS_FluidRelease();
        CWS_GetState().CWS_GraphRelease();
        CWS_GetState().CWS_CancelValueReadout();
        CWS_GetHorseState().CWSH_Suspend();
        CWS_GetHorseState().CWSH_ReleaseGraph();
        theGame.CWS_SetInput(NULL);
    }
    wrappedMethod();
}

@wrapMethod(CR4Game)
function OnTick()
{
    CWS_StateObject().CWS_ObserveMotionInput((CR4Player)thePlayer, GetEngineTimeAsSeconds());
    CWS_StateObject().CWS_GraphPoll();
    CWS_StateObject().CWS_ValueReadoutPoll();
    CWS_GetHorseState().CWSH_Poll();
    wrappedMethod();
    CWS_StateObject().CWS_FluidPoll();
    CWS_StateObject().CWS_GraphPoll();
    CWS_StateObject().CWS_ValueReadoutPoll();
    CWS_GetHorseState().CWSH_Poll();
    if (CWS_Input)
        CWS_Input.CWS_PollInput(GetEngineTimeAsSeconds());
}

@wrapMethod(CPlayerInput)
function OnCommWalkToggle(action : SInputAction)
{
    var now : float;
    var owned : bool;
    var delegateNative : bool;

    now = theGame.GetEngineTimeAsSeconds();
    owned = CWS_Held || CWS_SwallowRelease;
    CWS_PollInput(now);
    if (IsPressed(action))
    {
        if (!CWS_CanContinueGesture())
        {
            CWS_ResetInputGesture();
            // A fresh native press starts a native pair after interruption.
            CWS_SwallowRelease = false;
            CWS_NativeHeld = true;
            delegateNative = true;
        }
        else
        {
            CWS_NativeHeld = false;
            if (CWS_SwallowRelease && now <= CWS_CancelledPressTime)
                return false;
            if (!CWS_Held)
                CWS_CaptureGestureContext(now);
            CWS_PressGesture(now);
            return false;
        }
    }
    if (!delegateNative)
    {
        if (IsReleased(action) && (owned || CWS_SwallowRelease))
        {
            CWS_ReleaseGesture(now);
            return false;
        }
        // Preserve the release of a press delegated outside scope.
        if (CWS_NativeHeld)
        {
            if (IsReleased(action))
                CWS_NativeHeld = false;
        }
        else if (CWS_Held || CWS_SwallowRelease || CWS_CanContinueGesture())
            return false;
    }
    // The wrapper compiler expands one predecessor-call site, not one per branch.
    return wrappedMethod(action);
}

@addMethod(CPlayerInput)
function CWS_HandleStep(action : SInputAction, direction : int, actionName : name) : bool
{
    var keys : array<EInputKey>;
    var i : int;
    var axis : bool;
    var wheelUp : bool;
    var wheelDown : bool;
    var physicalDirection : int;
    var bound : bool;

    // Inactive profiles must not poll, cancel favorites, or consume input.
    if (CWS_GetState().requireModifier)
    {
        if (actionName != 'CWSIncrease' && actionName != 'CWSDecrease')
            return false;
    }
    else if (actionName != 'CWSIncreaseNoModifier' && actionName != 'CWSDecreaseNoModifier')
        return false;
    theInput.GetPCKeysForAction(actionName, keys);
    for (i = 0; i < keys.Size(); i += 1)
    {
        if (keys[i] != IK_None)
            bound = true;
        if (keys[i] == IK_MouseZ)
            axis = true;
        else if (keys[i] == IK_MouseWheelUp)
            wheelUp = true;
        else if (keys[i] == IK_MouseWheelDown)
            wheelDown = true;
    }
    if (!bound)
        return false;
    // The existing Geralt sign-wheel callback is the sole wheel owner while
    // it remains bound to MouseZ. Added callbacks cannot duplicate its step.
    // Buttons and Ciri (which has no native sign wheel) use this direct route.
    if ((axis || wheelUp || wheelDown) && CWS_NativeWheelOwner())
        return false;
    // MouseZ is the signed axis used by the verified vanilla wheel binding.
    // Both defaults share that axis: each action accepts only its direction.
    // Remapped buttons use a press edge, never held/release events.
    if (axis)
    {
        if ((direction > 0 && action.value <= 2.5f)
            || (direction < 0 && action.value >= -2.5f))
            return false;
        if (action.value > 0.0f)
            physicalDirection = 1;
        else
            physicalDirection = -1;
    }
    else if ((wheelUp || wheelDown) && (action.value > 2.5f || action.value < -2.5f))
    {
        // A discrete wheel rebind selects this action's fixed direction even
        // if native dispatch supplies a large signed delta instead of 1.0.
        if ((action.value > 0.0f && !wheelUp) || (action.value < 0.0f && !wheelDown))
            return false;
        if (action.value > 0.0f)
            physicalDirection = 1;
        else
            physicalDirection = -1;
    }
    else if (!IsPressed(action)
        && !(wheelDown && action.value < -0.7f && action.lastFrameValue >= -0.7f))
        return false;
    else if (wheelUp || wheelDown)
    {
        if (wheelDown && (!wheelUp || action.value < 0.0f))
            physicalDirection = -1;
        else
            physicalDirection = 1;
    }
    if (physicalDirection != 0 && CWS_WheelStep(physicalDirection) != direction)
        return false;
    if (CWS_ClaimWheelChord(theGame.GetEngineTimeAsSeconds()))
    {
        CWS_UseWheel(direction);
        return true;
    }
    return false;
}

@addMethod(CPlayerInput)
event OnCWSIncrease(action : SInputAction)
{
    return CWS_HandleStep(action, 1, 'CWSIncrease');
}

@addMethod(CPlayerInput)
event OnCWSDecrease(action : SInputAction)
{
    return CWS_HandleStep(action, -1, 'CWSDecrease');
}

@addMethod(CPlayerInput)
event OnCWSIncreaseNoModifier(action : SInputAction)
{
    return CWS_HandleStep(action, 1, 'CWSIncreaseNoModifier');
}

@addMethod(CPlayerInput)
event OnCWSDecreaseNoModifier(action : SInputAction)
{
    return CWS_HandleStep(action, -1, 'CWSDecreaseNoModifier');
}

@addMethod(CPlayerInput)
function CWS_ActionUsesWheel(actionName : name, direction : int, axisDirection : int, optional discreteOnly : bool) : bool
{
    var keys : array<EInputKey>;
    var i : int;

    theInput.GetPCKeysForAction(actionName, keys);
    for (i = 0; i < keys.Size(); i += 1)
    {
        if ((!discreteOnly && keys[i] == IK_MouseZ && direction == axisDirection)
            || (direction > 0 && keys[i] == IK_MouseWheelUp)
            || (direction < 0 && keys[i] == IK_MouseWheelDown))
            return true;
    }
    return false;
}

@addMethod(CPlayerInput)
function CWS_NativeWheelOwner() : bool
{
    var keys : array<EInputKey>;
    var i : int;

    if (theInput.GetContext() != 'Exploration')
        return false;
    theInput.GetPCKeysForAction('ToggleSigns', keys);
    for (i = 0; i < keys.Size(); i += 1)
    {
        if (keys[i] == IK_MouseZ)
            return true;
    }
    return false;
}

@addMethod(CPlayerInput)
function CWS_WheelStep(direction : int) : int
{
    var increase, decrease : name;

    if (CWS_GetState().requireModifier)
    {
        increase = 'CWSIncrease';
        decrease = 'CWSDecrease';
    }
    else
    {
        increase = 'CWSIncreaseNoModifier';
        decrease = 'CWSDecreaseNoModifier';
    }
    // An explicit discrete-wheel remap takes precedence over a default axis
    // binding to the same physical direction. Both owners use this decision.
    if (CWS_ActionUsesWheel(increase, direction, 1, true))
        return 1;
    if (CWS_ActionUsesWheel(decrease, direction, -1, true))
        return -1;
    if (CWS_ActionUsesWheel(increase, direction, 1))
        return 1;
    if (CWS_ActionUsesWheel(decrease, direction, -1))
        return -1;
    return 0;
}

@wrapMethod(CPlayerInput)
function OnToggleSigns(action : SInputAction)
{
    var direction : int;
    var step : int;

    // Native wheel delivery is already established for Geralt. Step through
    // that callback rather than suppressing signs and assuming another action
    // will arrive. Remapping either command still governs its wheel direction.
    if (action.value > 2.5f)
        direction = 1;
    else if (action.value < -2.5f)
        direction = -1;
    // Mounted CM actions own stepping; an optional sign binding is only consumed.
    if (direction != 0 && CWS_HorseCanInput((CR4Player)thePlayer)
        && CWS_WheelStep(direction) != 0 && CWS_ClaimWheelChord(theGame.GetEngineTimeAsSeconds()))
        return false;
    if (direction != 0 && CWS_NativeWheelOwner())
    {
        step = CWS_WheelStep(direction);
        if (step != 0 && CWS_ClaimWheelChord(theGame.GetEngineTimeAsSeconds()))
        {
            CWS_UseWheel(step);
            return false;
        }
    }
    return wrappedMethod(action);
}

@wrapMethod(CR4IngameMenu)
function OnChangeKeybind(keybindTag : name, newKeybindValue : EInputKey) : void
{
    var previousEdit : name;

    // Share MouseZ between CM commands and signs without native conflict clearing.
    // This bypass also retains other MouseZ bindings; other keys use native rules.
    if (newKeybindValue == IK_MouseZ
        && (keybindTag == 'CWSIncrease' || keybindTag == 'CWSDecrease'
            || keybindTag == 'CWSIncreaseNoModifier' || keybindTag == 'CWSDecreaseNoModifier'
            || keybindTag == 'ToggleSigns'))
    {
        hasChangedOption = true;
        mInGameConfigWrapper.SetVarValue('PCInput', keybindTag, newKeybindValue + ";IK_None");
        SendKeybindData();
        CWS_ResetGesture();
    }
    else
    {
        previousEdit = CWS_BindingEditAction;
        CWS_BindingEditAction = keybindTag;
        wrappedMethod(keybindTag, newKeybindValue);
        CWS_BindingEditAction = previousEdit;
    }
}

@addField(CR4IngameMenu) var CWS_BindingEditAction : name;

function CWS_BindingProfile(actionName : name) : int
{
    if (actionName == 'CWSIncrease' || actionName == 'CWSDecrease')
        return 1;
    if (actionName == 'CWSIncreaseNoModifier' || actionName == 'CWSDecreaseNoModifier')
        return 2;
    return 0;
}

@wrapMethod(CR4IngameMenu)
function GetKeybindGroupTag(keybindName : name) : name
{
    var editing, candidate : int;

    // During native conflict clearing, mutually exclusive profiles may share keys.
    // Same-profile and foreign conflicts stay native; edit context is call-scoped.
    editing = CWS_BindingProfile(CWS_BindingEditAction);
    candidate = CWS_BindingProfile(keybindName);
    if (editing != 0 && candidate != 0
        && (keybindName == CWS_BindingEditAction || editing != candidate))
        return 'CWS_ExclusiveProfiles';
    return wrappedMethod(keybindName);
}

// Suspend before the predecessor can hand an explicit sprint press to native state.
@wrapMethod(CPlayerInput)
function OnCommSprint(action : SInputAction)
{
    if (IsPressed(action))
        CWS_GetState().CWS_SuspendMotion();
    return wrappedMethod(action);
}

@wrapMethod(CPlayerInput)
function OnCommSprintToggle(action : SInputAction)
{
    if (IsPressed(action))
        CWS_GetState().CWS_SuspendMotion();
    return wrappedMethod(action);
}

@addMethod(CPlayerInput)
function CWS_RequestActiveFavorite(useB : bool)
{
    if(CWSS_ProfileActive()) CWS_GetSwimState().CWSS_RequestFavorite(useB);
    else if(CWS_HorseCanInput((CR4Player)thePlayer)) CWS_GetHorseState().CWSH_RequestFavorite(useB);
    else if(CWS_IsEligible((CR4Player)thePlayer)) CWS_GetState().CWS_RequestFavorite(useB);
}

@addMethod(CPlayerInput)
function CWS_RequestActiveStep(direction : int)
{
    if(CWSS_ProfileActive()) CWS_GetSwimState().CWSS_RequestAdjust(direction);
    else if(CWS_HorseCanInput((CR4Player)thePlayer)) CWS_GetHorseState().CWSH_RequestAdjust(direction);
    else if(CWS_IsEligible((CR4Player)thePlayer)) CWS_GetState().CWS_RequestStep(direction);
}

@wrapMethod(CWS_SwimState)
function CWSS_SetSelectedUnits(units : int, isCommand : bool)
{
    var previous, revision : int;
    var player : CR4Player;
    var input : CPlayerInput;
    var context : name;
    player = (CR4Player)thePlayer;
    input = theGame.CWS_Input;
    if (theInput) context = theInput.GetContext();
    previous = CWSS_SelectedUnits();
    revision = CWSS_CommandRevision();
    if (isCommand) revision += 1;
    wrappedMethod(units, isCommand);
    if (showSpeedChanges && previous != CWSS_SelectedUnits() && CWSS_ProfileActive())
    {
        if (revision == CWSS_CommandRevision() && player == thePlayer
            && input == theGame.CWS_Input && theInput && context == theInput.GetContext())
            CWS_GetState().CWS_PresentValueChange(CWSS_SelectedUnits(), false, true);
    }
}
