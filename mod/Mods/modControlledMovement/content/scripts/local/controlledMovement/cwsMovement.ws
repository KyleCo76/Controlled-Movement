// Numerical Player requests; native gait, animation, input and publication remain native.
enum ECWSPlayerPaceKind
{
    CWS_PaceOther,
    CWS_PaceZero,
    CWS_PaceWalk,
    CWS_PaceRun,
    CWS_PaceTurn,
    CWS_PaceSprint
}

@addField(CPlayer) private var CWS_nativeCalculation : bool;
@addField(CPlayer) private var CWS_nativeCommand : int;
@addField(CPlayer) private var CWS_nativeRevision : int;
@addField(CPlayer) private var CWS_nativeInput : CPlayerInput;
@addField(CPlayer) private var CWS_nativeContext : name;
@addField(CPlayer) private var CWS_nativeController : CR4LocomotionPlayerControllerScript;
@addMethod(CPlayer)
public function CWS_IsNativeCalculation() : bool
{
    return CWS_nativeCalculation && (CR4Player)this == thePlayer
        && CWS_nativeCommand == CWS_GetState().CWS_PlayerCommandRevision()
        && CWS_nativeRevision == CWS_GetState().CWS_MotionRevision()
        && CWS_nativeInput == theGame.CWS_Input && CWS_nativeContext == theInput.GetContext()
        && CWS_GetState().CWS_IsPlayerController(CWS_nativeController);
}
@addMethod(CPlayer)
public function CWS_BeginNativeCalculation(controller : CR4LocomotionPlayerControllerScript) : bool
{
    if (CWS_nativeCalculation)
        return false;
    CWS_nativeCalculation = true;
    CWS_nativeCommand = CWS_GetState().CWS_PlayerCommandRevision();
    CWS_nativeRevision = CWS_GetState().CWS_MotionRevision();
    CWS_nativeInput = theGame.CWS_Input;
    CWS_nativeContext = theInput.GetContext();
    CWS_nativeController = controller;
    return true;
}
@addMethod(CPlayer)
public function CWS_EndNativeCalculation()
{
    CWS_nativeCalculation = false;
    CWS_nativeInput = NULL;
    CWS_nativeController = NULL;
    CWS_EndFluidCalculation();
}

// Observe the final Geralt permission, including ranged/stamina restrictions.
@wrapMethod(W3PlayerWitcher)
function CanSprint(speed : float) : bool
{
    var allowed : bool;
    CWS_BeginDerivedSprint();
    allowed = wrappedMethod(speed);
    CWS_EndDerivedSprint();
    CWS_RecordSprintPermission(allowed);
    if (CWS_IsSprintProbe())
        return false;
    return allowed;
}

@addField(CR4LocomotionPlayerControllerScript) private var cwsInUpdate : bool;
@addField(CR4LocomotionPlayerControllerScript) private var cwsFrameInvalid : bool;
@addField(CR4LocomotionPlayerControllerScript) private var cwsFrameCalculated : bool;
@addField(CR4LocomotionPlayerControllerScript) private var cwsFrameEligible : bool;
@addField(CR4LocomotionPlayerControllerScript) private var cwsFramePrepared : bool;
@addField(CR4LocomotionPlayerControllerScript) private var cwsFramePlayer : CR4Player;
@addField(CR4LocomotionPlayerControllerScript) private var cwsFrameInput : CPlayerInput;
@addField(CR4LocomotionPlayerControllerScript) private var cwsFrameContext : name;
@addField(CR4LocomotionPlayerControllerScript) private var cwsFrameRevision : int;
@addField(CR4LocomotionPlayerControllerScript) private var cwsFrameCommand : int;
@addField(CR4LocomotionPlayerControllerScript) private var cwsFrameNativeInput : float;
@addField(CR4LocomotionPlayerControllerScript) private var cwsFrameNativeSpeed : float;
@addField(CR4LocomotionPlayerControllerScript) private var cwsFrameCandidate : float;
@addField(CR4LocomotionPlayerControllerScript) private var cwsFrameResolved : float;
@addField(CR4LocomotionPlayerControllerScript) private var cwsFrameKind : ECWSPlayerPaceKind;
@addField(CR4LocomotionPlayerControllerScript) private var cwsFrameRaw : bool;
@addField(CR4LocomotionPlayerControllerScript) private var cwsFramePriorCache : float;
@addField(CR4LocomotionPlayerControllerScript) private var cwsOwnsCache : bool;
@addField(CR4LocomotionPlayerControllerScript) private var cwsOwnsMove : bool;
@addField(CR4LocomotionPlayerControllerScript) private var cwsOwnedCustomSpeed : float;
@addField(CR4LocomotionPlayerControllerScript) private var cwsOwnedNativeSpeed : float;
@addField(CR4LocomotionPlayerControllerScript) private var cwsPendingCoast : bool;
@addField(CR4LocomotionPlayerControllerScript) private var cwsPendingCustomSpeed : float;
@addField(CR4LocomotionPlayerControllerScript) private var cwsPendingNativeSpeed : float;
@addField(CR4LocomotionPlayerControllerScript) private var cwsFrameHasOverlay : bool;
@addField(CR4LocomotionPlayerControllerScript) private var cwsFrameCustomSpeed : float;
@addField(CR4LocomotionPlayerControllerScript) private var cwsFrameFallback : float;

@addMethod(CR4LocomotionPlayerControllerScript)
private function CWS_RemoveSpeedOverlay(keepCoast : bool)
{
    cwsPendingCoast = false;
    if (cwsOwnsCache && cachedMoveSpeed == cwsOwnedCustomSpeed)
    {
        cachedMoveSpeed = cwsOwnedNativeSpeed;
        if (keepCoast)
        {
            cwsPendingCoast = true;
            cwsPendingCustomSpeed = cwsOwnedCustomSpeed;
            cwsPendingNativeSpeed = cwsOwnedNativeSpeed;
        }
    }
    if (cwsOwnsMove && moveSpeed == cwsOwnedCustomSpeed)
        moveSpeed = cwsOwnedNativeSpeed;
    cwsOwnsCache = false;
    cwsOwnsMove = false;
}

@addMethod(CR4LocomotionPlayerControllerScript)
private function CWS_PlayerFrameOwned() : bool
{
    return cwsInUpdate && !cwsFrameInvalid && player == cwsFramePlayer
        && CWS_GetState().CWS_IsPlayerController(this)
        && player == thePlayer && cwsFrameInput && cwsFrameInput == theGame.CWS_Input
        && CWS_GetState().CWS_PlayerSessionOwned(player, theGame.GetEngineTimeAsSeconds())
        && cwsFrameContext == theInput.GetContext() && CWS_IsEligible(player)
        && !player.IsInCombatActionFriendly() && !player.GetBInteractionPressed()
        && cwsFrameRevision == CWS_GetState().CWS_MotionRevision()
        && cwsFrameCommand == CWS_GetState().CWS_PlayerCommandRevision();
}

@addMethod(CR4LocomotionPlayerControllerScript)
public function CWS_PreparePlayerCalculation(nativeInput : float)
{
    var raw : Vector;
    cwsFrameCalculated = true;
    cwsFrameNativeInput = nativeInput;
    cwsFramePrepared = false;
    if (!CWS_PlayerFrameOwned() || speedWalkingMax != 0.6f || speedRunning != 1.0f)
        return;
    raw.X = theInput.GetActionValue('GI_AxisLeftX');
    raw.Y = theInput.GetActionValue('GI_AxisLeftY');
    cwsFrameRaw = raw.X != 0.0f || raw.Y != 0.0f;
    if (nativeInput != 0.0f && nativeInput != 1.0f && nativeInput != VecLength2D(raw))
        return;
    cwsFrameEligible = true;
    if (!cwsFrameRaw)
    {
        // Native readiness may retain positive input during the first release frame.
        // Keep its last accepted scalar without spending curve time or sprint intent.
        if (nativeInput > 0.0f && cwsPendingCoast)
        {
            cwsFramePrepared = true;
            cwsFrameCandidate = CWS_GetState().CWS_PlayerCoastPace(cwsPendingCustomSpeed);
        }
        return;
    }
    if (nativeInput <= 0.0f)
        return;
    if (!player.CWS_BeginNativeCalculation(this))
    {
        cwsFrameInvalid = true;
        return;
    }
    cwsFramePrepared = true;
    cwsFrameCandidate = CWS_GetState().CWS_PreviewPlayerPace(theGame.GetEngineTimeAsSeconds());
    player.CWS_PrepareFluidSprint(nativeInput);
}

@addMethod(CR4LocomotionPlayerControllerScript)
public function CWS_ResolvePlayerResult(nativeSpeed : float, kind : ECWSPlayerPaceKind, nativeForcedTurn : bool) : float
{
    var result : float;
    cwsFrameNativeSpeed = nativeSpeed;
    cwsFrameKind = kind;
    result = nativeSpeed;
    if (cwsFramePrepared && CWS_PlayerFrameOwned() && nativeSpeed > 0.0f
        && ((kind == CWS_PaceWalk && nativeSpeed == speedWalkingMax)
            || (kind == CWS_PaceRun && nativeSpeed == MinF(cwsFrameNativeInput, speedRunning))
            || (kind == CWS_PaceTurn && nativeForcedTurn && nativeSpeed == speedWalkingMax)
            || (kind == CWS_PaceSprint && player.CWS_HasOwnedSprint() && nativeSpeed == speedSprinting)))
    {
        cwsFrameCandidate = CWS_GetState().CWS_LimitPace(cwsFrameCandidate);
        result = cwsFrameCandidate;
        if (kind == CWS_PaceTurn)
            result = MinF(result, nativeSpeed);
        cwsFrameHasOverlay = true;
        cwsFrameCustomSpeed = result;
        cwsFrameFallback = nativeSpeed;
    }
    // Preserve native stopping using the last owned cache's original association.
    if (CWS_PlayerFrameOwned() && cwsFrameEligible && !cwsFrameRaw
        && kind == CWS_PaceZero && nativeSpeed == 0.0f
        && cwsPendingCoast && cachedMoveSpeed == cwsPendingNativeSpeed)
    {
        cwsFrameCustomSpeed = CWS_GetState().CWS_PlayerCoastPace(cwsPendingCustomSpeed);
        cachedMoveSpeed = cwsFrameCustomSpeed;
        cwsFrameHasOverlay = true;
        cwsFrameFallback = cwsPendingNativeSpeed;
    }
    cwsFrameResolved = result;
    return result;
}

@addMethod(CR4LocomotionPlayerControllerScript)
public function CWS_FinalizePlayerFrame(now : float)
{
    var velocity : Vector;
    if (!cwsFrameCalculated || !cwsFrameEligible || !CWS_PlayerFrameOwned())
    {
        if (player == thePlayer && CWS_GetState().CWS_IsPlayerController(this)
            && cwsFrameCommand == CWS_GetState().CWS_PlayerCommandRevision())
            CWS_GetState().CWS_SuspendMotion();
        return;
    }
    if (!cwsFrameRaw && cwsFrameKind == CWS_PaceZero && cwsFrameNativeSpeed == 0.0f)
    {
        CWS_GetState().CWS_PausePlayerPace('coasting', moveSpeed, now);
        if (moveSpeed == 0.0f && (cwsFramePriorCache <= 0.0f
            || (stopCheckEnabled && now > stoppedTimeStamp + stoppedTimeStampDelta)))
        {
            velocity = player.GetMovingAgentComponent().GetVelocity();
            if (VecLengthSquared(velocity) < 0.25f && CWS_PlayerFrameOwned())
                CWS_GetState().CWS_ConfirmPlayerRest(player, now, cwsFrameCommand);
        }
    }
    else if (!cwsFrameRaw && cwsFrameHasOverlay)
        CWS_GetState().CWS_PausePlayerPace('coasting', moveSpeed, now);
    else if (cwsFrameRaw && cwsFrameNativeInput == 0.0f && cwsFrameKind == CWS_PaceZero)
        CWS_GetState().CWS_PausePlayerPace('readiness_wait', moveSpeed, now);
    else if (cwsFramePrepared && cwsFrameHasOverlay)
        CWS_GetState().CWS_CommitPlayerPace(now, cwsFrameCandidate, moveSpeed, cwsFrameKind);
    else
        CWS_GetState().CWS_SuspendMotion();
}

@wrapMethod(CR4LocomotionPlayerControllerScript)
function UpdateLocomotion()
{
    var nested : bool;
    nested = cwsInUpdate;
    if (nested)
    {
        cwsFrameInvalid = true;
        if (cwsFramePlayer)
            cwsFramePlayer.CWS_EndNativeCalculation();
    }
    else
    {
        CWS_RemoveSpeedOverlay(true);
        cwsInUpdate = true;
        cwsFrameInvalid = false;
        cwsFrameCalculated = false;
        cwsFrameEligible = false;
        cwsFramePrepared = false;
        cwsFrameHasOverlay = false;
        cwsFrameRaw = false;
        cwsFrameCandidate = 0.0f;
        cwsFrameKind = CWS_PaceOther;
        cwsFramePlayer = player;
        cwsFrameInput = theGame.CWS_Input;
        cwsFrameContext = theInput.GetContext();
        cwsFramePriorCache = cachedMoveSpeed;
        if (player == thePlayer)
        {
            CWS_GetState().CWS_BindPlayerController(this);
            CWS_GetState().CWS_ObserveMotionInput(player, theGame.GetEngineTimeAsSeconds());
            CWS_GetState().CWS_FluidPoll();
        }
        cwsFrameRevision = CWS_GetState().CWS_MotionRevision();
        cwsFrameCommand = CWS_GetState().CWS_PlayerCommandRevision();
    }
    wrappedMethod();
    if (nested)
        return;
    CWS_FinalizePlayerFrame(theGame.GetEngineTimeAsSeconds());
    if (cwsFramePlayer)
    {
        cwsFramePlayer.CWS_EndNativeCalculation();
        if ((!cwsFrameEligible || cwsFrameInvalid) && cwsFramePlayer == thePlayer
            && CWS_GetState().CWS_IsPlayerController(this))
            cwsFramePlayer.CWS_SuspendFluidSprint();
    }
    if (cwsFrameHasOverlay)
    {
        cwsOwnedCustomSpeed = cwsFrameCustomSpeed;
        cwsOwnedNativeSpeed = cwsFrameFallback;
        cwsOwnsCache = cachedMoveSpeed == cwsOwnedCustomSpeed;
        cwsOwnsMove = moveSpeed == cwsOwnedCustomSpeed;
    }
    if (cwsFrameInvalid || player != cwsFramePlayer || !CWS_IsEligible(player)
        || cwsFrameInput != theGame.CWS_Input || cwsFrameContext != theInput.GetContext())
        CWS_RemoveSpeedOverlay(false);
    CWS_PlayerTraceFrame();
    cwsInUpdate = false;
    cwsPendingCoast = false;
    cwsFramePlayer = NULL;
    cwsFrameInput = NULL;
    if (player == thePlayer)
        CWS_GetState().CWS_ValueReadoutPoll();
}

@wrapMethod(CR4LocomotionPlayerControllerScript)
function Deactivate()
{
    var ownsSession : bool;
    ownsSession = player == thePlayer && CWS_GetState().CWS_IsPlayerController(this);
    if (ownsSession)
    {
        CWS_GetState().CWS_SuspendMotion();
        CWS_GetState().CWS_FluidRelease();
    }
    CWS_RemoveSpeedOverlay(false);
    if (player && ownsSession)
        player.CWS_EndNativeCalculation();
    cwsInUpdate = false;
    cwsFrameInvalid = true;
    cwsFramePlayer = NULL;
    cwsFrameInput = NULL;
    wrappedMethod();
}

// Native body: Copyright 2015 CD PROJEKT S.A. All rights reserved.
// THE WITCHER is a trademark of CD PROJEKT S.A.; based on Andrzej Sapkowski prose.
// BEGIN modControlledMovement native scalar boundary
@replaceMethod(CR4LocomotionPlayerControllerScript)
function CalculateMoveSpeed() : float
	{
    var cwsKind : ECWSPlayerPaceKind;
		var speedVec 		: Vector;
		var speed 			: float;
		var rawRightJoyVec	: Vector;
		var tempInt			: int;
		var terrainAngles	: EulerAngles;
		var currentTime		: float;
		var forceWalkSpeed	: bool;
    cwsKind = CWS_PaceOther;



		if ( thePlayer.IsCameraControlDisabled( 'Finisher' ) )
		{
			speed = 0;
		}
		else if ( _inputLocoEnabled )
		{
			speed = _inputMagLastCached;
		}
		else
		{


			speed	= thePlayer.substateManager.m_InputO.GetModuleF();
		}


        CWS_PreparePlayerCalculation(speed);

		if( thePlayer.IsSwimming() )
		{
			if ( thePlayer.rangedWeapon
				&& thePlayer.rangedWeapon.GetCurrentStateName() != 'State_WeaponWait'
				&& thePlayer.rangedWeapon.GetCurrentStateName() != 'State_WeaponHolster' )
			{
				speed = 0;
			}
		}

		player.terrainPitch 		= 90.0f - player.substateManager.m_MoverO.GetRealSlideAngle();






		if( thePlayer.CanSprint( speed ) )
		{
			if ( thePlayer.IsInCombat()
				&& thePlayer.moveTarget
				&& VecDistance( thePlayer.moveTarget.GetWorldPosition(), thePlayer.GetWorldPosition() ) < thePlayer.findMoveTargetDistMax )
			{
				thePlayer.SetIsSprinting(true);

				if ( thePlayer.modifyPlayerSpeed || thePlayer.interiorCamera )
					thePlayer.EnableSprintingCamera( false );
				else if ( thePlayer.GetSprintingTime() > 0.2 && !thePlayer.IsInCombatAction() )
					thePlayer.EnableSprintingCamera( true );
				else
					thePlayer.EnableSprintingCamera( false );
			}
			else
			{
				thePlayer.SetIsSprinting(true);

				if ( thePlayer.modifyPlayerSpeed || thePlayer.interiorCamera  )
					thePlayer.EnableSprintingCamera( false );
				else
					thePlayer.EnableSprintingCamera( true );
			}
		}
		else
		{

			if ( !player.disableSprintingTimerEnabled && player.GetIsSprinting() )
			{
				player.disableSprintingTimerEnabled = true;
				player.AddTimer( 'DisableSprintingTimer', 0.25f );
			}
		}


		if ( player.modifyPlayerSpeed )
		{
			if ( speed > 0.0f )
			{
				if ( thePlayer.IsRunPressed() )
					speed = speedRunning;
				else
					speed = ClampF( speed, 0.f, speedWalkingMax );
			}
		}

		else if( !thePlayer.IsActionAllowed( EIAB_Sprint ) && thePlayer.IsActionAllowed( EIAB_RunAndSprint ) && !thePlayer.IsCombatMusicEnabled() )
		{
			if ( speed <= 0.f )
			{
				player.playerMoveType = PMT_Idle;
			}
			else if( thePlayer.IsSprintActionPressed() )
			{

				if(theInput.LastUsedGamepad() && thePlayer.GetLeftStickSprint() && thePlayer.IsInInterior() && !thePlayer.GetIsSprintToggled())
				{
					speed = MapF( MinF( speed, speedRunning ), 0.0f, speedRunning, 0.0f,  speedWalkingMax );
					player.playerMoveType = PMT_Walk;
				}

				else if ( speed > 0.8f )
				{
					speed = MinF( speed, speedRunning );
					player.playerMoveType = PMT_Run;
				}
				else
				{
					speed = speedWalkingMax;
					player.playerMoveType = PMT_Walk;
				}
			}
			else
			{
				speed = MapF( MinF( speed, speedRunning ), 0.0f, speedRunning, 0.0f,  speedWalkingMax );
				player.playerMoveType = PMT_Walk;
			}
		}

		else
		{
			if ( theInput.LastUsedGamepad() )
			{
				thePlayer.SetWalkToggle(false);

			}

			if ( speed <= 0.f )
			{
				player.playerMoveType = PMT_Idle;
                cwsKind = CWS_PaceZero;
			}
			else if (!theGame.IsFading() && !theGame.IsBlackscreen())
			{
				if ( player.GetIsSprinting() )
				{
					speed = speedSprinting;
					player.playerMoveType = PMT_Sprint;
                cwsKind = CWS_PaceSprint;
				}
				else if ( speed > thePlayer.GetInputModuleNeededToRun()
						&& ( thePlayer.IsActionAllowed( EIAB_RunAndSprint ) || thePlayer.IsCombatMusicEnabled() )
						&& ( ( thePlayer.GetPlayerCombatStance() == PCS_Normal && !thePlayer.GetIsWalkToggled() )
							|| thePlayer.GetPlayerCombatStance() == PCS_AlertFar
							|| ( !thePlayer.GetIsWalkToggled() && !thePlayer.IsInCombat() && VecLength2D( speedVec ) > thePlayer.GetInputModuleNeededToRun() ) )
						)
				{
					speed =  MinF( speed, speedRunning );
					player.playerMoveType = PMT_Run;
                cwsKind = CWS_PaceRun;

					currentTime = EngineTimeToFloat( theGame.GetEngineTime() );

					if ( localMoveDirection > 0.7f )
					{
						if ( !isCheckingCommitToRightTurn )
						{
							isCheckingCommitToRightTurn = true;
							commitToRightTurnTimeStamp = currentTime;
						}

						if ( isCheckingCommitToRightTurn )
						{
							if ( currentTime >= commitToRightTurnTimeStamp + 0.25 )
							{
								directionSwitchTimeStampDelta = 0.f;
								isCheckingCommitToRightTurn = false;
								isTurningRight = true;
							}
						}
					}
					else if ( localMoveDirection < -0.7f )
					{
						if ( !isCheckingCommitToLeftTurn )
						{
							isCheckingCommitToLeftTurn = true;
							commitToLeftTurnTimeStamp = currentTime;
						}

						if ( isCheckingCommitToLeftTurn )
						{
							if ( currentTime >= commitToLeftTurnTimeStamp + 0.25f )
							{
								directionSwitchTimeStampDelta = 0.f;
								isCheckingCommitToLeftTurn = false;
								isTurningLeft = true;
							}
						}
					}

					if ( localMoveDirection > 0.f )
					{
						useLeftTurnTimeStamp = false;
						if ( isTurningLeft )
						{
							directionSwitchTimeStamp = currentTime;
							directionSwitchTimeStampDelta = 1.f;
							startRightTurnTimeStamp = currentTime;
							useRightTurnTimeStamp = true;
						}

						if ( useRightTurnTimeStamp && localMoveDirection > 0.3f )
						{
							if ( currentTime >= startRightTurnTimeStamp + 0.25 )
							{
								directionSwitchTimeStampDelta = 0.f;
							}
						}

						isTurningLeft = false;
						isCheckingCommitToLeftTurn = false;
					}
					else if ( localMoveDirection < 0.f )
					{
						useRightTurnTimeStamp = false;
						if ( isTurningRight )
						{
							directionSwitchTimeStamp = currentTime;
							directionSwitchTimeStampDelta = 1.f;
							startLeftTurnTimeStamp = currentTime;
							useLeftTurnTimeStamp = true;
						}

						if ( useLeftTurnTimeStamp && localMoveDirection < -0.3f )
						{
							if ( currentTime >= startLeftTurnTimeStamp + 0.25f )
							{
								directionSwitchTimeStampDelta = 0.f;
							}
						}

						isTurningRight = false;
						isCheckingCommitToRightTurn = false;
					}

					if ( currentTime < directionSwitchTimeStamp + directionSwitchTimeStampDelta )
					{
						if ( localMoveDirection >= -0.3f && localMoveDirection <= 0.3f )
						{
							if ( !isCheckingCentered )
							{
								isCheckingCentered = true;
								directionCenteredTimeStamp = currentTime;
							}
							else
							{
								if ( currentTime >= directionCenteredTimeStamp + 0.f )
								{
									isCheckingCentered = false;
									directionSwitchTimeStampDelta = 0.f;
									isCheckingCommitToRightTurn = false;
									isCheckingCommitToLeftTurn = false;
								}
							}
						}
						else
							isCheckingCentered = false;

						forceWalkSpeed = true;
                    cwsKind = CWS_PaceTurn;
						speed = speedWalkingMax;
					}
					else
						isCheckingCentered = false;

					if ( forceWalkSpeed )
						player.SetBehaviorVariable( 'forceWalkSpeed', 1 );
					else
						player.SetBehaviorVariable( 'forceWalkSpeed', 0 );
				}
				else
				{
					speed = speedWalkingMax;
					player.playerMoveType = PMT_Walk;
                cwsKind = CWS_PaceWalk;
				}
			}
			else
			{
				speed = speedWalkingMax;
				player.playerMoveType = PMT_Walk;
			}
		}

		if ( player.playerMoveType < PMT_Walk || (player.playerMoveType <= PMT_Run && !theGame.IsFocusModeActive() && !thePlayer.IsInAir()) )
		{
			if(thePlayer.IsInInterior() && player.playerMoveType >= PMT_Walk )
			{
				if(thePlayer.IsInCombat() && thePlayer.GetStatPercents(BCS_Stamina) <= 0.f)
					thePlayer.SetSprintToggle( false );
			}
			else if(!thePlayer.IsActionAllowed( EIAB_Sprint ) && thePlayer.IsActionAllowed( EIAB_RunAndSprint ) && player.playerMoveType >= PMT_Walk)
			{}
			else
				thePlayer.SetSprintToggle( false );
		}





		tempInt = (int)( player.playerMoveType );
		player.substateManager.SetBehaviorParamBool(  'onSteepSlope', thePlayer.IsTerrainTooSteepToRunUp() );
		player.SetBehaviorVariable( 'terrainPitch', player.terrainPitch );
		player.SetBehaviorVariable( 'playerMoveType', tempInt );
		player.SetBehaviorVariable( 'playerMoveTypeForOverlay', tempInt );
		player.substateManager.SetBehaviorParamBool( 'runInputPressed', thePlayer.IsSprintActionPressed() );
		player.substateManager.SetBehaviorParamBool( 'ikWeight',  player.playerMoveType == PMT_Walk || player.playerMoveType == PMT_Idle );



		rawRightJoyVec.X = theInput.GetActionValue( 'GI_AxisRightX' );
		rawRightJoyVec.Y = theInput.GetActionValue( 'GI_AxisRightY' );
		player.SetBehaviorVariable( 'cameraSpeed', VecLength2D( rawRightJoyVec ) );


		return CWS_ResolvePlayerResult(speed, cwsKind, forceWalkSpeed);
	}
// END modControlledMovement native scalar boundary
