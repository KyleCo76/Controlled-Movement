// Scoped horse integration. Native gait tokens remain discrete; CM owns only its
// prepared final request and gated locomotion graph values. No clock/velocity APIs.

function CWS_HorseCanonical(value : float) : float
{
    if(value <= 0.0f) return 0.0f;
    if(value <= 0.5f) return 0.5f;
    if(value <= 1.0f) return 1.0f;
    if(value <= 2.0f) return 2.0f;
    if(value <= 3.0f) return 3.0f;
    return 4.0f;
}

function CWS_HorseCanOwn(component : W3HorseComponent) : bool
{
    return component && thePlayer && component.user == thePlayer
        && thePlayer.GetUsedHorseComponent() == component && !component.isCart;
}

function CWS_HorseCanInput(player : CR4Player) : bool
{
    var horse : W3HorseComponent;
    var witcher : W3PlayerWitcher;
    var ciri : W3ReplacerCiri;
    var actor : CActor;
    var context : name;
    if(!player || player != thePlayer || !theGame || !theInput) return false;
    witcher = (W3PlayerWitcher)player;
    ciri = (W3ReplacerCiri)player;
    if(!witcher && !ciri) return false;
    context = theInput.GetContext();
    if(context != 'Horse' && context != 'Horse_Replacer_Ciri') return false;
    if(player.GetCurrentStateName() != 'HorseRiding' || !theInput.LastUsedPCInput()) return false;
    horse = player.GetUsedHorseComponent();
    if(!CWS_HorseCanOwn(horse) || !horse.IsFullyMounted() || horse.GetCurrentStateName() != 'Exploration') return false;
    actor = (CActor)horse.GetEntity();
    if(!actor || actor.GetBehaviorVariable('CWS_HorseGaits', -1.0f) < 0.0f
        || actor.GetBehaviorVariable('CWS_HorsePace', -1.0f) < 0.0f) return false;
    if(!horse.GetManualControl() || !horse.GetQuestRiderOverride() || horse.CanFollowNpc()
        || !horse.ShouldUseSimpleStaminaManagement() || !horse.controllable) return false;
    if(!CWS_GetHorseState().enabled || !theGame.IsActive() || theGame.IsPaused()
        || theGame.IsFading() || theGame.IsBlackscreen()) return false;
    if(theGame.GetGuiManager().IsAnyMenu() || player.IsUITakeInput() || !player.GetBIsInputAllowed()) return false;
    if(!player.IsAlive() || !player.GetIsMovable() || !player.IsActionAllowed(EIAB_Movement)) return false;
    if(player.IsInGameplayScene() || theGame.IsCurrentlyPlayingNonGameplayScene() || player.modifyPlayerSpeed) return false;
    if(player.IsInCombatAction() || horse.IsInHorseAction()) return false;
    if(theInput.IsActionPressed('Canter') || theInput.IsActionPressed('Gallop')) return false;
    return true;
}

@addField(CWS_HorseState) private var graphHorse : W3HorseComponent;
@addField(CWS_HorseState) private var graphActor : CActor;
@addField(CWS_HorseState) private var graphValue : float;
@addField(CWS_HorseState) private var lastNativeSpeed : float;
@addField(CWS_HorseState) private var hasOwnedRequest : bool;

@addMethod(CWS_HorseState)
function CWSH_OwnsHorse(component : W3HorseComponent) : bool { return graphHorse == component; }

@addMethod(CWS_HorseState)
function CWSH_ReleaseGraph(optional keepRequest : bool)
{
    // Restore only a still-identical owned output; external corrections win.
    if(!keepRequest && graphActor && graphHorse && hasOwnedRequest
        && graphActor.GetBehaviorVariable('speed', -1.0f) == graphValue
        && graphHorse.InternalGetSpeed() == graphValue)
        graphHorse.InternalSetSpeed(lastNativeSpeed);
    hasOwnedRequest = false;
    if(graphActor && graphActor.GetBehaviorVariable('CWS_HorseGaits', -1.0f) == 1.0f
        && graphActor.GetBehaviorVariable('CWS_HorsePace', -1.0f) == graphValue)
    {
        graphActor.SetBehaviorVariable('CWS_HorseGaits', 0.0f);
        if(graphActor.GetBehaviorVariable('CWS_HorseGaits', -1.0f) == 1.0f) return;
    }
    graphHorse = NULL;
    graphActor = NULL;
}

@addMethod(CWS_HorseState)
function CWSH_CommitGraph(component : W3HorseComponent, output : float, nativeSpeed : float) : bool
{
    var actor : CActor;
    actor = (CActor)component.GetEntity();
    if(graphHorse && graphHorse != component) CWSH_ReleaseGraph();
    if(graphHorse && graphHorse != component) return false;
    if(!actor || output <= 0.0f) return false;
    if(graphHorse == component)
    {
        if(actor.GetBehaviorVariable('CWS_HorseGaits', -1.0f) != 1.0f
            || actor.GetBehaviorVariable('CWS_HorsePace', -1.0f) != graphValue)
        {
            hasOwnedRequest = false;
            graphHorse = NULL;
            graphActor = NULL;
            return false;
        }
    }
    else if(actor.GetBehaviorVariable('CWS_HorseGaits', -1.0f) != 0.0f) return false;
    if(!actor.SetBehaviorVariable('CWS_HorsePace', output)
        || actor.GetBehaviorVariable('CWS_HorsePace', -1.0f) != output) return false;
    graphHorse = component;
    graphActor = actor;
    graphValue = output;
    lastNativeSpeed = nativeSpeed;
    hasOwnedRequest = false;
    if(!actor.SetBehaviorVariable('CWS_HorseGaits', 1.0f)
        || graphHorse != component || graphActor != actor
        || actor.GetBehaviorVariable('CWS_HorseGaits', -1.0f) != 1.0f
        || actor.GetBehaviorVariable('CWS_HorsePace', -1.0f) != output) return false;
    hasOwnedRequest = true;
    return true;
}

@addMethod(CWS_HorseState)
function CWSH_CoastSpeed(component : W3HorseComponent, nativeSpeed : float) : float
{
    if(graphHorse != component || !hasOwnedRequest) return nativeSpeed;
    return MinF(graphValue, nativeSpeed);
}

@addMethod(CWS_HorseState)
function CWSH_Poll()
{
    if(graphHorse && (!graphActor || graphActor.GetBehaviorVariable('CWS_HorseGaits', -1.0f) != 1.0f
        || graphActor.GetBehaviorVariable('CWS_HorsePace', -1.0f) != graphValue))
    {
        // An external graph owner ends both motion and a pending idle interval.
        CWSH_Suspend();
        CWSH_ReleaseGraph(true);
    }
    if(stopResetHorse && (stopResetPlayer != thePlayer || !CWS_HorseCanOwn(stopResetHorse)
        || !CWS_HorseCanInput((CR4Player)thePlayer))) CWSH_Suspend();
    if(graphHorse && (!CWS_HorseCanOwn(graphHorse) || !CWS_HorseCanInput((CR4Player)thePlayer)))
    {
        CWSH_Suspend();
        CWSH_ReleaseGraph();
    }
}

@addField(W3HorseComponentStateExploration) private var CWSH_depth : int;
@addField(W3HorseComponentStateExploration) private var CWSH_prepared : bool;
@addField(W3HorseComponentStateExploration) private var CWSH_allowed : bool;
@addField(W3HorseComponentStateExploration) private var CWSH_stopLatch : bool;
@addField(W3HorseComponentStateExploration) private var CWSH_generation : int;
@addField(W3HorseComponentStateExploration) private var CWSH_preparedGeneration : int;
@addField(W3HorseComponentStateExploration) private var CWSH_output : float;
@addField(W3HorseComponentStateExploration) private var CWSH_expectedGait : float;
@addField(W3HorseComponentStateExploration) private var CWSH_idle : bool;
@addField(W3HorseComponentStateExploration) private var CWSH_profileGeneration : int;
@addField(W3HorseComponentStateExploration) private var CWSH_commandSerial : int;

@addMethod(W3HorseComponentStateExploration)
function CWSH_BeginUpdate(dt : float)
{
    CWSH_depth += 1;
    CWSH_prepared = false;
    CWSH_allowed = false;
    CWSH_idle = false;
    if(CWSH_depth != 1)
    {
        CWSH_Invalidate();
        return;
    }
    if(!CWS_HorseCanOwn(parent)) return;
    // A new mount can arrive idle, before its first graph commit or input poll.
    if(!CWS_GetHorseState().CWSH_OwnsHorse(parent)) CWS_GetHorseState().CWSH_Poll();
    CWSH_allowed = CWS_HorseCanOwn(parent) && CWS_HorseCanInput((CR4Player)thePlayer);
    if(!CWSH_allowed)
    {
        CWS_GetHorseState().CWSH_Suspend();
        if(CWS_GetHorseState().CWSH_OwnsHorse(parent))
        {
            CWS_GetHorseState().CWSH_ReleaseGraph(true);
        }
    }
}

@addMethod(W3HorseComponentStateExploration)
function CWSH_Invalidate()
{
    CWSH_generation += 1;
    CWSH_prepared = false;
    CWSH_allowed = false;
    if(CWS_HorseCanOwn(parent) || CWS_GetHorseState().CWSH_OwnsHorse(parent))
    {
        CWS_GetHorseState().CWSH_Suspend();
        CWS_GetHorseState().CWSH_ReleaseGraph(CWSH_depth > 0);
    }
}

@addMethod(W3HorseComponentStateExploration)
function CWSH_InjectIntent(leftRight : float, forwardBack : float, dt : float, slidingBlocked : bool)
{
    var profile : CWS_HorseState;
    var limit : float;
    var generationBefore : int;
    // Any renewed intent cancels the older absence, even if a native guard wins.
    if(CWSH_depth == 1 && CWS_HorseCanOwn(parent) && (leftRight != 0.0f || forwardBack != 0.0f))
        CWS_GetHorseState().CWSH_CancelStopReset();
    if(!CWSH_allowed || CWSH_depth != 1 || !CWS_HorseCanOwn(parent)
        || !CWS_HorseCanInput((CR4Player)thePlayer)) return;
    profile = CWS_GetHorseState();
    if(slidingBlocked || isInJumpAnim || isInAutoJump || requestJump || dismountRequest
        || IsRiderInCombatAction() || !useSimpleStaminaManagement || !IsHorseControllable())
    {
        CWSH_allowed = false;
        profile.CWSH_Suspend();
        profile.CWSH_ReleaseGraph(true);
        return;
    }
    if(leftRight == 0.0f && forwardBack == 0.0f)
    {
        CWSH_stopLatch = false;
        CWSH_idle = true;
        // Check ownership before an elapsed interval can change the selection.
        generationBefore = profile.generation;
        profile.CWSH_Poll();
        if(generationBefore != profile.generation)
        {
            CWSH_allowed = false;
            return;
        }
        profile.CWSH_ObserveIdle(parent);
        return;
    }
    if(CWSH_stopLatch || !useSimpleStaminaManagement || isReversing || dismountRequest
        || stopRequest || isStopping || isSlowlyStopping || isRefusingToGo || requestJump
        || isInJumpAnim || isInAutoJump || IsRiderInCombatAction() || IsSpeedLocked()
        || !IsHorseControllable() || destSpeed <= MIN_SPEED) return;
    limit = MinF(speedRestriction, speedRestriction2);
    if(!CanCanter() || staminaBreak) limit = MinF(limit, GALLOP_SPEED);
    if(limit <= MIN_SPEED) return;
    if(limit >= CANTER_SPEED) limit = 8.0f;
    CWSH_output = profile.CWSH_PrepareMove(currSpeed, limit, dt);
    CWSH_expectedGait = CWS_HorseCanonical(CWSH_output);
    // Native fields stay canonical, including while the graph interpolates gaits.
    destSpeed = CWSH_expectedGait;
    CWSH_preparedGeneration = CWSH_generation;
    CWSH_profileGeneration = profile.generation;
    CWSH_commandSerial = profile.commandSerial;
    CWSH_prepared = true;
}

@addMethod(W3HorseComponentStateExploration)
function CWSH_EmitSpeed()
{
    var output, nativeSpeed, nativeDestination : float;
    var generationBefore, profileBefore, commandBefore : int;
    var profile : CWS_HorseState;
    var own : bool;
    output = currSpeed;
    if(CWSH_allowed && CWSH_depth == 1 && CWS_HorseCanOwn(parent) && CWS_HorseCanInput((CR4Player)thePlayer)
        && !isReversing && !dismountRequest && !isInJumpAnim && !isInAutoJump
        && !requestJump && !stopRequest && !isStopping && !isRefusingToGo
        && !IsRiderInCombatAction() && !IsSpeedLocked())
    {
        profile = CWS_GetHorseState();
        if(CWSH_prepared && CWSH_preparedGeneration == CWSH_generation
            && CWSH_profileGeneration == profile.generation && CWSH_commandSerial == profile.commandSerial
            && currSpeed == destSpeed && currSpeed <= CWSH_expectedGait)
        {
            output = CWSH_output;
            if(currSpeed < CWSH_expectedGait)
            {
                output = MinF(output, currSpeed);
                profile.CWSH_LateRestriction(output);
            }
            own = output > MIN_SPEED;
        }
        else if(CWSH_idle && currSpeed > MIN_SPEED && profile.CWSH_OwnsHorse(parent))
        {
            output = profile.CWSH_CoastSpeed(parent, currSpeed);
            own = true;
        }
        if(own)
        {
            generationBefore = CWSH_generation;
            profileBefore = profile.generation;
            commandBefore = profile.commandSerial;
            nativeSpeed = currSpeed;
            nativeDestination = destSpeed;
            own = profile.CWSH_CommitGraph(parent, output, currSpeed);
            // Graph callbacks may invalidate the prepared lease before publication.
            own = own && CWSH_allowed && CWSH_depth == 1
                && generationBefore == CWSH_generation && profileBefore == profile.generation
                && commandBefore == profile.commandSerial && nativeSpeed == currSpeed
                && nativeDestination == destSpeed && CWS_HorseCanOwn(parent) && CWS_HorseCanInput((CR4Player)thePlayer)
                && !isInJumpAnim && !isInAutoJump && !requestJump && !stopRequest
                && !dismountRequest && !isReversing && !isStopping && !isRefusingToGo;
            if(!own) profile.CWSH_Suspend();
        }
    }
    if(!own)
    {
        output = currSpeed;
        if(CWS_HorseCanOwn(parent) || CWS_GetHorseState().CWSH_OwnsHorse(parent))
        {
            profile = CWS_GetHorseState();
            if(profile.moving) profile.CWSH_Suspend();
            if(profile.CWSH_OwnsHorse(parent)) profile.CWSH_ReleaseGraph(true);
        }
    }
    parent.InternalSetSpeed(output);
    CWSH_prepared = false;
}

@addMethod(W3HorseComponentStateExploration)
function CWSH_EndUpdate()
{
    CWSH_prepared = false;
    CWSH_allowed = false;
    CWSH_depth = Max(0, CWSH_depth - 1);
}

@wrapMethod(W3HorseComponentStateExploration)
function OnStop(action : SInputAction)
{
    if(IsPressed(action) && IsHorseControllable() && !dismountRequest
        && CWS_HorseCanOwn(parent) && CWS_HorseCanInput((CR4Player)thePlayer))
    {
        CWS_GetHorseState().CWSH_Stop();
        CWSH_Invalidate();
    }
    return wrappedMethod(action);
}

@wrapMethod(W3HorseComponentStateExploration)
function OnHorseStop()
{
    CWSH_stopLatch = true;
    CWSH_Invalidate();
    return wrappedMethod();
}

@wrapMethod(W3HorseComponentStateExploration)
function OnForceStop()
{
    CWSH_stopLatch = true;
    CWSH_Invalidate();
    return wrappedMethod();
}

@wrapMethod(W3HorseComponentStateExploration)
function OnStopTheVehicleInstant()
{
    CWSH_stopLatch = true;
    CWSH_Invalidate();
    return wrappedMethod();
}

@wrapMethod(W3HorseComponentStateExploration)
function OnDismountStarted(entity : CEntity)
{
    if(CWS_HorseCanOwn(parent)) CWS_GetHorseState().CWSH_Stop();
    CWSH_Invalidate();
    return wrappedMethod(entity);
}

@wrapMethod(W3HorseComponentStateExploration)
function OnLeaveState(nextStateName : name)
{
    CWSH_Invalidate();
    return wrappedMethod(nextStateName);
}

@wrapMethod(W3HorseComponent)
function QuestSetRiderSpeed(value : float)
{
    if(CWS_HorseCanOwn(this) || CWS_GetHorseState().CWSH_OwnsHorse(this))
    {
        CWS_GetHorseState().CWSH_Suspend();
        CWS_GetHorseState().CWSH_ReleaseGraph();
    }
    wrappedMethod(value);
}

@wrapMethod(W3HorseComponentStateExploration)
function OnSpeedPress(action : SInputAction)
{
    CWSH_Invalidate();
    return wrappedMethod(action);
}

@wrapMethod(W3HorseComponentStateExploration)
function OnSpeedHold(action : SInputAction)
{
    CWSH_Invalidate();
    return wrappedMethod(action);
}

@wrapMethod(CR4Player)
function OnSpawned(spawnData : SEntitySpawnData)
{
    var witcher : W3PlayerWitcher;
    var ciri : W3ReplacerCiri;
    CWS_GetHorseState().CWSH_Suspend();
    CWS_GetHorseState().CWSH_ReleaseGraph();
    wrappedMethod(spawnData);
    witcher = (W3PlayerWitcher)this;
    ciri = (W3ReplacerCiri)this;
    if(witcher || ciri)
    {
        CWS_GetHorseState().CWSH_Load();
        CWS_GetHorseState().CWSH_ResetSpawn();
    }
}

@wrapMethod(CR4Game)
function OnBeforeWorldChange(worldName : string)
{
    CWS_GetHorseState().CWSH_Suspend();
    CWS_GetHorseState().CWSH_ReleaseGraph();
    wrappedMethod(worldName);
}

@wrapMethod(CR4Game)
function OnGameEnded()
{
    CWS_GetHorseState().CWSH_Suspend();
    CWS_GetHorseState().CWSH_ReleaseGraph();
    wrappedMethod();
}

@addField(W3HorseComponentStateExploration) private var CWSH_dispatchDepth : int;
@addField(W3HorseComponentStateExploration) private var CWSH_dispatchEnabled : bool;
@addField(W3HorseComponentStateExploration) private var CWSH_dispatchReentered : bool;

@addMethod(W3HorseComponentStateExploration)
function CWSH_ReleaseForDelegation()
{
    var profile : CWS_HorseState;
    CWSH_generation += 1;
    CWSH_prepared = false;
    CWSH_allowed = false;
    CWSH_idle = false;
    profile = CWS_GetHorseState();
    if(!CWS_HorseCanOwn(parent) && !profile.CWSH_OwnsHorse(parent)) return;
    // A different mount needs its existing conditional request restoration.
    if(!profile.CWSH_OwnsHorse(parent)) profile.CWSH_Poll();
    profile.CWSH_Suspend();
    // This horse's underlying update supplies its next speed. Do not insert a
    // cached restoration write before it or overwrite external corrections.
    if(profile.CWSH_OwnsHorse(parent)) profile.CWSH_ReleaseGraph(true);
}

@wrapMethod(W3HorseComponentStateExploration)
function UpdateLogic(dt : float)
{
    var profile : CWS_HorseState;
    if(CWSH_dispatchDepth == 0)
    {
        CWSH_dispatchDepth = 1;
        CWSH_dispatchEnabled = false;
        CWSH_dispatchReentered = false;
        profile = CWS_GetHorseState();
        // Profile initialization may call back before selection completes.
        // Keep that whole stack delegated; adopt the loaded mode next update.
        if(!CWSH_dispatchReentered) CWSH_dispatchEnabled = profile.enabled;
    }
    else
    {
        CWSH_dispatchDepth += 1;
        CWSH_dispatchReentered = true;
    }
    if(CWSH_dispatchEnabled)
        CWSH_UpdateControlled(dt);
    else
    {
        if(CWSH_dispatchDepth == 1) CWSH_ReleaseForDelegation();
        wrappedMethod(dt);
    }
    CWSH_dispatchDepth = Max(0, CWSH_dispatchDepth - 1);
}

// The source-pinned native update is unchanged; only four CM hook sites differ.
// Native implementation: CD PROJEKT S.A.; original source hash is in the handoff.

@addMethod(W3HorseComponentStateExploration)
function CWSH_UpdateControlled(dt : float)
{
		var actorParent : CActor;
		var player : W3PlayerWitcher;
		var slidingDisablesControll : bool;

		var waterDepth : float;
		var lookatPos : Vector;

		var staminaBreakSpeed : float;
		var displacementToleranceFactor : float;
		var outPosition : Vector;
		var outNormal : Vector;
		var collisionGroupsNames 			: array<name>;
		var speedFactor : float;
		var forwardDisplacement : float;
		var dbgSphereName : array<name>;

		CWSH_BeginUpdate(dt);

		if (currSpeed == CANTER_SPEED)
		{
			speedFactor = 10.0;
		}
		else
		{
			speedFactor = 5.0;
		}
		
		if(!thePlayer.GetIsHorseRacing())
			parentActor.SetBehaviorVariable( 'isRearingEnabled', 1.0 );
		else
			parentActor.SetBehaviorVariable( 'isRearingEnabled', 0.0 );
			
		waterDepth = GetSubmergeDepth();
		parentActor.SetBehaviorVariable( 'submergeDepth', ClampF( waterDepth, -5.0, 5.0 ) );
		
		if(waterDepth < -0.6f)
		{
			lookatPos = parentActor.GetWorldPosition() + VecConeRand(parentActor.GetHeading(), 0, 5,5) + Vector(0,0,2);
			
			parentActor.SetBehaviorVectorVariable( 'lookAtTarget', lookatPos );
			parentActor.SetBehaviorVariable( 'headWaterDepth', ClampF(-waterDepth/1.5, 0, 1) );
			parentActor.SetBehaviorVariable( 'lookatOn', 1.0f );
		}
		else
		{
			parentActor.SetBehaviorVariable( 'headWaterDepth', 0.f );
		}

		if( waterDepth < -2.f || CheckSliding( slidingDisablesControll ) )
			OnHideHorse();
			
		if( roadFollowBlock > 0.0 )
		{
			roadFollowBlock -= dt;
			if( roadFollowBlock < 0.0 )
				roadFollowBlock = 0.0;
		}
		
		useSimpleStaminaManagement = parent.ShouldUseSimpleStaminaManagement();
		
		if( thePlayer.GetIsMovable() && IsHorseControllable() && !dismountRequest && !slidingDisablesControll )
		{
			if (theGame.GetInGameConfigWrapper().GetVarValue('NewHorseControls', 'UseNewControls') == "true")
			{
				rl = theInput.GetActionValue( 'GI_AxisLeftX' ) * StringToFloat(theGame.GetInGameConfigWrapper().GetVarValue('Controls', 'SteeringSensitivity'));
			}
			else
			{
				rl = theInput.GetActionValue( 'GI_AxisLeftX' );
			}
			fb = theInput.GetActionValue( 'GI_AxisLeftY' );
		}
		else
		{
			rl = 0.0;
			fb = 0.0;
		}

		isReversing	= false;
		if(currSpeed == MIN_SPEED && fb < 0.f && parent.lastRider == thePlayer )
		{
			isReversing	= true;
		}	

		SetTimeoutForCurrentSpeed();
		MaintainCameraVariables( dt );

		if( ( !useSimpleStaminaManagement && destSpeed > GALLOP_SPEED ) || ( !IsSpeedLocked() && destSpeed > MIN_SPEED && !rl && !fb ) || ( !IsSpeedLocked() && destSpeed > TROT_SPEED ) )
		{
			if( maintainSpeedTimer > speedTimeoutValue )
			{
				destSpeed = MaxF( MIN_SPEED, destSpeed - 1.f );
				maintainSpeedTimer = 0.0;
			}
			else
			{
				maintainSpeedTimer += dt;
			}
		}
		
		actorParent = (CActor)parent.GetEntity();
		
		if ( useSimpleStaminaManagement && currSpeed >= GetMinimumSpeedForStaminaDrain() && !isFollowingRoad )
		{
			
			if(thePlayer.GetIsHorseRacing())
				actorParent.DrainStamina( ESAT_FixedValue, 3.33f*dt, 1.f, '', 0.f, 1.f );
			else
				actorParent.DrainStamina( ESAT_FixedValue, 3.33f*dt, 1.f, '', 0.f, 0.45f );
			
			if ( actorParent.GetStat( BCS_Stamina ) <= 0.f )
			{
				staminaBreak = true;
				staminaCooldownTimer = 0.f;
				theGame.HapticStart( "classic_vibro_small_oneshot" );
			}
		}
		
		destSpeed = MinF( destSpeed, speedRestriction );
		destSpeed = MinF( destSpeed, speedRestriction2 );
		
		if( currSpeed > destSpeed && currSpeed < GALLOP_SPEED )
			PlayVoicesetSlowerHorse();
		
		if ( IsMountsRemasterEnabled() )
		{
			ProcessControlInput( rl, fb, dt, parent.IsControllableInLocalSpace() );
		}
		else
		{
			ProcessControlInput( rl, fb, dt, parent.IsControllableInLocalSpace() || parent.riderSharedParams.mountStatus == VMS_mountInProgress );
		}
		
		CWSH_InjectIntent(rl, fb, dt, slidingDisablesControll);

		((CActor)parent.GetEntity()).SetShouldFilterObstacles( 
			theGame.GetInGameConfigWrapper().GetVarValue('NewHorseControls', 'UseNewControls') == "true" && theGame.GetInGameConfigWrapper().GetVarValue('NewHorseControls', 'TreeFiltering') == "true");

		if (!PerformAutoJumpTest2(rl, fb))
		{
			thePlayer.GetVisualDebug().AddText( 'AutoJumpTest2', "PerformAutoJumpTest2 (space behind)", thePlayer.GetWorldPosition() + Vector( 0.f,0.f,2.7f ), true, , Color( 255, 0, 0 ) );
		}
		else
		{
			thePlayer.GetVisualDebug().AddText( 'AutoJumpTest2', "PerformAutoJumpTest2 (space behind)" , thePlayer.GetWorldPosition() + Vector( 0.f,0.f,2.7f ), true, , Color( 0, 255, 0 ) );
		}

		currentUpdatePosition = parentActor.GetWorldPosition();
		thePlayer.GetVisualDebug().AddText( 'AutoJumpForwardDisplacement', "Forward displacement: " + FloatToString(CalculateForwardDisplacement(currentUpdatePosition, previousUpdatePosition, parentActor.GetHeadingVector())), thePlayer.GetWorldPosition() + Vector( 0.f,0.f,2.4f ), true, , Color( 0, 0, 255 ) );		
		
		thePlayer.GetVisualDebug().AddText( 'AutoJumpSpeed', "Delta time scaled speed: " +  FloatToString(dt * currSpeed), thePlayer.GetWorldPosition() + Vector( 0.f,0.f,2.3f ), true, , Color( 0, 0, 255 ) );		

		collisionGroupsNames.PushBack('Static');
		collisionGroupsNames.PushBack('Terrain');
		collisionGroupsNames.PushBack('Destructible');

		forwardDisplacement = CalculateForwardDisplacement(currentUpdatePosition, previousUpdatePosition, parentActor.GetHeadingVector());

		if (destSpeed < GALLOP_SPEED)
		{
			accumulatedForwardDisplacement = 0.f;
		}
		else
		{
			accumulatedForwardDisplacement = accumulatedForwardDisplacement + forwardDisplacement;
		}
		thePlayer.GetVisualDebug().AddText( 'AutoJumpForwardDisplacementTotal', "Forward displacement total: " + FloatToString(accumulatedForwardDisplacement), thePlayer.GetWorldPosition() + Vector( 0.f,0.f,2.2f ), true, , Color( 0, 0, 255 ) );		

		if(theGame.GetInGameConfigWrapper().GetVarValue('NewHorseControls', 'UseNewControls') == "false" && !thePlayer.GetIsHorseRacing() && !PerformNavDataTest() && !isInJumpAnim ) 
		{
			if( PerformInclinationTest( rl, fb ) && PerformWaterTest( rl, fb, waterDepth  ) ) 
			{
				ToggleSpeedLock( 'OnNavStop', false );

				parentActor.SetBehaviorVariable( 'canSlowWalk', 1.0f );
			}
			else if( !isFollowingRoad && !parent.ShouldIgnoreTests() )
			{			
				TriggerNavStop();
			}
			else
			{
				ToggleSpeedLock( 'OnNavStop', false );

				parentActor.SetBehaviorVariable( 'canSlowWalk', 1.0f );
			}
		}
		else if (theGame.GetInGameConfigWrapper().GetVarValue('NewHorseControls', 'UseNewControls') == "true" && theGame.GetInGameConfigWrapper().GetVarValue('NewHorseControls', 'AutoJump') == "true"
		 && !thePlayer.GetIsHorseRacing() && !parent.isCart && currSpeed >= GALLOP_SPEED  )
		{	
			if (!isFollowingRoad && (speedRestriction == CANTER_SPEED) && !isInJumpAnim && !PerformNavDataTest() && PerformAutoJumpTest2(rl, fb) && PerformWaterJumpTest() && PerformFallJumpTest() && PerformInclinationTest(rl, fb))
			{
				currentUpdatePosition = parentActor.GetWorldPosition();

				if (currSpeed == GALLOP_SPEED)
				{
					displacementToleranceFactor = 0.8;
				}
				else if (currSpeed == CANTER_SPEED)
				{
					displacementToleranceFactor = 1.5;
				}

				if (accumulatedForwardDisplacement > 5.f && (forwardDisplacement < (dt * currSpeed) * displacementToleranceFactor))
				{
					isInAutoJump = true;
					accumulatedForwardDisplacement = 0;
					Jump();
				}
			}
			else if (theGame.GetInGameConfigWrapper().GetVarValue('NewHorseControls', 'AutoStop') == "true" && !validSteeringCorrectionFound)
			{
				AutoStopIfNeeded(speedFactor);
			}
		}
		else if (parent.isCart && !(PerformInclinationTest( rl, fb ) || PerformWaterTest( rl, fb, waterDepth )))
		{
			TriggerNavStop();
		}
		else
		{
			if (theGame.GetInGameConfigWrapper().GetVarValue('NewHorseControls', 'AutoStop') == "true" && !validSteeringCorrectionFound)
			{
				if (AutoStopIfNeeded(speedFactor) == false)
				{
					ToggleSpeedLock( 'OnNavStop', false );

					parentActor.SetBehaviorVariable( 'canSlowWalk', 1.0f );	
				}
			}
			else
			{
				ToggleSpeedLock( 'OnNavStop', false );

				parentActor.SetBehaviorVariable( 'canSlowWalk', 1.0f );
			}
		}
		
		if( requestJump )
		{
			if( PerformObstructionJumpTest() && PerformWaterJumpTest() && PerformFallJumpTest() )
			{
				Jump();
			}
			else
			{
				if( !isRefusingToGo && parent.isInIdle && CanPlayCollisionAnim() && !isReversing ) 
				{
					parent.GenerateEvent( 'WallCollision' );
					collisionAnimTimestamp = theGame.GetEngineTimeAsSeconds();
				}
				requestJump = false;
			}
		}
		
		if( staminaBreak )
		{
			if ( parent.isCart )
				staminaBreakSpeed = WALK_SPEED;
			else
				staminaBreakSpeed = GALLOP_SPEED;

			if ( staminaCooldownTimer > staminaCooldown )
			{
				staminaBreak = false;
			}
			
			staminaCooldownTimer += dt;

			if(!isReversing)
				currSpeed = MinF( staminaBreakSpeed, currSpeed );

			destSpeed = currSpeed;
		}

		if ( currSpeed != destSpeed )
		{
			
			if(!isReversing)
				currSpeed = destSpeed;

			if ( currSpeed == MIN_SPEED && !parent.isInIdle )
				isSlowlyStopping = true;
			else
				isSlowlyStopping = false;
		}
		
		parent.InternalSetSpeedMultiplier( 1.f );
		CWSH_EmitSpeed();

		if(parent.lastRider == thePlayer)
		{
			parent.SetDistanceBasedSpeed( VecDistance(cachedPos,parent.GetWorldPosition()) );	
			cachedPos = parent.GetWorldPosition();
		
			if(isReversing)
				parentActor.SetBehaviorVariable( 'reverse', 1.0f );	
			else
				parentActor.SetBehaviorVariable( 'reverse', 0.0f );	
		}

		CalculateSoundParameters( dt );
		thePlayer.SoundParameter( "horse_speed", currSpeedSound, 'head' ); 
		actorParent.SoundParameter( "horse_stamina", actorParent.GetStatPercents( BCS_Stamina ) * 100 ); 

		previousUpdatePosition = parentActor.GetWorldPosition();
		CWSH_EndUpdate();
}
