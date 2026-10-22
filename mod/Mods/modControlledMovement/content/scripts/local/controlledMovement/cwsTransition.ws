// Unsaved applied requests belong to one current player and input owner.
// Only a prepared native calculation advances time; selection and HUD keep destinations.
@addField(CWS_State) private var CWS_motionPlayer : CR4Player;
@addField(CWS_State) private var CWS_motionInput : CPlayerInput;
@addField(CWS_State) private var CWS_motionContext : name;
@addField(CWS_State) private var CWS_motionMoving : bool;
@addField(CWS_State) private var CWS_motionActive : bool;
@addField(CWS_State) private var CWS_motionApplied : float;
@addField(CWS_State) private var CWS_motionTarget : float;
@addField(CWS_State) private var CWS_motionTime : float;
@addField(CWS_State) private var CWS_motionSampleTime : float;
@addField(CWS_State) private var CWS_motionRevision : int;
@addField(CWS_State) private var CWS_commandSelecting : bool;
@addField(CWS_State) private var CWS_commandRevision : int;
@addField(CWS_State) private var CWS_movingCommandRevision : int;
@addField(CWS_State) private var CWS_stopPending : bool;
@addField(CWS_State) private var CWS_startReady : bool;
@addField(CWS_State) private var CWS_startPending : bool;
@addField(CWS_State) private var CWS_motionCurve : int;
@addField(CWS_State) private var CWS_motionSpan : float;
@addField(CWS_State) private var CWS_motionDuration : float;
@addField(CWS_State) private var CWS_motionPhase : float;
@addField(CWS_State) private var CWS_motionBaseRate : float;
@addField(CWS_State) private var CWS_motionPreparedTarget : float;
@addField(CWS_State) private var CWS_motionPreparedPhase : float;

@addMethod(CWS_State)
public function CWS_CancelMotion()
{
    CWS_motionRevision += 1;
    CWS_commandSelecting = false;
    CWS_motionActive = false;
    CWS_startPending = false;
    CWS_motionTime = 0.0f;
    CWS_motionCurve = 0;
    CWS_motionSpan = 0.0f;
    CWS_motionDuration = 0.0f;
    CWS_motionPhase = 0.0f;
    CWS_motionBaseRate = 0.0f;
    CWS_motionPreparedTarget = 0.0f;
    CWS_motionPreparedPhase = 0.0f;
}

@addMethod(CWS_State)
public function CWS_SuspendMotion()
{
    CWS_CancelMotion();
    CWS_motionMoving = false;
    CWS_startReady = false;
    CWS_stopPending = false;
    CWS_motionPlayer = NULL;
    CWS_motionInput = NULL;
    CWS_motionContext = '';
    CWS_playerPhase = 'unowned';
    CWS_playerPermitted = 0.0f;
    CWS_playerRest = false;
    CWS_playerRecoveryPending = false;
}

@addMethod(CWS_State)
public function CWS_MotionRevision() : int
{
    return CWS_motionRevision;
}

@addMethod(CWS_State)
public function CWS_AppliedSpeed() : float
{
    if (CWS_motionActive)
        return CWS_LimitPace(CWS_motionApplied);
    // Keep the selected destination out of gait reads until the armed start is prepared.
    if (smoothStarting && (CWS_startReady || CWS_startPending) && theGame && theInput
        && CWS_MotionSessionOwned(theGame.GetEngineTimeAsSeconds()))
        return 0.11f;
    return CWS_TargetSpeed();
}

// An armed starting hint is not yet an applied frame. Nested command cancellation
// must retain its existing origin rather than turn that hint into a new ramp.
@addMethod(CWS_State)
private function CWS_CommandSpeed() : float
{
    if (CWS_motionPlayer && CWS_playerPhase != 'resting')
        return CWS_LimitPace(CWS_playerPermitted);
    return CWS_TargetSpeed();
}

@addMethod(CWS_State)
public function CWS_ObserveMotionInput(player : CR4Player, now : float) : bool
{
    var moving : bool;
    // An obsolete controller cannot suspend a replacement player's session.
    if (thePlayer && player && player != thePlayer)
        return false;
    // Subtraction rejects both infinity and NaN without an engine-only helper.
    if (now - now != 0.0f || !theGame.CWS_Input || !CWS_IsEligible(player)
        || player.CWS_ManualSprint() || player.IsInCombatActionFriendly() || player.GetBInteractionPressed())
    {
        CWS_SuspendMotion();
        return false;
    }
    if (CWS_motionPlayer && (CWS_motionPlayer != player || CWS_motionInput != theGame.CWS_Input
        || CWS_motionContext != theInput.GetContext() || now < CWS_motionSampleTime))
    {
        CWS_SuspendMotion();
        return false;
    }
    CWS_motionPlayer = player;
    CWS_motionInput = theGame.CWS_Input;
    CWS_motionContext = theInput.GetContext();
    moving = theInput.GetActionValue('GI_AxisLeftX') != 0.0f || theInput.GetActionValue('GI_AxisLeftY') != 0.0f;
    if (!moving && CWS_motionMoving)
        CWS_stopPending = CWS_commandRevision == CWS_movingCommandRevision;
    if (moving)
    {
        if (!CWS_motionMoving && CWS_startReady)
            CWS_startPending = smoothStarting;
        CWS_startReady = false;
        if (!CWS_motionMoving || now > CWS_motionSampleTime)
            CWS_movingCommandRevision = CWS_commandRevision;
        CWS_stopPending = false;
    }
    CWS_motionSampleTime = now;
    CWS_motionMoving = moving;
    return moving;
}

@addMethod(CWS_State)
public function CWS_ApplyStopReset()
{
    var previous, destination : float;
    if (!resetAtStop)
        return;
    previous = CWS_SelectedSpeed();
    destination = 0.11f;
    if (stopDestination == 0)
        destination = CWS_ResolveFavoriteSpeed(false);
    if (previous <= destination)
        return;
    if (CWS_commandSelecting)
        CWS_CancelMotion();
    if (stopDestination == 0)
        CWS_SelectFavorite(false);
    else
    {
        if (trueSteps)
        {
            CWS_trueUnits = 11;
            CWS_hasTrueSelection = true;
        }
        else
            CWS_SetStaticOverride(11);
        CWS_SelectionChanged(previous);
    }
}

// Stable remaining shapes avoid subtracting nearly equal numbers near arrival.
@addMethod(CWS_State)
private function CWS_CurveH(u : float) : float
{
    u = ClampF(u, 0.0f, 1.0f);
    return u * u * (3.0f - 2.0f * u);
}

@addMethod(CWS_State)
private function CWS_CurveIntegral(u : float, a : float, b : float) : float
{
    var z : float;
    if (u <= a)
        return 0.0f;
    if (u >= b)
        return u - (a + b) * 0.5f;
    z = (u - a) / (b - a);
    return (b - a) * z * z * z * (1.0f - 0.5f * z);
}

@addMethod(CWS_State)
private function CWS_CurveRemaining(curveId : int, u : float) : float
{
    var h, w : float;
    if (u <= 0.0f)
        return 1.0f;
    if (u >= 1.0f)
        return 0.0f;
    h = 1.0f - u;
    if (curveId == 1)
        return h * h * (1.0f + 2.0f * u);
    if (curveId == 2)
        return h * h * (1.0f + 2.0f * u + 3.0f * u * u);
    if (curveId == 3)
    {
        if (u >= 0.80f)
        {
            w = h / 0.20f;
            return 0.40f * w * w * w * (1.0f - 0.5f * w) / 1.275f;
        }
        return 1.0f - (CWS_CurveIntegral(u, 0.0f, 0.15f) + CWS_CurveIntegral(u, 0.35f, 0.55f)) / 1.275f;
    }
    return h;
}

@addMethod(CWS_State)
private function CWS_CurveRate(curveId : int, u : float) : float
{
    u = ClampF(u, 0.0f, 1.0f);
    if (curveId == 1)
        return 6.0f * u * (1.0f - u);
    if (curveId == 2)
        return 12.0f * u * u * (1.0f - u);
    if (curveId == 3)
    {
        if (u >= 0.80f)
            return 2.0f * CWS_CurveH((1.0f - u) / 0.20f) / 1.275f;
        return (CWS_CurveH(u / 0.15f) + CWS_CurveH((u - 0.35f) / 0.20f)) / 1.275f;
    }
    return 1.0f;
}

@addMethod(CWS_State)
private function CWS_CurveAscendingPhase(curveId : int, rate : float) : float
{
    var low, high, midpoint : float;
    var iteration : int;
    if (rate <= 0.0f)
        return 0.0f;
    high = 0.5f;
    if (curveId == 2)
        high = 2.0f / 3.0f;
    if (curveId == 3)
    {
        high = 0.55f;
        if (MaxF(rate - 1.0f / 1.275f, 1.0f / 1.275f - rate) <= 0.00005f)
            return 0.35f;
    }
    if (rate >= CWS_CurveRate(curveId, high))
        return high;
    low = 0.0f;
    for (iteration = 0; iteration < 16; iteration += 1)
    {
        midpoint = (low + high) * 0.5f;
        if (CWS_CurveRate(curveId, midpoint) < rate)
            low = midpoint;
        else
            high = midpoint;
    }
    return (low + high) * 0.5f;
}

@addMethod(CWS_State)
private function CWS_InitCurve(curveId : int, baseRate : float)
{
    CWS_motionCurve = curveId;
    CWS_motionBaseRate = baseRate;
    CWS_motionSpan = CWS_motionTarget - CWS_motionApplied;
    CWS_motionDuration = MaxF(CWS_motionSpan, -CWS_motionSpan) / baseRate;
    CWS_motionPhase = 0.0f;
    CWS_motionPreparedTarget = CWS_motionTarget;
    CWS_motionPreparedPhase = 0.0f;
}

@addMethod(CWS_State)
private function CWS_CurveStateValid() : bool
{
    return CWS_motionCurve >= 1 && CWS_motionCurve <= 3
        && CWS_motionPhase - CWS_motionPhase == 0.0f && CWS_motionPhase >= 0.0f && CWS_motionPhase <= 1.0f
        && CWS_motionSpan - CWS_motionSpan == 0.0f && CWS_motionSpan != 0.0f
        && CWS_motionApplied - CWS_motionApplied == 0.0f && CWS_motionTarget - CWS_motionTarget == 0.0f
        && CWS_motionPreparedTarget - CWS_motionPreparedTarget == 0.0f
        && CWS_motionPreparedPhase - CWS_motionPreparedPhase == 0.0f && CWS_motionPreparedPhase >= 0.0f && CWS_motionPreparedPhase <= 1.0f
        && CWS_motionDuration - CWS_motionDuration == 0.0f && CWS_motionDuration > 0.0f
        && CWS_motionBaseRate - CWS_motionBaseRate == 0.0f && CWS_motionBaseRate > 0.0f;
}

@addMethod(CWS_State)
public function CWS_RetargetMotion(fromSpeed : float, smooth : bool, now : float)
{
    var target, baseRate, remaining, phase, span, duration, settling : float;
    var curveId : int;
    target = CWS_TargetSpeed();
    // A smooth command keeps the queued start; preparation reads its latest target.
    if (smooth && CWS_startPending)
        return;
    curveId = increaseCurve;
    baseRate = 10.0f / (float)Max(1, Min(100, increaseTimeMs));
    if (target < fromSpeed)
    {
        curveId = decreaseCurve;
        baseRate = 10.0f / (float)Max(1, Min(100, decreaseTimeMs));
    }
    if (smooth && CWS_motionActive && target == CWS_motionTarget
        && curveId == CWS_motionCurve && (curveId == 0 || baseRate == CWS_motionBaseRate))
        return;
    if (smooth && CWS_motionActive && CWS_motionMoving && CWS_motionPlayer
        && now - now == 0.0f && now >= CWS_motionTime && CWS_CurveStateValid()
        && curveId == CWS_motionCurve && baseRate == CWS_motionBaseRate
        && (target - fromSpeed) * CWS_motionSpan > 0.0f)
    {
        // Commands may revise geometry, but only the last prepared sample is an anchor.
        // An intermediate extension must not leave a remap after the target changes again.
        phase = CWS_motionPreparedPhase;
        settling = 0.5f;
        if (curveId == 2)
            settling = 2.0f / 3.0f;
        if (curveId == 3)
            settling = 0.80f;
        // Remap extensions before testing the remaining tail; never snap a new gap.
        if ((target - CWS_motionPreparedTarget) * CWS_motionSpan > 0.0f && phase > settling)
            phase = CWS_CurveAscendingPhase(curveId, CWS_CurveRate(curveId, phase));
        remaining = CWS_CurveRemaining(curveId, phase);
        if (remaining > 0.0f)
        {
            span = (target - fromSpeed) / remaining;
            duration = MaxF(span, -span) / baseRate;
            if (span - span == 0.0f && duration - duration == 0.0f && duration > 0.0f)
            {
                CWS_motionTarget = target;
                CWS_motionSpan = span;
                CWS_motionDuration = duration;
                CWS_motionPhase = phase;
                CWS_motionRevision += 1;
                return;
            }
        }
    }
    CWS_CancelMotion();
    if (!smooth || !CWS_MotionCommandOwned(now) || !CWS_motionPlayer || now - now != 0.0f
        || fromSpeed - fromSpeed != 0.0f || target - target != 0.0f || target == fromSpeed)
        return;
    CWS_motionApplied = fromSpeed;
    CWS_motionTarget = target;
    CWS_motionTime = now;
    CWS_motionActive = true;
    CWS_InitCurve(curveId, baseRate);
}

// This checks the already sampled intent; commands add no native movement query.
@addMethod(CWS_State)
private function CWS_MotionCommandOwned(now : float) : bool
{
    return (CWS_motionMoving || CWS_playerPhase == 'coasting' || CWS_playerPhase == 'limited')
        && CWS_MotionSessionOwned(now);
}

// Idle commands retain observed readiness without creating a moving session.
@addMethod(CWS_State)
private function CWS_MotionSessionOwned(now : float) : bool
{
    return CWS_motionPlayer && CWS_motionPlayer == thePlayer
        && CWS_motionInput && CWS_motionInput == theGame.CWS_Input
        && CWS_motionContext == theInput.GetContext()
        && now - now == 0.0f && now >= CWS_motionSampleTime
        && CWS_IsEligible(CWS_motionPlayer) && !CWS_motionPlayer.CWS_ManualSprint()
        && !CWS_motionPlayer.IsInCombatActionFriendly() && !CWS_motionPlayer.GetBInteractionPressed();
}

@addMethod(CWS_State)
private function CWS_FinishMovementCommand(commandRevision : int, motionRevision : int, fromSpeed : float, smooth : bool, now : float)
{
    var currentTime : float;
    if (commandRevision != CWS_commandRevision)
        return;
    CWS_commandSelecting = false;
    if (motionRevision != CWS_motionRevision)
        return;
    currentTime = theGame.GetEngineTimeAsSeconds();
    if (!CWS_MotionSessionOwned(currentTime))
    {
        CWS_SuspendMotion();
        return;
    }
    // A command during readiness cannot spend the armed start.
    if (CWS_startReady || CWS_startPending)
        return;
    CWS_RetargetMotion(fromSpeed, smooth, now);
}

@addMethod(CWS_State)
public function CWS_RequestStep(direction : int)
{
    var fromSpeed, now : float;
    var commandRevision, motionRevision : int;
    now = theGame.GetEngineTimeAsSeconds();
    CWS_ObserveMotionInput((CR4Player)thePlayer, now);
    CWS_stopPending = false;
    CWS_commandRevision += 1;
    commandRevision = CWS_commandRevision;
    fromSpeed = CWS_CommandSpeed();
    motionRevision = CWS_motionRevision;
    CWS_commandSelecting = true;
    CWS_Adjust(direction);
    CWS_FinishMovementCommand(commandRevision, motionRevision, fromSpeed, CWS_MotionCommandOwned(now) && smoothSteps, now);
}

@addMethod(CWS_State)
public function CWS_RequestFavorite(useB : bool)
{
    var fromSpeed, now : float;
    var commandRevision, motionRevision : int;
    now = theGame.GetEngineTimeAsSeconds();
    CWS_ObserveMotionInput((CR4Player)thePlayer, now);
    CWS_stopPending = false;
    CWS_commandRevision += 1;
    commandRevision = CWS_commandRevision;
    fromSpeed = CWS_CommandSpeed();
    motionRevision = CWS_motionRevision;
    CWS_commandSelecting = true;
    CWS_SelectFavorite(useB);
    CWS_FinishMovementCommand(commandRevision, motionRevision, fromSpeed, CWS_MotionCommandOwned(now) && smoothFavorites, now);
}

@addMethod(CWS_State)
public function CWS_AdvanceMotion(player : CR4Player, now : float) : float
{
    var dt, travel, request : float;
    if (!CWS_ObserveMotionInput(player, now))
        return CWS_TargetSpeed();
    if (CWS_startPending)
    {
        // The prepared calculation starts the clock; idle and polling time is free.
        CWS_startPending = false;
        CWS_motionApplied = 0.11f;
        CWS_motionTarget = CWS_TargetSpeed();
        CWS_motionTime = now;
        CWS_motionActive = CWS_motionTarget > CWS_motionApplied;
        CWS_InitCurve(increaseCurve, 10.0f / (float)Max(1, Min(100, increaseTimeMs)));
        CWS_motionRevision += 1;
        return CWS_LimitPace(CWS_motionApplied);
    }
    if (!CWS_motionActive)
        return CWS_TargetSpeed();
    if (CWS_motionTarget != CWS_TargetSpeed() || now < CWS_motionTime)
    {
        CWS_CancelMotion();
        return CWS_TargetSpeed();
    }
    dt = now - CWS_motionTime;
    if (dt - dt != 0.0f)
    {
        CWS_CancelMotion();
        return CWS_TargetSpeed();
    }
    if (dt == 0.0f)
        return CWS_LimitPace(CWS_motionApplied);
    CWS_motionTime = now;
    if (CWS_motionCurve != 0)
    {
        if (!CWS_CurveStateValid() || (CWS_motionTarget - CWS_motionApplied) * CWS_motionSpan < 0.0f)
        {
            CWS_CancelMotion();
            return CWS_TargetSpeed();
        }
        CWS_motionPhase = MinF(1.0f, CWS_motionPhase + dt / CWS_motionDuration);
        request = CWS_motionTarget - CWS_motionSpan * CWS_CurveRemaining(CWS_motionCurve, CWS_motionPhase);
        if (request - request != 0.0f)
        {
            CWS_CancelMotion();
            return CWS_TargetSpeed();
        }
        if (CWS_motionSpan > 0.0f)
            CWS_motionApplied = ClampF(request, CWS_motionApplied, CWS_motionTarget);
        else
            CWS_motionApplied = ClampF(request, CWS_motionTarget, CWS_motionApplied);
        CWS_motionPreparedTarget = CWS_motionTarget;
        CWS_motionPreparedPhase = CWS_motionPhase;
        CWS_motionRevision += 1;
        if (CWS_motionPhase >= 1.0f || CWS_motionApplied == CWS_motionTarget)
        {
            CWS_motionApplied = CWS_motionTarget;
            CWS_motionActive = false;
        }
        return CWS_AppliedSpeed();
    }
    if (CWS_motionTarget > CWS_motionApplied)
    {
        travel = dt * 10.0f / (float)Max(1, Min(100, increaseTimeMs));
        CWS_motionApplied = MinF(CWS_motionTarget, CWS_motionApplied + travel);
    }
    else
    {
        travel = dt * 10.0f / (float)Max(1, Min(100, decreaseTimeMs));
        CWS_motionApplied = MaxF(CWS_motionTarget, CWS_motionApplied - travel);
    }
    CWS_motionRevision += 1;
    if (CWS_motionApplied == CWS_motionTarget)
        CWS_motionActive = false;
    return CWS_AppliedSpeed();
}

@wrapMethod(CR4Game)
function OnGameStarting(restored : bool)
{
    CWS_StateObject().CWS_SuspendMotion();
    wrappedMethod(restored);
}

@wrapMethod(CR4Game)
function OnBeforeWorldChange(worldName : string)
{
    CWS_StateObject().CWS_SuspendMotion();
    wrappedMethod(worldName);
}

@wrapMethod(CR4Game)
function OnGameEnded()
{
    CWS_StateObject().CWS_SuspendMotion();
    wrappedMethod();
}

// A preview never advances the committed curve. Completed native frames commit it.
@addField(CWS_State) private var CWS_playerPhase : name;
@addField(CWS_State) private var CWS_playerPermitted : float;
@addField(CWS_State) private var CWS_playerCandidate : float;
@addField(CWS_State) private var CWS_playerRest : bool;
@addField(CWS_State) private var CWS_playerRecoveryPending : bool;

@addMethod(CWS_State)
public function CWS_PlayerPhase() : name
{
    return CWS_playerPhase;
}

@addMethod(CWS_State)
public function CWS_PlayerPermittedPace() : float
{
    return CWS_playerPermitted;
}

@addMethod(CWS_State)
public function CWS_PlayerCommandRevision() : int
{
    return CWS_commandRevision;
}

@addMethod(CWS_State)
public function CWS_PreviewPlayerPace(now : float) : float
{
    var dt, phase, candidate : float;
    if (CWS_startPending)
        candidate = MinF(0.11f, CWS_TargetSpeed());
    else if (CWS_playerRecoveryPending)
        candidate = MinF(CWS_TargetSpeed(), MaxF(0.11f, CWS_playerPermitted));
    else if (!CWS_motionActive)
        candidate = CWS_TargetSpeed();
    else
    {
        dt = MaxF(0.0f, now - CWS_motionTime);
        if (CWS_playerPhase == 'coasting' || CWS_playerPhase == 'readiness_wait')
            dt = 0.0f;
        candidate = CWS_motionApplied;
        if (CWS_motionCurve != 0 && CWS_CurveStateValid())
        {
            phase = MinF(1.0f, CWS_motionPhase + dt / CWS_motionDuration);
            candidate = CWS_motionTarget - CWS_motionSpan * CWS_CurveRemaining(CWS_motionCurve, phase);
        }
        else if (CWS_motionTarget > CWS_motionApplied)
            candidate = MinF(CWS_motionTarget, CWS_motionApplied + dt * 10.0f / (float)Max(1, Min(100, increaseTimeMs)));
        else
            candidate = MaxF(CWS_motionTarget, CWS_motionApplied - dt * 10.0f / (float)Max(1, Min(100, decreaseTimeMs)));
    }
    CWS_playerCandidate = CWS_LimitPace(candidate);
    return CWS_playerCandidate;
}

@addMethod(CWS_State)
public function CWS_RebasePlayerPace(permittedPace : float, now : float)
{
    // Explicitly invalidate geometry: same-target retarget shortcuts cannot skip this.
    CWS_motionActive = false;
    CWS_startPending = false;
    CWS_RetargetMotion(MinF(CWS_TargetSpeed(), MaxF(0.11f, permittedPace)), true, now);
}

@addMethod(CWS_State)
public function CWS_PausePlayerPace(phase : name, permittedPace : float, now : float)
{
    if (phase == 'limited')
        CWS_playerRecoveryPending = true;
    if (CWS_playerRest && phase == 'coasting')
        phase = 'resting';
    CWS_playerPhase = phase;
    CWS_playerPermitted = permittedPace;
    CWS_motionTime = now;
}

@addMethod(CWS_State)
public function CWS_CommitPlayerPace(now : float, preparedPace : float, finalPace : float, kind : ECWSPlayerPaceKind)
{
    var priorPhase : name;
    priorPhase = CWS_playerPhase;
    CWS_playerRest = false;
    if (finalPace < preparedPace || (kind == CWS_PaceTurn && finalPace < CWS_TargetSpeed())
        || (CWS_FluidCapped() && finalPace < CWS_SelectedSpeed()))
    {
        CWS_PausePlayerPace('limited', finalPace, now);
        return;
    }
    if (CWS_playerRecoveryPending)
    {
        CWS_RebasePlayerPace(finalPace, now);
        CWS_playerRecoveryPending = false;
    }
    else
    {
        if (priorPhase == 'coasting' || priorPhase == 'readiness_wait')
            CWS_motionTime = now;
        CWS_AdvanceMotion(CWS_motionPlayer, now);
    }
    CWS_playerPermitted = finalPace;
    CWS_playerPhase = 'moving';
}

@addMethod(CWS_State)
public function CWS_ConfirmPlayerRest(player : CR4Player, now : float, commandRevision : int)
{
    if (CWS_playerRest || !CWS_MotionSessionOwned(now) || player != CWS_motionPlayer
        || CWS_commandRevision != commandRevision || CWS_motionMoving)
        return;
    CWS_playerRest = true;
    CWS_playerRecoveryPending = false;
    CWS_playerPhase = 'resting';
    CWS_CancelMotion();
    if (CWS_stopPending && CWS_commandRevision == CWS_movingCommandRevision)
        CWS_ApplyStopReset();
    CWS_stopPending = false;
    CWS_startReady = true;
    CWS_playerPermitted = 0.0f;
}

@addMethod(CWS_State)
public function CWS_PlayerSprintIntent() : bool
{
    return fluidControls && CWS_motionMoving && CWS_playerPhase == 'moving'
        && CWS_playerPermitted > (float)sprintThreshold / 100.0f
        && CWS_playerCandidate > (float)sprintThreshold / 100.0f;
}

@addField(CWS_State) private var CWS_playerController : CR4LocomotionPlayerControllerScript;
@addMethod(CWS_State)
public function CWS_BindPlayerController(controller : CR4LocomotionPlayerControllerScript)
{
    if (CWS_playerController && CWS_playerController != controller)
        CWS_SuspendMotion();
    CWS_playerController = controller;
}
@addMethod(CWS_State)
public function CWS_IsPlayerController(controller : CR4LocomotionPlayerControllerScript) : bool
{
    return CWS_playerController == controller;
}

// A downstream reduction survives phase changes until a completed positive rebase.
// Keep the owned cache association; use the representable recovery floor instead
// of replaying its pre-correction custom value or clearing native stopping state.
@addMethod(CWS_State)
public function CWS_PlayerCoastPace(cachedPace : float) : float
{
    if (CWS_playerRecoveryPending)
        return MinF(cachedPace, MinF(CWS_TargetSpeed(), MaxF(0.11f, CWS_playerPermitted)));
    return cachedPace;
}

@addMethod(CWS_State)
public function CWS_PlayerSessionOwned(player : CR4Player, now : float) : bool
{
    return player && player == CWS_motionPlayer && CWS_MotionSessionOwned(now);
}
