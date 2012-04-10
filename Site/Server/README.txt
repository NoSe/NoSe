
README
------

Il contesto pu˜ essere: 

> http://localhost:8080/NoSeVaadin

Lista funzionalitˆ
--------------------------------------------------------------------------------
Per inserire dati nel mongo db collegato:

http://localhost:8080/NoSeVaadin/import?data={"date": 1325602800000, "device": "pippo", "type": "pippo", "value": 33.0 }

--------------------------------------------------------------------------------

Per richiedere una serie di dati di un device e di un tipo:

/export?from=1325000243527&to=1325605043527&device=device&type=metrics

Ritorna la lista delle metriche in un dato intervallo

--------------------------------------------------------------------------------

Per validare (cambiare status) ad un oggetto mongo:

/validate?id=4f0c55066dee75ac9120774d&status=1

1: valido
-1: non valido
0: da validare


