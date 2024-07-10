-- ==============================================================================
-- Schema DDL & Analytical Queries: Database [Laminazione]
-- Tesi di Laurea: Alberto Mergoni - Universita degli Studi di Brescia (UNIBS)
-- Partner Industriale: Automazioni Industriali Capitanio (AIC)
-- ==============================================================================

USE [master];
GO

IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'Laminazione')
BEGIN
    CREATE DATABASE [Laminazione];
END
GO

USE [Laminazione];
GO

-- 1. Tabella Ordini di Produzione
IF OBJECT_ID('dbo.ORDINI', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.ORDINI (
        ID_ordine INT IDENTITY(1,1) PRIMARY KEY,
        stato_ordine INT NOT NULL DEFAULT 1, -- 1: Attivo, 5: Completato, 9: Annullato
        lunghezza FLOAT NOT NULL,
        sezione FLOAT NOT NULL,
        materiale NVARCHAR(100) NOT NULL,
        n_billette INT NOT NULL,
        n_bill_pesate INT NOT NULL DEFAULT 0,
        qualita FLOAT NULL DEFAULT 100.0,
        data_creazione DATETIME2 NOT NULL DEFAULT GETDATE(),
        data_fine DATETIME2 NULL
    );
END
GO

-- 2. Tabella Billette e Tracking di Processo
IF OBJECT_ID('dbo.BILLETTE', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.BILLETTE (
        ID_billetta INT IDENTITY(1,1) PRIMARY KEY,
        ID_ordine INT NOT NULL CONSTRAINT FK_Billette_Ordini FOREIGN KEY REFERENCES dbo.ORDINI(ID_ordine),
        stato_billetta INT NOT NULL DEFAULT 1, -- 1: In attesa, 2: Pesata, 3: In Forno, 4: Sfornata, 5: In Laminazione, 6: Finito
        peso_nominale FLOAT NOT NULL,
        peso_pesato FLOAT NULL,
        peso_prod_finito FLOAT NULL,
        temperatura_forno FLOAT NULL,
        data_pesatura DATETIME2 NULL,
        data_sfornamento DATETIME2 NULL,
        data_fine_laminazione DATETIME2 NULL,
        gabbia_corrente INT NULL DEFAULT 0
    );
END
GO

-- 3. Tabella Utilities, Telemetria & KPI di Impianto
IF OBJECT_ID('dbo.UTILITY', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.UTILITY (
        ID_utility INT PRIMARY KEY,
        nome_parametro NVARCHAR(100) NOT NULL,
        valore FLOAT NOT NULL,
        unita_misura NVARCHAR(20) NULL,
        ultimo_aggiornamento DATETIME2 NOT NULL DEFAULT GETDATE()
    );

    -- Dati base di utility per calcolo OEE (Disponibilita, Prestazioni)
    INSERT INTO dbo.UTILITY (ID_utility, nome_parametro, valore, unita_misura)
    VALUES 
        (1, N'Consumo Gas Metano Forno', 1420.5, N'Nm3/h'),
        (2, N'Pressione Acqua Circuiti Raffreddamento', 6.2, N'bar'),
        (3, N'Potenza Attiva Totale Laminatoio', 3850.0, N'kW'),
        (4, N'Ore Operative Impianto (Disponibilita)', 22.8, N'ore/24h'),
        (5, N'Billette Prodotte su Target (Prestazioni)', 1085.0, N'bill/1140');
END
GO

-- ==============================================================================
-- QUERY DI SUPERVISIONE E ANALISI (Integrate in Grafana)
-- ==============================================================================

-- A. Estrazione Piano di Carica Attivo
SELECT 
    ID_ordine, 
    lunghezza, 
    sezione, 
    materiale, 
    data_creazione AT TIME ZONE 'Central European Standard Time' AS data_creazione_locale, 
    (n_billette - n_bill_pesate) AS rimanenti, 
    n_billette 
FROM dbo.ORDINI 
WHERE stato_ordine = 1;

-- B. Produzione Cumulata e Pesi Billette Sfornate
SELECT 
    data_sfornamento AT TIME ZONE 'Central European Standard Time' AS data_sfornamento_locale, 
    peso_prod_finito
FROM dbo.BILLETTE
WHERE stato_billetta = 6
ORDER BY data_sfornamento ASC;

-- C. Indici Componenti OEE:
-- C1. Disponibilita (Operating Time / Planned Time)
SELECT (valore / 24.0) * 100.0 AS disponibilita_pct 
FROM dbo.UTILITY 
WHERE ID_utility = 4;

-- C2. Prestazioni (Actual Output / Theoretical Max Output)
SELECT (valore / 1140.0) * 100.0 AS prestazioni_pct 
FROM dbo.UTILITY 
WHERE ID_utility = 5;

-- C3. Qualita Media Giornaliera (Good Output / Total Output)
SELECT 
    AVG(qualita) AS qualita_media_pct, 
    CONVERT(DATE, data_fine AT TIME ZONE 'Central European Standard Time') AS giorno
FROM dbo.ORDINI
WHERE stato_ordine = 5
GROUP BY CONVERT(DATE, data_fine AT TIME ZONE 'Central European Standard Time');
GO
