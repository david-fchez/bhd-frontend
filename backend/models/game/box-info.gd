extends Node
class_name BoxInfo
func get_class():
	return "BoxInfo"

func is_class(value):
	return value == "BoxInfo"
	
const BoxStatusOpen       = 1
const BoxStatusWarmup     = 2
const BoxStatusSimulating = 3
const BoxStatusPlaying    = 4
const BoxStatusClosed     = 5
const BoxStatusDeleting   = 6
const BoxStatusDeleted    = 7	
	
var BoxId 			 : String	
var Name  			 : String
var MinPlayerCount   : int
var MaxPlayerCount   : int
var PlayerCount 	 : int
var EntryFee 		 : int
var Reward 			 : int
var MaxBoxAge 		 : int
var CreationTime 	 : int
var Status 			 : int
var PhysicsData 	 : PoolByteArray
var WarmupCountdown  : int
var SpeedupVoteCount : int

func toString() -> String:
	var res = "BoxId:" + String(BoxId) + " "
	res += "Name:" + String(Name) + " "
	res += "MinPlayerCount:" + String(MinPlayerCount) + " "
	res += "MaxPlayerCount:" + String(MaxPlayerCount) + " "
	res += "PlayerCount:" + String(PlayerCount) + " "
	res += "EntryFee:" + String(EntryFee) + " "
	res += "Reward:" + String(Reward) + " "	
	res += "MaxBoxAge:" + String(MaxBoxAge) + " "	
	res += "CreationTime:" + String(CreationTime) + " "	
	res += "Status:" + String(Status) + " "	
	res += "WarmupCountdown:" + String(WarmupCountdown)	 + " "
	res += "SpeedupVoteCount:" + String(SpeedupVoteCount)	
	return res;
	

# Get readable stauts
static func parse_status(status: int)->String:
	if status == BoxStatusOpen: 
		return "Open"
	if status == BoxStatusWarmup:
		return "Warmup"
	if status == BoxStatusClosed:
		return "Closed"
	if status == BoxStatusDeleted:
		return "Deleted"
	if status == BoxStatusDeleting:
		return "Deleting"
	if status == BoxStatusPlaying:
		return "Playing"
	if status == BoxStatusSimulating:
		return "Simulating"	
	return "Unknown"
