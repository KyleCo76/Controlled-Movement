// BEGIN modControlledMovement swimmingPlayback
// Native movement owns requests and damping; CM owns ordinary clip playback only.
@addMethod(CR4Player)
public function CWSS_IsDefaultController(controller : CR4LocomotionPlayerControllerScript) : bool
{
    return controller && defaultLocomotionController == controller;
}

function CWSS_IsEligible(player : CR4Player) : bool
{
    var physical : CMovingPhysicalAgentComponent;
    var witcher : W3PlayerWitcher;
    var ciri : W3ReplacerCiri;
    var context : name;
    if (!player || player != thePlayer || !theGame || !theInput) return false;
    witcher = (W3PlayerWitcher)player;
    ciri = (W3ReplacerCiri)player;
    if (!witcher && !ciri) return false;
    if (!CWS_GetSwimState().CWSS_CanUseControls() || !player.GetInputHandler()
        || player.GetInputHandler() != theGame.CWS_Input) return false;
    if (!theInput.LastUsedPCInput() || theInput.LastUsedGamepad()) return false;
    if (!theGame.IsActive() || theGame.IsPaused() || theGame.IsFading() || theGame.IsBlackscreen()
        || theGame.GetGuiManager().IsAnyMenu() || player.IsUITakeInput()) return false;
    context = theInput.GetContext();
    if (context != 'Swimming' && context != 'Diving') return false;
    if (player.GetCurrentStateName() != 'Swimming' || !player.IsSwimming()) return false;
    physical = (CMovingPhysicalAgentComponent)player.GetMovingAgentComponent();
    if (!physical || physical.GetPhysicalState() != CPS_Swimming || physical.IsDiving() != (context == 'Diving')) return false;
    if (!player.substateManager || !player.IsAlive() || !player.GetIsMovable()
        || !player.GetBIsInputAllowed() || !player.CanUpdateMovement()) return false;
    if (player.IsInCombatAction() || player.IsInCombatActionFriendly() || player.GetBInteractionPressed()) return false;
    if (player.IsInGameplayScene() || theGame.IsCurrentlyPlayingNonGameplayScene()
        || player.IsOnBoat() || player.GetUsedVehicle() || player.IsInAir()
        || player.modifyPlayerSpeed || player.IsCameraControlDisabled('Finisher')) return false;
    if (player.GetIsSprinting() || player.GetIsSprintToggled() || player.IsSprintActionPressed()
        || theInput.IsActionPressed('Sprint') || player.HasBuff(EET_OverEncumbered)
        || !player.IsActionAllowed(EIAB_RunAndSprint) || !player.IsActionAllowed(EIAB_Sprint)) return false;
    if (player.rangedWeapon && player.rangedWeapon.GetCurrentStateName() != 'State_WeaponWait'
        && player.rangedWeapon.GetCurrentStateName() != 'State_WeaponHolster') return false;
    return player.GetBehaviorVariable('dodgeBoost') == 0.0f;
}

function CWSS_ProfileActive() : bool
{
    return CWSS_IsEligible(thePlayer) && CWS_GetSwimState().CWSS_StateControls(thePlayer);
}

@addField(CWS_SwimState) private var CWSS_actor : CR4Player;
@addField(CWS_SwimState) private var CWSS_controller : CR4LocomotionPlayerControllerScript;
@addField(CWS_SwimState) private var CWSS_resident : bool;
@addField(CWS_SwimState) private var CWSS_waterConfirmed : bool;
@addField(CWS_SwimState) private var CWSS_landKnown : bool;
@addField(CWS_SwimState) private var CWSS_landEnabled : bool;
@addField(CWS_SwimState) private var CWSS_enterPending : bool;
@addField(CWS_SwimState) private var CWSS_exitPending : bool;
@addField(CWS_SwimState) private var CWSS_transferUnits : int;
@addField(CWS_SwimState) private var CWSS_transferRevision : int;
@addField(CWS_SwimState) private var CWSS_epoch : int;
@addField(CWS_SwimState) private var CWSS_stopArmed : bool;
@addField(CWS_SwimState) private var CWSS_stopPending : bool;
@addField(CWS_SwimState) private var CWSS_stopRevision : int;
@addField(CWS_SwimState) private var CWSS_stopTime : float;

@addMethod(CWS_SwimState)
public function CWSS_StateControls(actor : CR4Player) : bool
{
    if (!actor || actor != CWSS_actor || !CWSS_controller) return false;
    return actor.CWSS_IsDefaultController(CWSS_controller);
}

@addMethod(CWS_SwimState)
public function CWSS_StateOwnedBy(actor : CR4Player, controller : CR4LocomotionPlayerControllerScript) : bool
{
    if (!actor || !controller) return false;
    return actor == CWSS_actor && controller == CWSS_controller;
}

@addMethod(CWS_SwimState)
public function CWSS_StateEpoch() : int
{
    return CWSS_epoch;
}

@addMethod(CWS_SwimState)
public function CWSS_StateSuspend()
{
    CWSS_enterPending = false;
    CWSS_exitPending = false;
    CWSS_StateOutputSuspend();
}

@addMethod(CWS_SwimState)
private function CWSS_StateOutputSuspend()
{
    var controller : CR4LocomotionPlayerControllerScript;
    controller = CWSS_controller;
    CWSS_controller = NULL;
    CWSS_epoch += 1;
    CWSS_stopArmed = false;
    CWSS_stopPending = false;
    if (controller) controller.CWSS_ControllerRelease();
}

@addMethod(CWS_SwimState)
public function CWSS_StateControllerLost(controller : CR4LocomotionPlayerControllerScript)
{
    // Ordinary action handoffs retain the entry/shore boundary and its revision.
    if (CWSS_controller == controller) CWSS_StateOutputSuspend();
}

@addMethod(CWS_SwimState)
public function CWSS_StateReset()
{
    CWSS_StateSuspend();
    CWSS_actor = NULL;
    CWSS_controller = NULL;
    CWSS_resident = false;
    CWSS_waterConfirmed = false;
    CWSS_landKnown = false;
    CWSS_landEnabled = false;
}

@addMethod(CWS_SwimState)
public function CWSS_StateController(controller : CR4LocomotionPlayerControllerScript)
{
    if (CWSS_controller != controller)
    {
        if (CWSS_controller) CWSS_controller.CWSS_ControllerRelease();
        CWSS_controller = controller;
    }
}

@addMethod(CWS_SwimState)
public function CWSS_StateEnter(actor : CR4Player, previous : name)
{
    if (actor != thePlayer) return;
    if (CWSS_actor && CWSS_actor != actor) CWSS_StateReset();
    CWSS_actor = actor;
    if (previous == 'AimThrow' || CWSS_resident) return;
    CWSS_enterPending = CWSS_landKnown && CWSS_landEnabled && enabled && CWS_GetState().enabled
        && (previous == 'Exploration') && !actor.IsOnBoat() && !actor.GetUsedVehicle();
    CWSS_transferUnits = CWS_GetState().CWS_SelectedUnits();
    CWSS_transferRevision = CWSS_CommandRevision();
    CWSS_landKnown = false;
    CWSS_exitPending = false;
    CWSS_resident = true;
    CWSS_waterConfirmed = false;
    CWSS_stopArmed = false;
    CWSS_stopPending = false;
}

@addMethod(CWS_SwimState)
public function CWSS_StateLeave(actor : CR4Player, nextState : name)
{
    if (actor != CWSS_actor || nextState == 'AimThrow') return;
    CWSS_enterPending = false;
    CWSS_exitPending = CWSS_resident && CWSS_waterConfirmed && enabled && CWS_GetState().enabled
        && (nextState == 'Exploration' || nextState == 'TraverseExploration' || nextState == 'Falling');
    CWSS_transferUnits = CWSS_SelectedUnits();
    CWSS_transferRevision = CWS_GetState().CWS_PlayerCommandRevision();
    CWSS_stopArmed = false;
    CWSS_stopPending = false;
    if (CWSS_controller) CWSS_controller.CWSS_ControllerRelease();
}

@addMethod(CWS_SwimState)
public function CWSS_StateObserve(actor : CR4Player, optional controller : CR4LocomotionPlayerControllerScript)
{
    var physical : CMovingPhysicalAgentComponent;
    var units, revision, observedEpoch : int;
    if (!actor || actor != thePlayer || !actor.IsAlive() || actor.IsOnBoat() || actor.GetUsedVehicle())
    {
        CWSS_StateReset();
        return;
    }
    if (CWSS_actor && CWSS_actor != actor) CWSS_StateReset();
    CWSS_actor = actor;
    if (controller)
    {
        if (actor.CWSS_IsDefaultController(controller)) CWSS_StateController(controller);
        else CWSS_StateOutputSuspend();
    }
    observedEpoch = CWSS_epoch;
    if (!enabled || !CWS_GetState().enabled)
    {
        CWSS_enterPending = false;
        CWSS_exitPending = false;
    }
    physical = (CMovingPhysicalAgentComponent)actor.GetMovingAgentComponent();
    if (physical && physical.GetPhysicalState() == CPS_Swimming && actor.IsSwimming())
    {
        if (!CWSS_resident) CWSS_resident = true;
        CWSS_waterConfirmed = true;
        CWSS_landKnown = false;
        // Physical toggles alone cannot prove an active ordinary controller.
        if (CWSS_enterPending && controller && CWSS_StateControls(actor) && CWSS_IsEligible(actor)
            && actor.CWSS_IsDefaultController(controller) && CWSS_enterPending
            && CWSS_epoch == observedEpoch && CWSS_controller == controller && actor == thePlayer)
        {
            units = CWSS_transferUnits;
            revision = CWSS_transferRevision;
            CWSS_enterPending = false;
            if (enabled && CWS_GetState().enabled && revision == CWSS_CommandRevision())
                CWSS_SetSelectedUnits(units, true);
        }
        return;
    }
    if (!CWS_IsEligible(actor)) return;
    units = CWSS_transferUnits;
    revision = CWSS_transferRevision;
    if (CWSS_exitPending)
    {
        CWSS_exitPending = false;
        if (enabled && CWS_GetState().enabled && revision == CWS_GetState().CWS_PlayerCommandRevision())
            CWS_GetState().CWS_AcceptSwimSelection(units);
    }
    CWSS_resident = false;
    CWSS_waterConfirmed = false;
    CWSS_enterPending = false;
    CWSS_landKnown = true;
    CWSS_landEnabled = enabled && CWS_GetState().enabled;
}

@addMethod(CWS_SwimState)
public function CWSS_StateStop(eligible : bool, moving : bool, now : float)
{
    if (!eligible || now - now != 0.0f)
    {
        CWSS_stopArmed = false;
        CWSS_stopPending = false;
        return;
    }
    if (moving)
    {
        CWSS_stopArmed = true;
        CWSS_stopPending = false;
        CWSS_stopRevision = CWSS_CommandRevision();
        return;
    }
    if (!CWSS_stopArmed || CWSS_stopRevision != CWSS_CommandRevision())
    {
        CWSS_stopArmed = false;
        CWSS_stopPending = false;
        return;
    }
    if (!CWSS_stopPending)
    {
        CWSS_stopPending = true;
        CWSS_stopTime = now;
    }
    if (now < CWSS_stopTime)
    {
        CWSS_stopArmed = false;
        CWSS_stopPending = false;
    }
    else if (now - CWSS_stopTime > 1.0f)
    {
        CWSS_stopArmed = false;
        CWSS_stopPending = false;
        CWSS_SetSelectedUnits(CWSS_ClampUnits(startSpeedUnits), false);
    }
}

@addField(CR4LocomotionPlayerControllerScript) private var CWSS_busy : bool;
@addField(CR4LocomotionPlayerControllerScript) private var CWSS_frame : bool;
@addField(CR4LocomotionPlayerControllerScript) private var CWSS_calculated : bool;
@addField(CR4LocomotionPlayerControllerScript) private var CWSS_corrected : bool;
@addField(CR4LocomotionPlayerControllerScript) private var CWSS_framePlayer : CR4Player;
@addField(CR4LocomotionPlayerControllerScript) private var CWSS_owner : CR4Player;
@addField(CR4LocomotionPlayerControllerScript) private var CWSS_frameInput : CPlayerInput;
@addField(CR4LocomotionPlayerControllerScript) private var CWSS_context : name;
@addField(CR4LocomotionPlayerControllerScript) private var CWSS_frameEpoch : int;
@addField(CR4LocomotionPlayerControllerScript) private var CWSS_frameToken : int;
@addField(CR4LocomotionPlayerControllerScript) private var CWSS_activeToken : int;
@addField(CR4LocomotionPlayerControllerScript) private var CWSS_native : float;
@addField(CR4LocomotionPlayerControllerScript) private var CWSS_applied : float;
@addField(CR4LocomotionPlayerControllerScript) private var CWSS_ownGate : bool;
@addField(CR4LocomotionPlayerControllerScript) private var CWSS_ownFactor : bool;
@addField(CR4LocomotionPlayerControllerScript) private var CWSS_reason : string;

@addMethod(CR4LocomotionPlayerControllerScript)
public function CWSS_ControllerRelease()
{
    var owner : CR4Player;
    var factor, actual : float;
    var ownedGate, ownedFactor : bool;
    owner = CWSS_owner;
    factor = CWSS_applied;
    ownedGate = CWSS_ownGate;
    ownedFactor = CWSS_ownFactor;
    CWSS_owner = NULL;
    CWSS_ownGate = false;
    CWSS_ownFactor = false;
    if (!owner) return;
    actual = owner.GetBehaviorVariable('CWS_SwimGraphEnabled', -9876.5f);
    if (ownedGate && actual == 1.0f) owner.SetBehaviorVariable('CWS_SwimGraphEnabled', 0.0f);
    actual = owner.GetBehaviorVariable('CWS_SwimPlayback', -9876.5f);
    if (ownedFactor && actual == factor) owner.SetBehaviorVariable('CWS_SwimPlayback', 1.0f);
}

@addMethod(CR4LocomotionPlayerControllerScript)
private function CWSS_ControllerCurrent() : bool
{
    return CWSS_frame && CWSS_frameToken == CWSS_activeToken && player == CWSS_framePlayer && player == thePlayer
        && theGame.CWS_Input == CWSS_frameInput && CWS_GetSwimState().enabled
        && CWS_GetSwimState().CWSS_StateEpoch() == CWSS_frameEpoch
        && CWS_GetSwimState().CWSS_StateOwnedBy(player, this);
}

@addMethod(CR4LocomotionPlayerControllerScript)
private function CWSS_ControllerScope() : bool
{
    return CWSS_ControllerCurrent() && CWSS_IsEligible(player) && player.CWSS_IsDefaultController(this)
        && player.GetInputHandler() == CWSS_frameInput && theInput.GetContext() == CWSS_context
        && CWSS_ControllerCurrent();
}

@addMethod(CR4LocomotionPlayerControllerScript)
private function CWSS_ControllerMoving() : bool
{
    return theInput.GetActionValue('GI_AxisLeftX') != 0.0f || theInput.GetActionValue('GI_AxisLeftY') != 0.0f
        || (CWSS_context == 'Diving' && (theInput.IsActionPressed('DiveUp') || theInput.IsActionPressed('DiveDown')));
}

@addMethod(CR4LocomotionPlayerControllerScript)
private function CWSS_ControllerOrdinary() : bool
{
    var vertical, horizontal : bool;
    var gait, overlay, ik, expected : float;
    if (!CWSS_calculated || CWSS_corrected || !CWSS_ControllerScope() || moveSpeed != CWSS_native) return false;
    horizontal = theInput.GetActionValue('GI_AxisLeftX') != 0.0f || theInput.GetActionValue('GI_AxisLeftY') != 0.0f;
    vertical = CWSS_context == 'Diving' && (theInput.IsActionPressed('DiveUp') || theInput.IsActionPressed('DiveDown'));
    if (horizontal)
    {
        if (player.playerMoveType == PMT_Run) expected = speedRunning;
        else if (player.playerMoveType == PMT_Walk) expected = speedWalkingMax;
        else return false;
        if (CWSS_native != expected || speedRunning != 1.0f || speedWalkingMax != 0.6f) return false;
    }
    else if (CWSS_native != 0.0f || player.playerMoveType != PMT_Idle) return false;
    if (!horizontal && !vertical && CWSS_native != 0.0f) return false;
    if (player.GetBehaviorVariable('forceWalkSpeed') != 0.0f) return false;
    gait = player.GetBehaviorVariable('playerMoveType', -9876.5f);
    overlay = player.GetBehaviorVariable('playerMoveTypeForOverlay', -9876.5f);
    ik = player.GetBehaviorVariable('ikWeight', -9876.5f);
    if (gait != -9876.5f && gait != (float)(int)player.playerMoveType) return false;
    if (overlay != -9876.5f && overlay != (float)(int)player.playerMoveType) return false;
    expected = 1.0f;
    if (player.playerMoveType == PMT_Run) expected = 0.0f;
    if (ik != -9876.5f && ik != expected) return false;
    return CWSS_ControllerScope() && moveSpeed == CWSS_native;
}

@addMethod(CR4LocomotionPlayerControllerScript)
private function CWSS_ControllerIdle() : bool
{
    // Native stopping may retain a cached coast after the zero calculation.
    return CWSS_calculated && !CWSS_corrected && CWSS_native == 0.0f && player.playerMoveType == PMT_Idle
        && !CWSS_ControllerMoving() && CWSS_ControllerScope()
        && player.GetBehaviorVariable('forceWalkSpeed') == 0.0f && CWSS_ControllerCurrent();
}

@addMethod(CR4LocomotionPlayerControllerScript)
private function CWSS_ControllerIdleLease() : bool
{
    var gate, factor : float;
    if (!CWSS_ControllerScope()) return false;
    gate = player.GetBehaviorVariable('CWS_SwimGraphEnabled', -9876.5f);
    factor = player.GetBehaviorVariable('CWS_SwimPlayback', -9876.5f);
    if (!CWSS_ControllerCurrent()) return false;
    if (CWSS_owner)
        return CWSS_owner == player && CWSS_ownGate && CWSS_ownFactor
            && gate == 1.0f && factor == CWSS_applied;
    return gate == 0.0f && factor == 1.0f;
}

@addMethod(CR4LocomotionPlayerControllerScript)
public function CWSS_ControllerApply()
{
    var desired, gate, factor : float;
    var accepted : bool;
    CWSS_reason = "scope";
    if (!CWSS_ControllerOrdinary() || !CWSS_ControllerMoving() || !CWSS_ControllerCurrent())
    {
        CWSS_ControllerRelease();
        return;
    }
    gate = player.GetBehaviorVariable('CWS_SwimGraphEnabled', -9876.5f);
    factor = player.GetBehaviorVariable('CWS_SwimPlayback', -9876.5f);
    if (!CWSS_ControllerOrdinary() || !CWSS_ControllerCurrent()) { CWSS_ControllerRelease(); return; }
    CWSS_reason = "foreign-or-unavailable";
    if (CWSS_owner && (CWSS_owner != player || !CWSS_ownGate || !CWSS_ownFactor || gate != 1.0f || factor != CWSS_applied))
    {
        CWSS_ControllerRelease();
        return;
    }
    if (!CWSS_owner && (gate != 0.0f || factor != 1.0f)) return;
    desired = (float)CWS_GetSwimState().CWSS_SelectedUnits() / 100.0f;
    if (!CWSS_ControllerCurrent()) return;
    CWSS_owner = player;
    if (!CWSS_ownFactor || factor != desired)
    {
        CWSS_ownFactor = true;
        CWSS_applied = desired;
        accepted = player.SetBehaviorVariable('CWS_SwimPlayback', desired);
        if (!accepted || !CWSS_ControllerOrdinary() || !CWSS_ControllerCurrent()) { CWSS_ControllerRelease(); return; }
    }
    factor = player.GetBehaviorVariable('CWS_SwimPlayback', -9876.5f);
    if (factor != desired || !CWSS_ControllerOrdinary() || !CWSS_ControllerCurrent()) { CWSS_ControllerRelease(); return; }
    if (!CWSS_ownGate)
    {
        gate = player.GetBehaviorVariable('CWS_SwimGraphEnabled', -9876.5f);
        if (gate != 0.0f || !CWSS_ControllerOrdinary() || !CWSS_ControllerCurrent()) { CWSS_ControllerRelease(); return; }
        CWSS_ownGate = true;
        accepted = player.SetBehaviorVariable('CWS_SwimGraphEnabled', 1.0f);
        if (!accepted || !CWSS_ControllerOrdinary() || !CWSS_ControllerCurrent()) { CWSS_ControllerRelease(); return; }
    }
    gate = player.GetBehaviorVariable('CWS_SwimGraphEnabled', -9876.5f);
    factor = player.GetBehaviorVariable('CWS_SwimPlayback', -9876.5f);
    if (gate != 1.0f || factor != desired || !CWSS_ControllerOrdinary() || !CWSS_ControllerCurrent()) { CWSS_ControllerRelease(); return; }
    CWSS_reason = "applied";
}

@wrapMethod(CR4LocomotionPlayerControllerScript)
function MakeInputReady()
{
    // The pinned native update calls this after calculation only for correction.
    if (CWSS_frame && CWSS_calculated) CWSS_corrected = true;
    wrappedMethod();
}

@wrapMethod(CR4LocomotionPlayerControllerScript)
function CalculateMoveSpeed() : float
{
    var result : float;
    result = wrappedMethod();
    if (CWSS_ControllerCurrent())
    {
        CWSS_native = result;
        CWSS_calculated = true;
    }
    return result;
}

@wrapMethod(CR4LocomotionPlayerControllerScript)
function UpdateLocomotion()
{
    var eligible, moving, idleLease, nested : bool;
    var swimState : CWS_SwimState;
    swimState = CWS_GetSwimState();
    nested = CWSS_busy;
    if (nested)
    {
        CWSS_frameToken += 1;
        CWSS_frame = false;
        CWSS_ControllerRelease();
    }
    else
    {
        CWSS_busy = true;
        CWSS_frameToken += 1;
        CWSS_activeToken = CWSS_frameToken;
        // Cancellation during observation cannot become this frame's new baseline.
        CWSS_frameEpoch = swimState.CWSS_StateEpoch();
        CWSS_framePlayer = player;
        CWSS_frameInput = player.GetInputHandler();
        CWSS_context = theInput.GetContext();
        if (CWSS_frameEpoch == swimState.CWSS_StateEpoch() && CWSS_frameToken == CWSS_activeToken)
            swimState.CWSS_StateObserve(player, this);
        CWSS_frame = CWSS_frameEpoch == swimState.CWSS_StateEpoch() && CWSS_frameToken == CWSS_activeToken
            && swimState.CWSS_StateOwnedBy(player, this) && CWSS_IsEligible(player)
            && player.CWSS_IsDefaultController(this);
        CWSS_calculated = false;
        CWSS_corrected = false;
    }
    // One lexical predecessor lets the SDK bind both runtime paths.
    wrappedMethod();
    if (nested) return;
    eligible = CWSS_ControllerOrdinary() || CWSS_ControllerIdle();
    moving = eligible && CWSS_ControllerMoving();
    // Preserve a normal owned-to-neutral release; a foreign owner cancels idle.
    idleLease = !moving && CWSS_ControllerIdleLease();
    CWSS_ControllerApply();
    swimState.CWSS_StateStop(eligible && ((moving && CWSS_reason == "applied")
        || (!moving && idleLease && CWSS_ControllerIdleLease()))
        && CWSS_ControllerScope() && CWSS_ControllerCurrent(), moving, theGame.GetEngineTimeAsSeconds());
    CWSS_ControllerTrace();
    CWSS_frame = false;
    CWSS_busy = false;
}

@wrapMethod(CR4LocomotionPlayerControllerScript)
function Deactivate()
{
    CWSS_frameToken += 1;
    CWSS_frame = false;
    CWSS_ControllerRelease();
    CWS_GetSwimState().CWSS_StateControllerLost(this);
    wrappedMethod();
}

@wrapMethod(CR4PlayerStateSwimming)
function OnEnterState(prevStateName : name)
{
    CWS_GetSwimState().CWSS_StateEnter(parent, prevStateName);
    return wrappedMethod(prevStateName);
}

@wrapMethod(CR4PlayerStateSwimming)
function OnLeaveState(nextStateName : name)
{
    CWS_GetSwimState().CWSS_StateLeave(parent, nextStateName);
    return wrappedMethod(nextStateName);
}

@wrapMethod(CR4PlayerStateSwimming)
function ToggleSwimming(toggle : bool, optional ignorePAC : bool)
{
    wrappedMethod(toggle, ignorePAC);
    CWS_GetSwimState().CWSS_StateObserve(parent);
}

@wrapMethod(CR4PlayerStateSwimming)
function ToggleDiving(toggle : bool)
{
    wrappedMethod(toggle);
    CWS_GetSwimState().CWSS_StateObserve(parent);
}

@wrapMethod(CR4Player)
function OnSpawned(spawnData : SEntitySpawnData)
{
    CWS_GetSwimState().CWSS_StateReset();
    CWS_GetSwimState().CWSS_ResetSpawn();
    wrappedMethod(spawnData);
}

@wrapMethod(CPlayerInput)
function Initialize(isFromLoad : bool, optional previousInput : CPlayerInput)
{
    CWS_GetSwimState().CWSS_StateReset();
    wrappedMethod(isFromLoad, previousInput);
}

@wrapMethod(CR4Game)
function OnBeforeWorldChange(worldName : string)
{
    CWS_GetSwimState().CWSS_StateReset();
    wrappedMethod(worldName);
}

@wrapMethod(CR4Game)
function OnGameEnded()
{
    CWS_GetSwimState().CWSS_StateReset();
    wrappedMethod();
}

@addField(CR4Game) private var CWSS_traceEnabled : bool;
@addField(CR4LocomotionPlayerControllerScript) private var CWSS_traceHasTime : bool;
@addField(CR4LocomotionPlayerControllerScript) private var CWSS_tracePoint : bool;
@addField(CR4LocomotionPlayerControllerScript) private var CWSS_traceTime : float;
@addField(CR4LocomotionPlayerControllerScript) private var CWSS_pointTime : float;
@addField(CR4LocomotionPlayerControllerScript) private var CWSS_point : Vector;
@addField(CR4LocomotionPlayerControllerScript) private var CWSS_pointContext : name;
@addField(CR4LocomotionPlayerControllerScript) private var CWSS_pointPlayer : CR4Player;
@addField(CR4LocomotionPlayerControllerScript) private var CWSS_pointInput : CPlayerInput;
@addField(CR4LocomotionPlayerControllerScript) private var CWSS_pointRevision : int;
@addField(CR4LocomotionPlayerControllerScript) private var CWSS_pointEpoch : int;

@addMethod(CR4Game)
public function CWSS_GameTrace(enabled : bool)
{
    CWSS_traceEnabled = enabled;
}

@addMethod(CR4Game)
public function CWSS_GameTracing() : bool
{
    return CWSS_traceEnabled;
}

exec function CM_SwimTrace(enabled : bool)
{
    theGame.CWSS_GameTrace(enabled);
}

@addMethod(CR4LocomotionPlayerControllerScript)
private function CWSS_ControllerTrace()
{
    var now, elapsed, displacement, gate, factor : float;
    var position, velocity : Vector;
    var revision : int;
    var text : string;
    if (!theGame.CWSS_GameTracing()) { CWSS_traceHasTime = false; CWSS_tracePoint = false; return; }
    if (!CWSS_ControllerOrdinary() || CWSS_reason != "applied") CWSS_tracePoint = false;
    now = theGame.GetEngineTimeAsSeconds();
    revision = CWS_GetSwimState().CWSS_CommandRevision();
    if (CWSS_pointPlayer != player || CWSS_pointInput != CWSS_frameInput || CWSS_pointContext != CWSS_context
        || CWSS_pointRevision != revision || CWSS_pointEpoch != CWSS_frameEpoch || now < CWSS_traceTime) CWSS_tracePoint = false;
    if (CWSS_traceHasTime && now >= CWSS_traceTime && now - CWSS_traceTime < 1.0f) return;
    CWSS_traceHasTime = true;
    CWSS_traceTime = now;
    gate = player.GetBehaviorVariable('CWS_SwimGraphEnabled', -9876.5f);
    factor = player.GetBehaviorVariable('CWS_SwimPlayback', -9876.5f);
    text = "CM_SWIM schema=3 build=1.4.0-preview.1 selected=" + IntToString(CWS_GetSwimState().CWSS_SelectedUnits())
        + " context=" + NameToString(CWSS_context) + " native=" + FloatToStringPrec(CWSS_native, 2)
        + " current=" + FloatToStringPrec(moveSpeed, 2) + " gate=" + FloatToStringPrec(gate, 2)
        + " factor=" + FloatToStringPrec(factor, 2) + " reason=" + CWSS_reason;
    if (CWSS_reason == "applied" && CWSS_ControllerOrdinary() && CWSS_ControllerCurrent())
    {
        velocity = player.GetMovingAgentComponent().GetVelocity();
        if (!CWSS_ControllerOrdinary() || !CWSS_ControllerCurrent()) { CWSS_tracePoint = false; CWSS_ControllerRelease(); return; }
        if (revision != CWS_GetSwimState().CWSS_CommandRevision()) { CWSS_tracePoint = false; return; }
        position = player.GetWorldPosition();
        if (!CWSS_ControllerOrdinary() || !CWSS_ControllerCurrent() || !theGame.CWSS_GameTracing()) { CWSS_tracePoint = false; CWSS_ControllerRelease(); return; }
        if (revision != CWS_GetSwimState().CWSS_CommandRevision()) { CWSS_tracePoint = false; return; }
        elapsed = now - CWSS_pointTime;
        displacement = -1.0f;
        if (CWSS_tracePoint && CWSS_pointContext == CWSS_context && elapsed > 0.0f)
            displacement = VecDistance(position, CWSS_point) / elapsed;
        text += " velocity=" + FloatToStringPrec(VecLength(velocity), 3) + " worldSpeed=" + FloatToStringPrec(displacement, 3);
        CWSS_pointPlayer = player;
        CWSS_pointInput = CWSS_frameInput;
        CWSS_pointRevision = revision;
        CWSS_pointEpoch = CWSS_frameEpoch;
        CWSS_point = position;
        CWSS_pointTime = now;
        CWSS_pointContext = CWSS_context;
        CWSS_tracePoint = true;
    }
    if (theGame.CWSS_GameTracing()) LogChannel('CM_SWIM', text);
}
// END modControlledMovement swimmingPlayback
