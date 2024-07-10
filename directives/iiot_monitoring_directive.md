# SOP: Supervisione Impianto Siderurgico e Calcolo OEE

## Obiettivo
Monitorare i flussi operativi del laminatoio a caldo, assicurare il tracciamento continuo delle billette (dalla fase di pesatura e carica in forno fino alla laminazione finita) e calcolare gli indici di efficienza globale (OEE) per abilitare la manutenzione predittiva.

## Input e Sorgenti Dati
1. **Flussi Node-RED (`src/node_red/flows.json`):**
   - Acquisizione telemetria PLC e sensori di campo (temperature pirometri, velocità gabbie, assorbimenti motori, scanner barcode).
2. **Database Microsoft SQL Server (`data/sql/schema_laminazione.sql`):**
   - Tabelle `ORDINI`, `BILLETTE`, `UTILITY`.
3. **Piattaforma di Supervisione Grafana (`src/grafana/dashboard_laminazione.json`):**
   - Canvas di impianto, gauge di usura rulli, allarmi termici e monitoraggio OEE.

## Workflow Operativo a 3 Livelli

1. **Livello 1 (Direttiva):**
   - Definire i parametri critici di processo (temperatura forno tra 1140°C e 1200°C; soglia allarme usura gabbie > 75%).
   - Impostare i target di produzione giornalieri (es. 1140 billette/giorno).

2. **Livello 2 (Orchestrazione):**
   - Verificare lo stato dei container Docker (`docker-compose up -d`).
   - Monitorare la ricezione dei pacchetti TCP/IP su Node-RED porta 1880.
   - Attivare allarmi su superamento soglie.

3. **Livello 3 (Esecuzione):**
   - Eseguire `python execution/simulate_telemetry.py --billets 20` per collaudare la pipeline e generare il report OEE.
