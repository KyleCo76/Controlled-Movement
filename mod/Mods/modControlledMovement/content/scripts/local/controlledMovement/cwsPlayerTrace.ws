// Session-only observation. Physical intervals are evidence, never movement inputs.
@addField(CR4Game) public var CWS_playerTraceEnabled : bool;
@addField(CR4Game) public var CWS_playerTraceEpoch : int;

exec function CM_PlayerTrace(mode : int)
{
    var game : CR4Game;
    game = theGame;
    if (!game || (mode != 0 && mode != 1))
        return;
    if (game.CWS_playerTraceEnabled == (mode == 1))
        return;
    game.CWS_playerTraceEnabled = mode == 1;
    game.CWS_playerTraceEpoch += 1;
    if (mode == 1)
        LogChannel('CM_PLAYER', "CM_PLAYER schema=1 build=1.4.0-movement-probe.1 event=start");
    else
        LogChannel('CM_PLAYER', "CM_PLAYER schema=1 build=1.4.0-movement-probe.1 event=stop");
}

@addMethod(CPlayer)
public function CWS_PlayerTraceSprintTimer() : bool
{
    return disableSprintingTimerEnabled;
}

@addField(CR4LocomotionPlayerControllerScript) private var cwsTraceInterval : bool;
@addField(CR4LocomotionPlayerControllerScript) private var cwsTraceEpoch : int;
@addField(CR4LocomotionPlayerControllerScript) private var cwsTraceCommand : int;
@addField(CR4LocomotionPlayerControllerScript) private var cwsTraceRevision : int;
@addField(CR4LocomotionPlayerControllerScript) private var cwsTracePlayer : CR4Player;
@addField(CR4LocomotionPlayerControllerScript) private var cwsTraceInput : CPlayerInput;
@addField(CR4LocomotionPlayerControllerScript) private var cwsTraceContext : name;
@addField(CR4LocomotionPlayerControllerScript) private var cwsTracePhase : name;
@addField(CR4LocomotionPlayerControllerScript) private var cwsTraceSelected : float;
@addField(CR4LocomotionPlayerControllerScript) private var cwsTraceMaster : bool;
@addField(CR4LocomotionPlayerControllerScript) private var cwsTraceOwned : bool;
@addField(CR4LocomotionPlayerControllerScript) private var cwsTraceMode : bool;
@addField(CR4LocomotionPlayerControllerScript) private var cwsTraceTrueSteps : bool;
@addField(CR4LocomotionPlayerControllerScript) private var cwsTracePosition : Vector;
@addField(CR4LocomotionPlayerControllerScript) private var cwsTraceTime : float;
@addField(CR4LocomotionPlayerControllerScript) private var cwsTraceFrameTime : float;
@addField(CR4LocomotionPlayerControllerScript) private var cwsTraceLastLog : float;
@addField(CR4LocomotionPlayerControllerScript) private var cwsTraceHasLog : bool;
@addField(CR4LocomotionPlayerControllerScript) private var cwsTraceBusy : bool;

@addMethod(CR4LocomotionPlayerControllerScript)
private function CWS_PlayerTraceScope() : bool
{
    // Deliberately independent of the CM master and automatic-sprint eligibility.
    return theGame && theInput && theGame.CWS_playerTraceEnabled
        && player && player == thePlayer && player == cwsFramePlayer
        && cwsFrameInput && cwsFrameInput == theGame.CWS_Input
        && cwsFrameContext == theInput.GetContext()
        && !cwsFrameInvalid && cwsFrameCalculated
        && cwsFrameCommand == CWS_GetState().CWS_PlayerCommandRevision()
        && CWS_GetState().CWS_IsPlayerController(this)
        && theInput.LastUsedPCInput() && theGame.IsActive() && !theGame.IsPaused()
        && !theGame.IsFading() && !theGame.IsBlackscreen()
        && !theGame.GetGuiManager().IsAnyMenu() && !player.IsUITakeInput()
        && (cwsFrameContext == 'Exploration' || cwsFrameContext == 'Exploration_Replacer_Ciri')
        && player.GetCurrentStateName() == 'Exploration'
        && player.IsAlive() && player.GetIsMovable() && player.GetBIsInputAllowed()
        && player.CanUpdateMovement() && !player.IsInAir() && !player.IsSwimming()
        && !player.IsOnBoat() && !player.GetUsedVehicle()
        && !player.IsInCombat() && !player.IsInCombatAction() && !player.IsInCombatActionFriendly()
        && !player.GetBInteractionPressed() && !player.IsInGameplayScene()
        && !theGame.IsCurrentlyPlayingNonGameplayScene();
}

@addMethod(CR4LocomotionPlayerControllerScript)
private function CWS_PlayerTraceSame() : bool
{
    return CWS_PlayerTraceScope() && cwsTraceEpoch == theGame.CWS_playerTraceEpoch
        && cwsTracePlayer == player && cwsTraceInput == theGame.CWS_Input
        && cwsTraceContext == theInput.GetContext()
        && cwsTraceCommand == CWS_GetState().CWS_PlayerCommandRevision()
        && cwsTracePhase == CWS_GetState().CWS_PlayerPhase()
        && cwsTraceSelected == CWS_GetState().CWS_SelectedSpeed()
        && cwsTraceMaster == CWS_GetState().enabled
        && cwsTraceOwned == cwsFrameHasOverlay && cwsTraceMode == _inputLocoEnabled
        && cwsTraceTrueSteps == CWS_GetState().trueSteps;
}

@addMethod(CR4LocomotionPlayerControllerScript)
public function CWS_PlayerTraceFrame()
{
    var now, elapsed, displacement, absoluteSpeed, ik, sprintTime : float;
    var position, velocity : Vector;
    var walk, sprint, timerFlag, heading : bool;
    var gait : EPlayerMoveType;
    var line : string;
    if (cwsTraceBusy)
    {
        cwsTraceInterval = false;
        return;
    }
    if (!CWS_PlayerTraceScope())
    {
        if (cwsTraceInterval && theGame && theGame.CWS_playerTraceEnabled)
            LogChannel('CM_PLAYER', "CM_PLAYER schema=1 event=context invalid");
        cwsTraceInterval = false;
        return;
    }
    now = theGame.GetEngineTimeAsSeconds();
    if (cwsTraceInterval && (now <= cwsTraceFrameTime || now - cwsTraceFrameTime > 5.0f
        || !CWS_PlayerTraceSame()))
        cwsTraceInterval = false;
    cwsTraceFrameTime = now;
    cwsTraceRevision = CWS_GetState().CWS_MotionRevision();
    if (!cwsTraceInterval)
    {
        cwsTraceEpoch = theGame.CWS_playerTraceEpoch;
        cwsTracePlayer = player;
        cwsTraceInput = theGame.CWS_Input;
        cwsTraceContext = theInput.GetContext();
        cwsTraceCommand = CWS_GetState().CWS_PlayerCommandRevision();
        cwsTraceRevision = CWS_GetState().CWS_MotionRevision();
        cwsTracePhase = CWS_GetState().CWS_PlayerPhase();
        cwsTraceSelected = CWS_GetState().CWS_SelectedSpeed();
        cwsTraceMaster = CWS_GetState().enabled;
        cwsTraceOwned = cwsFrameHasOverlay;
        cwsTraceMode = _inputLocoEnabled;
        cwsTraceTrueSteps = CWS_GetState().trueSteps;
        cwsTraceBusy = true;
        position = player.GetWorldPosition();
        cwsTraceBusy = false;
        if (!CWS_PlayerTraceSame() || cwsTraceRevision != CWS_GetState().CWS_MotionRevision())
            return;
        cwsTracePosition = position;
        cwsTraceTime = now;
        cwsTraceInterval = true;
        LogChannel('CM_PLAYER', "CM_PLAYER schema=1 event=context phase=" + NameToString(cwsTracePhase)
            + " command=" + IntToString(cwsTraceCommand));
        return;
    }
    elapsed = now - cwsTraceTime;
    if (elapsed < 1.0f || (cwsTraceHasLog && now - cwsTraceLastLog < 1.0f))
        return;
    if (elapsed > 5.0f)
    {
        cwsTraceInterval = false;
        return;
    }
    cwsTraceBusy = true;
    velocity = player.GetMovingAgentComponent().GetVelocity();
    position = player.GetWorldPosition();
    absoluteSpeed = player.GetMovingAgentComponent().GetCurrentMoveSpeedAbs();
    walk = player.GetIsWalkToggled();
    gait = player.playerMoveType;
    ik = player.GetBehaviorVariable('ikWeight', -9999.0f);
    sprint = player.GetIsSprinting();
    sprintTime = player.GetSprintingTime();
    timerFlag = player.CWS_PlayerTraceSprintTimer();
    heading = player.IsInputHeadingReady();
    cwsTraceBusy = false;
    displacement = VecDistance(position, cwsTracePosition) / elapsed;
    if (!cwsTraceInterval || !CWS_PlayerTraceSame() || displacement > 20.0f
        || cwsTraceRevision != CWS_GetState().CWS_MotionRevision()
        || now != theGame.GetEngineTimeAsSeconds())
    {
        cwsTraceInterval = false;
        return;
    }
    line = "CM_PLAYER schema=1 build=1.4.0-movement-probe.1 event=sample phase=" + NameToString(cwsTracePhase)
        + " master=" + IntToString((int)cwsTraceMaster)
        + " selected=" + FloatToStringPrec(cwsTraceSelected, 2)
        + " candidate=" + FloatToStringPrec(cwsFrameCandidate, 2)
        + " native=" + FloatToStringPrec(cwsFrameNativeSpeed, 2)
        + " final=" + FloatToStringPrec(moveSpeed, 2)
        + " walk=" + IntToString((int)walk) + " gait=" + IntToString((int)gait)
        + " ik=" + FloatToStringPrec(ik, 2) + " sprint=" + IntToString((int)sprint)
        + " sprint_elapsed=" + FloatToStringPrec(sprintTime, 2) + " disable_timer=" + IntToString((int)timerFlag)
        + " heading_ready=" + IntToString((int)heading) + " input=" + FloatToStringPrec(cwsFrameNativeInput, 2)
        + " stop_check=" + IntToString((int)stopCheckEnabled)
        + " stop_time=" + FloatToStringPrec(stoppedTimeStamp, 3) + " stop_delta=" + FloatToStringPrec(stoppedTimeStampDelta, 3)
        + " cache=" + FloatToStringPrec(cachedMoveSpeed, 2) + " cap=" + IntToString((int)CWS_GetState().CWS_FluidCapped())
        + " velocity=" + FloatToStringPrec(VecLength(velocity), 2)
        + " endpoint_per_second=" + FloatToStringPrec(displacement, 2)
        + " elapsed_engine_seconds=" + FloatToStringPrec(elapsed, 3)
        + " absolute_getter=" + FloatToStringPrec(absoluteSpeed, 2);
    LogChannel('CM_PLAYER', line);
    cwsTraceHasLog = true;
    cwsTraceLastLog = now;
    cwsTraceTime = now;
    cwsTracePosition = position;
}
