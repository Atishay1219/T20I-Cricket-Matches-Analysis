USE T20;
SELECT * FROM T20I

--Q1 Identify matches played between two specific teams (e.g., India and South Africa) in 2024 and their results.

WITH base AS (
    SELECT 
        CASE 
            WHEN Team1 < Team2 THEN Team1 ELSE Team2 
        END AS TeamA,
        CASE 
            WHEN Team1 < Team2 THEN Team2 ELSE Team1 
        END AS TeamB,
        Winner
    FROM T20I
    WHERE YEAR(MatchDate) = 2024
)

SELECT 
    TeamA,
    TeamB,
    COUNT(*) AS TotalMatches,
    SUM(CASE WHEN Winner = TeamA THEN 1 ELSE 0 END) AS TeamA_Wins,
    SUM(CASE WHEN Winner = TeamB THEN 1 ELSE 0 END) AS TeamB_Wins,
    
    CASE 
        WHEN SUM(CASE WHEN Winner = TeamA THEN 1 ELSE 0 END) >
             SUM(CASE WHEN Winner = TeamB THEN 1 ELSE 0 END)
        THEN TeamA
        WHEN SUM(CASE WHEN Winner = TeamA THEN 1 ELSE 0 END) <
             SUM(CASE WHEN Winner = TeamB THEN 1 ELSE 0 END)
        THEN TeamB
        ELSE 'Tie'
    END AS DominantTeam

FROM base
GROUP BY TeamA, TeamB
ORDER BY TeamA, TeamB;

--Q2 Find the team with the highest number of wins in 2024 and the total matches it won.

SELECT TOP 1
    Winner,
    COUNT(*) AS TotalWins
FROM T20I
WHERE YEAR(MatchDate) = 2024
GROUP BY Winner
ORDER BY TotalWins DESC;

--Q3 Rank the teams based on the total number of wins in 2024.

SELECT 
    Winner AS Team,
    COUNT(*) AS TotalWins,
    
    RANK() OVER (ORDER BY COUNT(*) DESC) AS TeamRank

FROM T20I
WHERE YEAR(MatchDate) = 2024

GROUP BY Winner
ORDER BY TeamRank;

--Q4 Which team had the highest average winning margin (in runs), and what was the average margin?

SELECT TOP 1
    Winner AS Team,

    AVG(
        CAST(REPLACE(Margin, ' runs', '') AS INT)
    ) AS TeamAvgRunMargin,

    (
        SELECT AVG(
            CAST(REPLACE(Margin, ' runs', '') AS INT)
        )
        FROM T20I
        WHERE Margin LIKE '%runs'
    ) AS OverallAvgRunMargin

FROM T20I

WHERE Margin LIKE '%runs'

GROUP BY Winner

ORDER BY TeamAvgRunMargin DESC;

--Q5 Which team had the highest average winning margin (in wickets), and what was the average margin?

SELECT TOP 1
    Winner AS Team,

    AVG(
        CAST(REPLACE(Margin, ' wickets', '') AS INT)
    ) AS TeamAvgWicketMargin,

    (
        SELECT AVG(
            CAST(REPLACE(Margin, ' wickets', '') AS INT)
        )
        FROM T20I
        WHERE Margin LIKE '%wickets'
    ) AS OverallAvgWicketMargin

FROM T20I

WHERE Margin LIKE '%wickets'

GROUP BY Winner

ORDER BY TeamAvgWicketMargin DESC;

--Q6 List all matches where the winning margin was greater than the average margin across all matches.

SELECT *
FROM T20I

WHERE CAST(
    REPLACE(
        REPLACE(
            REPLACE(Margin,' runs',''),
        ' run',''),
    ' wickets','')
AS INT)

>

(
    SELECT AVG(

        CAST(
            REPLACE(
                REPLACE(
                    REPLACE(Margin,' runs',''),
                ' run',''),
            ' wickets','')
        AS INT)

    )

    FROM T20I
);

--Q7 Find the team with the most wins when chasing a target (wins by wickets)

SELECT TOP 1
    Winner AS Team,
    COUNT(*) AS ChasingWins

FROM T20I

WHERE Margin LIKE '%wickets'

GROUP BY Winner

ORDER BY ChasingWins DESC;

--Q8 Head-to-head record between two selected teams (e.g., England vs Australia).

WITH matches AS (
    SELECT 
        CASE 
            WHEN Team1 < Team2 THEN Team1 ELSE Team2 
        END AS TeamA,

        CASE 
            WHEN Team1 < Team2 THEN Team2 ELSE Team1 
        END AS TeamB,

        Winner

    FROM T20I
)

SELECT 
    TeamA,
    TeamB,

    COUNT(*) AS TotalMatches,

    SUM(CASE WHEN Winner = TeamA THEN 1 ELSE 0 END) AS TeamA_Wins,

    SUM(CASE WHEN Winner = TeamB THEN 1 ELSE 0 END) AS TeamB_Wins

FROM matches

GROUP BY TeamA, TeamB

ORDER BY TeamA, TeamB;

--Q9 Identify the month in 2024 with the highest number of T20I matches played.

SELECT TOP 1

    DATENAME(MONTH, MatchDate) AS MonthName,

    COUNT(*) AS TotalMatches

FROM T20I

WHERE YEAR(MatchDate) = 2024

GROUP BY DATENAME(MONTH, MatchDate), MONTH(MatchDate)

ORDER BY TotalMatches DESC;

--Q10For each team, find how many matches they played in 2024 and their win percentage.

WITH all_teams AS (

    SELECT Team1 AS Team FROM T20I
    WHERE YEAR(MatchDate) = 2024

    UNION ALL

    SELECT Team2 AS Team FROM T20I
    WHERE YEAR(MatchDate) = 2024
)

SELECT 
    a.Team,

    COUNT(*) AS MatchesPlayed,

    (
        SELECT COUNT(*)
        FROM T20I t
        WHERE t.Winner = a.Team
        AND YEAR(MatchDate) = 2024
    ) AS Wins,

    ROUND(
        (
            (
                SELECT COUNT(*)
                FROM T20I t
                WHERE t.Winner = a.Team
                AND YEAR(MatchDate) = 2024
            ) * 100.0
        ) / COUNT(*),
        2
    ) AS WinPercentage

FROM all_teams a

GROUP BY a.Team

ORDER BY WinPercentage DESC;

--Q11 Identify the most successful team at each ground (team with most wins per ground).

SELECT 
    Ground,
    Winner AS Most_Successful_Team,
    COUNT(*) AS TotalWins

FROM T20I

GROUP BY Ground, Winner

ORDER BY TotalWins DESC;