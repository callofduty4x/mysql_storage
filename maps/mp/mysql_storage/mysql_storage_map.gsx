#include maps\mp\mysql_storage\_mysql_storage_util;

// Store non-volatile map specific data.

AddToMapStorage(sKey, Data)
{
    _AddToStorage("storage_map", sKey, Data, getDvar("mapname"));
}

GetFromMapStorage(sKey)
{
    return _GetFromStorage("storage_map", sKey, getDvar("mapname"));
}

DeleteFromMapStorage(sKey)
{
    _DeleteFromStorage("storage_map", sKey, getDvar("mapname"));
}
