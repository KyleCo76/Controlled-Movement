// Horse transitions use the accepted CM curve functions, with independent runtime.
// Only the prepared native horse update advances phase; commands change destinations.
@addField(CWS_HorseState) public var moving : bool;
@addField(CWS_HorseState) public var startReady : bool;
@addField(CWS_HorseState) public var active : bool;
@addField(CWS_HorseState) public var applied : float;
@addField(CWS_HorseState) private var motionTarget : float;
@addField(CWS_HorseState) private var motionCurve : int;
@addField(CWS_HorseState) private var motionPhase : float;
@addField(CWS_HorseState) private var motionSpan : float;
@addField(CWS_HorseState) private var motionDuration : float;
@addField(CWS_HorseState) private var motionBaseRate : float;
@addField(CWS_HorseState) private var preparedPhase : float;
@addField(CWS_HorseState) private var preparedTarget : float;
@addField(CWS_HorseState) public var generation : int;
@addField(CWS_HorseState) public var commandSerial : int;
@addField(CWS_HorseState) private var stopResetHorse : W3HorseComponent;
@addField(CWS_HorseState) private var stopResetPlayer : CR4Player;
@addField(CWS_HorseState) private var stopResetStarted : float;
@addField(CWS_HorseState) private var stopResetObserved : float;

@addMethod(CWS_HorseState)
function CWSH_CancelStopReset()
{
    stopResetHorse = NULL;
    stopResetPlayer = NULL;
    stopResetStarted = 0.0f;
    stopResetObserved = 0.0f;
}

@addMethod(CWS_HorseState)
function CWSH_Suspend()
{
    CWSH_CancelStopReset();
    generation += 1;
    active = false;
    moving = false;
    startReady = false;
    motionPhase = 0.0f;
    preparedPhase = 0.0f;
}

@addMethod(CWS_HorseState)
function CWSH_ObserveIdle(component : W3HorseComponent)
{
    var now : float;
    now = theGame.GetEngineTimeAsSeconds();
    if(moving)
    {
        // Physical motion still stops natively. Only selection reset waits.
        CWSH_Suspend();
        startReady = true;
        if(resetAtStop && now - now == 0.0f)
        {
            stopResetHorse = component;
            stopResetPlayer = (CR4Player)thePlayer;
            stopResetStarted = now;
            stopResetObserved = now;
        }
        return;
    }
    startReady = true;
    if(!stopResetHorse) return;
    if(!resetAtStop || stopResetHorse != component || stopResetPlayer != thePlayer
        || now - now != 0.0f)
    {
        CWSH_CancelStopReset();
        return;
    }
    // Missing observations and clock reversals cannot count as continuous absence.
    if(now < stopResetObserved || now - stopResetObserved > 0.25f) stopResetStarted = now;
    stopResetObserved = now;
    if(now - stopResetStarted > 1.0f) CWSH_Stop();
}

// Stable remaining shapes avoid subtracting nearly equal numbers near arrival.
@addMethod(CWS_HorseState)
private function CWSH_CurveH(u : float) : float
{
    u = ClampF(u, 0.0f, 1.0f);
    return u * u * (3.0f - 2.0f * u);
}

@addMethod(CWS_HorseState)
private function CWSH_CurveIntegral(u : float, a : float, b : float) : float
{
    var z : float;
    if (u <= a)
        return 0.0f;
    if (u >= b)
        return u - (a + b) * 0.5f;
    z = (u - a) / (b - a);
    return (b - a) * z * z * z * (1.0f - 0.5f * z);
}

@addMethod(CWS_HorseState)
private function CWSH_CurveRemaining(curveId : int, u : float) : float
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
        return 1.0f - (CWSH_CurveIntegral(u, 0.0f, 0.15f) + CWSH_CurveIntegral(u, 0.35f, 0.55f)) / 1.275f;
    }
    if (curveId == 4)
    {
        if (u >= 0.90f)
        {
            w = h / 0.10f;
            return 0.50f * w * w * w * (1.0f - 0.5f * w) / 1.352f;
        }
        return 1.0f - (0.05f * CWSH_CurveIntegral(u, 0.0f, 0.20f)
            + 0.45f * CWSH_CurveIntegral(u, 0.50f, 0.58f)
            + 4.50f * CWSH_CurveIntegral(u, 0.65f, 0.75f)) / 1.352f;
    }
    return h;
}

@addMethod(CWS_HorseState)
private function CWSH_CurveRate(curveId : int, u : float) : float
{
    u = ClampF(u, 0.0f, 1.0f);
    if (curveId == 1)
        return 6.0f * u * (1.0f - u);
    if (curveId == 2)
        return 12.0f * u * u * (1.0f - u);
    if (curveId == 3)
    {
        if (u >= 0.80f)
            return 2.0f * CWSH_CurveH((1.0f - u) / 0.20f) / 1.275f;
        return (CWSH_CurveH(u / 0.15f) + CWSH_CurveH((u - 0.35f) / 0.20f)) / 1.275f;
    }
    if (curveId == 4)
    {
        if (u >= 0.90f)
            return 5.0f * CWSH_CurveH((1.0f - u) / 0.10f) / 1.352f;
        return (0.05f * CWSH_CurveH(u / 0.20f)
            + 0.45f * CWSH_CurveH((u - 0.50f) / 0.08f)
            + 4.50f * CWSH_CurveH((u - 0.65f) / 0.10f)) / 1.352f;
    }
    return 1.0f;
}

@addMethod(CWS_HorseState)
private function CWSH_CurveAscendingPhase(curveId : int, rate : float) : float
{
    var low, high, midpoint : float;
    var iteration, iterations : int;
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
    if (curveId == 4)
    {
        high = 0.75f;
        if (MaxF(rate - 0.05f / 1.352f, 0.05f / 1.352f - rate) <= 0.00005f)
            return 0.50f;
        if (MaxF(rate - 0.50f / 1.352f, 0.50f / 1.352f - rate) <= 0.00005f)
            return 0.65f;
    }
    if (rate >= CWSH_CurveRate(curveId, high))
        return high;
    low = 0.0f;
    iterations = 16;
    if(curveId == 4) iterations = 20;
    for (iteration = 0; iteration < iterations; iteration += 1)
    {
        midpoint = (low + high) * 0.5f;
        if (CWSH_CurveRate(curveId, midpoint) < rate)
            low = midpoint;
        else
            high = midpoint;
    }
    return (low + high) * 0.5f;
}

@addMethod(CWS_HorseState)
function CWSH_Retarget(destination : float, smooth : bool)
{
    var curveId : int;
    var rate, phase, settling, remaining, span, duration : float;
    // Native restrictions may legitimately fall below the selectable minimum.
    destination = ClampF(destination, 0.0f, 8.0f);
    if(!moving)
    {
        motionTarget = destination;
        active = false;
        return;
    }
    curveId = increaseCurve;
    rate = 10.0f / (float)Max(1, Min(100, increaseTimeMs));
    if(destination < applied)
    {
        curveId = decreaseCurve;
        rate = 10.0f / (float)Max(1, Min(100, decreaseTimeMs));
    }
    if(smooth && active && destination == motionTarget && curveId == motionCurve && rate == motionBaseRate)
        return;
    if(smooth && active && curveId > 0 && curveId == motionCurve && rate == motionBaseRate
        && motionDuration > 0.0f && motionDuration - motionDuration == 0.0f
        && (destination - applied) * motionSpan > 0.0f)
    {
        phase = preparedPhase;
        settling = 0.5f;
        if(curveId == 2) settling = 2.0f / 3.0f;
        if(curveId == 3) settling = 0.80f;
        if(curveId == 4) settling = 0.90f;
        if((destination - preparedTarget) * motionSpan > 0.0f && phase > settling)
            phase = CWSH_CurveAscendingPhase(curveId, CWSH_CurveRate(curveId, phase));
        remaining = CWSH_CurveRemaining(curveId, phase);
        if(remaining > 0.0f)
        {
            span = (destination - applied) / remaining;
            duration = MaxF(span, -span) / rate;
            if(span - span == 0.0f && duration - duration == 0.0f && duration > 0.0f)
            {
                motionTarget = destination;
                motionSpan = span;
                motionDuration = duration;
                motionPhase = phase;
                return;
            }
        }
    }
    active = false;
    motionTarget = destination;
    if(!smooth || destination == applied)
    {
        applied = destination;
        return;
    }
    motionCurve = curveId;
    motionBaseRate = rate;
    motionSpan = destination - applied;
    motionDuration = MaxF(motionSpan, -motionSpan) / rate;
    motionPhase = 0.0f;
    preparedPhase = 0.0f;
    preparedTarget = destination;
    active = true;
}

@addMethod(CWS_HorseState)
function CWSH_Advance(dt : float)
{
    var previous, remaining : float;
    if(!active || !moving || dt - dt != 0.0f || dt <= 0.0f || dt > 0.25f) return;
    previous = applied;
    if(motionCurve == 0)
    {
        remaining = motionBaseRate * dt;
        if(motionTarget > applied) applied = MinF(motionTarget, applied + remaining);
        else applied = MaxF(motionTarget, applied - remaining);
    }
    else
    {
        if(motionDuration <= 0.0f || motionDuration - motionDuration != 0.0f)
        {
            active = false;
            return;
        }
        motionPhase = MinF(1.0f, motionPhase + dt / motionDuration);
        applied = motionTarget - motionSpan * CWSH_CurveRemaining(motionCurve, motionPhase);
        applied = ClampF(applied, MinF(previous, motionTarget), MaxF(previous, motionTarget));
        preparedPhase = motionPhase;
        preparedTarget = motionTarget;
    }
    if(MaxF(applied - motionTarget, motionTarget - applied) <= 0.000001f)
    {
        applied = motionTarget;
        active = false;
    }
}

@addMethod(CWS_HorseState)
function CWSH_PrepareMove(nativeSpeed : float, limit : float, dt : float) : float
{
    var selectedSpeed, destination : float;
    var starting, fastStart : bool;
    selectedSpeed = CWSH_SelectedSpeed();
    destination = MinF(selectedSpeed, limit);
    if(!moving)
    {
        // Fast idle starts bypass both origins; native caps still limit the destination.
        fastStart = startReady && selectedSpeed > 2.50f;
        starting = startReady && smoothStarting && !fastStart;
        startReady = false;
        moving = true;
        applied = destination;
        if(starting) applied = MinF((float)startSpeedUnits / 100.0f, destination);
        else if(!fastStart && nativeSpeed > 0.0f) applied = MinF(nativeSpeed, limit);
        CWSH_Retarget(destination, starting || (!fastStart && nativeSpeed > 0.0f && (smoothSteps || smoothFavorites || smoothStarting)));
    }
    else if(destination != motionTarget)
        CWSH_Retarget(destination, smoothSteps || smoothFavorites || smoothStarting);
    CWSH_Advance(dt);
    applied = MinF(applied, limit);
    return applied;
}

@addMethod(CWS_HorseState)
function CWSH_LateRestriction(value : float)
{
    applied = MaxF(0.0f, value);
    motionTarget = applied;
    active = false;
}
