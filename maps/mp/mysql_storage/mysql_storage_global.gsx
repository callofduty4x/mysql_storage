#include maps\mp\mysql_storage\_mysql_storage_util;

// sParam is optional.
AddToGlobalStorage(sKey, Data, sParam)
{
    _AddToStorage("storage_global", sKey, Data, sParam);
}

// sParam is optional.
GetFromGlobalStorage(sKey, sParam)
{
    return _GetFromStorage("storage_global", sKey, sParam);
}

// sParam is optional.
DeleteFromGlobalStorage(sKey, sParam)
{
    _DeleteFromStorage("storage_global", sKey, sParam);
}
