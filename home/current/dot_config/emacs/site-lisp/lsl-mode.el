;; ---------------------------------------------------------------------------
;;; lsl-mode.el --- major mode for editing LSL scripts (Linden Scripting
;;; Language)

;; Copyright (C) 2006 Reinhard Neurocam

;; This program is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by the
;; Free Software Foundation; either version 2, or (at your option) any
;; later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License along
;; with this program; see the file COPYING.  If not, write to the Free
;; Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
;; 02111-1307, USA.

;; COMMENTS:
;; This major mode is a simple derived mode from c-mode.el, setting
;; indentation-defaults to be consistent with the SL-editor, and
;; introducing new font-lock keywords

;; To install lsl-mode, put lsl-mode.el in your user elisp directory. I
;; recommend adding the following code to your ~/.emacs file.
;;
;; (add-to-list 'load-path "<path-user-elisp>")
;;(load "lsl-mode.el")
;;(require 'lsl-mode)
;;(setq auto-mode-alist (append auto-mode-alist
;;  (list
;;   '("\\.lsl$" . lsl-mode)
;;   )))

(eval-when-compile
  (let ((load-path
	  (if (and (boundp 'byte-compile-dest-file)
		     (stringp byte-compile-dest-file))
	           (cons (file-name-directory byte-compile-dest-file) load-path)
	       load-path)))
    (require 'cc-bytecomp)))

(load "cc-mode")
(require 'cc-mode)

;; -------------------- font-lock settings --------------------

;; ----- basic keywords and type

;;(regexp-opt '("integer" "float" "string" "key" "vector" "rotation" "list") t)
;; (regexp-opt '("for" "do" "while" "if" "else" "jump" "@.*") t)
;;(regexp-opt '("state_entry" "dataserver" "state_exit" "touch_start" "touch" "touch_end" "collision_start" "collision" "collision_end" "land_collision_start" "land_collision" "land_collision_end" "timer" "listen" "sensor" "no_sensor" "control" "at_target" "not_at_target" "at_rot_target" "not_at_rot_target" "money" "email" "run_time_permissions" "changed" "attach" "moving_start" "moving_end" "on_rez" "link_message") t)
;; (regexp-opt '("TRUE" "FALSE") t)
;; (regexp-opt '("PI" "TWO_PI" "PI_BY_TWO" "DEG_TO_RAD" "RAD_TO_DEG" "SQRT2" "NULL_KEY" "ZERO_VECTOR" "ZERO_ROTATION") t)
;; (regexp-opt '("STATUS_PHYSICS" "STATUS_PHANTOM" "STATUS_ROTATE_X" "STATUS_ROTATE_Y" "STATUS_ROTATE_Z" "AGENT" "ACTIVE" "PASSIVE" "SCRIPTED" "PERMISSION_DEBIT" "PERMISSION_TAKE_CONTROLS" "PERMISSION_REMAP_CONTROLS" "PERMISSION_TRIGGER_ANIMATION" "PERMISSION_ATTACH" "PERMISSION_RELEASE_OWNERSHIP" "PERMISSION_CHANGE_LINKS" "PERMISSION_CHANGE_JOINTS" "PERMISSION_CHANGE_PERMISSIONS" "INVENTORY_TEXTURE" "INVENTORY_SOUND" "INVENTORY_OBJECT" "INVENTORY_SCRIPT" "ATTACH_CHEST" "ATTACH_HEAD" "ATTACH_LSHOULDER" "ATTACH_RSHOULDER" "ATTACH_LHAND" "ATTACH_RHAND" "ATTACH_LFOOT" "ATTACH_RFOOT" "ATTACH_BACK" "LAND_LEVEL" "LAND_RAISE" "LAND_LOWER" "LAND_SMALL_BRUSH" "LAND_MEDIUM_BRUSH" "LAND_LARGE_BRUSH" "LINK_SET" "LINK_ROOT" "LINK_ALL_OTHERS" "LINK_ALL_CHILDREN" "CONTROL_FWD" "CONTROL_BACK" "CONTROL_LEFT" "CONTROL_RIGHT" "CONTROL_ROT_LEFT" "CONTROL_ROT_RIGHT" "CONTROL_UP" "CONTROL_DOWN" "CONTROL_LBUTTON" "CONTROL_ML_LBUTTON" "CHANGED_INVENTORY" "CHANGED_COLOR" "CHANGED_SHAPE" "CHANGED_SCALE" "CHANGED_TEXTURE" "CHANGED_LINK" "CHANGED_OWNER" "TYPE_INTEGER" "TYPE_FLOAT" "TYPE_STRING" "TYPE_KEY" "TYPE_VECTOR" "TYPE_QUATERNION" "TYPE_INVALID") t)
;;(regexp-opt '( "INVENTORY_ALL" "INVENTORY_NONE" "INVENTORY_TEXTURE" "INVENTORY_SOUND" "INVENTORY_LANDMARK" "INVENTORY_CLOTHING" "INVENTORY_OBJECT" "INVENTORY_NOTECARD" "INVENTORY_SCRIPT" "INVENTORY_BODYPART" "INVENTORY_ANIMATION" "INVENTORY_GESTURE" ) t)

(defvar rp-lsl-keywords
  '(("[^a-zA-Z_]\\(float\\|integer\\|key\\|list\\|rotation\\|string\\|vector\\)[^a-zA-Z_]" . font-lock-type-face)
    ("^\\(float\\|integer\\|key\\|list\\|rotation\\|string\\|vector\\)[^a-zA-Z_]" . font-lock-type-face)
    ("[^a-zA-Z_]\\(at\\(?:_\\(?:\\(?:rot_\\)?target\\)\\|tach\\)\\|c\\(?:hanged\\|o\\(?:llision\\(?:_\\(?:end\\|start\\)\\)?\\|ntrol\\)\\)\\|dataserver\\|email\\|l\\(?:and_collision\\(?:_\\(?:end\\|start\\)\\)?\\|i\\(?:nk_message\\|sten\\)\\)\\|mo\\(?:ney\\|ving_\\(?:end\\|start\\)\\)\\|no\\(?:_sensor\\|t_at_\\(?:\\(?:rot_\\)?target\\)\\)\\|on_rez\\|run_time_permissions\\|s\\(?:ensor\\|tate_e\\(?:ntry\\|xit\\)\\)\\|t\\(?:imer\\|ouch\\(?:_\\(?:end\\|start\\)\\)?\\)\\)[^a-zA-Z_]" 0 font-lock-builtin-face)
    ("\\(\\(?:FALS\\|TRU\\)E\\)" . font-lock-constant-face )
    ("\\(@\\.\\*\\|do\\|else\\|for\\|if\\|jump\\|while\\|return\\)" . font-lock-keyword-face)
    ("\\(DEG_TO_RAD\\|NULL_KEY\\|PI\\(?:_BY_TWO\\)?\\|RAD_TO_DEG\\|SQRT2\\|TWO_PI\\|ZERO_\\(?:ROTATION\\|VECTOR\\)\\)" . font-lock-constant-face)
    ("\\(A\\(?:CTIVE\\|GENT\\|TTACH_\\(?:BACK\\|CHEST\\|HEAD\\|L\\(?:FOOT\\|HAND\\|SHOULDER\\)\\|R\\(?:FOOT\\|HAND\\|SHOULDER\\)\\)\\)\\|C\\(?:HANGED_\\(?:COLOR\\|INVENTORY\\|LINK\\|OWNER\\|\\(?:S\\(?:CAL\\|HAP\\)\\|TEXTUR\\)E\\)\\|ONTROL_\\(?:BACK\\|DOWN\\|FWD\\|L\\(?:BUTTON\\|EFT\\)\\|ML_LBUTTON\\|R\\(?:\\(?:IGH\\|OT_\\(?:LEF\\|RIGH\\)\\)T\\)\\|UP\\)\\)\\|INVENTORY_\\(?:OBJECT\\|S\\(?:CRIPT\\|OUND\\)\\|TEXTURE\\)\\|L\\(?:AND_\\(?:L\\(?:ARGE_BRUSH\\|EVEL\\|OWER\\)\\|MEDIUM_BRUSH\\|RAISE\\|SMALL_BRUSH\\)\\|INK_\\(?:ALL_\\(?:CHILDREN\\|OTHERS\\)\\|\\(?:ROO\\|SE\\)T\\)\\)\\|P\\(?:ASSIVE\\|ERMISSION_\\(?:ATTACH\\|CHANGE_\\(?:\\(?:JOINT\\|LINK\\|PERMISSION\\)S\\)\\|DEBIT\\|RE\\(?:LEASE_OWNERSHIP\\|MAP_CONTROLS\\)\\|T\\(?:AKE_CONTROLS\\|RIGGER_ANIMATION\\)\\)\\)\\|S\\(?:CRIPTED\\|TATUS_\\(?:PH\\(?:ANTOM\\|YSICS\\)\\|ROTATE_[XYZ]\\)\\)\\|TYPE_\\(?:FLOAT\\|IN\\(?:TEGER\\|VALID\\)\\|KEY\\|QUATERNION\\|STRING\\|VECTOR\\)\\)" . font-lock-constant-face)
    ("\\(INVENTORY_\\(?:A\\(?:LL\\|NIMATION\\)\\|BODYPART\\|CLOTHING\\|GESTURE\\|LANDMARK\\|NO\\(?:NE\\|TECARD\\)\\|OBJECT\\|S\\(?:CRIPT\\|OUND\\)\\|TEXTURE\\)\\)" . font-lock-constant-face)
    ("\\<\\(FIXME\\):" 1 font-lock-warning-face t)
    ))

;; ----- LSL function-names
;;(regexp-opt '("llAbs" "llAcos" "llAddToLandBanList" "llAddToLandPassList" "llAdjustSoundVolume" "llAllowInventoryDrop" "llAngleBetween" "llApplyImpulse" "llApplyRotationalImpulse" "llAsin" "llAtan2" "llAttachToAvatar" "llAvatarOnSitTarget" "llAxes2Rot" "llAxisAngle2Rot" ) t)
(defvar rp-lsl-functions-a
  '(("\\(llA\\(?:bs\\|cos\\|d\\(?:dToLand\\(?:\\(?:Ban\\|Pass\\)List\\)\\|justSoundVolume\\)\\|llowInventoryDrop\\|ngleBetween\\|pply\\(?:\\(?:Rotational\\)?Impulse\\)\\|sin\\|t\\(?:an2\\|tachToAvatar\\)\\|\\(?:vatarOnSitTarge\\|x\\(?:\\(?:es\\|isAngle\\)2Ro\\)\\)t\\)\\)" . font-lock-function-name-face )
    ))

;;(regexp-opt '("llBase64ToString" "llBreakAllLinks" "llBreakLink" ) t)
(defvar rp-lsl-functions-b
  '(("\\(llB\\(?:ase64ToString\\|reak\\(?:AllLinks\\|Link\\)\\)\\)" . font-lock-function-name-face )
    ))

;;(regexp-opt '("llCSV2List" "llCeil" "llCloseRemoteDataChannel" "llCloud" "llCollisionFilter" "llCollisionSound" "llCollisionSprite" "llCos" "llCreateLink" ) t)
(defvar rp-lsl-functions-c '(("\\(llC\\(?:SV2List\\|eil\\|lo\\(?:seRemoteDataChannel\\|ud\\)\\|o\\(?:llision\\(?:Filter\\|S\\(?:ound\\|prite\\)\\)\\|s\\)\\|reateLink\\)\\)" . font-lock-function-name-face)))

;;(regexp-opt '("llDeleteSubList" "llDeleteSubString" "llDetachFromAvatar" "llDetectedGrab" "llDetectedGroup" "llDetectedKey" "llDetectedLinkNumber" "llDetectedName" "llDetectedOwner" "llDetectedPos" "llDetectedRot" "llDetectedType" "llDetectedVel" "llDialog" "llDie" "llDumpList2String" ) t)
(defvar rp-lsl-functions-d '(("\\(llD\\(?:e\\(?:leteSub\\(?:List\\|String\\)\\|t\\(?:achFromAvatar\\|ected\\(?:Gr\\(?:ab\\|oup\\)\\|Key\\|LinkNumber\\|Name\\|Owner\\|Pos\\|Rot\\|Type\\|Vel\\)\\)\\)\\|i\\(?:alog\\|e\\)\\|umpList2String\\)\\)" . font-lock-function-name-face )))

;;(regexp-opt '("llEdgeOfWorld" "llEjectFromLand" "llEmail" "llEscapeURL" "llEuler2Rot" ) t)
(defvar rp-lsl-functions-e '(("\\(llE\\(?:dgeOfWorld\\|jectFromLand\\|mail\\|scapeURL\\|uler2Rot\\)\\)" . font-lock-function-name-face )))

;;(regexp-opt '("llFabs" "llFloor" "llForceMouselook" "llFrand" ) t) 
(defvar rp-lsl-functions-f '(("\\(llF\\(?:abs\\|loor\\|orceMouselook\\|rand\\)\\)" . font-lock-function-name-face )))

;;(regexp-opt '("llGetAccel" "llGetAgentInfo" "llGetAgentSize" "llGetAlpha" "llGetAndResetTime" "llGetAnimation" "llGetAnimationList" "llGetAttached" "llGetBoundingBox" "llGetCameraPos" "llGetCameraRot" "llGetCenterOfMass" "llGetCreator" "llGetColor" "llGetDate" "llGetEnergy" "llGetForce" "llGetFreeMemory" "llGetGeometricCenter" "llGetGMTclock" "llGetInventoryCreator" "llGetInventoryKey" "llGetInventoryName" "llGetInventoryNumber" "llGetInventoryPermMask" "llGetInventoryType" "llGetKey" "llGetLandOwnerAt" "llGetLinkKey" "llGetLinkName" "llGetLinkNumber" "llGetListEntryType" "llGetListLength" "llGetLocalPos" "llGetLocalRot" "llGetMass" "llGetNextEmail" "llGetNotecardLine" "llGetNumberOfNotecardLines" "llGetNumberOfPrims" "llGetNumberOfSides" "llGetObjectDesc" "llGetObjectMass" "llGetObjectName" "llGetObjectPermMask" "llGetOmega" "llGetOwner" "llGetOwnerKey" "llGetPermissions" "llGetPermissionsKey" "llGetPos" "llGetPrimitiveParams" "llGetRegionCorner" "llGetRegionFPS" "llGetRegionName" "llGetRegionTimeDilation" "llGetRootPosition" "llGetRootRotation" "llGetRot" "llGetScale" "llGetScriptName" "llGetScriptState" "llGetSimulatorHostname" "llGetStartParameter" "llGetStatus" "llGetSubString" "llGetSunDirection" "llGetTexture" "llGetTextureOffset" "llGetTextureRot" "llGetTextureScale" "llGetTime" "llGetTimeOfDay" "llGetTimestamp" "llGetTorque" "llGetVel" "llGetWallclock" "llGiveInventory" "llGiveInventoryList" "llGiveMoney" "llGodLikeRezObject" "llGround" "llGroundContour" "llGroundNormal" "llGroundRepel" "llGroundSlope" ) t)
(defvar rp-lsl-functions-g '(("\\(llG\\(?:et\\(?:A\\(?:ccel\\|gent\\(?:Info\\|Size\\)\\|lpha\\|n\\(?:dResetTime\\|imation\\(?:List\\)?\\)\\|ttached\\)\\|BoundingBox\\|C\\(?:amera\\(?:Pos\\|Rot\\)\\|enterOfMass\\|\\(?:ol\\|reat\\)or\\)\\|Date\\|Energy\\|F\\(?:orce\\|reeMemory\\)\\|G\\(?:MTclock\\|eometricCenter\\)\\|Inventory\\(?:Creator\\|Key\\|N\\(?:ame\\|umber\\)\\|PermMask\\|Type\\)\\|Key\\|L\\(?:andOwnerAt\\|i\\(?:nk\\(?:Key\\|N\\(?:ame\\|umber\\)\\)\\|st\\(?:EntryType\\|Length\\)\\)\\|ocal\\(?:Pos\\|Rot\\)\\)\\|Mass\\|N\\(?:extEmail\\|otecardLine\\|umberOf\\(?:\\(?:NotecardLine\\|Prim\\|Side\\)s\\)\\)\\|O\\(?:bject\\(?:Desc\\|Mass\\|Name\\|PermMask\\)\\|mega\\|wner\\(?:Key\\)?\\)\\|P\\(?:ermissions\\(?:Key\\)?\\|\\(?:o\\|rimitiveParam\\)s\\)\\|R\\(?:egion\\(?:Corner\\|FPS\\|Name\\|TimeDilation\\)\\|o\\(?:ot\\(?:\\(?:Posi\\|Rota\\)tion\\)\\|t\\)\\)\\|S\\(?:c\\(?:\\(?:al\\|ript\\(?:Nam\\|Stat\\)\\)e\\)\\|imulatorHostname\\|ta\\(?:rtParameter\\|tus\\)\\|u\\(?:bString\\|nDirection\\)\\)\\|T\\(?:exture\\(?:Offset\\|Rot\\|Scale\\)?\\|ime\\(?:OfDay\\|stamp\\)?\\|orque\\)\\|Vel\\|Wallclock\\)\\|ive\\(?:Inventory\\(?:List\\)?\\|Money\\)\\|odLikeRezObject\\|round\\(?:Contour\\|Normal\\|Repel\\|Slope\\)?\\)\\)"  . font-lock-function-name-face )))

;;(regexp-opt '("llInsertString" "llInstantMessage" "llIntegerToBase64" ) t)
(defvar rp-lsl-functions-i '(("\\(llIn\\(?:s\\(?:ertString\\|tantMessage\\)\\|tegerToBase64\\)\\)" . font-lock-function-name-face )))

;;(regexp-opt '("llKey2Name") t)
(defvar rp-lsl-functions-k '(("\\(llKey2Name\\)" . font-lock-function-name-face)))

;(regexp-opt '("llList2CSV" "llList2Float" "llList2Integer" "llList2Key" "llList2List" "llList2ListStrided" "llList2Rot" "llList2String" "llList2Vector" "llListFindList" "llListInsertList" "llListRandomize" "llListReplaceList" "llListSort" "llListen" "ellListenControl" "llListenRemove" "llLoadURL" "llLog" "llLog10" "llLookAt" "llLoopSound" "llLoopSoundMaster" "llLoopSoundSlave" ) t)
(defvar rp-lsl-functions-l '(("\\(ellListenControl\\|llL\\(?:ist\\(?:2\\(?:CSV\\|Float\\|Integer\\|Key\\|List\\(?:Strided\\)?\\|Rot\\|String\\|Vector\\)\\|FindList\\|InsertList\\|R\\(?:andomize\\|eplaceList\\)\\|Sort\\|en\\(?:Remove\\)?\\)\\|o\\(?:adURL\\|g\\(?:10\\)?\\|o\\(?:kAt\\|pSound\\(?:Master\\|Slave\\)?\\)\\)\\)\\)" . font-lock-function-name-face)))

;(regexp-opt '("llMapDestination" "llMD5String" "llMessageLinked" "llMinEventDelay" "llModifyLand" "llModPow" "llMoveToTarget" ) t)
(defvar rp-lsl-functions-m '(("\\(llM\\(?:D5String\\|apDestination\\|essageLinked\\|inEventDelay\\|o\\(?:d\\(?:Pow\\|ifyLand\\)\\|veToTarget\\)\\)\\)" . font-lock-function-name-face)))

;(regexp-opt '("llOffsetTexture" "llOpenRemoteDataChannel" "llOverMyLand" "llOwnerSay" ) t)
(defvar rp-lsl-functions-o '(("\\(llO\\(?:ffsetTexture\\|penRemoteDataChannel\\|verMyLand\\|wnerSay\\)\\)" . font-lock-function-name-face)))

;(regexp-opt '("llParcelMediaCommandList" "llParcelMediaQuery" "llParseString2List" "llParseStringKeepNulls" "llParticleSystem" "llPassCollisions" "llPassTouches" "llPlaySound" "llPlaySoundSlave" "llPointAt" "llPow" "llPreloadSound" "llPushObject" ) t)
(defvar rp-lsl-functions-p '(("\\(llP\\(?:a\\(?:r\\(?:celMedia\\(?:CommandList\\|Query\\)\\|seString\\(?:2List\\|KeepNulls\\)\\|ticleSystem\\)\\|ss\\(?:\\(?:Collision\\|Touche\\)s\\)\\)\\|laySound\\(?:Slave\\)?\\|o\\(?:intAt\\|w\\)\\|reloadSound\\|ushObject\\)\\)" . font-lock-function-name-face)))

;(regexp-opt '("llRefreshPrimURL" "llReleaseCamera" "llReleaseControls" "llRemoteDataReply" "llRemoteDataSetRegion" "llRemoteLoadScriptPin" "llRemoveFromLandBanList" "llRemoveFromLandPassList" "llRemoveInventory" "llRemoveVehicleFlags" "llRequestAgentData" "llRequestInventoryData" "llRequestPermissions" "llRequestSimulatorData" "llResetOtherScript" "llResetScript" "llResetTime" "llRezAtRoot" "llRezObject" "llRot2Angle" "llRot2Axis" "llRot2Euler" "llRot2Fwd" "llRot2Left" "llRot2Up" "llRotBetween" "llRotLookAt" "llRotTarget" "llRotTargetRemove" "llRotateTexture" "llRound" ) t)
(defvar rp-lsl-functions-r  '(("\\(llR\\(?:e\\(?:freshPrimURL\\|leaseC\\(?:amera\\|ontrols\\)\\|mo\\(?:te\\(?:Data\\(?:Reply\\|SetRegion\\)\\|LoadScriptPin\\)\\|ve\\(?:FromLand\\(?:\\(?:Ban\\|Pass\\)List\\)\\|Inventory\\|VehicleFlags\\)\\)\\|quest\\(?:AgentData\\|InventoryData\\|Permissions\\|SimulatorData\\)\\|set\\(?:OtherScript\\|Script\\|Time\\)\\|z\\(?:\\(?:AtRoo\\|Objec\\)t\\)\\)\\|o\\(?:t\\(?:2\\(?:A\\(?:ngle\\|xis\\)\\|Euler\\|Fwd\\|Left\\|Up\\)\\|Between\\|LookAt\\|Target\\(?:Remove\\)?\\|ateTexture\\)\\|und\\)\\)\\)" . font-lock-function-name-face)))

;(regexp-opt '("llSameGroup" "llSay" "llScaleTexture" "llScriptDanger" "llSendRemoteData" "llSensor" "llSensorRemove" "llSensorRepeat" "llSetAlpha" "llSetBuoyancy" "llSetCameraAtOffset" "llSetCameraEyeOffset" "llSetColor" "llSetDamage" "llSetForce" "llSetForceAndTorque" "llSetHoverHeight" "llSetLinkAlpha" "llSetLinkColor" "llSetLocalRot" "llSetObjectDesc" "llSetObjectName" "llSetParcelMusicURL" "llSetPos" "llSetPrimURL" "llSetPrimitiveParams" "llSetPayPrice" "llSetRemoteScriptAccessPin" "llSetRot" "llSetScale" "llSetScriptState" "llSetSitText" "llSetSoundQueueing" "llSetSoundRadius" "llSetStatus" "llSetText" "llSetTexture" "llSetTextureAnim" "llSetTimerEvent" "llSetTorque" "llSetTouchText" "llSetVehicleFlags" "llSetVehicleFloatParam" "llSetVehicleRotationParam" "llSetVehicleType" "llSetVehicleVectorParam" "llShout" "llSin" "llSitTarget" "llSleep" "llSqrt" "llStartAnimation" "llStopAnimation" "llStopHover" "llStopLookAt" "llStopMoveToTarget" "llStopPointAt" "llStopSound" "llStringLength" "llStringToBase64" "llSubStringIndex") t)
(defvar rp-lsl-functions-s '(("\\(llS\\(?:a\\(?:meGroup\\|y\\)\\|c\\(?:aleTexture\\|riptDanger\\)\\|e\\(?:n\\(?:dRemoteData\\|sor\\(?:Re\\(?:move\\|peat\\)\\)?\\)\\|t\\(?:Alpha\\|Buoyancy\\|C\\(?:amera\\(?:\\(?:At\\|Eye\\)Offset\\)\\|olor\\)\\|Damage\\|Force\\(?:AndTorque\\)?\\|HoverHeight\\|L\\(?:ink\\(?:Alpha\\|Color\\)\\|ocalRot\\)\\|Object\\(?:Desc\\|Name\\)\\|P\\(?:a\\(?:rcelMusicURL\\|yPrice\\)\\|os\\|rim\\(?:URL\\|itiveParams\\)\\)\\|R\\(?:emoteScriptAccessPin\\|ot\\)\\|S\\(?:c\\(?:\\(?:al\\|riptStat\\)e\\)\\|itText\\|ound\\(?:Queueing\\|Radius\\)\\|tatus\\)\\|T\\(?:ext\\(?:ure\\(?:Anim\\)?\\)?\\|imerEvent\\|o\\(?:rque\\|uchText\\)\\)\\|Vehicle\\(?:Fl\\(?:ags\\|oatParam\\)\\|RotationParam\\|Type\\|VectorParam\\)\\)\\)\\|hout\\|i\\(?:n\\|tTarget\\)\\|leep\\|qrt\\|t\\(?:artAnimation\\|op\\(?:Animation\\|Hover\\|LookAt\\|MoveToTarget\\|PointAt\\|Sound\\)\\|ring\\(?:Length\\|ToBase64\\)\\)\\|ubStringIndex\\)\\)" . font-lock-function-name-face)))

;(regexp-opt '("llTakeCamera" "llTakeControls" "llTan" "llTarget" "llTargetOmega" "llTargetRemove" "llTeleportAgent" "llTeleportAgentHome" "llToLower" "llToUpper" "llTriggerSound" "llTriggerSoundLimited" ) t)
(defvar rp-lsl-functions-t '(("\\(llT\\(?:a\\(?:keC\\(?:amera\\|ontrols\\)\\|n\\|rget\\(?:Omega\\|Remove\\)?\\)\\|eleportAgent\\(?:Home\\)?\\|o\\(?:\\(?:Low\\|Upp\\)er\\)\\|riggerSound\\(?:Limited\\)?\\)\\)" . font-lock-function-name-face)))

;(regexp-opt '("llUnescapeURL" "llUnSit" ) t)
(defvar rp-lsl-functions-u '(("\\(llUn\\(?:Sit\\|escapeURL\\)\\)" . font-lock-function-name-face)))

;(regexp-opt '("llVecDist" "llVecMag" "llVecNorm" "llVolumeDetect" ) t)
(defvar rp-lsl-functions-v '(("\\(llV\\(?:ec\\(?:Dist\\|Mag\\|Norm\\)\\|olumeDetect\\)\\)" . font-lock-function-name-face)))

;(regexp-opt '("llWater" "llWhisper" "llWind" ) t)
(defvar rp-lsl-functions-w '(("\\(llW\\(?:ater\\|hisper\\|ind\\)\\)" . font-lock-function-name-face)))

;(regexp-opt '("llXorBase64Strings" ) t)
(defvar rp-lsl-functions-x '(("\\(llXorBase64Strings\\)" . font-lock-function-name-face)))

;(regexp-opt '("llMakeExplosion" "llMakeFire" "llMakeFountain" "llSound" "llSoundPreload") t)
(defvar rp-lsl-functions-deprecated '(("\\(ll\\(?:Make\\(?:Explosion\\|F\\(?:ire\\|ountain\\)\\)\\|Sound\\(?:Preload\\)?\\)\\)" . font-lock-warning-face)))

(defvar rp-lsl-function-names
  (append rp-lsl-functions-a rp-lsl-functions-b rp-lsl-functions-c rp-lsl-functions-d rp-lsl-functions-e rp-lsl-functions-f rp-lsl-functions-g rp-lsl-functions-i rp-lsl-functions-k rp-lsl-functions-l rp-lsl-functions-m rp-lsl-functions-o rp-lsl-functions-p rp-lsl-functions-r rp-lsl-functions-s rp-lsl-functions-t rp-lsl-functions-u rp-lsl-functions-v rp-lsl-functions-w rp-lsl-functions-x rp-lsl-functions-deprecated)
  )

(defvar rp-lsl-font-lock-keywords
  (append rp-lsl-keywords rp-lsl-function-names)
)

;; ----- end font-lock settings

(defun lsl-mode ()
  "Major mode for editing LSL scripts (Linden Scripting Language).

To see what version of CC Mode you are running, enter `\\[c-version]'.

The hook variable `lsl-mode-hook' is run with no args, if that value is
bound and has a non-nil value.  Also the hook `c-mode-common-hook' is
run first.

Key bindings:
\\{c-mode-map}"
  (interactive)
  (c-mode)
  (setq major-mode 'lsl-mode
	mode-name "LSL")
  ;; ----- lsl-specific settings
  ;; (setq c-echo-syntactic-information-p t);; uncomment for syntax/indentation debugging
  (setq indent-tabs-mode nil)
  (setq c-basic-offset 4)
  (c-set-offset 'substatement-open 0)
  (c-set-offset 'block-open 0)
  (c-set-offset 'statement-cont 0)
  (make-local-variable 'font-lock-defaults)
  (setq font-lock-defaults '(rp-lsl-font-lock-keywords))
  (turn-on-font-lock)
  ;;(font-lock-fontify-buffer)
  ;; -----
  (run-hooks 'lsl-mode-hook)
  (c-update-modeline))

(cc-provide 'lsl-mode)
;;;
