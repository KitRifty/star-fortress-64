#define MAX_ENTITES 4096
#define MAX_BUTTONS 26

#define FSOLID_NOT_SOLID 0x0004
#define FSOLID_TRIGGER 0x0008

#define COLLISION_GROUP_DEBRIS 1

// Hud Element hiding flags (possibly outdated)
#define	HIDEHUD_WEAPONSELECTION		( 1<<0 )	// Hide ammo count & weapon selection
#define	HIDEHUD_FLASHLIGHT			( 1<<1 )
#define	HIDEHUD_ALL					( 1<<2 )
#define HIDEHUD_HEALTH				( 1<<3 )	// Hide health & armor / suit battery
#define HIDEHUD_PLAYERDEAD			( 1<<4 )	// Hide when local player's dead
#define HIDEHUD_NEEDSUIT			( 1<<5 )	// Hide when the local player doesn't have the HEV suit
#define HIDEHUD_MISCSTATUS			( 1<<6 )	// Hide miscellaneous status elements (trains, pickup history, death notices, etc)
#define HIDEHUD_CHAT				( 1<<7 )	// Hide all communication elements (saytext, voice icon, etc)
#define	HIDEHUD_CROSSHAIR			( 1<<8 )	// Hide crosshairs
#define	HIDEHUD_VEHICLE_CROSSHAIR	( 1<<9 )	// Hide vehicle crosshair
#define HIDEHUD_INVEHICLE			( 1<<10 )
#define HIDEHUD_BONUS_PROGRESS		( 1<<11 )	// Hide bonus progress display (for bonus map challenges)

#define MAX_MATERIAL_STRING_BITS 10
#define MAX_MATERIAL_STRINGS (1 << MAX_MATERIAL_STRING_BITS)
#define OVERLAY_MATERIAL_INVALID_STRING (MAX_MATERIAL_STRINGS - 1)

#define VGUI_SCREEN_ATTACHED_TO_VIEWMODEL 0x4

#define SF64_MAX_PILOT_NAME_LENGTH 64

#define SF64_PILOT_TOP_CLEAR (1 << 0)
#define SF64_PILOT_RIGHT_CLEAR (1 << 1)
#define SF64_PILOT_LEFT_CLEAR (1 << 2)
#define SF64_PILOT_BOTTOM_CLEAR (1 << 3)

enum
{
	Arwing_EntRef = 0,
	Arwing_Enabled,
	Arwing_Destroyed,
	Arwing_Obliterated,
	Arwing_ObliterateTime,
	Arwing_MaxHealth,
	Arwing_Health,
	Arwing_MaxSpeed,
	Arwing_Team,
	Arwing_Pilot,
	Arwing_PilotSequence,
	Arwing_PilotSequenceStartTime,
	Arwing_PilotSequenceEndTime,
	Arwing_IgnorePilotControls,
	Arwing_Intro,
	Arwing_IntroStartTime,
	Arwing_IntroEndTime,
	Arwing_Locked,
	Arwing_ForwardMove,
	Arwing_SideMove,
	Arwing_PitchRate,
	Arwing_YawRate,
	Arwing_RollRate,
	Arwing_AccelFactor,
	Arwing_Target,
	Arwing_Buttons,
	Arwing_CameraEnt,
	Arwing_CameraPitchRate,
	Arwing_CameraYawRate,
	Arwing_CameraRollRate,
	Arwing_CameraAngAccelFactor,
	Arwing_HasTiltAbility,
	Arwing_InTilt,
	Arwing_TiltDesiredDirection,
	Arwing_TiltDirection,
	Arwing_TiltDegrees,
	Arwing_TiltTurnRate,
	Arwing_LaserSpeed,
	Arwing_LaserLifeTime,
	Arwing_LaserDamage,
	Arwing_LaserHyperDamage,
	Arwing_NextLaserAttackTime,
	Arwing_LaserCooldown,
	Arwing_LaserMaxUpgradeLevel,
	Arwing_LaserUpgradeLevel,
	Arwing_ChargedLaserSpeed,
	Arwing_ChargedLaserLifeTime,
	Arwing_ChargedLaserDamage,
	Arwing_ChargedLaserDamageRadius,
	Arwing_ChargedLaserEnt,
	Arwing_ChargedLaserMaxUpgradeLevel,
	Arwing_ChargedLaserUpgradeLevel,
	Arwing_ChargedLaserStartTime,
	Arwing_ChargedLaserTrackDuration,
	Arwing_ChargedLaserChargeDuration,
	Arwing_ChargedLaserReady,
	Arwing_ChargedLaserKillTimer,
	Arwing_LastChargedLaserAttackTime,
	Arwing_NextChargedLaserAttackTime,
	Arwing_ChargedLaserCooldown,
	Arwing_SmartBombLifeTime,
	Arwing_SmartBombMaxSpeed,
	Arwing_SmartBombDamage,
	Arwing_SmartBombDamageRadius,
	Arwing_SmartBombMaxNum,
	Arwing_SmartBombTrackDuration,
	Arwing_SmartBombNum,
	Arwing_SmartBombEnt,
	Arwing_HasBarrelRollAbility,
	Arwing_InBarrelRoll,
	Arwing_BarrelRollStartTime,
	Arwing_BarrelRollRotateEnt,
	Arwing_BarrelRollRotatePosX,
	Arwing_BarrelRollRotatePosY,
	Arwing_BarrelRollRotatePosZ,
	Arwing_BarrelRollEnt,
	Arwing_LastBarrelRollTime,
	Arwing_BarrelRollDuration,
	Arwing_NextBarrelRollTime,
	Arwing_BarrelRollCooldown,
	Arwing_BarrelRollDesiredDirection,
	Arwing_BarrelRollDirection,
	Arwing_BarrelRollNum,
	Arwing_InDamageSequence,
	Arwing_LastDamageSequenceTime,
	Arwing_LastDamageSequenceUpdateTime,
	Arwing_DamageSequenceTimer,
	Arwing_DamageSequenceRedBlinkTimer,
	Arwing_DamageSequenceRedBlink,
	Arwing_MaxEnergy,
	Arwing_Energy,
	Arwing_EnergyRechargeRate,
	Arwing_EnergyRechargeTimer,
	Arwing_HasBrakeAbility,
	Arwing_InBrake,
	Arwing_LastBrakeTime,
	Arwing_BrakeSpeed,
	Arwing_BrakeEnergyBurnRate,
	Arwing_BrakeEnergyBurnTimer,
	Arwing_HasBoostAbility,
	Arwing_InBoost,
	Arwing_LastBoostTime,
	Arwing_BoostSpeed,
	Arwing_BoostEnergyBurnRate,
	Arwing_BoostEnergyBurnTimer,
	Arwing_HasSomersaultAbility,
	Arwing_InSomersault,
	Arwing_SomersaultTime,
	Arwing_LastSomersaultTime,
	Arwing_SomersaultDuration,
	Arwing_SomersaultTimer,
	Arwing_SomersaultYawAngle,
	Arwing_SomersaultAngleFactor,
	Arwing_SomersaultSpeed,
	Arwing_SomersaultEnergyBurnRate,
	Arwing_SomersaultEnergyBurnTimer,
	Arwing_HasUTurnAbility,
	Arwing_InUTurn,
	Arwing_UTurnTime,
	Arwing_LastUTurnTime,
	Arwing_UTurnDuration,
	Arwing_UTurnTimer,
	Arwing_UTurnPhase,
	Arwing_UTurnPhaseTimer,
	Arwing_UTurnSomersaultAngleFactor,
	Arwing_UTurnSomersaultDuration,
	Arwing_UTurnSomersaultSpeed,
	Arwing_UTurnBoostSpeed,
	Arwing_UTurnYawAngle,
	Arwing_UTurnEnergyBurnRate,
	Arwing_UTurnEnergyBurnTimer,
	Arwing_HealthBarStartEntity,
	Arwing_HealthBarEndEntity,
	Arwing_FakePilotModel,
	Arwing_InPilotSequence,
	Arwing_MaxStats
};

enum
{
	Laser_EntRef = 0,
	Laser_LastSpawnTime,
	Laser_LifeTime,
	Laser_IsHyperLaser,
	Laser_Team,
	Laser_Owner,
	Laser_Damage,
	Laser_TrailEnt,
	Laser_TrailLifeTime,
	Laser_MaxStats
};

enum
{
	ChargedLaser_EntRef = 0,
	ChargedLaser_LastSpawnTime,
	ChargedLaser_LifeTime,
	ChargedLaser_MaxSpeed,
	ChargedLaser_Damage,
	ChargedLaser_DamageRadius,
	ChargedLaser_Team,
	ChargedLaser_Owner,
	ChargedLaser_Target,
	ChargedLaser_Hit,
	ChargedLaser_IsCharging,
	ChargedLaser_ChargeStartTime,
	ChargedLaser_ChargeEndTime,
	ChargedLaser_IsTracking,
	ChargedLaser_TrackStrength,
	ChargedLaser_TrackDuration,
	ChargedLaser_TrackStartTime,
	ChargedLaser_TrackEndTime,
	ChargedLaser_TrailEnt1,
	ChargedLaser_TrailEnt2,
	ChargedLaser_TrailEnt3,
	ChargedLaser_MaxStats,
};

enum
{
	SBomb_EntRef = 0,
	SBomb_LastSpawnTime,
	SBomb_LifeTime,
	SBomb_MaxSpeed,
	SBomb_Damage,
	SBomb_DamageRadius,
	SBomb_Team,
	SBomb_Owner,
	SBomb_Target,
	SBomb_TrailEnt,
	SBomb_Detonated,
	SBomb_DetonateTimer,
	SBomb_DetonateHurtEnt,
	SBomb_DetonateHurtTimer,
	SBomb_DetonateStopHurtTimer,
	SBomb_DetonateKillTimer,
	SBomb_IsTracking,
	SBomb_TrackDuration,
	SBomb_MaxStats
};

enum
{
	TargetReticle_EntRef = 0,
	TargetReticle_Owner,
	TargetReticle_IsLockOn,
	TargetReticle_MaxStats
};

enum
{
	Effect_EntRef = 0,
	Effect_Type,
	Effect_Event,
	Effect_Owner,
	Effect_CustomIndex,
	Effect_ShouldCheckTeam,
	Effect_InKill,
	Effect_MaxStats,
};

enum EffectType
{
	EffectType_Invalid = -1,
	EffectType_Sprite = 0,
	EffectType_Smokestack,
	EffectType_Smoketrail,
	EffectType_Trail,
	EffectType_ParticleSystem
};

enum EffectEvent
{
	EffectEvent_All = -2,
	EffectEvent_Invalid = -1,
	EffectEvent_Constant = 0,
	EffectEvent_ArwingEnabled,
	EffectEvent_ArwingFullEnergy,
	EffectEvent_ArwingHealth75Pct,
	EffectEvent_ArwingHealth50Pct,
	EffectEvent_ArwingHealth25Pct,
	EffectEvent_ArwingFireLaser,
	EffectEvent_ArwingFireHyperLaser,
	EffectEvent_ArwingDamaged,
	EffectEvent_ArwingDestroyed,
	EffectEvent_ArwingObliterated,
	EffectEvent_ArwingBarrelRoll,
	EffectEvent_ArwingBoost,
	EffectEvent_ArwingBrake,
	EffectEvent_ArwingSomersault,
	EffectEvent_ArwingUTurn
};

enum
{
	Pickup_EntRef = 0,
	Pickup_Type,
	Pickup_Quantity,
	Pickup_Enabled,
	Pickup_CanRespawn,
	Pickup_RespawnTimer,
	Pickup_MaxStats
};

enum
{
	PickupType_Invalid = -1,
	PickupType_Laser = 0,
	PickupType_SmartBomb,
	PickupType_Ring,
	PickupType_Ring2
};

enum
{
	PickupGet_EntRef = 0,
	PickupGet_Type,
	PickupGet_Target,
	PickupGet_LastSpawnTime,
	PickupGet_MaxStats
};

enum
{
	HudElementType_Invalid = -1,
	HudElementType_Health = 0,
	HudElementType_Warning
};

enum
{
	HudElement_Owner = 1,
	HudElement_Type,
	HudElement_MinWidth,
	HudElement_MaxWidth,
	HudElement_MinHeight,
	HudElement_MaxHeight,
	HudElement_MinRange,
	HudElement_MaxRange,
	HudElement_CustomIndex,
	HudElement_Initializing,
	HudElement_OverlayMaterial,
	HudElement_InitializeTimer,
	HudElement_MaxStats
};

enum
{
	Music_Channel = 0,
	Music_Volume,
	Music_Pitch,
	Music_Flags,
	Music_MaxStats
};

enum
{
	ActiveMusic_Id = 0,
	ActiveMusic_MusicIndex,
	ActiveMusic_MaxStats
};

enum
{
	PlayerActiveMusic_ActiveMusicId = 0,
	PlayerActiveMusic_FadeTimer,
	PlayerActiveMusic_Played,
	PlayerActiveMusic_MaxStats
};

enum
{
	FadingPlayerActiveMusic_Channel = 0,
	FadingPlayerActiveMusic_Volume,
	FadingPlayerActiveMusic_Pitch,
	FadingPlayerActiveMusic_FadeTimer,
	FadingPlayerActiveMusic_MaxStats
};

enum AIState
{
	AIState_Dead = 0,
	AIState_Idle,
	AIState_Alert,
	AIState_Combat
};

enum AICondition
{
	AICondition_LightDamage = 1,
	AICondition_SeeEnemy,
	AICondition_SeeSmartBomb,
	AICondition_SeeChargedLaser,
	
};

enum AISchedule
{
	AISchedule_Invalid = -1,
	AISchedule_None = 0,
	AISchedule_PatrolArea,
	AISchedule_ScriptedFollowPath,
	AISchedule_ChaseEnemy,
	AISchedule_GetBehindEnemy,
	AISchedule_EstablishLineOfSightToEnemy,
	AISchedule_AttackEnemy,
	AISchedule_RunFromEnemy,
	AISchedule_TakeCoverFromEnemy,
	AISchedule_FindHealth,
	AISchedule_FindSupplies
};

enum AIScheduleTask
{
	AIScheduleTask_Invalid = -1,
	AIScheduleTask_DodgeEnemyFire,
	AIScheduleTask_GetChasePathToEnemyLOS,
	AIScheduleTask_GetPathToTarget,
	AIScheduleTask_SetToleranceDistance,
	AIScheduleTask_FollowPath,
	AIScheduleTask_WaitForMovement,
	AIScheduleTask_FaceEnemy,
	AIScheduleTask_RangeAttack,
	AIScheduleTask_SpecialAttack,
};