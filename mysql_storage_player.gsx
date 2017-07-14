#include maps\mp\mysql_storage\_mysql_storage_util;

// Store non-volatile player specific data.

// Call this on player entity.
AddToPlayerStorage(sKey, Data)
{
    _AddToStorage("storage_player", sKey, Data, self getGuid());
}

// Call this on player entity.
GetFromPlayerStorage(sKey)
{
    return _GetFromStorage("storage_player", sKey, self getGuid());
}
